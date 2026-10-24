part of '../../main.dart';

final authorProfileRevision = ValueNotifier<int>(0);
Future<List<_ProfileCommentHit>> loadCommentsByAuthor(String uid) async {
  final viewer = FirebaseAuth.instance.currentUser?.uid;
  final blocks = blockedListRevision.value;
  final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
      .httpsCallable('readProfileComments', options: HttpsCallableOptions(
        timeout: const Duration(seconds: 120),
          ))
      .call<Map<String, dynamic>>({'userId': uid});
  if (viewer != FirebaseAuth.instance.currentUser?.uid ||
      blocks != blockedListRevision.value || response.data['posts'] is! List) {
    throw StateError(mainTextCurrent("تعذر تأكيد صلاحية عرض التعليقات"));
  }
  final hits = <_ProfileCommentHit>[];
  for (final row in response.data['posts'] as List) {
    if (row is! Map || row['id'] is! String || row['data'] is! Map || row['commentIds'] is! List) {
      throw StateError(mainTextCurrent("بيانات تعليقات غير صالحة"));
    }
    final post = _Post.fromData(row['id'] as String, Map<String, dynamic>.from(row['data'] as Map));
    final selected = Set<String>.from(row['commentIds'] as List);
    void walk(List<_Comment> comments) {
      for (final comment in comments) {
        if (comment.authorId == uid && selected.remove(comment.id)) {
          hits.add(_ProfileCommentHit(post: post, comment: comment));
        }
        walk(comment.replies);
      }
    }
    walk(post.comments);
  }
  hits.sort((a, b) => b.comment.createdAt.compareTo(a.comment.createdAt));
  return hits;
}
Future<void> propagateAuthorToPosts({
  required String uid,
  String? photoUrl,
  String? authorName,
  bool useFullName = false,
}) async {
  if (photoUrl != null) await syncOwnPostIdentity(uid, 'photo');
  if (authorName != null && authorName.trim().isNotEmpty) {
    await syncOwnPostIdentity(uid, useFullName ? 'fullName' : 'displayName');
  }
  if (FirebaseAuth.instance.currentUser?.uid == uid) authorProfileRevision.value++;
}

Future<Set<String>> loadBlockedUserIds() =>
    _loadNotificationBlockedIds(FirebaseAuth.instance.currentUser?.uid);

bool isBlockedPost(_Post post, Set<String> blockedIds) {
  final author = (post.authorId ?? '').trim();
  if (author.isNotEmpty && blockedIds.contains(author)) return true;

  if (post.isRepost && post.repostOf != null) {
    final orig = (post.repostOf!['authorId'] ?? '').toString().trim();
    if (orig.isNotEmpty && blockedIds.contains(orig)) return true;
  }
  return false;
}

Future<void> setUserPresence({required bool online}) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  try {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'isOnline': online,
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  } catch (e) {
    debugPrint('setUserPresence failed: $e');
  }
}

Future<Set<String>> loadHiddenPostIds() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return {};
  try {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('hidden_posts')
        .get();
    return snap.docs.map((d) => d.id).toSet();
  } catch (e) {
    debugPrint('loadHiddenPostIds failed: $e');
    return {};
  }
}



class _DownloadPickResult {
  const _DownloadPickResult(this.items);
  final List<_PostMediaItem> items;
}

class _DownloadMediaSheet extends StatefulWidget {
  const _DownloadMediaSheet({required this.postId, required this.items});
  final String postId;
  final List<_PostMediaItem> items;

  @override
  State<_DownloadMediaSheet> createState() => _DownloadMediaSheetState();
}

class _DownloadMediaSheetState extends State<_DownloadMediaSheet> {
  late final Set<int> _selected = {for (var i = 0; i < widget.items.length; i++) i};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mainText(context, "اختر ما تريد تحميله"),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, i) {
                final item = widget.items[i];
                final on = _selected.contains(i);
                final isVideo = item.kind == _MediaKind.video;
                return GestureDetector(
                  onTap: () => setState(() {
                    if (on) {
                      _selected.remove(i);
                    } else {
                      _selected.add(i);
                    }
                  }),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (isVideo)
                          ColoredBox(
                            color: Colors.black87,
                            child: Icon(Icons.play_circle_outline_rounded,
                                color: Colors.white.withValues(alpha: 0.85), size: 36),
                          )
                        else
                          Uri.tryParse(item.path)?.host == 'firebasestorage.googleapis.com'
                              ? _AuthorizedImageView(postId: widget.postId, path: item.path, preview: true)
                              : item.path.startsWith('http')
                              ? ProtectedCachedNetworkImage(imageUrl: item.path, fit: BoxFit.cover)
                              : Image.file(File(item.path), fit: BoxFit.cover),
                        if (isVideo)
                          const Positioned(
                            left: 6,
                            bottom: 6,
                            child: Icon(Icons.videocam_rounded, color: Colors.white, size: 16),
                          ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Icon(
                            on ? Icons.check_circle_rounded : Icons.circle_outlined,
                            color: on ? AppTeal.main : Colors.white,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selected.isEmpty
                    ? null
                    : () {
                  final picked = _selected
                      .map((i) => widget.items[i]).toList();
                  Navigator.pop(context, _DownloadPickResult(picked));
                },
                style: FilledButton.styleFrom(foregroundColor: Colors.white, backgroundColor: AppTeal.main),
                child: Text(mainText(context, "تحميل ({0})", <Object?>[_selected.length])),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

