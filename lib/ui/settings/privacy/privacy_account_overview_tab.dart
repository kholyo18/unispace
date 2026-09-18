import 'package:cloud_functions/cloud_functions.dart';
import '../../../services/post_privacy_sync.dart';
import '../profile_privacy.dart';
import 'dart:async';
import 'dart:ui' as ui;


import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:UniSpace/features/settings/privacy/privacy_policy_screen.dart';
import 'package:UniSpace/features/settings/privacy/account_deletion_screen.dart';
import 'package:UniSpace/features/settings/privacy/data_retention_policy_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';


class PrivacySettings {
  const PrivacySettings({
    this.privateAccount = false,
    this.appearInSearch = true,
    this.suggestAccount = true,
    this.findByEmail = false,
    this.findByPhone = false,
    this.hideLikeCounts = false,
    this.messageRequests = true,
    this.readReceipts = true,
    this.typingIndicator = true,
    this.showOnline = true,
    this.showLastSeen = false,
    this.showEmailOnProfile = false,
    this.showAcademicInfo = true,
    this.showSocialLinks = true,
    this.followersVisibility = 'everyone',
    this.followingVisibility = 'everyone',
    this.whoCanComment = 'everyone',
    this.whoCanRepost = 'everyone',
    this.whoCanMention = 'everyone',
    this.whoCanMessage = 'mutual',
    this.hiddenWords = const [],

  });

  final bool privateAccount;
  final bool appearInSearch;
  final bool suggestAccount;
  final bool findByEmail;
  final bool findByPhone;
  final bool hideLikeCounts;
  final bool messageRequests;
  final bool readReceipts;
  final bool typingIndicator;
  final bool showOnline;
  final bool showLastSeen;
  final bool showEmailOnProfile;
  final bool showAcademicInfo;
  final bool showSocialLinks;
  final String followersVisibility;
  final String followingVisibility;
  final String whoCanComment;
  final String whoCanRepost;
  final String whoCanMention;
  final String whoCanMessage;
  final List<String> hiddenWords;

  factory PrivacySettings.fromMap(Map<String, dynamic>? raw) {
    final m = raw ?? const <String, dynamic>{};
    bool b(String k, bool d) => m[k] is bool ? m[k] as bool : d;
    String s(String k, String d) {
      final v = m[k]?.toString().trim();
      return (v == null || v.isEmpty) ? d : v;

    }
    List<String> words() {
      final raw = m['hiddenWords'];
      if (raw is! List) return const [];
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return PrivacySettings(
      privateAccount: b('privateAccount', false),
      appearInSearch: b('appearInSearch', true),
      suggestAccount: b('suggestAccount', true),
      findByEmail: m['findByEmail'] == true,
      findByPhone: m['findByPhone'] == true,
      hideLikeCounts: b('hideLikeCounts', false),
      messageRequests: b('messageRequests', true),
      readReceipts: b('readReceipts', true),
      typingIndicator: b('typingIndicator', true),
      showOnline: b('showOnline', true),
      showLastSeen: b('showLastSeen', false),
      showEmailOnProfile: b('showEmailOnProfile', false),
      showAcademicInfo: b('showAcademicInfo', true),
      showSocialLinks: b('showSocialLinks', true),
      followersVisibility: s('followersVisibility', 'everyone'),
      followingVisibility: s('followingVisibility', 'everyone'),
      whoCanComment: s('whoCanComment', 'everyone'),
      whoCanRepost: s('whoCanRepost', 'everyone'),
      whoCanMention: s('whoCanMention', 'everyone'),
      whoCanMessage: s('whoCanMessage', 'mutual'),
      hiddenWords: words(),
    );
  }

  Map<String, dynamic> toMap() => {
    'privateAccount': privateAccount,
    'appearInSearch': appearInSearch,
    'suggestAccount': suggestAccount,
    'findByEmail': findByEmail,
    'findByPhone': findByPhone,
    'hideLikeCounts': hideLikeCounts,
    'messageRequests': messageRequests,
    'readReceipts': readReceipts,
    'typingIndicator': typingIndicator,
    'showOnline': showOnline,
    'showLastSeen': showLastSeen,
    'showEmailOnProfile': showEmailOnProfile,
    'showAcademicInfo': showAcademicInfo,
    'showSocialLinks': showSocialLinks,
    'followersVisibility': followersVisibility,
    'followingVisibility': followingVisibility,
    'whoCanComment': whoCanComment,
    'whoCanRepost': whoCanRepost,
    'whoCanMention': whoCanMention,
    'whoCanMessage': whoCanMessage,
    'hiddenWords': hiddenWords,
  };

  PrivacySettings copyWith({
    bool? privateAccount,
    bool? appearInSearch,
    bool? suggestAccount,
    bool? findByEmail,
    bool? findByPhone,
    bool? hideLikeCounts,
    bool? messageRequests,
    bool? readReceipts,
    bool? typingIndicator,
    bool? showOnline,
    bool? showLastSeen,
    bool? showEmailOnProfile,
    bool? showAcademicInfo,
    bool? showSocialLinks,
    String? followersVisibility,
    String? followingVisibility,
    String? whoCanComment,
    String? whoCanRepost,
    String? whoCanMention,
    String? whoCanMessage,
    List<String>? hiddenWords,
  }) {
    return PrivacySettings(
      privateAccount: privateAccount ?? this.privateAccount,
      appearInSearch: appearInSearch ?? this.appearInSearch,
      suggestAccount: suggestAccount ?? this.suggestAccount,
      findByEmail: findByEmail ?? this.findByEmail,
      findByPhone: findByPhone ?? this.findByPhone,
      hideLikeCounts: hideLikeCounts ?? this.hideLikeCounts,
      messageRequests: messageRequests ?? this.messageRequests,
      readReceipts: readReceipts ?? this.readReceipts,
      typingIndicator: typingIndicator ?? this.typingIndicator,
      showOnline: showOnline ?? this.showOnline,
      showLastSeen: showLastSeen ?? this.showLastSeen,
      showEmailOnProfile: showEmailOnProfile ?? this.showEmailOnProfile,
      showAcademicInfo: showAcademicInfo ?? this.showAcademicInfo,
      showSocialLinks: showSocialLinks ?? this.showSocialLinks,
      followersVisibility: followersVisibility ?? this.followersVisibility,
      followingVisibility: followingVisibility ?? this.followingVisibility,
      whoCanComment: whoCanComment ?? this.whoCanComment,
      whoCanRepost: whoCanRepost ?? this.whoCanRepost,
      whoCanMention: whoCanMention ?? this.whoCanMention,
      whoCanMessage: whoCanMessage ?? this.whoCanMessage,
      hiddenWords: hiddenWords ?? this.hiddenWords,
    );
  }
}

class PrivacySettingsRepository {
  DocumentReference<Map<String, dynamic>>? _userRef() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  Future<PrivacySettings> load() async {
    final ref = _userRef();
    if (ref == null) return const PrivacySettings();
    try {
      final snap = await ref.get();
      final raw = snap.data()?['privacy'];
      final privacy = ProfilePrivacy.fromDocument(snap.data());
      return PrivacySettings.fromMap(raw is Map ? Map<String, dynamic>.from(raw) : null)
          .copyWith(privateAccount: privacy.isPrivate, showEmailOnProfile: privacy.showEmail);
    } catch (e) {
      debugPrint('privacy load failed: $e');
      return const PrivacySettings();
    }
  }

  Future<void> save(PrivacySettings settings, {required PrivacySettings previous}) async {
    final ref = _userRef();
    if (ref == null) throw StateError('not signed in');
    await ref.set({
      'privacy': {
        for (final entry in settings.toMap().entries)
          if (entry.value != previous.toMap()[entry.key]) entry.key: entry.value,
      },
      if (settings.privateAccount != previous.privateAccount)
        'profileVisibility': settings.privateAccount ? 'private' : 'public',
      if (settings.showEmailOnProfile != previous.showEmailOnProfile)
        'showEmailInProfile': settings.showEmailOnProfile,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

class PrivacyAccountOverviewTab extends StatefulWidget {
  const PrivacyAccountOverviewTab({super.key});

  @override
  State<PrivacyAccountOverviewTab> createState() =>
      _PrivacyAccountOverviewTabState();
}

class _PrivacyAccountOverviewTabState extends State<PrivacyAccountOverviewTab> {
  final _repo = PrivacySettingsRepository();
  PrivacySettings _settings = const PrivacySettings();
  bool _loading = true;

  static const _audienceLabels = {
    'everyone': 'الجميع',
    'followers': 'المتابعون',
    'mutual': 'المتبادلون',
    'none': 'لا أحد',
  };

  String _label(String key) => _audienceLabels[key] ?? key;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await _repo.load();
    if (!mounted) return;
    setState(() {
      _settings = loaded;
      _loading = false;
    });
  }

  Future<bool> _apply(PrivacySettings next) async {
    final prev = _settings;
    setState(() => _settings = next);
    try {
      await _repo.save(next, previous: prev);
      return true;
    } catch (e) {
      debugPrint('privacy save failed: $e');
      if (!mounted) return false;
      setState(() => _settings = prev);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ الإعداد')),
      );
      return false;
    }
  }

  bool _exporting = false;

  Future<void> _downloadMyData() async {
    if (_exporting) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول أولاً')),
      );
      return;
    }

    setState(() => _exporting = true);
    try {

      final profileResponse = await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('readOwnProfileExport').call(<String, dynamic>{});
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) throw StateError('Account changed');
      final profileExport = Map<String, dynamic>.from(profileResponse.data as Map);
      final userData = Map<String, dynamic>.from(profileExport['profile'] as Map);
      final exportedPrivacy = Map<String, dynamic>.from(profileExport['privacy'] as Map);

      void checkExportAccount() {
        if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) throw StateError('Account changed');
      }
      Future<List<Map<String, dynamic>>> col(String name) async {
        final items = <Map<String, dynamic>>[];
        String? cursor;
        while (true) {
          checkExportAccount();
          final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
              .httpsCallable('readOwnListExportPage').call({'collection': name, 'cursor': cursor});
          checkExportAccount();
          final page = Map<String, dynamic>.from(response.data as Map);
          for (final row in page['items'] as List) {
            items.add(Map<String, dynamic>.from(row as Map));
          }
          if (page['exhausted'] == true) {
            return items;
          }
          final next = page['cursor'];
          if (page['exhausted'] != false || next is! String || next.isEmpty ||
              (cursor != null && next.compareTo(cursor) <= 0)) {
            throw StateError('Invalid list export cursor');
          }
          cursor = next;
        }
      }

      final posts = <Map<String, dynamic>>[];
      String? cursor;
      while (true) {
        checkExportAccount();
        final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
            .httpsCallable('readOwnPostExportPage').call({'cursor': cursor});
        checkExportAccount();
        final page = Map<String, dynamic>.from(response.data as Map);
        for (final row in page['posts'] as List) {
          posts.add(Map<String, dynamic>.from(row as Map));
        }
        if (page['exhausted'] == true) {
          break;
        }
        final next = page['cursor'];
        if (page['exhausted'] != false || next is! String || next.isEmpty ||
            (cursor != null && next.compareTo(cursor) <= 0)) {
          throw StateError('Invalid export cursor');
        }
        cursor = next;
      }

      Object? jsonSafe(Object? v) {
        if (v == null) return null;
        if (v is Timestamp) return v.toDate().toIso8601String();
        if (v is DateTime) return v.toIso8601String();
        if (v is GeoPoint) {
          return {'lat': v.latitude, 'lng': v.longitude};
        }
        if (v is DocumentReference) return v.path;
        if (v is List) return v.map(jsonSafe).toList();
        if (v is Map) {
          return v.map((k, val) => MapEntry(k.toString(), jsonSafe(val)));
        }
        return v;
      }

      final payload = jsonSafe({
        'exportedAt': DateTime.now().toIso8601String(),
        'uid': uid,
        'profile': userData,
        'privacy': exportedPrivacy,
        'profileExportScope': 'Explicit personal profile fields and saved privacy settings; excludes device tokens, sessions, recovery data, internal security fields and unknown fields.',
        'posts': posts,
        'postsExportScope': 'Own posts and own comments on those posts; excludes voter identities, other users comments, poll responses and repost snapshots.',
        'listsExportScope': 'Relationship and saved/hidden item IDs, timestamps and references only; excludes cached names, photos and content snapshots.',
        'blockedAccounts': await col('blocked_accounts'),
        'hiddenPosts': await col('hidden_posts'),
        'following': await col('following'),
        'followers': await col('followers'),
        'savedPosts': await col('saved_posts'),
        'hiddenComments': await col('hidden_comments'),
      });

      checkExportAccount();
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/unispace-data-$uid.json',
      );
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(payload),
      );

      checkExportAccount();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          text: 'نسخة بيانات UniSpace',
        ),
      );
    } catch (e) {
      debugPrint('export data failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تجهيز الملف')),
      );
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  Future<void> _editHiddenWords() async {
    final saved = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _HiddenWordsSheet(initial: _settings.hiddenWords),
    );
    if (saved == null) return;
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    await _apply(_settings.copyWith(hiddenWords: saved));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.hintColor;

    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            'الخصوصية',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'تحكم في من يرى حسابك ومن يمكنه التفاعل معك.',
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
          const SizedBox(height: 22),

          _header('الحساب'),
          _card([
            _switchTile(
              icon: Icons.lock_outline_rounded,
              title: 'حساب خاص',
              subtitle:
              'المتابعة بموافقتك. المنشورات والمتابعون يظهرون للموافق عليهم فقط.',
              value: _settings.privateAccount,
              onChanged: (v) async {
                if (v) {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('تحويل الحساب إلى خاص؟'),
                      content: const Text(
                        'المتابعون الحاليون يبقون. أي متابعة جديدة تحتاج موافقتك، ولن تظهر منشوراتك لغير المتابعين.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('إلغاء'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('تأكيد'),
                        ),
                      ],
                    ),
                  );
                  if (ok != true) return;
                }
                if (!await _apply(_settings.copyWith(privateAccount: v))) return;
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid != null) {
                  await syncAuthorPrivateOnPosts(uid: uid, isPrivate: v);
                }
              },
            ),
            _navTile(
              icon: Icons.groups_outlined,
              title: 'من يرى قائمة المتابعين',
              value: _label(_settings.followersVisibility),
              onTap: () => _pickAudience(
                title: 'من يرى قائمة المتابعين',
                current: _settings.followersVisibility,
                onSave: (v) =>
                    _apply(_settings.copyWith(followersVisibility: v)),
              ),
            ),
            _navTile(
              icon: Icons.person_add_alt_outlined,
              title: 'من يرى قائمة المتابَعين',
              value: _label(_settings.followingVisibility),
              onTap: () => _pickAudience(
                title: 'من يرى قائمة المتابَعين',
                current: _settings.followingVisibility,
                onSave: (v) =>
                    _apply(_settings.copyWith(followingVisibility: v)),
              ),
            ),
          ]),

          _header('الظهور والبحث'),
          _card([
            _switchTile(
              icon: Icons.search_rounded,
              title: 'الظهور في البحث',
              subtitle: 'السماح بظهور حسابك عند البحث بالاسم.',
              value: _settings.appearInSearch,
              onChanged: (v) async {
                await _apply(_settings.copyWith(appearInSearch: v));
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid != null) {
                  await syncAuthorSearchFlagOnPosts(
                    uid: uid,
                    appearInSearch: v,
                  );
                }
              },
            ),
            _switchTile(
              icon: Icons.recommend_outlined,
              title: 'اقتراح حسابي للآخرين',
              subtitle: 'قد يظهر حسابك في اقتراحات المتابعة.',
              value: _settings.suggestAccount,
              onChanged: (v) =>
                  _apply(_settings.copyWith(suggestAccount: v)),
            ),
            _switchTile(
              icon: Icons.alternate_email_outlined,
              title: 'العثور عليّ بالبريد',
              subtitle: 'يسمح بالبحث عن حسابك إذا كُتب إيميلك كاملاً.',
              value: _settings.findByEmail,
              onChanged: (v) => _apply(_settings.copyWith(findByEmail: v)),
            ),
            _switchTile(
              icon: Icons.phone_outlined,
              title: 'العثور عليّ برقم الهاتف',
              subtitle: 'يسمح بالبحث عن حسابك إذا كُتب رقمك.',
              value: _settings.findByPhone,
              onChanged: (v) => _apply(_settings.copyWith(findByPhone: v)),
            ),
          ]),

          _header('المنشورات والتفاعل'),
          _card([
            _navTile(
              icon: Icons.mode_comment_outlined,
              title: 'من يمكنه التعليق',
              value: _label(_settings.whoCanComment),
              onTap: () => _pickAudience(
                title: 'من يمكنه التعليق',
                current: _settings.whoCanComment,
                onSave: (v) =>
                    _apply(_settings.copyWith(whoCanComment: v)),
              ),
            ),
            _navTile(
              icon: Icons.repeat_rounded,
              title: 'من يمكنه إعادة النشر',
              value: _label(_settings.whoCanRepost),
              onTap: () => _pickAudience(
                title: 'من يمكنه إعادة النشر',
                current: _settings.whoCanRepost,
                onSave: (v) =>
                    _apply(_settings.copyWith(whoCanRepost: v)),
              ),
            ),
            _navTile(
              icon: Icons.alternate_email,
              title: 'من يمكنه الإشارة إليّ',
              subtitle: 'الوسوم والإشارات في المنشورات والتعليقات.',
              value: _label(_settings.whoCanMention),
              onTap: () => _pickAudience(
                title: 'من يمكنه الإشارة إليّ',
                current: _settings.whoCanMention,
                onSave: (v) =>
                    _apply(_settings.copyWith(whoCanMention: v)),
              ),
            ),

            _switchTile(
              icon: Icons.favorite_border_rounded,
              title: 'إخفاء عدد الإعجابات',
              subtitle: 'لا يظهر عدد التصويتات على منشوراتك للآخرين.',
              value: _settings.hideLikeCounts,
              onChanged: (v) async {
                await _apply(_settings.copyWith(hideLikeCounts: v));
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid != null) {
                  await syncAuthorHideLikesOnPosts(uid: uid, hide: v);
                }
              },
            ),
            // _navTile(
            //   icon: Icons.filter_alt_outlined,
            //   title: 'الكلمات المخفية',
            //   subtitle: 'إخفاء تعليقات تحتوي كلمات معيّنة.',
            //   value: _settings.hiddenWords.isEmpty
            //       ? 'غير مفعّل'
            //       : '${_settings.hiddenWords.length} كلمة',
            //   onTap: _editHiddenWords,
            // ),
          ]),

          _header('الرسائل'),
          _card([
            _navTile(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'من يمكنه مراسلتي',
              value: _label(_settings.whoCanMessage),
              onTap: () => _pickAudience(
                title: 'من يمكنه مراسلتي',
                current: _settings.whoCanMessage,
                onSave: (v) =>
                    _apply(_settings.copyWith(whoCanMessage: v)),
              ),
            ),
            _switchTile(
              icon: Icons.mark_email_unread_outlined,
              title: 'طلبات الرسائل',
              subtitle: 'رسائل الغرباء تذهب إلى الطلبات بدل الصندوق.',
              value: _settings.messageRequests,
              onChanged: (v) =>
                  _apply(_settings.copyWith(messageRequests: v)),
            ),
            _switchTile(
              icon: Icons.done_all_rounded,
              title: 'إيصالات القراءة',
              subtitle:
              'إظهار أنك قرأت الرسالة. إن أوقفتها لن تراها عند الآخرين.',
              value: _settings.readReceipts,
              onChanged: (v) =>
                  _apply(_settings.copyWith(readReceipts: v)),
            ),
            _switchTile(
              icon: Icons.more_horiz_rounded,
              title: 'مؤشر الكتابة',
              subtitle: 'إظهار أنك تكتب الآن.',
              value: _settings.typingIndicator,
              onChanged: (v) =>
                  _apply(_settings.copyWith(typingIndicator: v)),
            ),
          ]),

          _header('النشاط'),
          _card([
            _switchTile(
              icon: Icons.circle,
              title: 'إظهار أنني متصل',
              subtitle: 'المتابعون أو من تراسلهم يرون حالة الاتصال.',
              value: _settings.showOnline,
              onChanged: (v) =>
                  _apply(_settings.copyWith(showOnline: v)),
            ),
            _switchTile(
              icon: Icons.schedule_rounded,
              title: 'آخر ظهور',
              subtitle: 'إظهار وقت آخر نشاط على الحساب.',
              value: _settings.showLastSeen,
              onChanged: (v) =>
                  _apply(_settings.copyWith(showLastSeen: v)),
            ),
          ]),

          _header('معلومات الملف الشخصي'),
          _card([
            _switchTile(
              icon: Icons.email_outlined,
              title: 'إظهار البريد في الملف',
              subtitle: 'يظهر بريدك للزائرين في صفحة الحساب.',
              value: _settings.showEmailOnProfile,
              onChanged: (v) =>
                  _apply(_settings.copyWith(showEmailOnProfile: v)),
            ),
            _switchTile(
              icon: Icons.school_outlined,
              title: 'إظهار المعلومات الأكاديمية',
              subtitle: 'الجامعة، الكلية، والتخصص.',
              value: _settings.showAcademicInfo,
              onChanged: (v) =>
                  _apply(_settings.copyWith(showAcademicInfo: v)),
            ),
            _switchTile(
              icon: Icons.link_rounded,
              title: 'إظهار الروابط الاجتماعية',
              subtitle: 'GitHub وLinkedIn والمعرض.',
              value: _settings.showSocialLinks,
              onChanged: (v) =>
                  _apply(_settings.copyWith(showSocialLinks: v)),
            ),
          ]),

          _header('البيانات والسلامة'),
          _card([
            _navTile(
              icon: Icons.block_rounded,
              title: 'الحسابات المحظورة',
              subtitle: 'إدارة من حظرتهم.',
              onTap: () {
                final go = PrivacyExternalRoutes.blockedAccounts;
                if (go == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تعذر فتح القائمة')),
                  );
                  return;
                }
                Navigator.of(context).push(MaterialPageRoute(builder: go));
              },
            ),
            _navTile(
              icon: Icons.visibility_off_outlined,
              title: 'العناصر المخفية',
              subtitle: 'منشورات أخفيتها من الفيد.',
              onTap: () {
                final go = PrivacyExternalRoutes.hiddenPosts;
                if (go == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تعذر فتح القائمة')),
                  );
                  return;
                }
                Navigator.of(context).push(MaterialPageRoute(builder: go));
              },
            ),
            _navTile(
              icon: Icons.download_outlined,
              title: 'تنزيل بياناتي',
              subtitle: _exporting
                  ? 'جارٍ تجهيز النسخة...'
                  : 'نسخة من البيانات التي يدعمها مسار التصدير الحالي.',
              onTap: _exporting ? null : _downloadMyData,
            ),
            _navTile(
              icon: Icons.delete_outline_rounded,
              title: 'حذف الحساب والبيانات',
              subtitle: 'تقديم طلب حذف مرتبط بالحساب الحالي.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AccountDeletionScreen(),
                  ),
                );
              },
            ),
            _navTile(
              icon: Icons.policy_outlined,
              title: 'سياسة الحذف والاحتفاظ',
              subtitle: 'المدد المستهدفة وحدود الاحتفاظ.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DataRetentionPolicyScreen(),
                  ),
                );
              },
            ),
            _navTile(
              icon: Icons.privacy_tip_outlined,
              title: 'سياسة الخصوصية',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen(),
                  ),
                );
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _header(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13.5,
          color: Theme.of(context).hintColor,
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.35),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1)
                Divider(
                  height: 1,
                  indent: 56,
                  color: theme.dividerColor.withValues(alpha: 0.25),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      secondary: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: TextStyle(color: Theme.of(context).hintColor)),
      value: value,
      onChanged: onChanged,
    );
  }

  Future<void> _pickAudience({
    required String title,
    required String current,
    required Future<void> Function(String value) onSave,
  }) async {
    const options = <(String, String, String)>[
      ('everyone', 'الجميع', 'أي شخص في UniSpace'),
      ('followers', 'المتابعون', 'من يتابعك فقط'),
      ('mutual', 'المتبادلون', 'من تتابعانه بعضكما'),
      ('none', 'لا أحد', 'أنت فقط'),
    ];

    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              for (final o in options)
                ListTile(
                  title: Text(
                    o.$2,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(o.$3),
                  trailing: current == o.$1
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => Navigator.pop(ctx, o.$1),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked == null || picked == current) return;
    await onSave(picked);
  }

  Widget _navTile({
    required IconData icon,
    required String title,
    String? subtitle,
    String? value,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: subtitle == null
          ? (value == null
          ? null
          : Text(value, style: TextStyle(color: theme.hintColor)))
          : Text(
        value == null ? subtitle : '$subtitle\n$value',
        style: TextStyle(color: theme.hintColor),
      ),
      trailing: const Icon(Icons.chevron_left_rounded),
      onTap: onTap,
    );
  }
}

Future<void> syncAuthorPrivateOnPosts({
  required String uid,
  required bool isPrivate,
}) async {
  await syncOwnPostPrivacy(uid);
}

Future<void> syncAuthorSearchFlagOnPosts({
  required String uid,
  required bool appearInSearch,
}) async {
  await syncOwnPostPrivacy(uid);
}

Future<void> syncAuthorHideLikesOnPosts({
  required String uid,
  required bool hide,
}) async {
  await syncOwnPostPrivacy(uid);
}

class _HiddenWordsSheet extends StatefulWidget {
  const _HiddenWordsSheet({required this.initial});
  final List<String> initial;

  @override
  State<_HiddenWordsSheet> createState() => _HiddenWordsSheetState();
}

class _HiddenWordsSheetState extends State<_HiddenWordsSheet> {
  late final TextEditingController _ctrl;
  late List<String> _words;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    _words = List<String>.from(widget.initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add() {
    final w = _ctrl.text.trim();
    if (w.isEmpty) return;
    if (_words.any((e) => e.toLowerCase() == w.toLowerCase())) {
      _ctrl.clear();
      return;
    }
    setState(() => _words.add(w));
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'الكلمات المخفية',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'لن تظهر لك التعليقات التي تحتوي هذه الكلمات.',
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'أضف كلمة أو عبارة',
                    isDense: true,
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded),
                onPressed: _add,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_words.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'لا توجد كلمات بعد',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _words.length,
                itemBuilder: (_, i) {
                  return ListTile(
                    dense: true,
                    title: Text(_words[i]),
                    trailing: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () =>
                          setState(() => _words.removeAt(i)),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(List<String>.from(_words)),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class PrivacyExternalRoutes {
  static WidgetBuilder? blockedAccounts;
  static WidgetBuilder? hiddenPosts;
}