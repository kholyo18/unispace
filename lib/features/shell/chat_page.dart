import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import '../../core/branding.dart';

String directChatId(String a, String b) {
  final ids = [a, b]..sort();
  return '${ids[0]}_${ids[1]}';
}

String _chatTimeAgo(DateTime? dt) {
  if (dt == null) return '';
  final d = DateTime.now().difference(dt);
  if (d.inSeconds < 60) return 'الآن';
  if (d.inMinutes < 60) return '${d.inMinutes}د';
  if (d.inHours < 24) return '${d.inHours}س';
  if (d.inDays < 7) return '${d.inDays}ي';
  return '${dt.day}/${dt.month}';
}

Future<Set<String>> _chatBlockedIds() async {
  final me = FirebaseAuth.instance.currentUser?.uid;
  if (me == null) return {};
  final ids = <String>{};
  try {
    final mine = await FirebaseFirestore.instance
        .collection('users')
        .doc(me)
        .collection('blocked_accounts')
        .get();
    ids.addAll(mine.docs.map((d) => d.id));
  } catch (_) {}
  try {
    final theirs = await FirebaseFirestore.instance
        .collection('users')
        .doc(me)
        .collection('blocked_by')
        .get();
    ids.addAll(theirs.docs.map((d) => d.id));
  } catch (_) {}
  return ids;
}

class ChatPage extends StatelessWidget {
  const ChatPage({super.key, required this.onOpenDrawer});

  final VoidCallback onOpenDrawer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final me = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: onOpenDrawer,
            ),
            const SizedBox(width: 4),
            Text(
              'المحادثات',
              style: GoogleFonts.pacifico(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppTeal.main,
              ),
            ),
          ],
        ),
      ),
      body: me == null
          ? const Center(child: Text('سجّل الدخول أولاً'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('memberIds', arrayContains: me)
            .orderBy('lastMessageAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            debugPrint('chats stream error: ${snap.error}');
            return Center(
              child: Text(
                'تعذر تحميل المحادثات',
                style: TextStyle(color: theme.hintColor),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const _ChatsEmptyState();

          return FutureBuilder<Set<String>>(
            future: _chatBlockedIds(),
            builder: (context, blockedSnap) {
              final blocked = blockedSnap.data ?? {};
              final visible = docs.where((d) {
                final ids = (d.data()['memberIds'] as List? ?? [])
                    .map((e) => e.toString());
                return !ids.any(
                      (id) => id != me && blocked.contains(id),
                );
              }).toList();
              if (visible.isEmpty) return const _ChatsEmptyState();
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 120),
                itemCount: visible.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  indent: 76,
                  color: theme.dividerColor.withValues(alpha: 0.25),
                ),
                itemBuilder: (context, i) {
                  return _ChatTile(doc: visible[i], myUid: me);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({required this.doc, required this.myUid});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String myUid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = doc.data();
    final members = Map<String, dynamic>.from(data['members'] ?? {});
    final peerId = (data['memberIds'] as List? ?? [])
        .map((e) => e.toString())
        .firstWhere((id) => id != myUid, orElse: () => '');
    final peer = Map<String, dynamic>.from(members[peerId] ?? {});
    final name = (peer['name'] ?? 'طالب UniSpace').toString();
    final photo = peer['photoUrl']?.toString();
    final last = (data['lastMessage'] ?? '').toString();
    final at = data['lastMessageAt'];
    final time = _chatTimeAgo(at is Timestamp ? at.toDate() : null);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppTeal.main.withValues(alpha: 0.15),
        backgroundImage: (photo != null && photo.isNotEmpty)
            ? NetworkImage(photo)
            : null,
        child: (photo == null || photo.isEmpty)
            ? const Icon(Icons.person_outline)
            : null,
      ),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
      subtitle: Text(
        last.isEmpty ? 'لا توجد رسائل بعد' : last,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: theme.hintColor, fontSize: 13),
      ),
      trailing: Text(
        time,
        style: TextStyle(color: theme.hintColor, fontSize: 11),
      ),
      onTap: () {
        if (peerId.isEmpty) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatThreadScreen(
              chatId: doc.id,
              peerId: peerId,
              peerName: name,
              peerPhotoUrl: photo,
            ),
          ),
        );
      },
    );
  }
}

class _ChatsEmptyState extends StatelessWidget {
  const _ChatsEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [AppTeal.accent, AppTeal.chat],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: const Icon(
                Icons.chat_bubble_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'لا توجد محادثات',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ابدأ محادثة من ملف شخص ما.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> openDirectChat(
    BuildContext context, {
      required String peerId,
      required String peerName,
      String? peerPhotoUrl,
    }) async {
  final me = FirebaseAuth.instance.currentUser;
  if (me == null || peerId.isEmpty || peerId == me.uid) return;

  var myName = (me.displayName ?? '').trim();
  if (myName.isEmpty) myName = 'طالب UniSpace';

  final id = directChatId(me.uid, peerId);
  final ref = FirebaseFirestore.instance.collection('chats').doc(id);
  final snap = await ref.get();
  if (!snap.exists) {
    await ref.set({
      'type': 'direct',
      'memberIds': [me.uid, peerId],
      'members': {
        me.uid: {'name': myName, 'photoUrl': me.photoURL},
        peerId: {'name': peerName, 'photoUrl': peerPhotoUrl},
      },
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  if (!context.mounted) return;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ChatThreadScreen(
        chatId: id,
        peerId: peerId,
        peerName: peerName,
        peerPhotoUrl: peerPhotoUrl,
      ),
    ),
  );
}

class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({
    super.key,
    required this.chatId,
    required this.peerId,
    this.peerName,
    this.peerPhotoUrl,
  });

  final String chatId;
  final String peerId;
  final String? peerName;
  final String? peerPhotoUrl;

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  List<types.Message> _messages = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  late final types.User _me;
  late final types.User _peer;

  CollectionReference<Map<String, dynamic>> get _msgs =>
      FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages');

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _me = types.User(id: uid);
    _peer = types.User(
      id: widget.peerId,
      firstName: widget.peerName,
      imageUrl: widget.peerPhotoUrl,
    );
    _sub = _msgs.orderBy('createdAt', descending: true).snapshots().listen((snap) {
      if (!mounted) return;
      setState(() {
        _messages = snap.docs.map(_toMessage).toList();
      });
    }, onError: (e) => debugPrint('messages stream error: $e'));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  types.TextMessage _toMessage(
      QueryDocumentSnapshot<Map<String, dynamic>> d,
      ) {
    final data = d.data();
    final authorId = (data['authorId'] ?? '').toString();
    final created = data['createdAt'];
    return types.TextMessage(
      id: d.id,
      author: authorId == _peer.id ? _peer : types.User(id: authorId),
      createdAt: created is Timestamp
          ? created.millisecondsSinceEpoch
          : DateTime.now().millisecondsSinceEpoch,
      text: (data['text'] ?? '').toString(),
    );
  }

  Future<void> _handleSendPressed(types.PartialText message) async {
    final t = message.text.trim();
    if (t.isEmpty || _me.id.isEmpty) return;
    await _msgs.add({
      'authorId': _me.id,
      'text': t,
      'type': 'text',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .update({
      'lastMessage': t,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderId': _me.id,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: (widget.peerPhotoUrl ?? '').isNotEmpty
                  ? NetworkImage(widget.peerPhotoUrl!)
                  : null,
              child: (widget.peerPhotoUrl ?? '').isEmpty
                  ? const Icon(Icons.person_outline, size: 18)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.peerName ?? 'محادثة',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Chat(
        messages: _messages,
        onSendPressed: _handleSendPressed,
        user: _me,
        showUserAvatars: true,
        l10n: const ChatL10nEn(
          inputPlaceholder: 'رسالة...',
          emptyChatPlaceholder: 'لا توجد رسائل بعد',
        ),
      ),
    );
  }
}