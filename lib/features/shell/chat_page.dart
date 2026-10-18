import '../../services/chat_download_coordinator.dart';
import 'chat/chat_transfer_center.dart';
import 'package:UniSpace/services/chat_unread_reminders.dart';
import '../../ui/settings/privacy/privacy_account_overview_tab.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:UniSpace/services/chat_local_persistence.dart';
import 'chat/chat_recording_leave_guard.dart';
import 'chat/chat_audio_player.dart';
import 'chat/chat_policy_image.dart';
import 'chat/chat_media_settings_page.dart';
import 'chat/chat_conversation_storage_page.dart';
import 'package:UniSpace/services/chat_audio_coordinator.dart';
import 'package:UniSpace/services/chat_media_policy.dart';
import 'chat/chat_context_widgets.dart';
import 'chat/chat_starred_messages_page.dart';
import 'package:UniSpace/services/chat_message_readers.dart';
import 'chat/chat_message_info_sheet.dart';
import 'chat/chat_nickname_sheet.dart';
import 'chat/chat_profile_avatar.dart';
import 'chat/chat_search_scroll_controller.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'chat/chat_message_search.dart';
import 'chat/chat_unified_search_page.dart';
import 'chat/chat_wallpaper_scaffold.dart';
import 'chat/chat_media_send_queue.dart';
import 'package:UniSpace/services/chat_reaction.dart';
import 'chat/chat_transfer_progress.dart';
import 'chat/chat_message_action_frame.dart';
import 'package:UniSpace/services/chat_translation.dart';
import 'chat/chat_translated_text.dart';
import 'chat/chat_wallpaper_presets.dart';
import 'chat/chat_media_gallery.dart' show ChatMediaGallery, showChatMediaGallery;
import 'chat/chat_rich_attachment_sheet.dart';
import 'chat/chat_rich_message_card.dart';
import 'chat/chat_link_dialog.dart';
import 'package:UniSpace/services/chat_attachment_input.dart';
import 'chat/chat_media_composer.dart';
import 'chat/chat_photo_editor.dart';
import 'chat/chat_view_once_page.dart';


import 'chat/voice_session.dart';
export 'chat/voice_session.dart';
import 'chat/chat_media_viewers.dart';
import 'chat/chat_location_sheet.dart';
import 'chat/chat_text_content.dart';
import 'package:open_filex/open_filex.dart';
import 'package:UniSpace/services/chat_media_format.dart';
import 'package:UniSpace/services/chat_document_service.dart';
import 'chat/chat_group_pages.dart';
import 'chat/new_conversation_page.dart';
import 'package:UniSpace/l10n/chat_group_strings.dart';
import 'package:UniSpace/l10n/chat_ui_strings.dart';
import 'package:UniSpace/services/chat_conversation_metadata.dart';
import 'package:UniSpace/services/chat_message_service.dart';
import 'package:UniSpace/services/community_search_text.dart';
import 'package:UniSpace/features/guide/app_guide.dart';
import 'package:UniSpace/l10n/shell_strings.dart';

import 'package:UniSpace/services/storage_upload_service.dart';
import 'package:UniSpace/services/chat_activity_client.dart';
import 'package:UniSpace/services/chat_preferences_client.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui' show ImageFilter;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:video_player/video_player.dart';
import '../../core/branding.dart';
import '../../ui/settings/public_profile_service.dart';
import 'package:UniSpace/main.dart';
import 'package:flutter/services.dart';

import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart' show consolidateHttpClientResponseBytes;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'chat/chat_composer_text.dart';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:just_audio/just_audio.dart';
import 'package:emojis/emoji.dart' as ue;
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart'
    show consolidateHttpClientResponseBytes, ValueNotifier, ValueListenable;


final Map<String, String> _chatSignedSessions = {};
String _stableChatSession() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  final signed = _chatSignedSessions[uid];
  return uid == null || signed == null ? '' : '$uid:$signed';
}
String _currentChatSession() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  final signed = _chatSignedSessions[uid];
  return uid == null || signed == null ? '' : '$uid:$signed:${PublicProfileService.viewerSession}';
}
Future<void> _refreshChatSession() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) { _chatSignedSessions.clear(); return; }
  final token = await user.getIdTokenResult();
  if (FirebaseAuth.instance.currentUser?.uid != user.uid) return;
  final sid = token.claims?['sid'];
  if (sid is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(sid)) throw StateError('Signed session required');
  _chatSignedSessions[user.uid] = '$sid:${token.claims?['auth_time']}';
}

String directChatId(String a, String b) {
  final ids = [a, b]..sort();
  return '${ids[0]}_${ids[1]}';
}

String _chatTimeAgo(BuildContext context, DateTime? dt) {
  if (dt == null) return '';
  final d = DateTime.now().difference(dt);
  if (d.inSeconds < 60) return shellText(context, 'الآن');
  if (d.inMinutes < 60) return shellFormat(context, '{0}د', [d.inMinutes]);
  if (d.inHours < 24) return shellFormat(context, '{0}س', [d.inHours]);
  if (d.inDays < 7) return shellFormat(context, '{0}ي', [d.inDays]);
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

Color _chatWallpaperColor(String id, bool isDark) {
  final extra = extraChatWallpaper(id);
  if (extra != null) return extra.gradient(isDark).colors.first;
  switch (id) {
    case 'mint':
      return isDark ? const Color(0xFF0B1F1C) : const Color(0xFFB7EEE5);
    case 'ocean':
      return isDark ? const Color(0xFF0B1C2C) : const Color(0xFFB9D9FF);
    case 'lavender':
      return isDark ? const Color(0xFF1A1325) : const Color(0xFFD8C4FF);
    case 'sunset':
      return isDark ? const Color(0xFF2A1510) : const Color(0xFFFFA6C1);
    case 'coral':
      return isDark ? const Color(0xFF2A1612) : const Color(0xFFFFB4A2);
    case 'sky':
      return isDark ? const Color(0xFF0B1E2A) : const Color(0xFFBAE6FD);
    case 'forest':
      return isDark ? const Color(0xFF102015) : const Color(0xFF86EFAC);
    case 'rose':
      return isDark ? const Color(0xFF2A1218) : const Color(0xFFFBCFE8);
    case 'sand':
      return isDark ? const Color(0xFF231C12) : const Color(0xFFFED7AA);
    case 'dusk':
      return isDark ? const Color(0xFF1A1325) : const Color(0xFFE9D5FF);
    case 'paper':
      return isDark ? const Color(0xFF171412) : const Color(0xFFF7F1E8);
    case 'night':
    case 'midnight':
      return const Color(0xFF1E293B);
    case 'graphite':
      return const Color(0xFF0F172A);
    default:
      return isDark ? Colors.black : const Color(0xFFF5F7FA);
  }
}

BoxDecoration chatWallpaperDecoration({
  required String id,
  required String url,
  required bool isDark,
}) {
  if (id == 'photo' && url.trim().isNotEmpty) {
    return BoxDecoration(
      image: DecorationImage(
        image: NetworkImage(url),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(
          Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
          BlendMode.darken,
        ),
      ),
    );
  }

  final extra = extraChatWallpaper(id);
  if (extra != null) return BoxDecoration(gradient: extra.gradient(isDark));
  LinearGradient? g;
  switch (id) {
    case 'mint':
      g = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: isDark
            ? const [Color(0xFF0B1F1C), Color(0xFF134E4A)]
            : const [Color(0xFFE0F7F3), Color(0xFFB7EEE5)],
      );
    case 'ocean':
      g = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: isDark
            ? const [Color(0xFF0B1C2C), Color(0xFF1E3A5F)]
            : const [Color(0xFFDFF6FF), Color(0xFF7DD3FC)],
      );
    case 'lavender':
      g = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF1A1325), Color(0xFF3B0764)]
            : const [Color(0xFFF0E7FF), Color(0xFFC4B5FD)],
      );
    case 'sunset':
      g = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: isDark
            ? const [Color(0xFF2A1510), Color(0xFF7C2D12)]
            : const [Color(0xFFFFD6A5), Color(0xFFFF7AB2)],
      );
    case 'coral':
      g = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF2A1612), Color(0xFF9A3412)]
            : const [Color(0xFFFFE0D2), Color(0xFFFB7185)],
      );
    case 'sky':
      g = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [Color(0xFF0B1E2A), Color(0xFF075985)]
            : const [Color(0xFFE0F2FE), Color(0xFF7DD3FC)],
      );
    case 'forest':
      g = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: isDark
            ? const [Color(0xFF102015), Color(0xFF166534)]
            : const [Color(0xFFD9F99D), Color(0xFF4ADE80)],
      );
    case 'rose':
      g = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF2A1218), Color(0xFF9D174D)]
            : const [Color(0xFFFFE4E6), Color(0xFFF9A8D4)],
      );
    case 'sand':
      g = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: isDark
            ? const [Color(0xFF231C12), Color(0xFF92400E)]
            : const [Color(0xFFFFF7ED), Color(0xFFFDBA74)],
      );
    case 'dusk':
      g = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: isDark
            ? const [Color(0xFF1A1325), Color(0xFF5B21B6)]
            : const [Color(0xFFF5F3FF), Color(0xFFDDD6FE)],
      );
    case 'paper':
      g = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [Color(0xFF171412), Color(0xFF292524)]
            : const [Color(0xFFFFFBEB), Color(0xFFF7F1E8)],
      );
    case 'night':
    case 'midnight':
      g = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFF1E293B), Color(0xFF312E81)],
      );
    case 'graphite':
      g = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF334155), Color(0xFF0F172A)],
      );
  }

  return BoxDecoration(
    color: g == null ? _chatWallpaperColor(id, isDark) : null,
    gradient: g,
  );
}

class _ChatDetailsPage extends StatefulWidget {
  const _ChatDetailsPage({
    required this.chatId,
    required this.peerId,
    required this.peerName,
    required this.peerPhotoUrl,
    required this.muted,
    required this.nickname,
    required this.wallpaper,
    this.wallpaperUrl,
    required this.bubbleColor,
    required this.autoTranslate,
    required this.autoTranslateLang,
    required this.startedAt,
    required this.messages,
    required this.onSearch,
    required this.onStarredMessages,
    required this.onOpenProfile,
    required this.preferences,
    required this.onClear,
    this.onWallpaperChanged,
    this.onBubbleColorChanged,
    this.onBubbleGradientChanged,
    this.onWallpaperUrlChanged,
    required this.onWallpaperPhoto,
  });

  final String chatId;
  final String peerId;
  final String peerName;
  final String? peerPhotoUrl;
  final bool muted;
  final String nickname;
  final String wallpaper;
  final String? wallpaperUrl;
  final int bubbleColor;
  final bool autoTranslate;
  final String autoTranslateLang;
  final DateTime? startedAt;
  final List<types.Message> messages;
  final VoidCallback onSearch;
  final VoidCallback onStarredMessages;
  final VoidCallback onOpenProfile;
  final ChatPreferencesClient preferences;
  final VoidCallback onClear;
  final ValueChanged<String>? onWallpaperChanged;
  final ValueChanged<int>? onBubbleColorChanged;
  final ValueChanged<List<int>?>? onBubbleGradientChanged;
  final ValueChanged<String>? onWallpaperUrlChanged;
  final Future<String?> Function(File) onWallpaperPhoto;

  @override
  State<_ChatDetailsPage> createState() => _ChatDetailsPageState();
}

class _ChatDetailsPageState extends State<_ChatDetailsPage> {
  late final TextEditingController _nick;
  late bool _muted;
  late bool _auto;
  late String _lang;
  late String _wallpaper;
  late int _bubble;
  String? _wallpaperUrl;
  String? _bubbleGradientKey;
  String? _wallpaperGradientKey;

  bool _savingPreference = false;
  String get _uid => widget.preferences.expectedUid;
  bool get _currentPreferences => mounted && widget.preferences.isCurrent;

  @override
  void initState() {
    super.initState();
    _nick = TextEditingController(text: widget.nickname);
    _muted = widget.muted;
    _auto = widget.autoTranslate;
    _lang = widget.autoTranslateLang;
    _wallpaper = widget.wallpaper;
    _wallpaperUrl = widget.wallpaperUrl;
    _bubble = widget.bubbleColor;
  }

  @override
  void dispose() {
    _nick.dispose();
    super.dispose();
  }

  Future<bool> _savePreference(Future<bool> Function() action) async {
    if (!_currentPreferences || _savingPreference) return false;
    setState(() => _savingPreference = true);
    try {
      return await action() && _currentPreferences;
    } catch (_) {
      if (_currentPreferences) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(shellText(context, "تعذر حفظ إعداد المحادثة. حاول مجددًا."))),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _savingPreference = false);
    }
  }
  Future<void> _editNickname() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ChatNicknameSheet(initialName: _nick.text, peerName: widget.peerName),
    );
    if (value == null || !_currentPreferences) return;
    if (await _savePreference(() => widget.preferences.setNickname(value))) {
      _nick.text = value;
      setState(() {});
    }
  }

  Future<void> _block() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(shellText(context, "حظر هذا الحساب؟")),
        content: Text(shellText(context, "لن يتمكن من مراسلتك وستُخفى المحادثة.")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(shellText(context, "إلغاء"))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(shellText(context, "حظر")),
          ),
        ],
      ),
    );
    if (ok != true || _uid.isEmpty) return;
    await blockAccount(targetId: widget.peerId, targetName: widget.peerName);
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _report() async {
    final result = await showCommunityReportSheet(
      context,
      type: CommunityReportType.user,
    );
    if (result == null || !mounted) return;
    try {
      await submitCommunityReport(
        type: CommunityReportType.user,
        targetId: widget.peerId,
        ownerId: widget.peerId,
        ownerName: widget.peerName,
        reason: result.reasonId,
        details: result.details,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(shellText(context, "تم إرسال التبليغ"))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageForCommunityReportError(e))),
      );
    }
  }

  bool _isLink(types.Message m) {
    if (m is! types.TextMessage) return false;
    return RegExp(r'https?://|www\.', caseSensitive: false).hasMatch(m.text);
  }

  bool _isPost(types.Message m) {
    final meta = m.metadata ?? {};
    final t = (meta['type'] ?? meta['sharedType'] ?? '').toString();
    return meta['postId'] != null || t == 'post';
  }

  bool _isMedia(types.Message m) {
    return m is types.ImageMessage || m is types.VideoMessage;
  }

  String _wallpaperLabel(String id) {
    final extra = extraChatWallpaper(id);
    if (extra != null) return extra.label(context);
    if (id == 'photo') return shellText(context, "صورة مخصصة");
    switch (id) {
      case 'mint':
        return shellText(context, "نعناع");
      case 'dusk':
        return shellText(context, "بنفسجي");
      case 'paper':
        return shellText(context, "ورق");
      case 'night':
        return shellText(context, "ليلي");
      default:
        return shellText(context, "افتراضي");
    }
  }

  Future<void> _openWallpaperSheet() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final wallpaperStyles = <_WallpaperStyle>[
      for (final preset in extraChatWallpapers)
        _WallpaperStyle(id: preset.id, label: preset.label(context), gradient: preset.gradient(isDark)),
      _WallpaperStyle(
        id: 'default',
        label: shellText(context, "افتراضي"),
        color: const Color(0xFFF5F7FA),
      ),
      _WallpaperStyle(
        id: 'mint',
        label: shellText(context, "نعناع"),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFFE0F7F3),
            Color(0xFFB7EEE5),
          ],
        ),
      ),
      _WallpaperStyle(
        id: 'ocean',
        label: shellText(context, "محيط"),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFFDFF6FF),
            Color(0xFFB9D9FF),
          ],
        ),
      ),
      _WallpaperStyle(
        id: 'lavender',
        label: shellText(context, "لافندر"),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF0E7FF),
            Color(0xFFD8C4FF),
          ],
        ),
      ),
      _WallpaperStyle(
        id: 'sunset',
        label: shellText(context, "غروب"),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFFFFD6A5),
            Color(0xFFFFA6C1),
          ],
        ),
      ),
      _WallpaperStyle(
        id: 'coral',
        label: shellText(context, "مرجاني"),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE0D2),
            Color(0xFFFFB4A2),
          ],
        ),
      ),
      _WallpaperStyle(
        id: 'sky',
        label: shellText(context, "سماء"),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE0F2FE),
            Color(0xFFBAE6FD),
          ],
        ),
      ),
      _WallpaperStyle(
        id: 'forest',
        label: shellText(context, "غابة"),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFFD9F99D),
            Color(0xFF86EFAC),
          ],
        ),
      ),
      _WallpaperStyle(
        id: 'rose',
        label: shellText(context, "وردي"),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE4E6),
            Color(0xFFFBCFE8),
          ],
        ),
      ),
      _WallpaperStyle(
        id: 'sand',
        label: shellText(context, "رملي"),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFFFFF7ED),
            Color(0xFFFED7AA),
          ],
        ),
      ),
      _WallpaperStyle(
        id: 'midnight',
        label: shellText(context, "منتصف الليل"),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF312E81),
          ],
        ),
      ),
      _WallpaperStyle(
        id: 'graphite',
        label: shellText(context, "جرافيت"),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF334155),
            Color(0xFF0F172A),
          ],
        ),
      ),
    ];
    final bubbleStyles = <_BubbleStyle>[
      for (final entry in <(String, String, String, String, int)>[
        ('plum', 'برقوقي', 'Plum', 'Prune', 0xFF76406B),
        ('pine', 'صنوبر', 'Pine', 'Pin', 0xFF246454),
        ('cocoa', 'كاكاو', 'Cocoa', 'Cacao', 0xFF795548),
        ('slate', 'أردوازي', 'Slate', 'Ardoise', 0xFF475569),
      ]) _BubbleStyle(id: entry.$1, label: mediaText(context, entry.$2, entry.$3, entry.$4), color: Color(entry.$5)),
      _BubbleStyle(
        id: 'teal',
        label: shellText(context, "فيروزي"),
        color: const Color(0xFF0D9488),
      ),
      _BubbleStyle(
        id: 'blue',
        label: shellText(context, "أزرق"),
        color: const Color(0xFF2563EB),
      ),
      _BubbleStyle(
        id: 'violet',
        label: shellText(context, "بنفسجي"),
        color: const Color(0xFF7C3AED),
      ),
      _BubbleStyle(
        id: 'green',
        label: shellText(context, "أخضر"),
        color: const Color(0xFF16A34A),
      ),
      _BubbleStyle(
        id: 'pink',
        label: shellText(context, "وردي"),
        color: const Color(0xFFE11D48),
      ),
      _BubbleStyle(
        id: 'orange',
        label: shellText(context, "برتقالي"),
        color: const Color(0xFFF97316),
      ),
      _BubbleStyle(
        id: 'yellow',
        label: shellText(context, "ذهبي"),
        color: const Color(0xFFEAB308),
      ),
      _BubbleStyle(
        id: 'cyan',
        label: shellText(context, "سماوي"),
        color: const Color(0xFF0891B2),
      ),
      _BubbleStyle(
        id: 'indigo',
        label: shellText(context, "نيلي"),
        color: const Color(0xFF4F46E5),
      ),
      _BubbleStyle(
        id: 'red',
        label: shellText(context, "أحمر"),
        color: const Color(0xFFDC2626),
      ),
      _BubbleStyle(
        id: 'lime',
        label: shellText(context, "ليموني"),
        color: const Color(0xFF65A30D),
      ),
      _BubbleStyle(
        id: 'dark',
        label: shellText(context, "داكن"),
        color: const Color(0xFF0F172A),
      ),
      _BubbleStyle(
        id: 'sunset',
        label: shellText(context, "غروب"),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFFFF512F),
            Color(0xFFF09819),
          ],
        ),
      ),
      _BubbleStyle(
        id: 'berry',
        label: shellText(context, "توت"),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEC4899),
            Color(0xFF8B5CF6),
          ],
        ),
      ),
      _BubbleStyle(
        id: 'ocean',
        label: shellText(context, "موج"),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFF06B6D4),
            Color(0xFF2563EB),
          ],
        ),
      ),
      _BubbleStyle(
        id: 'mint',
        label: shellText(context, "نعناع"),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF14B8A6),
            Color(0xFF84CC16),
          ],
        ),
      ),
      _BubbleStyle(
        id: 'fire',
        label: shellText(context, "ناري"),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFFF43F5E),
            Color(0xFFF97316),
          ],
        ),
      ),
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (sheetContext) {
        var selectedBubble = _bubble;
        var selectedBubbleGradient = _bubbleGradientKey;
        var selectedWallpaper = _wallpaper;

        return DraggableScrollableSheet(
          initialChildSize: 0.64,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          snap: true,
          snapSizes: const [0.64, 0.92],
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                final colors = Theme.of(context).colorScheme;

                return Material(
                  color: colors.surface,
                  clipBehavior: Clip.antiAlias,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 9, 16, 24),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate(
                            [
                              Center(
                                child: Container(
                                  width: 34,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: colors.onSurface.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          shellText(context, "مظهر المحادثة"),
                                          style: TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          shellText(context, "اختر ألوانًا وخلفيات تناسبك"),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton.filledTonal(
                                    onPressed: () {
                                      Navigator.of(sheetContext).pop();
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 22),

                               _CompactSectionTitle(
                                icon: Icons.palette_outlined,
                                title: shellText(context, "لون الفقاعات"),
                              ),

                              const SizedBox(height: 11),

                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: bubbleStyles.length,
                                gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 6,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 1,
                                ),
                                itemBuilder: (context, index) {
                                  final style = bubbleStyles[index];

                                  final isSelected = style.gradient != null
                                      ? selectedBubbleGradient == style.id
                                      : selectedBubble ==
                                      style.color!.value &&
                                      selectedBubbleGradient == null;

                                  return _CompactBubbleOption(
                                    style: style,
                                    selected: isSelected,
                                    onTap: () async {
                                      final gradient = style.gradient == null
                                          ? null : _gradientColors(style.gradient!);
                                      final saved = await _savePreference(() => gradient != null
                                          ? widget.preferences.setBubbleGradient(gradient)
                                          : widget.preferences.setBubbleColor(style.color!.value));
                                      if (!saved) return;
                                      if (sheetContext.mounted) {
                                        setSheetState(() {
                                          selectedBubbleGradient = gradient != null ? style.id : null;
                                          if (gradient == null) selectedBubble = style.color!.value;
                                        });
                                      }
                                      setState(() {
                                        _bubbleGradientKey = gradient != null ? style.id : null;
                                        if (gradient == null) _bubble = style.color!.value;
                                      });
                                      if (gradient != null) {
                                        widget.onBubbleGradientChanged?.call(gradient);
                                      } else {
                                        widget.onBubbleColorChanged?.call(style.color!.value);
                                      }
                                    },
                                  );
                                },
                              ),

                              const SizedBox(height: 24),

                              Row(
                                children: [
                                   Expanded(
                                    child: _CompactSectionTitle(
                                      icon: Icons.wallpaper_outlined,
                                      title: shellText(context, "خلفية المحادثة"),
                                    ),
                                  ),
                                  if (selectedWallpaper == 'photo')
                                    _SelectedLabel(
                                      label: shellText(context, "صورة مخصصة"),
                                      color: colors.primary,
                                    ),
                                ],
                              ),

                              const SizedBox(height: 11),
                            ],
                          ),
                        ),
                      ),

                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              if (index == 0) {
                                return _CompactCustomWallpaperOption(
                                  selected: selectedWallpaper == 'photo',
                                  imageUrl: _wallpaperUrl,
                                  onTap: () async {
                                    Navigator.of(sheetContext).pop();
                                    await _pickCustomWallpaper();
                                  },
                                );
                              }

                              final style = wallpaperStyles[index - 1];

                              return _CompactWallpaperOption(
                                style: style,
                                selected: selectedWallpaper == style.id,
                                isDark: isDark,
                                onTap: () async {
                                  final saved = await _savePreference(
                                    () => widget.preferences.setWallpaper(style.id),
                                  );
                                  if (!saved) return;
                                  setState(() {
                                    _wallpaper = style.id;
                                    _wallpaperGradientKey = style.id;
                                    _wallpaperUrl = null;
                                  });
                                  widget.onWallpaperChanged?.call(style.id);
                                  if (sheetContext.mounted) {
                                    setSheetState(() => selectedWallpaper = style.id);
                                    Navigator.of(sheetContext).pop();
                                  }
                                },
                              );
                            },
                            childCount: wallpaperStyles.length + 1,
                          ),
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 9,
                            mainAxisSpacing: 9,
                            childAspectRatio: 1.18,
                          ),
                        ),
                      ),

                      const SliverPadding(
                        padding: EdgeInsets.only(bottom: 22),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  List<int> _gradientColors(Gradient gradient) {
    if (gradient is LinearGradient) {
      return gradient.colors.map((color) => color.value).toList();
    }

    return const [];
  }


  Future<void> _pickCustomWallpaper() async {
    await _savePreference(() async {
      final files = await showChatMediaGallery(context, imagesOnly: true);
      if (files == null || files.isEmpty || !_currentPreferences) return false;
      final source = files.single;
      final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Text(shellText(ctx, 'خلفية المحادثة')),
        content: SizedBox(width: 280, height: 340, child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(source, fit: BoxFit.cover, cacheWidth: 700),
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(mediaText(ctx, 'إلغاء', 'Cancel', 'Annuler'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(mediaText(ctx, 'تعيين الخلفية', 'Set wallpaper', 'Définir le fond'))),
        ],
      ));
      if (confirmed != true || !_currentPreferences) return false;
      // The conversation owns this work after the details route is closed.
      final url = await widget.onWallpaperPhoto(source);
      if (mounted && url != null) setState(() { _wallpaper = 'photo'; _wallpaperUrl = url; });
      return url != null;
    });

  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final media = widget.messages.where(_isMedia).toList();
    final posts = widget.messages.where(_isPost).toList();
    final links = widget.messages.where(_isLink).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: isDark
              ? const Color(0xFF18191D)
              : const Color(0xFFF7F7F7),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                _SimpleSheetHeader(
                  title: shellText(context, "تفاصيل المحادثة"),
                  onClose: () => Navigator.of(context).pop(),
                ),

                Expanded(
                  child: ListView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      _SimpleProfileHeader(
                        name: widget.peerName,
                        photoUrl: widget.peerPhotoUrl,
                        muted: _muted,
                      ),

                      const SizedBox(height: 18),

                      _SimpleSettingsGroup(
                        title: shellText(context, "الإشعارات والترجمة"),
                        children: [
                          SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            secondary: Icon(
                              _muted
                                  ? Icons.notifications_off_outlined
                                  : Icons.notifications_none_outlined,
                            ),
                            title: Text(shellText(context, "كتم الإشعارات")),
                            subtitle: Text(
                              _muted
                                  ? shellText(context, "الإشعارات مكتومة")
                                  : shellText(context, "الإشعارات مفعّلة"),
                            ),
                            value: _muted,
                            onChanged: _savingPreference ? null : (value) async {
                              if (await _savePreference(() => widget.preferences.setMuted(value))) {
                                setState(() => _muted = value);
                              }
                            },
                          ),

                          const Divider(height: 1, indent: 72),

                          SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            secondary: const Icon(
                              Icons.translate_outlined,
                            ),
                            title: Text(shellText(context, "ترجمة تلقائية")),
                            subtitle: Text(
                              _auto
                                  ? shellText(context, "تتم ترجمة الرسائل تلقائياً")
                                  : shellText(context, "الترجمة التلقائية متوقفة"),
                            ),
                            value: _auto,
                            onChanged: _savingPreference ? null : (value) async {
                              if (await _savePreference(() => widget.preferences.setAutoTranslate(value))) {
                                setState(() => _auto = value);
                              }
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      _SimpleSettingsGroup(
                        title: shellText(context, "التخصيص"),
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            leading: const Icon(Icons.badge_outlined),
                            title: Text(shellText(context, "الاسم البديل")),
                            subtitle: Text(
                              _nick.text.trim().isEmpty
                                  ? shellText(context, "اسم للعرض في هذه المحادثة")
                                  : _nick.text.trim(),
                            ),
                            trailing: const Icon(
                              Icons.chevron_left_rounded,
                            ),
                            onTap: _editNickname,
                          ),

                          const Divider(height: 1, indent: 72),

                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            leading: const Icon(Icons.wallpaper_outlined),
                            title: Text(shellText(context, "مظهر المحادثة")),
                            subtitle: Text(
                              _wallpaperLabel(_wallpaper),
                            ),
                            trailing: const Icon(
                              Icons.chevron_left_rounded,
                            ),
                            onTap: _openWallpaperSheet,
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      _SimpleSettingsGroup(
                        title: shellText(context, "المحتوى المشترك"),
                        children: [
                          ListTile(leading: const Icon(Icons.star_outline_rounded), title: Text(chatGroupText(context, 'Starred messages')), trailing: const Icon(Icons.chevron_right_rounded), onTap: widget.onStarredMessages),
                          SizedBox(
                            height: 300,
                            child: Column(
                              children: [
                                TabBar(
                                  labelColor: AppTeal.main,
                                  unselectedLabelColor:
                                  Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  indicatorColor: AppTeal.main,
                                  tabs: [
                                    Tab(
                                      text: shellFormat(context, "وسائط {0}", [media.isEmpty ? '' : media.length]),
                                    ),
                                    Tab(
                                      text: shellFormat(context, "منشورات {0}", [posts.isEmpty ? '' : posts.length]),
                                    ),
                                    Tab(
                                      text: shellFormat(context, "روابط {0}", [links.isEmpty ? '' : links.length]),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: TabBarView(
                                    children: [
                                      _ChatSharedGrid(
                                        items: media,
                                        empty: shellText(context, "لا توجد وسائط"),
                                      ),
                                      _ChatSharedGrid(
                                        items: posts,
                                        empty: shellText(context, "لا توجد منشورات"),
                                      ),
                                      _ChatSharedGrid(
                                        items: links,
                                        empty: shellText(context, "لا توجد روابط"),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      _SimpleSettingsGroup(
                        title: shellText(context, "إجراءات الحساب"),
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            leading: const Icon(
                              Icons.flag_outlined,
                              color: Color(0xFFB45309),
                            ),
                            title: Text(shellText(context, "إبلاغ")),
                            subtitle: Text(
                              shellText(context, "الإبلاغ عن هذا الحساب"),
                            ),
                            onTap: _report,
                          ),

                          const Divider(height: 1, indent: 72),

                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            leading: const Icon(
                              Icons.block_outlined,
                              color: Color(0xFFDC2626),
                            ),
                            title: Text(
                              shellText(context, "حظر"),
                              style: TextStyle(
                                color: Color(0xFFDC2626),
                              ),
                            ),
                            subtitle: Text(
                              shellText(context, "منع الحساب من مراسلتك"),
                            ),
                            onTap: _block,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
class _CompactSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _CompactSectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color: colors.primary,
        ),
        const SizedBox(width: 7),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
class _CompactBubbleOption extends StatelessWidget {
  final _BubbleStyle style;
  final bool selected;
  final Future<void> Function() onTap;

  const _CompactBubbleOption({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: shellFormat(context, "اختيار {0}", [style.label]),
      child: InkWell(
        onTap: () {
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? colors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: style.color,
              gradient: style.gradient,
              boxShadow: [
                BoxShadow(
                  color: (style.color ?? colors.primary).withOpacity(0.24),
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: selected
                ? const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 18,
            )
                : null,
          ),
        ),
      ),
    );
  }
}
class _CompactWallpaperOption extends StatelessWidget {
  final _WallpaperStyle style;
  final bool selected;
  final bool isDark;
  final Future<void> Function() onTap;

  const _CompactWallpaperOption({
    required this.style,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withOpacity(0.45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? colors.primary
                : colors.outlineVariant.withOpacity(0.55),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: chatWallpaperDecoration(id: style.id, url: '', isDark: isDark).copyWith(borderRadius: BorderRadius.circular(10)),
                      child: CustomPaint(
                        painter: _MiniWallpaperPatternPainter(
                          color: Colors.white.withOpacity(0.10),
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: Container(
                      width: 29,
                      height: 7,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.88),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 22,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppTeal.main.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  if (selected)
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Container(
                        width: 19,
                        height: 19,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Text(
              style.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _CompactCustomWallpaperOption extends StatelessWidget {
  final bool selected;
  final String? imageUrl;
  final Future<void> Function() onTap;

  const _CompactCustomWallpaperOption({
    required this.selected,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return InkWell(
      onTap: () {
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withOpacity(0.45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? colors.primary
                : colors.outlineVariant.withOpacity(0.55),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return _GalleryPlaceholder(colors: colors);
                        },
                      )
                    else
                      _GalleryPlaceholder(colors: colors),

                    if (selected)
                      Positioned(
                        right: 5,
                        top: 5,
                        child: Container(
                          width: 19,
                          height: 19,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              hasImage ? shellText(context, "الصورة الخاصة") : shellText(context, "من المعرض"),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _GalleryPlaceholder extends StatelessWidget {
  final ColorScheme colors;

  const _GalleryPlaceholder({
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            colors.primaryContainer,
            colors.secondaryContainer,
          ],
        ),
      ),
      child: Icon(
        Icons.add_photo_alternate_outlined,
        size: 27,
        color: colors.onPrimaryContainer,
      ),
    );
  }
}
class _MiniWallpaperPatternPainter extends CustomPainter {
  final Color color;

  _MiniWallpaperPatternPainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const gap = 18.0;

    for (double x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniWallpaperPatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _SelectedLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _SelectedLabel({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}


class _WallpaperStyle {
  final String id;
  final String label;
  final Color? color;
  final Gradient? gradient;

  const _WallpaperStyle({
    required this.id,
    required this.label,
    this.color,
    this.gradient,
  });
}

class _BubbleStyle {
  final String id;
  final String label;
  final Color? color;
  final Gradient? gradient;

  const _BubbleStyle({
    required this.id,
    required this.label,
    this.color,
    this.gradient,
  });
}





class _SimpleSheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _SimpleSheetHeader({
    required this.title,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: shellText(context, "إغلاق"),
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}
class _SimpleProfileHeader extends StatelessWidget {
  final String name;
  final bool muted;
  final String? photoUrl;

  const _SimpleProfileHeader({
    required this.name,
    required this.muted,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          ChatProfileAvatar(name: name, photoUrl: photoUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  muted ? shellText(context, "الإشعارات مكتومة") : shellText(context, "إعدادات المحادثة"),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _SimpleSettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SimpleSettingsGroup({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: 20,
            bottom: 7,
          ),
          child: Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Material(
          color: isDark ? const Color(0xFF222428) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: theme.dividerColor.withOpacity(0.25)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}



class _ChatSharedGrid extends StatelessWidget {
  const _ChatSharedGrid({required this.items, required this.empty});
  final List<types.Message> items;
  final String empty;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Text(empty));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final m = items[i];
        if (m is types.ImageMessage) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(m.uri, fit: BoxFit.cover),
          );
        }
        if (m is types.VideoMessage) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const ColoredBox(
              color: Colors.black87,
              child: Icon(Icons.play_circle_fill_rounded, color: Colors.white),
            ),
          );
        }
        if (m is types.AudioMessage) {
          return const Card(child: Center(child: Icon(Icons.mic_rounded)));
        }
        final text = m is types.TextMessage ? m.text : shellText(context, "منشور");
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, height: 1.3),
          ),
        );
      },
    );
  }
}

// ==================== شاشة قائمة المحادثات ====================



class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.onOpenDrawer,
  });

  final VoidCallback onOpenDrawer;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';
  bool _requestsExpanded = false;
  String _inboxFilter = 'الكل';
  int _chatLimit = 40;
  StreamSubscription<User?>? _inboxAuth;
  void _remindersChanged() { if (mounted) setState(() {}); }


  @override
  void initState() {
    super.initState();
    var owner = _auth.currentUser?.uid;
    ChatUnreadReminders.instance.addListener(_remindersChanged);
    if (owner != null) unawaited(ChatUnreadReminders.instance.load(owner));
    _inboxAuth = _auth.authStateChanges().listen((user) {
      if (!mounted || owner == user?.uid) return;
      owner = user?.uid;
      if (owner != null) unawaited(ChatUnreadReminders.instance.load(owner!));
      _searchController.clear();
      setState(() { _chatLimit = 40; _requestsExpanded = false; _inboxFilter = 'الكل'; });
    });
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    ChatUnreadReminders.instance.removeListener(_remindersChanged);
    _inboxAuth?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Color _page(BuildContext context) => Theme.of(context).colorScheme.surfaceContainerLow;
  Color _border(BuildContext context) => Theme.of(context).colorScheme.outlineVariant;
  Color _secondary(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant;
  Color _primary(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  Color _card(BuildContext context) => Theme.of(context).colorScheme.surface;

  /// يدعم profileImageUrl (الحقل المستخدم في UniSpace) و photoUrl
  static String? _readPhoto(Map<String, dynamic>? data) {
    if (data == null) return null;
    final a = data['profileImageUrl']?.toString().trim();
    if (a != null && a.isNotEmpty) return a;
    final b = data['photoUrl']?.toString().trim();
    if (b != null && b.isNotEmpty) return b;
    return null;
  }

  static String _readName(Map<String, dynamic>? data, {String fallback = 'User'}) {
    if (data == null) return fallback;
    final n = (data['name'] ?? data['displayName'] ?? data['firstName'] ?? '')
        .toString()
        .trim();
    if (n.isNotEmpty) return n;
    final fn = (data['firstName'] ?? '').toString().trim();
    final ln = (data['lastName'] ?? '').toString().trim();
    final full = [fn, ln].where((e) => e.isNotEmpty).join(' ');
    return full.isEmpty ? fallback : full;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: _page(context),
        body: Center(
          child: Text(
            shellText(context, "سجّل الدخول أولاً"),
            style: TextStyle(color: _primary(context)),
          ),
        ),
      );
    }

    return AppGuide(
      id: 'chat',
      steps: const [
        GuideStep('chat.search', 'chat.search'),
        GuideStep('chat.requests', 'chat.requests'),
        GuideStep('chat.conversations', 'chat.conversations'),
      ],
      child: Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: _page(context),
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context: context, uid: currentUser.uid),
              const SizedBox(height: 4),
              GuideTarget(id: 'chat.search', child: _buildSearchField(context)),
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    for (final filter in ['الكل', 'غير المقروءة', 'groups', 'الأرشيف'])
                      Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: ChoiceChip(
                        label: Text(filter == 'groups' ? chatUiText(context, 'Groups') : shellText(context, filter)),
                        selected: _inboxFilter == filter,
                        showCheckmark: false,
                        side: BorderSide.none,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        selectedColor: Theme.of(context).colorScheme.secondaryContainer,
                        labelStyle: TextStyle(
                          color: _inboxFilter == filter ? Theme.of(context).colorScheme.onSecondaryContainer : _secondary(context),
                          fontWeight: _inboxFilter == filter ? FontWeight.w600 : FontWeight.w500,
                        ),
                        onSelected: (_) => setState(() { _inboxFilter = filter; _requestsExpanded = false; }),
                      )),
                  ]),
                ),
              ),
              Expanded(
                child: _buildBody(uid: currentUser.uid),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildTopBar({
    required BuildContext context,
    required String uid,
  }) {
    final primary = _primary(context);
    final canPop = Navigator.of(context).canPop();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 16),
      child: Row(
        children: [

            IconButton(
              onPressed: canPop ? () => Navigator.of(context).pop() : widget.onOpenDrawer,
              icon: Icon(canPop ? Icons.arrow_back_rounded : Icons.menu_rounded, color: primary),
            ),
            _buildProfileAvatar(context, uid),
          Expanded(
            child: Center(
              child: Text(
                shellText(context, "Chat"),
                style: TextStyle(
                  color: primary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .2,
                ),
              ),
            ),
          ),

          IconButton(
            tooltip: mediaText(context, 'البحث في الرسائل', 'Search messages', 'Rechercher des messages'),
            icon: Icon(Icons.manage_search_rounded, color: primary),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (searchContext) => ChatUnifiedSearchPage(
              onOpen: (hit) => openChatById(searchContext, hit.chatId, initialMessageId: hit.messageId),
            ))),
          ),
          PopupMenuButton<String>(
            tooltip: chatUiText(context, 'New conversation'),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.all(12),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            icon: const Icon(Icons.edit_outlined),
            onSelected: _startConversation,
            itemBuilder: (_) => [
              PopupMenuItem(value: 'direct', child: Text(chatUiText(context, 'New message'))),
              PopupMenuItem(value: 'group', child: Text(chatGroupText(context, 'New group'))),
              PopupMenuItem(value: 'join', child: Text(mediaText(context, 'الانضمام برابط دعوة', 'Join by invite link', 'Rejoindre par invitation'))),
              PopupMenuItem(value: 'transfers', child: Text(mediaText(context, 'الإرسال', 'Sending', 'Envois'))),
              PopupMenuItem(value: 'media', child: Text(mediaText(context, 'الوسائط والتخزين', 'Media and storage', 'Médias et stockage'))),
              PopupMenuItem(value: 'privacy', child: Text(mediaText(context, 'إعدادات الخصوصية', 'Privacy settings', 'Confidentialité'))),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _startConversation(String kind) async {
    if (kind == 'transfers') {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatTransferCenterPage()));
      return;
    }
    if (kind == 'join') {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatGroupJoinPage()));
      return;
    }
    if (kind == 'media') {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatMediaSettingsPage()));
      return;
    }
    if (kind == 'privacy') {
      await Navigator.of(context).push(MaterialPageRoute(builder: (context) => Scaffold(appBar: AppBar(title: Text(mediaText(context, 'إعدادات الخصوصية', 'Privacy settings', 'Confidentialité'))), body: const SafeArea(child: PrivacyAccountOverviewTab()))));
      return;
    }
    if (kind == 'group') {
      final id = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const CreateChatGroupPage()));
      if (mounted && id != null) await openChatById(context, id);
    } else {
      final contact = await Navigator.of(context).push<ChatContact>(MaterialPageRoute(builder: (_) => const NewConversationPage()));
      if (mounted && contact != null) await openDirectChat(context, peerId: contact.id, peerName: contact.name, peerPhotoUrl: contact.photoUrl);
    }
  }

  Widget _buildProfileAvatar(BuildContext context, String uid) {
    final primary = _primary(context);
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _firestore.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final photoUrl = _readPhoto(data);

        return GestureDetector(
          onTap: widget.onOpenDrawer,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _card(context),
              border: Border.all(color: _border(context).withValues(alpha: .5)),
              image: photoUrl != null
                  ? DecorationImage(
                image: NetworkImage(photoUrl),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: photoUrl == null
                ? Icon(Icons.person_outline, color: primary, size: 23)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final primary = _primary(context);
    final secondary = _secondary(context);
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 52,
        child: TextField(
          controller: _searchController,
          textDirection: Directionality.of(context),
          style: TextStyle(color: primary, fontSize: 14),
          decoration: InputDecoration(
            hintText: shellText(context, "Search"),
            hintStyle: TextStyle(color: secondary, fontSize: 14),
            prefixIcon: Icon(Icons.search, size: 20, color: secondary),
            suffixIcon: _searchText.isNotEmpty
                ? IconButton(
              onPressed: _searchController.clear,
              icon: Icon(Icons.close, size: 18, color: secondary),
            )
                : null,
            filled: true,
            fillColor: _card(context),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: colors.primary.withValues(alpha: .65), width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  /// الجسم: شريط التبويب + (طلبات إن فُتحت) + محادثات
  Widget _buildBody({required String uid}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTabsHeader(uid: uid),
        Expanded(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: ChatGroupInvitations(key: ValueKey('invites_$uid'), onOpen: (id, _) => openChatById(context, id))),
              if (_requestsExpanded) ...[
                SliverToBoxAdapter(
                  child: _buildRequestsInline(uid: uid),
                ),
                // فاصل بين الطلبات والمحادثات
                SliverToBoxAdapter(
                  child: Divider(
                    height: 2,
                    thickness: 2,
                    indent: 10,
                    endIndent: 200,
                    radius: BorderRadius.all(Radius.circular(20)),
                    color: _border(context),
                  ),
                ),
                // عنوان Conversation تحت الفاصل وفوق قائمة المحادثات
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                    child: Text(
                      shellText(context, "Conversation"),
                      style: TextStyle(
                        color: _primary(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
              // إن كانت الطلبات مغلقة، لا نكرر عنوان Conversation هنا
              // (يظهر في الشريط العلوي فقط)
              if (!_requestsExpanded)
                const SliverToBoxAdapter(child: SizedBox(height: 0)),
              // قائمة المحادثات
              SliverFillRemaining(
                hasScrollBody: true,
                child: _buildConversations(uid: uid),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabsHeader({required String uid}) {
    final primary = _primary(context);
    final secondary = _secondary(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('messageRequests')
            .where('receiverId', isEqualTo: uid)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          final count = snapshot.hasData ? snapshot.data!.docs.length : 0;

          return AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topLeft,
            child: _requestsExpanded
            // مفتوح: Request فقط (يسار) — بدون Conversation هنا
                ? Align(
              alignment: Alignment.centerLeft,
              child: GuideTarget(id: 'chat.requests', child: GestureDetector(
                onTap: () => setState(() => _requestsExpanded = false),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      shellText(context, "Request"),
                      style: TextStyle(
                        color: primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 5),
                      ChatRequestBadge(count: count),
                    ],
                    const SizedBox(width: 3),
                    Icon(
                      Icons.keyboard_arrow_up,
                      color: secondary,
                      size: 17,
                    ),
                  ],
                ),
              )),
            )
            // مغلق: Conversation يسار + Request يمين
                : Row(
              children: [
                GuideTarget(id: 'chat.conversations', child: Text(
                  shellText(context, "Conversation"),
                  style: TextStyle(
                    color: primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                )),
                const Spacer(),
                GuideTarget(id: 'chat.requests', child: GestureDetector(
                  onTap: () => setState(() => _requestsExpanded = true),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        shellText(context, "Request"),
                        style: TextStyle(
                          color: secondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 5),
                        ChatRequestBadge(count: count),
                      ],
                      const SizedBox(width: 3),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: secondary,
                        size: 17,
                      ),
                    ],
                  ),
                )),
              ],
            ),

          );
        },
      ),
    );
  }
  /// قائمة الطلبات داخل السكرول (لا تبدّل الشاشة كاملة)
  Widget _buildRequestsInline({required String uid}) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('messageRequests')
          .where('receiverId', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text(
              shellText(context, "تعذر تحميل الطلبات"),
              style: TextStyle(color: _secondary(context), fontSize: 13),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
          );
        }

        final requests = snapshot.data!.docs;

        if (requests.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Text(
              shellText(context, "No requests"),
              style: TextStyle(
                color: _secondary(context),
                fontSize: 13,
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = requests[index].data();
            final senderId = data['senderId']?.toString() ?? '';
            return _RequestRow(
              senderId: senderId,
              requestId: requests[index].id,
              primary: _primary(context),
              secondary: _secondary(context),
              card: _card(context),
            );
          },
        );
      },
    );
  }

  Widget _buildConversations({required String uid}) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      key: ValueKey('conversations_$uid'),
      stream: _firestore
          .collection('chats')
          .where('memberIds', arrayContains: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              shellText(context, "تعذر تحميل المحادثات"),
              style: TextStyle(color: _secondary(context)),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
          );
        }

        final chats = [...snapshot.data!.docs];

        chats.sort((a, b) {
          final aPinned = a.data()['pinned_$uid'] == true;
          final bPinned = b.data()['pinned_$uid'] == true;
          if (aPinned != bPinned) return bPinned ? 1 : -1;

          final aTime = a.data()['lastMessageAt'];
          final bTime = b.data()['lastMessageAt'];
          if (aTime is Timestamp && bTime is Timestamp) {
            return bTime.compareTo(aTime);
          }
          return 0;
        });

        final filteredChats = chats.where((chat) {
          final data = chat.data();
          if (!(data['memberIds'] as List? ?? []).contains(uid) || _auth.currentUser?.uid != uid) return false;
          if (data['deletedBy_$uid'] == true) return false;
          final archived = data['archived_$uid'] == true;
          if ((_inboxFilter == 'الأرشيف') != archived) return false;
          if (_inboxFilter == 'غير المقروءة' && ((data['unread'] as Map?)?[uid] as num? ?? 0) == 0 && !ChatUnreadReminders.instance.contains(uid, chat.id)) return false;
          if (_inboxFilter == 'groups' && data['type'] != 'group') return false;
          if (_searchText.isEmpty) return true;

          final members = Map<String, dynamic>.from(data['members'] ?? {});
          final memberIds =
          (data['memberIds'] as List? ?? []).map((e) => e.toString());
          final peerId = memberIds.firstWhere(
                (id) => id != uid,
            orElse: () => '',
          );
          final peer = Map<String, dynamic>.from(members[peerId] ?? {});
          final name = (data['type'] == 'group' ? data['name']?.toString() ?? '' : _readName(peer)).toLowerCase();
          final lastMessage =
              data['lastMessage']?.toString().toLowerCase() ?? '';
          return normalizeCommunitySearch(name).contains(normalizeCommunitySearch(_searchText)) || normalizeCommunitySearch(lastMessage).contains(normalizeCommunitySearch(_searchText));
        }).toList();

        if (filteredChats.isEmpty) {
          return _buildEmptyState(
            title: shellText(context, 'No conversations'),
            subtitle: shellText(context, 'Start a new conversation.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          itemCount: min(filteredChats.length, _chatLimit) + (filteredChats.length > _chatLimit ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 17),
          itemBuilder: (context, index) {
            if (index == _chatLimit) return TextButton(
              onPressed: () => setState(() => _chatLimit += 40),
              child: Text(shellText(context, 'تحميل المزيد')));
            final doc = filteredChats[index];
            return _ChatRow(
              document: doc,
              myUid: uid,
              markedUnread: ChatUnreadReminders.instance.contains(uid, doc.id),
              primary: _primary(context),
              secondary: _secondary(context),
              card: _card(context),
              onLongPress: (globalPosition) {
                _showChatActions(
                  context: context,
                  globalPosition: globalPosition,
                  chatId: doc.id,
                  ownerUid: uid,
                  pinned: doc.data()['pinned_$uid'] == true,
                  muted: ChatPreferencesSnapshot.readMuted(doc.data(), uid),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer, shape: BoxShape.circle),
            child: Icon(Icons.forum_outlined, size: 36, color: Theme.of(context).colorScheme.onSecondaryContainer),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: TextStyle(
              color: _primary(context),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            style: TextStyle(
              color: _secondary(context),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showChatActions({
    required BuildContext context,
    required Offset globalPosition,
    required String chatId,
    required String ownerUid,
    required bool pinned,
    required bool muted,
  }) async {
    // Bind the menu before its asynchronous selection, not to a later account.
    final menuSession = PublicProfileService.viewerSession;
    if (ownerUid.isEmpty || menuSession == null ||
        _auth.currentUser?.uid != ownerUid) return;
    final primary = _primary(context);
    final card = _card(context);
    final secondary = _secondary(context);

    // موضع القائمة نسبةً للشاشة
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final size = overlay.size;

    // نفتح القائمة أسفل نقطة اللمس قليلاً، مع إبقاءها داخل الشاشة
    final left = globalPosition.dx.clamp(12.0, size.width - 200);
    final top = globalPosition.dy.clamp(48.0, size.height - 220);

    final selected = await showMenu<String>(
      context: context,
      color: card,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _border(context).withValues(alpha: 0.35),
        ),
      ),
      position: RelativeRect.fromLTRB(
        left,
        top,
        size.width - left,
        size.height - top,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'unread',
          child: Text(mediaText(context, 'تعليم كغير مقروءة على هذا الجهاز', 'Mark unread on this device', 'Marquer non lu sur cet appareil')),
        ),
        PopupMenuItem<String>(
          value: 'archive',
          child: Text(shellText(context, _inboxFilter == 'الأرشيف' ? 'إلغاء الأرشفة' : 'أرشفة المحادثة')),
        ),
        PopupMenuItem<String>(
          value: 'pin',
          height: 44,
          child: Row(
            children: [
              Icon(
                pinned ? Icons.push_pin_outlined : Icons.push_pin,
                size: 20,
                color: primary,
              ),
              const SizedBox(width: 12),
              Text(
                pinned ? shellText(context, "Unpin conversation") : shellText(context, "Pin conversation"),
                style: TextStyle(
                  color: primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'mute',
          height: 44,
          child: Row(
            children: [
              Icon(
                muted
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                size: 20,
                color: primary,
              ),
              const SizedBox(width: 12),
              Text(
                muted ? shellText(context, "Unmute conversation") : shellText(context, "Mute conversation"),
                style: TextStyle(
                  color: primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          height: 44,
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 20, color: Colors.red.shade700),
              const SizedBox(width: 12),
              Text(
                shellText(context, "Delete conversation"),
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (selected == null || !mounted || !context.mounted ||
        _auth.currentUser?.uid != ownerUid ||
        PublicProfileService.viewerSession != menuSession) return;

    final uid = ownerUid;
    final ref = _firestore.collection('chats').doc(chatId);

    switch (selected) {
      case 'unread':
        try { await ChatUnreadReminders.instance.set(uid, chatId, true); }
        catch (_) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(shellText(context, 'تعذر حفظ إعدادات المحادثة. حاول مجدداً.')))); }
        break;
      case 'archive':
        await ref.set({'archived_$uid': _inboxFilter != 'الأرشيف'}, SetOptions(merge: true));
        break;
      case 'pin':
        await ref.set({'pinned_$uid': !pinned}, SetOptions(merge: true));
        break;
      case 'mute':
        final preferences = ChatPreferencesClient(
          expectedUid: ownerUid,
          currentUid: () => mounted ? _auth.currentUser?.uid : null,
          sessionKey: () => PublicProfileService.viewerSession,
          merge: (data) => ref.set(data, SetOptions(merge: true)),
          serverTimestamp: FieldValue.serverTimestamp,
          deleteField: FieldValue.delete,
        );
        try {
          await preferences.setMuted(!muted);
        } catch (_) {
          if (mounted && context.mounted && preferences.isCurrent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(shellText(context, "تعذر حفظ إعدادات المحادثة. حاول مجدداً."))),
            );
          }
        } finally {
          preferences.dispose();
        }
        break;
      case 'delete':
        await ref.set({'deletedBy_$uid': true}, SetOptions(merge: true));
        break;
    }
  }
}

class _ChatRow extends StatefulWidget {
  const _ChatRow({
    this.markedUnread = false,
    required this.document,
    required this.myUid,
    required this.onLongPress,
    required this.primary,
    required this.secondary,
    required this.card,
  });

  final bool markedUnread;
  final QueryDocumentSnapshot<Map<String, dynamic>> document;
  final String myUid;
  final void Function(Offset globalPosition) onLongPress;
  final Color primary;
  final Color secondary;
  final Color card;

  @override
  State<_ChatRow> createState() => _ChatRowState();
}

class _ChatRowState extends State<_ChatRow> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final data = widget.document.data();
    final members = Map<String, dynamic>.from(data['members'] ?? {});
    final memberIds =
    (data['memberIds'] as List? ?? []).map((e) => e.toString());
    final peerId = memberIds.firstWhere(
          (id) => id != widget.myUid,
      orElse: () => '',
    );
    final peer = Map<String, dynamic>.from(members[peerId] ?? {});

    final isGroup = data['type'] == 'group';
    final name = isGroup ? (data['name']?.toString() ?? chatUiText(context, 'Group')) : _ChatPageState._readName(peer, fallback: shellText(context, 'User'));
    final photoUrl = isGroup ? null : _ChatPageState._readPhoto(peer);
    final lastTime = data['lastMessageAt'];
    final muted = ChatPreferencesSnapshot.readMuted(data, widget.myUid);
    final lastMessage = data['lastMessage']?.toString() ?? '';
    final unreadMap = Map<String, dynamic>.from(data['unread'] ?? {});
    final unread = (unreadMap[widget.myUid] as num?)?.toInt() ?? 0;
    final pinned = data['pinned_${widget.myUid}'] == true;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onLongPressStart: (details) {
        _setPressed(true);
        widget.onLongPress(details.globalPosition);
      },
      onLongPressEnd: (_) => _setPressed(false),
      onLongPressCancel: () => _setPressed(false),
      onTap: () {
        _setPressed(false);
        if (!isGroup && peerId.isEmpty) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatThreadScreen(
              chatId: widget.document.id,
              isGroup: isGroup,
              peerId: isGroup ? '' : peerId,
              peerName: name,
              peerPhotoUrl: photoUrl,
            ),
          ),
        );
      },
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            color: _pressed
                ? colors.surfaceContainerHighest
                : unread > 0 ? Color.alphaBlend(colors.primary.withValues(alpha: .045), widget.card) : widget.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: unread > 0 ? colors.primary.withValues(alpha: .12) : colors.outlineVariant.withValues(alpha: .25)),
          ),
          child: Row(
            children: [
              if (isGroup)
                CircleAvatar(radius: 26, backgroundColor: colors.secondaryContainer, child: Icon(Icons.group_outlined, color: colors.onSecondaryContainer))
              else
                _Avatar(photoUrl: photoUrl, primary: widget.primary, card: widget.card),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: widget.primary,
                              fontSize: 15.5,
                              fontWeight: unread > 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (lastTime is Timestamp)
                          Padding(padding: const EdgeInsetsDirectional.only(start: 8), child: Text(
                            _chatTimeAgo(context, lastTime.toDate()),
                            style: TextStyle(fontSize: 11, color: unread > 0 ? colors.primary : widget.secondary, fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400),
                          )),
                        if (muted) Padding(padding: const EdgeInsetsDirectional.only(start: 5),
                          child: Icon(Icons.notifications_off_outlined, size: 14, color: widget.secondary)),
                        if (pinned)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(start: 5),
                            child: Icon(
                              Icons.push_pin_outlined,
                              size: 14,
                              color: widget.secondary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage.isEmpty
                                ? shellText(context, 'لا توجد رسائل بعد')
                                : lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamilyFallback: const ['NotoColorEmoji'],
                              color: unread > 0
                                  ? widget.primary
                                  : widget.secondary,
                              fontSize: 13,
                              fontWeight: unread > 0
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (unread == 0 && widget.markedUnread)
                          Semantics(label: mediaText(context, 'معلّمة كغير مقروءة', 'Marked unread', 'Marquée non lue'), child: Container(margin: const EdgeInsetsDirectional.only(start: 8), width: 10, height: 10, decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle))),
                        if (unread > 0)
                          Semantics(label: '${chatUiText(context, 'Unread messages')}: $unread',
                            child: Container(
                              margin: const EdgeInsetsDirectional.only(start: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(12)),
                              child: Text(unread > 99 ? '99+' : '$unread', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onPrimary)),
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.senderId,
    required this.requestId,
    required this.primary,
    required this.secondary,
    required this.card,
  });

  final String senderId;
  final String requestId;
  final Color primary;
  final Color secondary;
  final Color card;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: PublicProfileService.load(senderId),
      builder: (context, snapshot) {
        final data = snapshot.data ?? <String, dynamic>{};
        final name = _ChatPageState._readName(data, fallback: shellText(context, 'User'));
        final photoUrl = _ChatPageState._readPhoto(data);

        return Row(
          children: [
            _Avatar(photoUrl: photoUrl, primary: primary, card: card),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: () async {
                try {
                  await ChatMessageService().respondChatRequest(requestId: requestId, action: 'accept');
                  if (context.mounted) await openDirectChat(context, peerId: senderId, peerName: name);
                } catch (_) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(shellText(context, 'تعذر تحديث طلب المراسلة'))));
                }
              },
              icon: Icon(Icons.check, color: primary, size: 20),
            ),
            IconButton(
              onPressed: () async {
                try { await ChatMessageService().respondChatRequest(requestId: requestId, action: 'reject'); }
                catch (_) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(shellText(context, 'تعذر تحديث طلب المراسلة'))));
                }
              },
              icon: Icon(Icons.close, color: secondary, size: 20),
            ),
          ],
        );
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.photoUrl,
    required this.primary,
    required this.card,
  });

  final String? photoUrl;
  final Color primary;
  final Color card;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.secondaryContainer,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .35)),
        image: photoUrl != null && photoUrl!.isNotEmpty
            ? DecorationImage(
          image: NetworkImage(photoUrl!),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: photoUrl == null || photoUrl!.isEmpty
          ? Icon(Icons.person_outline, color: Theme.of(context).colorScheme.onSecondaryContainer, size: 25)
          : null,
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

  late String id;
  try {
    final result = await ChatMessageService().openChat(peerId);
    id = result.chatId;
    if (result.status != 'open') {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(shellText(context, 'تم إرسال طلب المراسلة'))));
      return;
    }
  } catch (_) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(shellText(context, 'تعذر فتح المحادثة.'))));
    return;
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

Future<String?> chatMessagingBlockedReason(String peerId) async {
  try {
    final result = await ChatMessageService().openChat(peerId);
    return result.status == 'open' ? null : 'تم إرسال طلب المراسلة';
  } catch (_) {
    return 'تعذر التحقق من إمكانية المراسلة. أعد المحاولة';
  }
}

// ==================== شاشة المحادثة (مبنية من الصفر، ستايل انستغرام) ====================

/// Resolve current membership/type before routing notifications or newly created chats.
Future<void> openChatById(BuildContext context, String chatId, {String? initialMessageId}) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  try {
    final doc = await FirebaseFirestore.instance.collection('chats').doc(chatId).get(const GetOptions(source: Source.server));
    if (!context.mounted || FirebaseAuth.instance.currentUser?.uid != uid) return;
    final data = doc.data();
    if (data == null || !(data['memberIds'] as List? ?? []).contains(uid)) throw StateError('Unavailable');
    final metadata = ChatConversationMetadata(data, uid);
    final peer = metadata.otherIds.isEmpty ? '' : metadata.otherIds.first;
    final details = Map<String, dynamic>.from((data['members'] as Map?)?[peer] ?? {});
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatThreadScreen(
      chatId: chatId, initialMessageId: initialMessageId, isGroup: metadata.isGroup, peerId: metadata.isGroup ? '' : peer,
      peerName: metadata.isGroup ? data['name']?.toString() : _ChatPageState._readName(details),
      peerPhotoUrl: metadata.isGroup ? null : _ChatPageState._readPhoto(details),
    )));
  } catch (_) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(chatUiText(context, 'Conversation unavailable'))));
  }
}

class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({
    super.key,
    this.initialMessageId,
    required this.chatId,
    required this.peerId,
    this.isGroup = false,
    this.peerName,
    this.peerPhotoUrl,
  });

  final String? initialMessageId;
  final String chatId;
  final String peerId;
  final String? peerName;
  final bool isGroup;
  final String? peerPhotoUrl;

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> with WidgetsBindingObserver {
  bool _initialized = false;
  Map<String, dynamic> _conversationData = {};
  bool _accessUnavailable = false;
  bool get _isGroup => widget.isGroup || _conversationData['type'] == 'group';
  String get _conversationName => _isGroup
      ? (_conversationData['name']?.toString() ?? widget.peerName ?? chatUiText(context, 'Group'))
      : (widget.peerName ?? shellText(context, 'محادثة'));
  String _senderName(String uid) {
    if (uid == FirebaseAuth.instance.currentUser?.uid) return shellText(context, 'أنت');
    final member = (_conversationData['members'] as Map?)?[uid];
    return member is Map && (member['name']?.toString() ?? '').isNotEmpty
        ? member['name'].toString() : (_isGroup ? shellText(context, 'User') : _conversationName);
  }
  Future<void> _openGroupDetails() async {
    final left = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => ChatGroupDetailsPage(chatId: widget.chatId, onStarredMessages: _openStarredMessages)));
    if (!mounted) return;
    if (left == true) { Navigator.of(context).pop(); } else { unawaited(_markChatRead()); }
  }
  String get _mediaScope => '$_openedSession/${widget.chatId}';
  bool get _mediaAuthorized => mounted && !_accessUnavailable && _openedSession == _liveSessionKey && (_conversationData['memberIds'] as List? ?? []).contains(_me.id);
  bool get _postingAllowed => !_isGroup || _conversationData['adminsOnlyMessaging'] != true || (_conversationData['adminIds'] as List? ?? []).contains(_me.id);
  void _revokeConversationAccess() {
    if (!mounted) return;
    chatImageMemoryCache.clearScope(_mediaScope);
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    unawaited(chatAudioCoordinator.stop());
    _searchDebounce?.cancel();
    _searchScanRequested = false;
    _desiredSearchId = null;
_translations.dispose();
    _sub?.cancel();
    _peerTypingExpiry?.cancel();
    unawaited(_activeUpload?.cancel());
    if (_mediaQueueCreated) chatTransfers.revoke(widget.chatId);
    _outbox.clear();
    if (_initialized) unawaited(_voice.cancel());
    setState(() { _accessUnavailable = true; _messages.clear(); _replyTo = null; _editing = null; _peerTyping = false; _inputCtrl.clear(); });
  }
  Future<String?> _messagingBlockedReason() async {
    if (_accessUnavailable) return 'تعذر تحميل الرسائل';
    if (!_isGroup) return chatMessagingBlockedReason(widget.peerId);
    try {
      final doc = await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).get(const GetOptions(source: Source.server));
      if (!mounted || _openedSession != _liveSessionKey || !(doc.data()?['memberIds'] as List? ?? []).contains(_me.id)) return 'تعذر تحميل الرسائل';
      return null;
    } catch (_) { return 'تعذر تحميل الرسائل'; }
  }
  String? _startupError;
  String get _liveSessionKey => _currentChatSession();
  String _openedSession = '';
  StreamSubscription<User?>? _authSub;
  int? _initialUnreadCount;
  final _messageService = ChatMessageService();
  final List<Future<void> Function()> _uploadRetries = [];
  bool _uploadFailed = false;
  UploadTask? _activeUpload;
  StreamSubscription<TaskSnapshot>? _uploadSub;
  double? _uploadProgress;
  void _trackUpload(UploadTask task) {
    if (!mounted || !_chatActivity.isCurrent) { unawaited(task.cancel()); return; }
    setState(() { _activeUpload = task; _uploadProgress = 0; });
    _uploadSub?.cancel();
    _uploadSub = task.snapshotEvents.listen((snapshot) {
      if (!mounted || !identical(_activeUpload, task)) return;
      setState(() { _uploadProgress = snapshot.totalBytes > 0 ? snapshot.bytesTransferred / snapshot.totalBytes : null; });
      if (snapshot.state == TaskState.success || snapshot.state == TaskState.canceled || snapshot.state == TaskState.error) {
        setState(() { _activeUpload = null; _uploadProgress = null; });
      }
    }, onError: (Object _) {
      if (mounted && identical(_activeUpload, task)) setState(() { _activeUpload = null; _uploadProgress = null; });
    });
  }
  Future<TaskSnapshot> _uploadBytes(Reference ref, Uint8List bytes, SettableMetadata metadata) async {
    _uploadFailed = false;
    try { return await StorageUploadService.putData(ref, bytes, metadata, onTask: _trackUpload); }
    catch (_) { _uploadFailed = true; rethrow; }
  }
  Future<TaskSnapshot> _uploadFile(Reference ref, File file, SettableMetadata metadata) async {
    _uploadFailed = false;
    try { return await StorageUploadService.putFile(ref, file, metadata, onTask: _trackUpload); }
    catch (_) { _uploadFailed = true; rethrow; }
  }
  ChatLocalPersistence? _localPersistence;
  ChatMediaDraftStore? _composerDrafts;
  StreamSubscription<List<ConnectivityResult>>? _networkSub;
  Timer? _retryTimer;
  bool _retryingPending = false;
  late final ChatOutbox _outbox;
  bool _mediaQueueCreated = false;
  late final ChatMediaSendQueue _mediaQueue = _createMediaQueue();
  void _mediaChanged() { if (mounted) setState(() {}); }
  ChatMediaSendQueue _createMediaQueue() {
    _mediaQueueCreated = true;
    final queue = chatTransfers.obtain(chatId: widget.chatId, title: widget.peerName ?? widget.chatId, session: _openedSession, currentSession: _currentChatSession, outbox: _outbox, persistence: _localPersistence,
      tooLarge: mediaText(context, 'حجم الوسائط كبير. قلّل الجودة أو قص الفيديو.', 'Media is too large. Reduce quality or trim the video.', 'Média trop volumineux. Réduisez la qualité ou raccourcissez la vidéo.'),
      tooLong: mediaText(context, 'قص الفيديو إلى دقيقة أو أقل.', 'Trim the video to one minute or less.', 'Limitez la vidéo à une minute.'),
      stillOnly: mediaText(context, 'العرض مرة واحدة للصور الثابتة فقط.', 'View once is available for still photos only.', 'La vue unique est disponible pour les photos fixes uniquement.'));
    queue.addListener(_mediaChanged);
    return queue;
  }
  final _messageScroll = ChatSearchScrollController();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _privacySub;
  bool _shareReadReceipt = false;
  bool _shareTyping = false;
  bool _foreground = true;
  int _messageLimit = 40;
  bool _hasOlder = false;
  bool _loadingMessages = true;
  String? _messagesError;
  String? _lastReadMarker;
  String? _lastDeliveredMessageId;
  String _draftBeforeEdit = '';
  DateTime? _lastTypingSent;
  DateTime? _peerDeliveredAt;

  Future<void> _publishMessage(Map<String, dynamic> message) async {
    if (!mounted || !_initialized || _accessUnavailable || _openedSession != _liveSessionKey) {
      throw StateError('Conversation session changed');
    }
    final entry = _outbox.enqueue(chatId: widget.chatId, message: message);
    if (message['type'] == 'text' && _inputCtrl.text.trim() == message['text']) {
      _inputCtrl.clear();
      if (mounted) setState(() => _replyTo = null);
    }
    final sent = await _outbox.attempt(entry.id);
    if (!sent) throw StateError('تعذر إرسال الرسالة');
  }

  Future<void> _retryPending() async {
    if (_retryingPending || !_initialized || !_mediaAuthorized || !_postingAllowed) return;
    _retryingPending = true;
    try { await _outbox.retryTransient(); await _mediaQueue.retryTransient(); }
    catch (_) { /* Pending entries retain their visible retry action. */ }
    finally { _retryingPending = false; }
  }
  Future<void> _flushPending() async {
    if (!_initialized) return;
    try { await Future.wait([_outbox.flush(), _mediaQueue.flush(), ChatDraftStore.flush(), if (_composerDrafts != null) _composerDrafts!.flush()]); }
    catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mediaText(context, 'تعذر حفظ بعض المسودات على الجهاز', 'Some drafts could not be saved on this device', 'Certaines ébauches n’ont pas pu être enregistrées')))); }
  }

  bool get _canRead => mounted && _foreground &&
      ModalRoute.of(context)?.isCurrent == true &&
      (!_messageScroll.hasClients || _messageScroll.offset < 80);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) { unawaited(_markChatRead()); unawaited(_retryPending()); }
    else { unawaited(_setChatTyping(false)); unawaited(_flushPending()); }
  }

  void _listenMessages() {
    _sub?.cancel();
    _sub = _msgs.orderBy('createdAt', descending: true).limit(_messageLimit)
        .snapshots(includeMetadataChanges: true).listen((snap) {
      if (!mounted || !_chatActivity.isCurrent) return;
      setState(() {
        _messages = snap.docs.where((d) => (d.data()['hiddenBy'] as Map?)?[_me.id] != true)
            .map(_toMessage).toList();
        _hasOlder = snap.docs.length == _messageLimit || (snap.metadata.isFromCache && _hasOlder);
        _loadingMessages = snap.metadata.isFromCache && _searchLoadingOlder;
        if (!snap.metadata.isFromCache) _searchLoadingOlder = false;
        _messagesError = null;
      });
      _outbox.observe(snap.docs.map((doc) => doc.id));
      if (!snap.metadata.isFromCache && _mediaAuthorized) {
        unawaited(_retryPending());
        unawaited(prefetchChatImages(scope: _mediaScope, authorized: () => _mediaAuthorized, items: [
          for (final message in _messages.take(6))
            if (message is types.ImageMessage) ChatMediaPrefetchItem(source: message.uri, viewOnce: message.metadata?['viewOnce'] == true)
            else if (message.metadata?['thumbnailUrl'] is String) ChatMediaPrefetchItem(source: message.metadata!['thumbnailUrl'] as String, viewOnce: message.metadata?['viewOnce'] == true),
        ]));
      }
      _refreshChatSearch();
      if (!snap.metadata.isFromCache) _advanceInitialTarget();
      if (!snap.metadata.isFromCache && snap.docs.isNotEmpty && _lastDeliveredMessageId != snap.docs.first.id) {
        _lastDeliveredMessageId = snap.docs.first.id;
        unawaited(FirebaseFirestore.instance.collection('chats').doc(widget.chatId)
          .set({'lastDeliveredAt': {_me.id: FieldValue.serverTimestamp()}}, SetOptions(merge: true))
          .catchError((Object _) {}));
      }
      unawaited(_markChatRead());
    }, onError: (Object error) {
      if (error is FirebaseException && error.code == 'permission-denied') _revokeConversationAccess();
      if (mounted) setState(() { _messagesError = 'تعذر تحميل الرسائل'; _loadingMessages = false; _searchLoadingOlder = false; _searchScanRequested = false; });
    });
  }

  void _loadOlder() {
    if (_loadingMessages || !_hasOlder) return;
    setState(() { _messageLimit += 40; _loadingMessages = true; });
    _listenMessages();
  }

  List<types.Message> _messages = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  late final types.User _me;
  late final types.User _peer;
  types.Message? _replyTo;
  types.Message? _editing;
  String? _initialTargetId, _targetHighlightId;
  int _targetPagesRemaining = 5;
  void _advanceInitialTarget() {
    final id = _initialTargetId;
    if (id == null || !mounted || !_initialized || _accessUnavailable) return;
    final index = _visibleMessages.indexWhere((message) => message.id == id);
    if (index >= 0) {
      setState(() { _initialTargetId = null; _targetHighlightId = id; });
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || _accessUnavailable || _targetHighlightId != id) return;
        final currentIndex = _visibleMessages.indexWhere((message) => message.id == id);
        if (currentIndex >= 0 && _messageScroll.hasClients) await _messageScroll.reveal(currentIndex);
      });
    } else if (!_canSearchOlder && !_loadingMessages) {
      setState(() => _initialTargetId = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mediaText(context,
        'لم تعد الرسالة متاحة في هذه المحادثة', 'This message is no longer available in this conversation', 'Ce message n’est plus disponible dans cette discussion'))));
    } else if (!_loadingMessages && _targetPagesRemaining > 0) {
      _targetPagesRemaining--;
      _loadOlder();
    }
  }
  bool _searching = false;
  final _messageSearch = ChatMessageSearch();
  Timer? _searchDebounce;
  bool _searchLoadingOlder = false, _searchScanRequested = false;
  String? _searchOlderThanId, _desiredSearchId;
  bool _searchScrolling = false;
  bool get _canSearchOlder => _hasOlder && (_clearedAt == null || _messages.isEmpty ||
      (_messages.last.createdAt ?? 0) > _clearedAt!.millisecondsSinceEpoch);

  List<ChatSearchEntry> get _searchEntries => _visibleMessages.map((message) {
    final rich = message.metadata?['richData'];
    return ChatSearchEntry(id: message.id, text: [
      if (message is types.TextMessage) message.text,
      if (message is types.FileMessage) message.name,
      if (message.metadata?['caption'] is String) message.metadata!['caption'] as String,
      if (rich is Map) for (final key in ['question', 'contactName', 'contactPhone', 'title'])
        if (rich[key] is String) rich[key] as String,
    ].join(' '));
  }).toList();

  void _onChatSearchChanged() {
    _initialTargetId = null;
    _targetHighlightId = null;
    _messageScroll.cancelSearchJump();
    _searchDebounce?.cancel();
    _searchOlderThanId = null;
    _searchScanRequested = true;
    _desiredSearchId = null;
    setState(() => _messageSearch.update(_searchCtrl.text, _searchEntries));
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      if (mounted && _searching) _refreshChatSearch(jump: true);
    });
  }

  void _refreshChatSearch({bool jump = false}) {
    if (!mounted || !_searching || _accessUnavailable || !_initialized) return;
    final previous = _messageSearch.selectedId;
    _messageSearch.update(_searchCtrl.text, _searchEntries);
    if (normalizeCommunitySearch(_searchCtrl.text).isEmpty) {
      _searchScanRequested = false;
      _searchOlderThanId = null;
      setState(() {});
      return;
    }
    if (_searchOlderThanId != null && !_messageSearch.matchIds.contains(_searchOlderThanId)) {
      _searchOlderThanId = null;
      _searchScanRequested = _messageSearch.matchIds.isEmpty;
      jump = true;
    }
    if (_searchOlderThanId != null) {
      if (_messageSearch.selectedId == _searchOlderThanId && _messageSearch.move(1)) {
        _searchOlderThanId = null;
        _searchScanRequested = false;
        jump = true;
      }
    } else if (_messageSearch.matchIds.isNotEmpty) {
      _searchScanRequested = false;
    }
    setState(() {});
    if (jump || previous != _messageSearch.selectedId) _jumpToSearchResult();
    if (_searchScanRequested && !_searchLoadingOlder && !_loadingMessages) {
      if (_canSearchOlder) {
        _searchLoadingOlder = true;
        _loadOlder();
      } else {
        _searchScanRequested = false;
        _searchOlderThanId = null;
      }
    }
  }

  void _moveChatSearch(int delta) {
    FocusManager.instance.primaryFocus?.unfocus();
    _searchOlderThanId = null;
    _searchScanRequested = false;
    if (_messageSearch.move(delta)) {
      setState(() {});
      _jumpToSearchResult();
    } else if (delta > 0 && _canSearchOlder && !_searchLoadingOlder) {
      _searchOlderThanId = _messageSearch.selectedId;
      _searchScanRequested = true;
      _refreshChatSearch();
    }
  }

  Future<void> _jumpToSearchResult() async {
    _desiredSearchId = _messageSearch.selectedId;
    if (_searchScrolling || _desiredSearchId == null) return;
    _searchScrolling = true;
    try {
      while (mounted && _searching && _desiredSearchId != null) {
        final id = _desiredSearchId;
        _desiredSearchId = null;
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted || !_searching || _messageSearch.selectedId != id || !_messageScroll.hasClients) continue;
        final index = _visibleMessages.indexWhere((message) => message.id == id);
        if (index >= 0) {
          await _messageScroll.reveal(index);
          if (mounted && _searching && _messageSearch.selectedId == id &&
              _visibleMessages.indexWhere((message) => message.id == id) != index) _desiredSearchId = id;
        }
      }
    } catch (error) {
      debugPrint('Chat search navigation interrupted: ' + error.runtimeType.toString());
    } finally { _searchScrolling = false; }
  }

  final _searchCtrl = TextEditingController();
  final _inputCtrl = TextEditingController();
  final _translations = ChatTranslationService();
  bool _sending = false;
  bool _hasText = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _chatSub;
  Timer? _typingIdle;
  Timer? _peerTypingExpiry;
  late final ChatActivityClient _chatActivity;
  late final ChatPreferencesClient _chatPreferences;
  bool _peerTyping = false;
  bool _muted = false;
  DateTime? _peerLastActive;
  StreamSubscription? _peerSub;
  DateTime? _clearedAt;
  DateTime? _peerReadAt;
  final _recorder = AudioRecorder();
  bool _recording = false;
  Timer? _recordTicker;
  final AudioPlayer _previewPlayer = AudioPlayer();
  bool _previewPlaying = false;
  CollectionReference<Map<String, dynamic>> get _msgs =>
      FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages');


  VoiceRecordingState _voiceState = VoiceRecordingState.idle;


  bool _voicePaused = false;


  late final VoiceSessionController _voice;


  String? _voicePath; // مسار الملف أثناء المعاينة

  String _nickname = '';
  String _wallpaperUrl = '';
  String _wallpaper = 'default';
  int _bubbleColor = 0xFF0D9488;
  List<Color>? _bubbleGradient;
  bool _autoTranslate = false;
  String _autoTranslateLang = 'auto';
  DateTime? _chatStartedAt;



  static const double _cancelDistance = 90.0;
  static const double _lockDistance = 75.0;
  static const Duration _minimumVoiceDuration =
  Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _initialTargetId = widget.initialMessageId;
    unawaited(_prepareChat());
  }

  Future<void> _prepareChat() async {
    try {
      await _refreshChatSession();
      if (!mounted) return;
      if (_liveSessionKey.isEmpty) throw StateError('Sign in required');
      await _initializeChat();
      setState(() {});
    } catch (_) {
      if (mounted) setState(() => _startupError = mediaText(context, 'تعذر فتح المحادثة أو استعادة المسودات. حاول مجددًا.', 'Could not open the conversation or restore drafts. Try again.', 'Impossible d’ouvrir la conversation ou de restaurer les ébauches. Réessayez.'));
    }
  }

  Future<void> _initializeChat() async {
    final openingSession = _liveSessionKey;
    _openedSession = openingSession;
    if (Platform.isAndroid) {
      _localPersistence = await ChatLocalPersistence.open(sessionKey: _stableChatSession(), currentSessionKey: _stableChatSession);
      await ChatDraftStore.restore(widget.chatId, openingSession, persistence: _localPersistence!);
      _composerDrafts = ChatMediaDraftStore(persistence: _localPersistence!, chatId: widget.chatId);
      await _composerDrafts!.ready;
    }
    if (!mounted || openingSession != _liveSessionKey) return;
    final retainedService = ChatMessageService();
    _outbox = ChatOutboxStore.forSession(
      chatId: widget.chatId,
      retainUntilObserved: true,
      persistence: _localPersistence,
      currentSessionKey: _currentChatSession,
      newMessageId: () => FirebaseFirestore.instance.collection('chats').doc().id,
      sender: (chatId, messageId, message) async {
        await retainedService.sendChatMessage(chatId: chatId, messageId: messageId, message: message);
      },
    );
    await _outbox.ready;
    await _mediaQueue.ready;
    if (!mounted || openingSession != _liveSessionKey) return;
    _outbox.onChanged = () { if (mounted) setState(() {}); };
    _initialized = true;
    _networkSub = Connectivity().onConnectivityChanged.listen((states) {
      if (!states.contains(ConnectivityResult.none)) unawaited(_retryPending());
    });
    _retryTimer = Timer.periodic(const Duration(seconds: 15), (_) => unawaited(_retryPending()));
    _voice = VoiceSessionController();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    WidgetsBinding.instance.addObserver(this);
    _openedSession = _liveSessionKey;
    unawaited(ChatUnreadReminders.instance.set(uid, widget.chatId, false).catchError((Object _) {}));
    _inputCtrl.text = ChatDraftStore.get(widget.chatId, _openedSession);
    _hasText = _inputCtrl.text.trim().isNotEmpty;
    _authSub = FirebaseAuth.instance.idTokenChanges().listen((_) async {
      try { await _refreshChatSession(); } catch (_) { _chatSignedSessions.clear(); }
      if (!mounted || _openedSession == _liveSessionKey) return;
      _outbox.onChanged = null;
      unawaited(_localPersistence?.purge().catchError((Object _) {}));
      chatImageMemoryCache.clearScope(_mediaScope);
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      unawaited(chatAudioCoordinator.stop());
      chatTransfers.clear();
      ChatOutboxStore.clear();
      ChatDraftStore.clear();
      _sub?.cancel();
      await _voice.cancel();
      if (!mounted) return;
      setState(() { _accessUnavailable = true; _messages.clear(); _inputCtrl.clear(); });
      Navigator.of(context).maybePop();
    });
    _messageScroll.addListener(() {
      if (mounted) setState(() {});
      if (_messageScroll.offset < 80) unawaited(_markChatRead());
      if (!_searching && !_messageScroll.isAutoScrolling && _messageScroll.position.extentAfter < 160) _loadOlder();
    });
    _privacySub = FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((doc) {
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) return;
      final privacy = doc.data()?['privacy'];
      setState(() {
        _shareReadReceipt = privacy is Map && privacy['readReceipts'] != false;
        _shareTyping = privacy is Map && privacy['typingIndicator'] != false;
      });
      if (!_shareTyping) unawaited(_setChatTyping(false));
      unawaited(_markChatRead());
    }, onError: (Object _) {
      if (mounted) setState(() { _shareReadReceipt = false; _shareTyping = false; });
    });
    _chatActivity = ChatActivityClient(
      expectedUid: uid,
      currentUid: () => FirebaseAuth.instance.currentUser?.uid,
      sessionKey: () => PublicProfileService.viewerSession,
      merge: (data) => FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .set(data, SetOptions(merge: true)),
      serverTimestamp: FieldValue.serverTimestamp,
      deleteField: FieldValue.delete,
    );
    _chatPreferences = ChatPreferencesClient(
      expectedUid: uid,
      currentUid: () => FirebaseAuth.instance.currentUser?.uid,
      sessionKey: () => PublicProfileService.viewerSession,
      merge: (data) => FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .set(data, SetOptions(merge: true)),
      serverTimestamp: FieldValue.serverTimestamp,
      deleteField: FieldValue.delete,
    );
    _me = types.User(id: uid, firstName: 'أنا');
    _peer = types.User(
      id: widget.peerId,
      firstName: widget.peerName,
      imageUrl: widget.peerPhotoUrl,
    );

    _inputCtrl.addListener(() {
      if (_openedSession == _liveSessionKey && _editing == null) {
        try { ChatDraftStore.put(widget.chatId, _liveSessionKey, _inputCtrl.text); }
        catch (_) { debugPrint('Chat draft capacity reached'); }
      }
      final has = _inputCtrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });

    _chatSub = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .snapshots()
        .listen((doc) {
      if (!mounted || !_chatActivity.isCurrent) return;
      if (!doc.exists && doc.metadata.isFromCache) return;
      final data = doc.data() ?? {};
      if (!(data['memberIds'] as List? ?? []).contains(_me.id)) { _revokeConversationAccess(); return; }
      _conversationData = data;
      final metadata = ChatConversationMetadata(data, _me.id);
      final remaining = metadata.typingRemaining(
        timestamp: (value) => value is Timestamp ? value.toDate() : null,
        now: DateTime.now(),
      );
      final typing = remaining > Duration.zero;
      _peerTypingExpiry?.cancel();
      if (typing) {
        _peerTypingExpiry = Timer(remaining, () {
          if (mounted && _chatActivity.isCurrent) {
            setState(() => _peerTyping = false);
          }
        });
      }

      final initialMetadata = _initialUnreadCount == null;
      if (initialMetadata) {
        final unread = data['unread'];
        _initialUnreadCount = unread is Map ? (unread[_me.id] as num?)?.toInt() ?? 0 : 0;
      }
      final peerRead = metadata.receiptThrough('lastReadAt',
        timestamp: (value) => value is Timestamp ? value.toDate() : null);

      final preferences = ChatPreferencesSnapshot.fromData(data, _me.id);
      final cr = preferences.clearedAt;
      final started = data['createdAt'];
      setState(() {
        _peerTyping = typing;
        _peerReadAt = peerRead;
        _peerDeliveredAt = metadata.receiptThrough('lastDeliveredAt', timestamp: (value) => value is Timestamp ? value.toDate() : null);
        _muted = preferences.muted;
        _nickname = preferences.nickname;
        _wallpaper = preferences.wallpaper;
        _wallpaperUrl = preferences.wallpaperUrl;
        _bubbleColor = preferences.bubbleColor;
        _bubbleGradient = preferences.bubbleGradient?.map((color) => Color(color)).toList();
        _autoTranslate = preferences.autoTranslate;
        _autoTranslateLang = preferences.autoTranslateLang;
        _chatStartedAt = started is Timestamp ? started.toDate() : null;
        _clearedAt = cr is Timestamp ? cr.toDate() : null;
      });
      if (initialMetadata) unawaited(_markChatRead());
    }, onError: (Object error) {
      if (error is FirebaseException && error.code == 'permission-denied') _revokeConversationAccess();
    });
    _listenMessages();

    if (!_isGroup && widget.peerId.isNotEmpty) _peerSub = PublicProfileService.watch(widget.peerId).listen((data) {
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != _me.id) return;
      final raw = data['lastSeenAt'];
      setState(() {
        _peerLastActive = raw is Timestamp ? raw.toDate() : null;
      });
    }, onError: (Object error) {
      if (mounted) setState(() => _peerLastActive = null);
      debugPrint('Peer presence unavailable: $error');
    });

    _touchMyPresence();
  }

  void _touchMyPresence() {
    final uid = _me.id;
    if (uid.isEmpty || FirebaseAuth.instance.currentUser?.uid != uid) return;
    unawaited(
      FirebaseFirestore.instance.collection('users').doc(uid).set({
        'lastSeenAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).catchError((Object error) {
        debugPrint('Presence update unavailable: $error');
      }),
    );
  }



  /// ■ إيقاف للمعاينة: يُنهي الملف ثم يبقيه للسماع/الإرسال
  Future<void> _pauseVoiceRecording() async {
    if (!_recording || _voicePaused) return;

    await _stopPreview();

    try {
      final path = await _recorder.stop();
      _recordTicker?.cancel();
      _recordTicker = null;

      final finalPath = (path != null && path.isNotEmpty) ? path : _voicePath;
      _voicePath = finalPath;

      // تحقق أن الملف صالح
      if (finalPath == null) {
        if (mounted) {
          setState(() {
            _recording = false;
            _voicePaused = false;
          });
        }
        return;
      }

      final file = File(finalPath);
      final exists = await file.exists();
      final len = exists ? await file.length() : 0;
      debugPrint('voice file: path=$finalPath exists=$exists size=$len');

      if (!exists || len < 100) {
        if (mounted) {
          setState(() {
            _recording = false;
            _voicePaused = false;
            _voicePath = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(shellText(context, "التسجيل قصير أو غير صالح"))),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _recording = true; // ما زلنا في جلسة الصوت (واجهة المعاينة)
          _voicePaused = true;
        });
      }
    } catch (e) {
      debugPrint('pause/stop voice failed: $e');
      if (mounted) {
        setState(() {
          _recording = false;
          _voicePaused = false;
        });
      }
    }
  }

  Future<void> _stopPreview() async {
    try {
      await _previewPlayer.stop();
    } catch (_) {}
    if (mounted && _previewPlaying) {
      setState(() => _previewPlaying = false);
    }
  }





  void _stopRecordTicker() {
    _recordTicker?.cancel();
    _recordTicker = null;
  }

  @override
  void dispose() {
    _networkSub?.cancel();
    _retryTimer?.cancel();
    unawaited(_flushPending());
    _composerDrafts?.dispose();
    _searchDebounce?.cancel();
    if (_mediaQueueCreated) { _mediaQueue.removeListener(_mediaChanged); chatTransfers.detach(widget.chatId); }
_translations.dispose();
    if (!_initialized) {
      _inputCtrl.dispose(); _searchCtrl.dispose(); _messageScroll.dispose();
      unawaited(_recorder.dispose()); unawaited(_previewPlayer.dispose());
      super.dispose(); return;
    }
    unawaited(chatAudioCoordinator.stop());
    _voice.dispose();
    _sub?.cancel();
    _peerSub?.cancel();
    _chatSub?.cancel();
    _typingIdle?.cancel();
    _peerTypingExpiry?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _privacySub?.cancel();
    _authSub?.cancel();
    _uploadSub?.cancel();
    unawaited(_activeUpload?.cancel());
    _messageScroll.dispose();
    _outbox.onChanged = null;
    _chatActivity.dispose();
    _chatPreferences.dispose();
    _recordTicker?.cancel();
    _inputCtrl.dispose();
    _searchCtrl.dispose();
    unawaited(_recorder.dispose());
    unawaited(_previewPlayer.dispose());
    super.dispose();
  }


  Future<void> _clearChat() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(shellText(context, "مسح المحادثة؟")),
        content: Text(shellText(context, "تُمسح عندك فقط. الطرف الآخر يبقي الرسائل.")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(shellText(context, "إلغاء"))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: Text(shellText(context, "مسح")),
          ),
        ],
      ),
    );
    if (ok != true || !mounted || !_chatPreferences.isCurrent) return;
    try {
      await _chatPreferences.clearHistory();
    } catch (_) {
      if (mounted && _chatPreferences.isCurrent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(shellText(context, "تعذر مسح المحادثة عندك. حاول مجددًا."))),
        );
      }
    }
  }

  Future<void> _markChatRead() async {
    try {
      if (_accessUnavailable || !_canRead || _loadingMessages || _initialUnreadCount == null) return;
      final marker = '${_messages.isEmpty ? '' : _messages.first.id}:$_shareReadReceipt';
      if (_lastReadMarker == marker) return;
      _lastReadMarker = marker;
      await _chatActivity.markRead(shareReadReceipt: _shareReadReceipt);
    } catch (_) {
      _lastReadMarker = null;
      debugPrint('Chat read acknowledgement failed');
    }
  }

  Future<void> _setChatTyping(bool active) async {
    try {
      if (_accessUnavailable || active && (!_shareTyping || !_foreground)) return;
      final now = DateTime.now();
      if (active && _lastTypingSent != null && now.difference(_lastTypingSent!) < const Duration(seconds: 2)) return;
      _lastTypingSent = active ? now : null;
      await _chatActivity.setTyping(active);
    } catch (_) {
      debugPrint('Chat typing update failed');
    }
  }

  void _onComposerChanged(String text) {
    if (!_chatActivity.isCurrent) return;
    _typingIdle?.cancel();
    if (text.trim().isEmpty) {
      unawaited(_setChatTyping(false));
      return;
    }
    unawaited(_setChatTyping(true));
    _typingIdle = Timer(const Duration(seconds: 3), () {
      unawaited(_setChatTyping(false));
    });
  }

  types.Message _toMessage(QueryDocumentSnapshot<Map<String, dynamic>> d,) {
    return _messageFromData(d.id, d.data());
  }

  types.Message _messageFromData(String id, Map<String, dynamic> data) {
    final authorId = (data['authorId'] ?? '').toString();
    final created = data['createdAt'];
    final replyText = (data['replyToText'] ?? '').toString();
    final author = authorId == _peer.id ? _peer : types.User(id: authorId);
    final createdAt = created is Timestamp
        ? created.millisecondsSinceEpoch
        : DateTime.now().millisecondsSinceEpoch;
    final meta = <String, dynamic>{
      'caption': data['caption'],
      'thumbnailUrl': data['thumbnailUrl'],
      'viewOnce': data['type'] == 'viewOnce',
      'opened': (data['viewOnceOpenedBy'] as Map?)?[_me.id] == true,
      'local': data['local'] == true,
      'pending': data['pending'] == true,
      'failed': data['failed'] == true,
      if (replyText.isNotEmpty) 'replyToText': replyText,
      if ((data['replyToName'] ?? '').toString().isNotEmpty)
        'replyToName': data['replyToName'].toString(),
      if ((data['replyToId'] ?? '').toString().isNotEmpty)
        'replyToId': data['replyToId'].toString(),
      'starred': data['starredBy'] is Map &&
          (data['starredBy'] as Map)[_me.id] == true,
      'edited': data['editedAt'] != null,
      'reactions': data['reactions'] is Map
          ? Map<String, dynamic>.from(data['reactions'] as Map)
          : const <String, dynamic>{},
    };

    types.Status? status;
    if (authorId == _me.id) {
      final seen = _peerReadAt != null &&
          createdAt <= _peerReadAt!.millisecondsSinceEpoch;
      final delivered = _peerDeliveredAt != null && createdAt <= _peerDeliveredAt!.millisecondsSinceEpoch;
      status = seen ? types.Status.seen : delivered ? types.Status.delivered : types.Status.sent;
    }

    final type = (data['type'] ?? 'text').toString();
    if (['contact','poll','event'].contains(type)) {
      return types.CustomMessage(id:id,author:author,createdAt:createdAt,status:status,metadata:{...meta,'richData':Map<String,dynamic>.from(data)});
    }
    if (type == 'viewOnce') {
      return types.CustomMessage(id:id,author:author,createdAt:createdAt,status:status,metadata:meta);
    }
    if (type == 'image') {
      return types.ImageMessage(
        id: id,
        author: author,
        createdAt: createdAt,
        name: 'image.jpg',
        size: (data['size'] as num?)?.toInt() ?? 0,
        uri: (data['imageUrl'] ?? '').toString(),
        showStatus: authorId == _me.id,
        status: status,
        metadata: meta,
      );
    }
    if (type == 'gif') {
      return types.ImageMessage(
        id: id,
        author: author,
        createdAt: createdAt,
        name: 'gif.gif',
        size: (data['size'] as num?)?.toInt() ?? 0,
        uri: (data['gifUrl'] ?? data['imageUrl'] ?? '').toString(),
        showStatus: authorId == _me.id,
        status: status,
        metadata: meta,
      );
    }
    if (type == 'file') {
      return types.FileMessage(
        id: id,
        author: author,
        createdAt: createdAt,
        name: (data['fileName'] ?? 'file').toString(),
        size: (data['size'] as num?)?.toInt() ?? 0,
        uri: (data['fileUrl'] ?? '').toString(),
        showStatus: authorId == _me.id,
        status: status,
        metadata: meta,
      );
    }
    if (type == 'video') {
      return types.VideoMessage(
        id: id,
        author: author,
        createdAt: createdAt,
        name: 'video.mp4',
        size: (data['size'] as num?)?.toInt() ?? 0,
        uri: (data['videoUrl'] ?? '').toString(),
        showStatus: authorId == _me.id,
        status: status,
        metadata: meta,
      );
    }
    if (type == 'audio') {
      return types.AudioMessage(
        id: id,
        author: author,
        createdAt: createdAt,
        name: 'audio.m4a',
        size: (data['size'] as num?)?.toInt() ?? 0,
        uri: (data['audioUrl'] ?? '').toString(),
        duration: Duration(milliseconds: (data['durationMs'] as num?)?.toInt() ?? 0),
        showStatus: authorId == _me.id,
        status: status,
        metadata: meta,
      );
    }
    return types.TextMessage(
      id: id,
      author: author,
      createdAt: createdAt,
      text: (data['text'] ?? '').toString(),
      showStatus: authorId == _me.id,
      status: status,
      metadata: meta,
    );
  }

  List<types.Message> get _visibleMessages {
    final ids = _messages.map((m) => m.id).toSet();
    final combined = <types.Message>[
      ..._messages,
      for (final entry in _outbox.entries)
        if (!ids.contains(entry.id)) _messageFromData(entry.id, {
          ...entry.message,
          'authorId': _me.id,
          'createdAt': Timestamp.fromDate(entry.createdAt),
          'local': true,
          'pending': entry.state != ChatOutboxState.acknowledged,
          'failed': entry.state == ChatOutboxState.failed,
        }),
    ]..sort((a,b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
    var list = combined;
    if (_clearedAt != null) {
      final cut = _clearedAt!.millisecondsSinceEpoch;
      list = list.where((m) => (m.createdAt ?? 0) > cut).toList();
    }
    return list;
  }

  void _stopSearch() {
    _messageScroll.cancelSearchJump();
    _searchDebounce?.cancel();
    _searchCtrl.clear();
    _desiredSearchId = null;
    _searchOlderThanId = null;
    _searchScanRequested = false;
    _messageSearch.update('', const []);
    setState(() => _searching = false);
  }


  Future<void> _sendKeyboardImage({required Uint8List bytes, required String mimeType,}) async {
    if (_me.id.isEmpty || _sending) return;

    final reason = await _messagingBlockedReason();
    if (!mounted) return;
    if (reason != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(shellText(context, reason))));
      return;
    }

    final isGif = mimeType.toLowerCase().contains('gif');
    setState(() => _sending = true);

    try {
      final id = FirebaseFirestore.instance.collection('chats').doc().id;
      final ext = isGif ? 'gif' : 'jpg';
      final contentType = isGif ? 'image/gif' : (mimeType.isEmpty ? 'image/jpeg' : mimeType);

      final ref = FirebaseStorage.instance
          .ref()
          .child('chats/${widget.chatId}/images/$id.$ext');

      await _uploadBytes(ref, bytes, SettableMetadata(contentType: contentType));
      final url = await ref.getDownloadURL();

      await _publishMessage({
        'type': isGif ? 'gif' : 'image',
        if (isGif) 'gifUrl': url else 'imageUrl': url,
        'size': bytes.length,
      });

      _touchMyPresence();
    } catch (e) {
      if (_uploadFailed) _uploadRetries.add(() => _sendKeyboardImage(bytes: bytes, mimeType: mimeType));
      debugPrint('keyboard image failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(shellFormat(context, "تعذر إرسال الصورة: {0}", [serviceErrorText(context, e)]))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
  Future<void> _uploadVoice(File file, {required Duration duration,}) async {
    if (!mounted || !_initialized || _accessUnavailable || _openedSession != _liveSessionKey) {
      try { if (await file.exists()) await file.delete(); } catch (_) {}
      return;
    }
    var sent = false;
    try {
      if (!mounted) return;

      setState(() {
        _sending = true;
        _voiceState = VoiceRecordingState.sending;
      });

      final id = FirebaseFirestore.instance.collection('chats').doc().id;

      final ref = FirebaseStorage.instance
          .ref()
          .child('chats/${widget.chatId}/audio/$id.${file.path.endsWith('.aac') ? 'aac' : 'm4a'}');

      await _uploadFile(ref,
        file,
        SettableMetadata(
          contentType: file.path.endsWith('.aac') ? 'audio/aac' : 'audio/mp4',
        ),
      );

      final url = await ref.getDownloadURL();
      final size = await file.length();

      await _publishMessage({
        'type': 'audio',
        'audioUrl': url,
        'size': size,
        'durationMs': duration.inMilliseconds,
      });

      sent = true;
      _touchMyPresence();
    } catch (error, stackTrace) {
      if (_uploadFailed) _uploadRetries.add(() => _uploadVoice(file, duration: duration));
      debugPrint('uploadVoice failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(shellFormat(context, "تعذر إرسال التسجيل: {0}", [serviceErrorText(context, error)])),
          ),
        );
      }
    } finally {
      _stopRecordTicker();

      if (mounted) {
        setState(() {
          _sending = false;
          _voiceState = VoiceRecordingState.idle;
        });
      }

      try {
        if (sent && await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _me.id.isEmpty || _sending || _accessUnavailable ||
        !_initialized || _openedSession != _liveSessionKey) return;
    if (_editing != null) {
      setState(() => _sending = true);
      try { await _commitEdit(text); }
      finally { if (mounted) setState(() => _sending = false); }
      return;
    }
    // Enqueue synchronously; the callable remains authoritative for access.
    // Do not lock the composer on the network acknowledgement.
    final reply = _replyTo;
    try {
      final entry = _outbox.enqueue(chatId: widget.chatId, message: {
        'type': 'text', 'text': text,
        if (reply != null) 'replyToId': reply.id,
        if (reply is types.TextMessage) 'replyToText': reply.text,
        if (reply != null) 'replyToAuthorId': reply.author.id,
        if (reply != null) 'replyToName': _senderName(reply.author.id),
      });
      if (_inputCtrl.text.trim() == text) _inputCtrl.clear();
      setState(() => _replyTo = null);
      unawaited(_outbox.attempt(entry.id));
      _typingIdle?.cancel();
      unawaited(_setChatTyping(false));
      if (_messageScroll.hasClients) {
        unawaited(_messageScroll.animateTo(0, duration: const Duration(milliseconds: 160), curve: Curves.easeOut));
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(serviceErrorText(context, error))));
    }
  }

  bool _sharingLocation = false;
  Future<void> _shareLocation() async {
    if (_accessUnavailable || _sending || _sharingLocation || !_initialized) return;
    _sharingLocation = true;
    final session = _openedSession;
    try {
      final text = await showChatLocationSheet(context);
      if (!mounted || text == null || session != _liveSessionKey || _accessUnavailable) return;
      // Keep the wire format compatible with older app versions and the outbox.
      // Do not consume a pending text draft or its edit/reply state.
      final entry = _outbox.enqueue(chatId: widget.chatId, message: {'type': 'text', 'text': text});
      final sent = await _outbox.attempt(entry.id);
      if (mounted && session == _liveSessionKey && !sent &&
          !_messages.any((message) => message.id == entry.id)) {
        throw StateError('تعذر إرسال الرسالة');
      }
    } catch (error) {
      if (mounted && session == _liveSessionKey) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(serviceErrorText(context, error))));
    } finally {
      _sharingLocation = false;
    }
  }

  Future<void> _downloadMedia(types.Message m) async {
    if (m.metadata?['local'] == true || m.metadata?['viewOnce'] == true || !_mediaAuthorized) return;
    final name = m is types.FileMessage ? (m.name.isEmpty ? 'file_${m.id}' : m.name)
      : m is types.ImageMessage ? 'img_${m.id}.jpg'
      : m is types.VideoMessage ? 'vid_${m.id}.mp4'
      : m is types.AudioMessage ? 'aud_${m.id}.m4a' : '';
    if (name.isEmpty) return;
    final session = _openedSession;
    try {
      final saved = await chatDownloads.start(scope: _mediaScope, session: session,
        chatId: widget.chatId, messageId: m.id, name: name,
        isCurrentSession: () => session == _currentChatSession());
      if (!mounted || session != _currentChatSession() || !_mediaAuthorized) return;
      if (m is types.FileMessage) {
        final opened = await OpenFilex.open(saved.path);
        if (opened.type != ResultType.done) throw StateError(opened.message);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(shellText(context, 'تم التحميل'))));
    } catch (error) {
      if (!mounted || session != _currentChatSession()) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(shellFormat(context, 'تعذر التحميل: {0}', [serviceErrorText(context, error)]))));
    }
  }
  Future<void> _showActions(types.Message message, BuildContext bubbleContext) async {
    if (message.metadata?['viewOnce'] == true) return;
    final mine = message.author.id == _me.id;
    final text = message is types.TextMessage ? message.text : '';
    final isText = message is types.TextMessage;
    final starred = message.metadata?['starred'] == true;
    final preview = text.isEmpty
        ? (message is types.ImageMessage
        ? shellText(context, "📷 صورة")
        : message is types.VideoMessage
        ? shellText(context, "🎬 فيديو")
        : message is types.AudioMessage
        ? shellText(context, "🎤 رسالة صوتية")
        : shellText(context, "رسالة"))
        : text;

    final box = bubbleContext.findRenderObject() as RenderBox?;
    final origin = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    final rect = (box != null && box.hasSize)
        ? origin & box.size
        : Rect.fromLTWH(origin.dx, origin.dy, 200, 48);
    if (box == null || !box.hasSize) return;


    HapticFeedback.mediumImpact();

    final result = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: shellText(context, 'إغلاق'),
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (_, __, ___) => _PinnedMessageActionsOverlay(
        rect: rect,
        message: message,
        preview: preview,
        isMine: mine,
        starred: starred,
        isText: isText,
        canDownload: message is! types.CustomMessage,
      ),
    );

    if (!mounted || result == null) return;

    if (result.startsWith('react:')) {
      await _react(message.id, result.substring(6));
      return;
    }
    switch (result) {
      case 'reply':
        setState(() => _replyTo = message);
      case 'copy':
        await Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(shellText(context, "تم النسخ"))),
        );
      case 'translate':
        await _translate(text);
      case 'star':
        await _toggleStar(message);
      case 'edit':
        if (mine) _startEdit(message);
      case 'info':
        _showInfo(message);
      case 'download':
        await _downloadMedia(message);
      case 'hide':
        await _msgs.doc(message.id).update({'hiddenBy.${_me.id}': true});
      case 'delete':
        if (mine) await _delete(message.id);
    }
  }

  Future<void> _quickReact(types.Message message) async {
    HapticFeedback.lightImpact();
    await _react(message.id, '❤️');
  }

  Future<void> _react(String id, String emoji) async {
    if (id.isEmpty || emoji.isEmpty || _me.id.isEmpty) return;
    final uid = _me.id;
    final session = _openedSession;
    try {
      final ref = _msgs.doc(id);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        if (!snapshot.exists) return;
        if (!mounted || session != _liveSessionKey) throw StateError('Session changed');
        final reactions = snapshot.data()?['reactions'];
        final current = reactions is Map ? reactions[uid] : null;
        final next = nextChatReaction(current, emoji);
        transaction.update(ref, {
          'reactions.$uid': next.isEmpty ? FieldValue.delete() : next,
        });
      });
    } catch (e) {
      debugPrint('react failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(shellFormat(context, "تعذر حفظ التفاعل: {0}", [serviceErrorText(context, e)]))),
      );
    }
  }

  Future<void> _toggleStar(types.Message message) async {
    final next = message.metadata?['starred'] != true;
    await _msgs.doc(message.id).update({
      'starredBy.${_me.id}': next ? true : FieldValue.delete(),
    });
  }

  void _startEdit(types.Message message) {
    if (message is! types.TextMessage) return;
    if (_editing == null) _draftBeforeEdit = _inputCtrl.text;
    setState(() {
      _replyTo = null;
      _editing = message;
      _inputCtrl.text = message.text;
      _inputCtrl.selection = TextSelection.collapsed(offset: message.text.length);
      _hasText = message.text.trim().isNotEmpty;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editing = null;
      _inputCtrl.text = _draftBeforeEdit;
      _hasText = _inputCtrl.text.trim().isNotEmpty;
    });
  }

  Future<void> _commitEdit(String text) async {
    final msg = _editing;
    if (msg == null || text.trim().isEmpty) return;
    if (msg is types.TextMessage && msg.text == text.trim()) {
      _cancelEdit();
      return;
    }
    setState(() => _sending = true);
    try {
      await _messageService.mutateChatMessage(chatId: widget.chatId, messageId: msg.id, action: 'edit', text: text.trim());
      if (!mounted) return;
      _cancelEdit();
    } catch (e) {
      debugPrint('edit failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(shellText(context, "تعذر تعديل الرسالة"))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _translate(String text) async {
    if (text.trim().isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _ChatTranslateSheet(text: text),
    );
  }

  void _openStarredMessages() {
    if (!_chatActivity.isCurrent || _accessUnavailable) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatStarredMessagesPage(
      chatId: widget.chatId, ownerUid: _me.id,
      isCurrent: () => mounted && _chatActivity.isCurrent && !_accessUnavailable,
    )));
  }

  void _showInfo(types.Message message) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => StreamBuilder<User?>(
        stream: FirebaseAuth.instance.userChanges(),
        initialData: FirebaseAuth.instance.currentUser,
        builder: (context, auth) {
          if (!mounted || !_chatActivity.isCurrent || _accessUnavailable || auth.data?.uid != _me.id) {
            return const SizedBox.shrink();
          }
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('chats').doc(widget.chatId).snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.hasError ? <String,dynamic>{} : snapshot.data?.data() ?? <String,dynamic>{};
              if (snapshot.hasError || snapshot.hasData && !(data['memberIds'] as List? ?? []).contains(_me.id)) return const SizedBox.shrink();
              return ChatMessageInfoSheet(
                message: message, senderName: _senderName(message.author.id), isMine: message.author.id == _me.id,
                readers: chatMessageReaders(conversation: data, viewerId: _me.id, authorId: message.author.id,
                  createdAt: message.createdAt, timestamp: (value) => value is Timestamp ? value.toDate() : null,
                  pending: message.metadata?['pending'] == true, failed: message.metadata?['failed'] == true),
              );
            },
          );
        },
      ),
    );
  }
  Future<void> _delete(String id) async {
    try {
      await _messageService.mutateChatMessage(chatId: widget.chatId, messageId: id, action: 'delete');
    } catch (e) {
      debugPrint('delete failed: $e');
    }
  }

  void _openPeerProfile() {
    if (_isGroup) { unawaited(_openGroupDetails()); return; }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          userId: widget.peerId,
          initialName: widget.peerName,
          initialPhotoUrl: widget.peerPhotoUrl,
        ),
      ),
    ).then((_) { if (mounted) unawaited(_markChatRead()); });
  }

  void _openImageFullscreen(String url) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => ChatImageViewer(url: url, scope: _mediaScope, authorized: () => _mediaAuthorized),
      ),
    ).then((_) { if (mounted) unawaited(_markChatRead()); });
  }

  void _openVideoFullscreen(String url) {
    unawaited(chatAudioCoordinator.stop());
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ChatVideoViewer(url: url),
      ),
    ).then((_) { if (mounted) unawaited(_markChatRead()); });
  }


  bool _wallpaperUploading = false;
  double? _wallpaperUploadProgress;
  Future<String?> _setPhotoWallpaper(File source) async {
    if (_wallpaperUploading || !_chatPreferences.isCurrent) return null;
    final session = _openedSession;
    final uid = _me.id;
    File? prepared;
    StreamSubscription<TaskSnapshot>? subscription;
    void guard() {
      if (!mounted || session != _liveSessionKey || !_chatPreferences.isCurrent) {
        throw StateError('Conversation session changed');
      }
    }
    setState(() { _wallpaperUploading = true; _wallpaperUploadProgress = null; });
    try {
      prepared = await prepareChatPhoto(source, hd: false);
      guard();
      final handle = await prepared.open();
      late List<int> header;
      try { header = await handle.read(32); } finally { await handle.close(); }
      final format = detectChatImageFormat(header, prepared.path);
      final ref = FirebaseStorage.instance.ref('chats/${widget.chatId}/wallpaper/$uid.jpg');
      await StorageUploadService.putFile(ref, prepared, SettableMetadata(contentType: format.contentType), onTask: (task) {
        subscription = task.snapshotEvents.listen((snapshot) {
          if (mounted && session == _liveSessionKey) setState(() => _wallpaperUploadProgress =
            snapshot.totalBytes > 0 ? snapshot.bytesTransferred / snapshot.totalBytes : null);
        }, onError: (Object _) {});
      });
      guard();
      final uploaded = Uri.parse(await ref.getDownloadURL());
      final url = uploaded.replace(queryParameters: {...uploaded.queryParameters,
        'v': DateTime.now().microsecondsSinceEpoch.toString()}).toString();
      guard();
      await _chatPreferences.setWallpaper('photo', photoUrl: url);
      guard();
      setState(() { _wallpaper = 'photo'; _wallpaperUrl = url; });
      return url;
    } catch (error) {
      debugPrint('[ChatWallpaper] failed: ${error is FirebaseException ? error.code : error.runtimeType}');
      if (mounted && session == _liveSessionKey) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(serviceErrorText(context, error))));
      return null;
    } finally {
      await subscription?.cancel();
      if (prepared != null && prepared.path != source.path) {
        try { await prepared.delete(); } catch (_) {}
      }
      if (mounted) setState(() { _wallpaperUploading = false; _wallpaperUploadProgress = null; });
    }
  }

  bool _openingAttachment = false;
  String _attachmentText(String ar, String en, String fr) => mediaText(context, ar, en, fr);

  Future<void> _publishAttachment(Map<String, dynamic> data, String session) async {
    if (!mounted || !_initialized || _accessUnavailable || session != _liveSessionKey || session != _openedSession) {
      throw StateError('Conversation session changed');
    }
    final entry = _outbox.enqueue(chatId: widget.chatId, message: data);
    final sent = await _outbox.attempt(entry.id);
    if (mounted && session == _liveSessionKey && !sent && !_messages.any((m) => m.id == entry.id)) {
      throw StateError('Message send failed');
    }
  }

  Future<void> _shareRichAttachment(String kind) async {
    if (_openingAttachment || _sending || _accessUnavailable || !_initialized) return;
    _openingAttachment = true;
    final session = _openedSession;
    try {
      final data = await showChatRichAttachmentSheet(context, kind: kind);
      if (data == null || !mounted || session != _liveSessionKey) return;
      await _publishAttachment(data, session);
    } catch (error) {
      if (mounted && session == _liveSessionKey) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(serviceErrorText(context, error))));
    } finally { _openingAttachment = false; }
  }

  Future<void> _openCamera() async {
    if (_openingAttachment || _sending || _accessUnavailable || !_initialized) return;
    _openingAttachment = true;
    final session = _openedSession;
    try {
      final video = await showModalBottomSheet<bool>(context: context, builder: (ctx) => SafeArea(child: Column(
        mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.photo_camera), title: Text(_attachmentText('التقاط صورة', 'Take photo', 'Prendre une photo')), onTap: () => Navigator.pop(ctx, false)),
          ListTile(leading: const Icon(Icons.videocam), title: Text(_attachmentText('تسجيل فيديو', 'Record video', 'Enregistrer une vidéo')), onTap: () => Navigator.pop(ctx, true)),
        ],
      )));
      if (video == null || !mounted || session != _liveSessionKey) return;
      final picker = ImagePicker();
      final picked = video
          ? await picker.pickVideo(source: ImageSource.camera, maxDuration: const Duration(seconds: 60))
          : await picker.pickImage(source: ImageSource.camera, imageQuality: 100);
      if (picked == null || !mounted || session != _liveSessionKey) return;
      await _reviewMedia([File(picked.path)]);
    } catch (_) {
      if (mounted && session == _liveSessionKey) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        _attachmentText('تعذر فتح الكاميرا. تحقق من صلاحيتها وحاول مجددًا.', 'Could not open camera. Check permission and try again.', 'Impossible d’ouvrir la caméra. Vérifiez l’autorisation puis réessayez.'))));
    } finally { _openingAttachment = false; }
  }

  Future<void> _uploadAndSendImage(XFile picked) async {
    if (!mounted) return;
    setState(() => _sending = true);
    try {
      final bytes = await picked.readAsBytes();
      final format = detectChatImageFormat(bytes, picked.path);
      if (bytes.length >= 40 * 1024 * 1024) throw StateError('Media exceeds 40 MB');
      final id = FirebaseFirestore.instance.collection('chats').doc().id;
      final ref = FirebaseStorage.instance
          .ref()
          .child('chats/${widget.chatId}/images/$id.${format.extension}');

      await _uploadBytes(ref, bytes, SettableMetadata(contentType: format.contentType));
      final url = await ref.getDownloadURL();

      await _publishMessage({
        'type': format.isGif ? 'gif' : 'image',
        if (format.isGif) 'gifUrl': url else 'imageUrl': url,
        'size': bytes.length,
      });

      _touchMyPresence();
    } catch (e, st) {
      if (_uploadFailed) _uploadRetries.add(() => _uploadAndSendImage(picked));
      debugPrint('send image failed: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(shellFormat(context, "تعذر إرسال الصورة: {0}", [serviceErrorText(context, e)]))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickVideo() async {
    if (_me.id.isEmpty || _sending) return;

    final reason = await _messagingBlockedReason();
    if (!mounted) return;
    if (reason != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(shellText(context, reason))));
      return;
    }

    final picked = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );
    if (picked == null || !mounted) return;
    await _reviewMedia([File(picked.path)]);
  }

  Future<void> _uploadPickedVideo(XFile picked) async {
    setState(() => _sending = true);
    try {
      final id = FirebaseFirestore.instance.collection('chats').doc().id;
      final file = File(picked.path);
      final format = detectChatVideoFormat(picked.path);
      final size = await picked.length();
      if (size >= 40 * 1024 * 1024) throw StateError('Media exceeds 40 MB');
      final ref = FirebaseStorage.instance
          .ref()
          .child('chats/${widget.chatId}/videos/$id.${format.extension}');

      if (await file.exists()) {
        await _uploadFile(ref, file, SettableMetadata(contentType: format.contentType));
      } else {
        final bytes = await picked.readAsBytes();
        await _uploadBytes(ref, bytes, SettableMetadata(contentType: format.contentType));
      }

      final url = await ref.getDownloadURL();

      await _publishMessage({
        'type': 'video',
        'videoUrl': url,
        'size': size,
      });

      _touchMyPresence();
    } catch (e, st) {
      if (_uploadFailed) _uploadRetries.add(() => _uploadPickedVideo(picked));
      debugPrint('send video failed: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(shellFormat(context, "تعذر إرسال الفيديو: {0}", [serviceErrorText(context, e)]))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickFile() async {
    if (_openingAttachment || _sending || _accessUnavailable || !_initialized) return;
    _openingAttachment = true;
    final session = _openedSession;
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any, withData: false);
      if (result == null || result.files.isEmpty || !mounted || session != _liveSessionKey) return;
      final file = result.files.single;
      if (file.size <= 0 || file.size > chatDocumentMaxBytes) {
        throw FormatException(_attachmentText('الملف فارغ أو حجمه أكبر من 20 ميغابايت.', 'File is empty or larger than 20 MB.', 'Le fichier est vide ou dépasse 20 Mo.'));
      }
      final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: Text(_attachmentText('إرسال مستند', 'Send document', 'Envoyer un document')),
        content: Text('${chatDocumentName(file.name)}\n${(file.size / (1024 * 1024)).toStringAsFixed(2)} MB'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(shellText(context, 'إلغاء'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(shellText(context, 'إرسال'))),
        ],
      ));
      if (confirmed != true || !mounted || session != _liveSessionKey) return;
      final bytes = await readChatDocument(file);
      if (!mounted || session != _liveSessionKey) return;
      await _uploadPickedFile(PlatformFile(name: chatDocumentName(file.name), size: bytes.length, bytes: bytes));
    } catch (error) {
      if (mounted && session == _liveSessionKey) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        error is FormatException ? _attachmentText('تعذر قراءة الملف. تحقق من أنه غير فارغ وأن حجمه لا يتجاوز 20 ميغابايت.', 'Could not read file. Check it is not empty and at most 20 MB.', 'Impossible de lire le fichier. Vérifiez sa taille : de 1 octet à 20 Mo.') : serviceErrorText(context, error))));
    } finally { _openingAttachment = false; }
  }

  Future<void> _uploadPickedFile(PlatformFile file) async {
    final session = _openedSession;
    if (!mounted || _accessUnavailable || session != _liveSessionKey) return;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(shellText(context, "تعذر قراءة الملف"))),
      );
      return;
    }

    // حد أقصى ~20MB
    if (bytes.length > 20 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(shellText(context, "حجم الملف كبير جداً (الحد 20MB)"))),
      );
      return;
    }

    var uploaded = false;
    setState(() => _sending = true);
    try {
      final id = FirebaseFirestore.instance.collection('chats').doc().id;
      final name = chatDocumentName(file.name);
      final safeName = name.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      final url = await ChatDocumentService.upload(
        path: 'chats/${widget.chatId}/files/${id}_$safeName', bytes: bytes,
      );

      uploaded = true;
      await _publishAttachment({
        'type': 'file',
        'fileUrl': url,
        'fileName': name,
        'size': bytes.length,
      }, session);

      _touchMyPresence();
    } catch (e, st) {
      // Failed message submissions already live in the outbox; keep only upload retries.
      if (!uploaded) {
        _uploadRetries.add(() => _uploadPickedFile(file));
      }
      debugPrint('send file failed: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(shellFormat(context, "تعذر إرسال الملف: {0}", [serviceErrorText(context, e)]))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
  bool _isVideoMediaFile(File file) {
    final path = file.path.toLowerCase();
    return path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.m4v') ||
        path.endsWith('.3gp') ||
        path.endsWith('.webm') ||
        path.endsWith('.mkv');
  }

  Future<void> _sendPickedMediaFiles(List<File> files, {String caption = ''}) =>
      _reviewMedia(files, caption: caption);

  Future<void> _reviewMedia(List<File> files, {String caption = ''}) async {
    final retained = _composerDrafts?.drafts ?? const <ChatMediaDraft>[];
    if (!mounted || (files.isEmpty && retained.isEmpty) || _sending || _accessUnavailable || _openedSession != _liveSessionKey) return;
    final drafts = [...retained, for (final file in files) ChatMediaDraft(file)..caption = caption];
    if (drafts.length > 30) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mediaText(context, 'أرسل المسودات الحالية أو احذفها قبل إضافة المزيد', 'Send or discard current drafts before adding more', 'Envoyez ou supprimez les ébauches avant d’en ajouter'))));
      return;
    }
    final session = _liveSessionKey;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatMediaComposer(
      files: files.take(30).toList(), initialCaption: caption, initialDrafts: drafts,
      onDraftsChanged: _composerDrafts?.save,
      onDraftsSent: _composerDrafts?.clear,
      onSend: (draft, progress) => chatTransfers.send(widget.chatId, draft, progress),
      onEnqueue: (drafts) async {
        if (!mounted || session != _liveSessionKey || _accessUnavailable) throw StateError('Session changed');
        _mediaQueue.enqueue(drafts);
        await _mediaQueue.flush();
        if (_messageScroll.hasClients) _messageScroll.jumpTo(0);
      },
    )));
    if (mounted) setState(() {});
  }

  Future<void> _openWhatsAppGallery() async {
    if (_me.id.isEmpty || _sending || _accessUnavailable) return;
    try {
      final picked=await showChatMediaGallery(context);
      if (!mounted || picked == null || picked.isEmpty) return;
      await _reviewMedia(picked);
    } catch (_) {
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(shellText(context,'تعذر فتح أداة اختيار الصور والفيديو'))));
    }
  }

  Future<void> _insertLink() async {
    if (_openingAttachment || _sending || _accessUnavailable || !_initialized) return;
    _openingAttachment = true;
    final session = _openedSession;
    try {
      final link = await showChatLinkDialog(context);
      if (link != null && mounted && session == _liveSessionKey) {
        await _publishAttachment({'type': 'text', 'text': link}, session);
      }
    } catch (error) {
      if (mounted && session == _liveSessionKey) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(serviceErrorText(context, error))));
    } finally { _openingAttachment = false; }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return Scaffold(appBar: AppBar(), body: Center(
      child: _startupError == null ? const CircularProgressIndicator()
        : Text(shellText(context, _startupError!))));
    if (_accessUnavailable) return Scaffold(appBar: AppBar(), body: Center(child: Text(chatUiText(context, 'Conversation unavailable'))));

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final messages = _visibleMessages;

    return ChatRecordingLeaveGuard(voice: _voice, child: ChatWallpaperScaffold(
      decoration: chatWallpaperDecoration(id: _wallpaper, url: _wallpaperUrl, isDark: isDark),
      appBar: AppBar(
        backgroundColor: _wallpaper == 'photo' && _wallpaperUrl.isNotEmpty
            ? Colors.transparent
            : _chatWallpaperColor(_wallpaper, isDark).withValues(alpha: 0.92),
        flexibleSpace: _wallpaper == 'photo' && _wallpaperUrl.isNotEmpty ? const ChatPhotoHeaderBackdrop() : null,
        foregroundColor: theme.colorScheme.onSurface,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        shape: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        leading: _searching
            ? IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _stopSearch,
        )
            : null,
        title: _searching
            ? _ChatSearchBar(
          controller: _searchCtrl,
          isDark: isDark,
          resultCount: _searchCtrl.text.trim().isEmpty
              ? null
              : _messageSearch.matchIds.length,
          onChanged: _onChatSearchChanged,
          onClear: () {
            _searchCtrl.clear();
            _onChatSearchChanged();
          },
        )
            : InkWell(
          onTap: _openPeerProfile,
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: (widget.peerPhotoUrl ?? '').isNotEmpty
                    ? NetworkImage(widget.peerPhotoUrl!)
                    : null,
                child: (widget.peerPhotoUrl ?? '').isEmpty
                    ? Icon(_isGroup ? Icons.group_outlined : Icons.person_outline, size: 18)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _nickname.trim().isNotEmpty
                          ? _nickname.trim()
                          : _conversationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                      ),
                    ),
                    if (_peerTyping)
                      Text(
                        shellText(context, "يكتب الآن…"),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTeal.main,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else if (_isGroup)
                      Text('${(_conversationData['memberIds'] as List? ?? []).length} ${chatGroupText(context, 'Members')}', style: TextStyle(fontSize: 12, color: theme.hintColor))
                    else if (_peerLastActive != null)
                      Text(
                        DateTime.now()
                            .difference(_peerLastActive!)
                            .inMinutes <
                            3
                            ? shellText(context, "متصل الآن")
                            : shellFormat(context, "آخر ظهور {0}", [_chatTimeAgo(context, _peerLastActive)]),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.hintColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (!_searching) ...[
            IconButton(
              tooltip: mediaText(context, 'تخزين المحادثة', 'Conversation storage', 'Stockage de la conversation'),
              icon: const Icon(Icons.storage_outlined),
              onPressed: () {
                if (!_mediaAuthorized) return;
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatConversationStoragePage(
                  scope: _mediaScope,
                  title: _conversationName,
                  authorized: () => _mediaAuthorized,
                  protectedStore: _localPersistence,
                )));
              },
            ),
            IconButton(
              tooltip: shellText(context, "بحث"),
              icon: const Icon(Icons.search_rounded),
              onPressed: () => setState(() => _searching = true),
            ),
            IconButton(
              tooltip: shellText(context, "المزيد"),
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                if (!_chatPreferences.isCurrent) return;
                if (_isGroup) { unawaited(_openGroupDetails()); return; }
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _ChatDetailsPage(
                    chatId: widget.chatId,
                    peerId: widget.peerId,
                    peerName: widget.peerName ?? shellText(context, "محادثة"),
                    peerPhotoUrl: widget.peerPhotoUrl,
                    muted: _muted,
                    nickname: _nickname,
                    wallpaper: _wallpaper,
                    wallpaperUrl: _wallpaperUrl,
                    bubbleColor: _bubbleColor,
                    autoTranslate: _autoTranslate,
                    autoTranslateLang: _autoTranslateLang,
                    startedAt: _chatStartedAt,
                    messages: _messages,
                    onStarredMessages: () { Navigator.of(context).pop(); _openStarredMessages(); },
                    onSearch: () {
                      Navigator.pop(context);
                      setState(() => _searching = true);
                    },
                    onOpenProfile: _openPeerProfile,
                    preferences: _chatPreferences,
                    onClear: _clearChat,
                    onWallpaperPhoto: _setPhotoWallpaper,
                    onWallpaperChanged: (id) {
                      setState(() {
                        _wallpaper = id;
                        if (id != 'photo') _wallpaperUrl = '';
                      });
                    },
                    onBubbleColorChanged: (c) {
                      setState(() {
                        _bubbleColor = c;
                        _bubbleGradient = null;
                      });
                    },
                    onBubbleGradientChanged: (g) {
                      setState(() {
                        _bubbleGradient = g
                            ?.map((e) => Color(e))
                            .toList();
                      });
                    },
                    onWallpaperUrlChanged: (url) {
                      setState(() {
                        _wallpaper = 'photo';
                        _wallpaperUrl = url;
                      });
                    },
                  ),
                );
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty && _loadingMessages
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? Center(
              child: Text(
                shellText(context, _messagesError ?? "لا توجد رسائل بعد"),
                style: TextStyle(color: theme.hintColor),
              ),
            )
                : ListView.builder(
              controller: _messageScroll,
              clipBehavior: Clip.none,
              reverse: true,
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final message = messages[i];
                final mine = message.author.id == _me.id;
                final older = i + 1 < messages.length ? messages[i + 1] : null;
                final sameGroupAsOlder = older != null &&
                    older.author.id == message.author.id &&
                    ((message.createdAt ?? 0) - (older.createdAt ?? 0)) <
                        3 * 60 * 1000;
                final isLastOverall = i == 0;

                return AutoScrollTag(key: ValueKey(message.id), controller: _messageScroll, index: i,
                  child: ChatSearchHighlight(selected: _targetHighlightId == message.id || (_searching && _messageSearch.selectedId == message.id),
                  child: Padding(
                  padding: EdgeInsets.only(
                    top: sameGroupAsOlder ? 3 : 12,
                  ),
                  child: Column(children: [
                    if (ChatConversationMetadata.startsDay(message.createdAt, older?.createdAt))
                      Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(
                        MaterialLocalizations.of(context).formatMediumDate(DateTime.fromMillisecondsSinceEpoch(message.createdAt!)),
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                      )),
                    if (_isGroup && !mine && !sameGroupAsOlder)
                      Align(alignment: Alignment.centerLeft, child: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 12, bottom: 4),
                        child: Text(_senderName(message.author.id), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                      )),
                    if ((_initialUnreadCount ?? 0) > 0 && i == _initialUnreadCount! - 1)
                      Padding(padding: const EdgeInsets.all(8), child: Text(shellText(context, 'رسائل جديدة'))),
                    Align(
                    alignment: mine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: _SwipeToReply(
                      mine: mine,
                      onReply: () {
                        if (message.metadata?['local'] == true) return;
                        HapticFeedback.mediumImpact();
                        setState(() => _replyTo = message);
                      },
                      child: _MessageBubbleTile(
                        message: message,
                        translationService: _translations,
                        autoTranslate: _autoTranslate && !mine,
                        translationTarget: chatTranslationTarget(_autoTranslateLang, Localizations.localeOf(context).languageCode),
                        mediaScope: _mediaScope,
                        mediaAuthorized: () => _mediaAuthorized,
                        currentUid: _me.id,
                        onVote: message.metadata?['local'] == true ? null : (option) => _messageService.voteChatPoll(chatId: widget.chatId, messageId: message.id, optionIndex: option),
                        onRespondEvent: message.metadata?['local'] == true ? null : (attending) => _messageService.respondChatEvent(chatId: widget.chatId, messageId: message.id, attending: attending),
                        mine: mine,
                        isLastOverall: isLastOverall,
                        peerReadAt: _peerReadAt,
                        peerDeliveredAt: _peerDeliveredAt,
                        onTapViewOnce: () { if (message.author.id != _me.id && message.metadata?['opened'] != true && message.metadata?['local'] != true) Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatViewOncePage(chatId:widget.chatId,messageId:message.id))); },
                        onTapImage: _openImageFullscreen,
                        onTapVideo: _openVideoFullscreen,
                        onTapFile: (file) => unawaited(_downloadMedia(file)),
                        onLongPress: (ctx) { if (message.metadata?['local'] != true) _showActions(message, ctx); },
                        onDoubleTap: () { if (message.metadata?['local'] != true) _quickReact(message); },
                        accent: Color(_bubbleColor),
                        accentGradient: _bubbleGradient == null
                            ? null
                            : LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: _bubbleGradient!,
                        ),
                      ),
                    ),
                  ),
                    if (message.metadata?['failed'] == true)
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        TextButton(onPressed: () => _outbox.retry(message.id), child: Text(shellText(context, 'إعادة المحاولة'))),
                        IconButton(tooltip: shellText(context, 'إلغاء'), onPressed: () => _outbox.removeFailed(message.id), icon: const Icon(Icons.close)),
                      ]),
                  ]),
                )));
              },
            ),
          ),
          if (_initialTargetId != null) Material(
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: Row(children: [
              if (_loadingMessages) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              Expanded(child: Text(mediaText(context, 'البحث عن موقع الرسالة', 'Locating the message', 'Localisation du message'))),
              if (!_loadingMessages) TextButton(onPressed: () { _targetPagesRemaining = 5; _advanceInitialTarget(); }, child: Text(mediaText(context, 'متابعة', 'Continue', 'Continuer'))),
              IconButton(tooltip: mediaText(context, 'إلغاء', 'Cancel', 'Annuler'), onPressed: () => setState(() { _initialTargetId = null; _messageScroll.cancelSearchJump(); }), icon: const Icon(Icons.close)),
            ])),
          ),
          if (_searching && normalizeCommunitySearch(_searchCtrl.text).isNotEmpty) ChatSearchNavigation(
            current: _messageSearch.selectedIndex + 1, total: _messageSearch.matchIds.length,
            loading: _searchLoadingOlder, hasOlder: _canSearchOlder,
            onOlder: !_searchLoadingOlder && (_messageSearch.selectedIndex + 1 < _messageSearch.matchIds.length || _canSearchOlder) ? () => _moveChatSearch(1) : null,
            onNewer: _messageSearch.selectedIndex > 0 ? () => _moveChatSearch(-1) : null,
          ),
          if (_messagesError != null)
            TextButton(onPressed: _listenMessages, child: Text(shellText(context, 'إعادة المحاولة'))),
          if (!_searching && _messageScroll.hasClients && _messageScroll.offset > 80)
            TextButton.icon(onPressed: () => _messageScroll.animateTo(0,
              duration: const Duration(milliseconds: 200), curve: Curves.easeOut),
              icon: const Icon(Icons.arrow_downward), label: Text(shellText(context, 'أحدث الرسائل'))),
          if (_uploadRetries.isNotEmpty && !_sending)
            SizedBox(height: 56, child: ListView.builder(
              itemCount: _uploadRetries.length,
              itemBuilder: (context, index) => Row(children: [
                Expanded(child: Text(shellText(context, 'تعذر رفع المرفق'))),
                TextButton(onPressed: () async {
                  final retry = _uploadRetries[index];
                  setState(() => _uploadRetries.removeAt(index));
                  await retry();
                }, child: Text(shellText(context, 'إعادة المحاولة'))),
                IconButton(onPressed: () => setState(() => _uploadRetries.removeAt(index)), icon: const Icon(Icons.close)),
              ]),
            )),
          if (_wallpaperUploading) ChatTransferProgress(
            label: _attachmentText('جارٍ تعيين الخلفية', 'Setting wallpaper', 'Application du fond'),
            progress: _wallpaperUploadProgress,
          ),
          if (_mediaQueue.entries.isNotEmpty) SizedBox(
            height: min(180.0, _mediaQueue.entries.length * 96.0),
            child: ListView(children: [for (final entry in _mediaQueue.entries)
              Row(children: [Expanded(child: ChatTransferProgress(
                label: entry.error != null ? shellText(context, 'تعذر رفع المرفق')
                    : entry.sending ? _attachmentText('جارٍ الإرسال', 'Sending', 'Envoi en cours')
                    : _attachmentText('بانتظار الإرسال', 'Waiting to send', 'En attente'),
                detail: entry.draft.viewOnce ? _attachmentText('عرض مرة واحدة', 'View once', 'Vue unique')
                    : entry.draft.caption.isNotEmpty ? entry.draft.caption
                    : entry.draft.video ? _attachmentText('فيديو', 'Video', 'Vidéo') : _attachmentText('صورة', 'Photo', 'Photo'),
                progress: entry.progress,
              )),
                if (entry.error != null) IconButton(tooltip: shellText(context, 'إعادة المحاولة'),
                  onPressed: () => _mediaQueue.retry(entry), icon: const Icon(Icons.refresh)),
                if (!entry.sending) IconButton(tooltip: shellText(context, 'إلغاء'),
                  onPressed: () => _mediaQueue.discard(entry), icon: const Icon(Icons.close)),
              ]),
            ])),
          if (_activeUpload != null && _mediaQueue.entries.isEmpty) ChatTransferProgress(
            label: _attachmentText('جارٍ الإرسال', 'Sending', 'Envoi en cours'),
            progress: _uploadProgress,
            onCancel: () => _activeUpload?.cancel(),
          ),
          ListenableBuilder(listenable: chatDownloads, builder: (context, _) => Column(children: [
            for (final job in chatDownloads.jobs.where((job) => job.scope == _mediaScope && job.status == ChatDownloadStatus.downloading))
              ChatTransferProgress(label: _attachmentText('جارٍ التحميل', 'Downloading', 'Téléchargement'),
                detail: job.name, progress: job.progress, downloading: true,
                onCancel: () => chatDownloads.cancel(job.id)),
          ])),          if (_peerTyping)
            Padding(
              padding: const EdgeInsets.only(right: 14, bottom: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: _TypingBubble(isDark: isDark),
              ),
            ),
          if (!_searching && (_composerDrafts?.drafts.isNotEmpty ?? false))
            ListTile(leading: const Icon(Icons.photo_library_outlined),
              title: Text(mediaText(context, 'مرفقات غير مرسلة (${_composerDrafts!.drafts.length})', 'Unsent attachments (${_composerDrafts!.drafts.length})', 'Pièces jointes non envoyées (${_composerDrafts!.drafts.length})')),
              onTap: () => _reviewMedia(const []),
              trailing: IconButton(icon: const Icon(Icons.delete_outline), tooltip: shellText(context, 'حذف'), onPressed: () async {
                final discard = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: Text(mediaText(context, 'حذف مسودات المرفقات؟', 'Discard attachment drafts?', 'Supprimer les ébauches jointes ?')), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(shellText(ctx, 'إلغاء'))), TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(shellText(ctx, 'حذف')))]));
                if (discard != true || !mounted) return;
                try { await _composerDrafts?.clear(); if (mounted) setState(() {}); }
                catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mediaText(context, 'تعذر حذف المسودة', 'Could not discard draft', 'Impossible de supprimer l’ébauche')))); }
              })),
          if (!_searching && !_postingAllowed) Padding(padding: const EdgeInsets.all(16), child: Text(mediaText(context, 'يمكن للمشرفين فقط الإرسال في هذه المجموعة', 'Only administrators can send to this group', 'Seuls les administrateurs peuvent envoyer des messages'))),
          if (!_searching && _postingAllowed) InstagramComposer(
            controller: _inputCtrl,
            replyTo: _replyTo,
            editing: _editing,
            onCancelEdit: _sending ? null : _cancelEdit,
            peerName: _replyTo == null ? _conversationName : _senderName(_replyTo!.author.id),
            sending: _sending,
            hasText: _hasText,
            voice: _voice,
            onSendVoice: (file, duration) => _uploadVoice(file, duration: duration),
            // Recording is local; upload and send still enforce server access.
            onBeforeStart: () async {
              await chatAudioCoordinator.stop();
              return mounted && _initialized && !_accessUnavailable && _postingAllowed && _openedSession == _liveSessionKey;
            },
            onStartFailed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(shellText(context, _voice.lastError == 'mic-permission' ? "يلزم السماح بالميكروفون" : "تعذر بدء التسجيل. حاول مجددًا."))),
              );
            },

            onCancelReply: () => setState(() => _replyTo = null),
            onSend: _send,
            onChanged: _onComposerChanged,

            onSendMedia: (files, caption) =>
                _sendPickedMediaFiles(files, caption: caption),
            onPickImage: () => unawaited(_openWhatsAppGallery()),
            onPickVideo: () => unawaited(_pickVideo()),
            onPickFile: () => unawaited(_pickFile()),
            onLocation: () => unawaited(_shareLocation()),
            onContact: () => unawaited(_shareRichAttachment('contact')),
            onPoll: () => unawaited(_shareRichAttachment('poll')),
            onEvent: () => unawaited(_shareRichAttachment('event')),
            onOpenCamera: () => unawaited(_openCamera()),
            onInsertLink: () => unawaited(_insertLink()),

            onContentInserted: (c) async {
              final data = c.data;
              if (data == null || data.isEmpty) return;
              await _sendKeyboardImage(bytes: data, mimeType: c.mimeType);
            },
          ),


        ],
      ),
    ));
  }
}

class _SwipeToReply extends StatefulWidget {
  const _SwipeToReply({
    required this.mine,
    required this.onReply,
    required this.child,
  });

  final bool mine;
  final VoidCallback onReply;
  final Widget child;

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply> {
  double _dx = 0;
  static const _max = 48.0;
  static const _trigger = 32.0;

  void _reset() {
    if (_dx == 0) return;
    setState(() => _dx = 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (d) {
        final next = widget.mine
            ? (_dx + d.delta.dx).clamp(-_max, 0.0)
            : (_dx + d.delta.dx).clamp(0.0, _max);
        if (next != _dx) setState(() => _dx = next);
      },
      onHorizontalDragEnd: (_) {
        if (_dx.abs() >= _trigger) widget.onReply();
        _reset();
      },
      onHorizontalDragCancel: _reset,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: widget.mine ? Alignment.centerRight : Alignment.centerLeft,
        children: [
          Opacity(
            opacity: (_dx.abs() / _max).clamp(0.0, 1.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.reply_rounded,
                size: 20,
                color: AppTeal.main,
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(_dx, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _AllEmojiSheet extends StatelessWidget {
  const _AllEmojiSheet();

  static const Color _darkBackground = Color(0xFF18191C);
  static const Color _darkSurface = Color(0xFF222428);
  static const Color _lightBackground = Color(0xFFF7F8FA);
  static const Color _lightSurface = Colors.white;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color backgroundColor =
    isDark ? _darkBackground : _lightBackground;

    final Color surfaceColor =
    isDark ? _darkSurface : _lightSurface;

    // ارتفاع لوحة المفاتيح — يمنع ظهور شريط البحث تحتها
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Material(
      color: Colors.transparent,
      child: Padding(
        // يرفع الورقة فوق لوحة المفاتيح عند فتح البحث
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            top: false,
            // لا نضاعف الـ SafeArea عند وجود لوحة مفاتيح
            bottom: bottomInset == 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPicker(
                  context: context,
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  bottomInset: bottomInset,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }




  Widget _buildPicker({
    required BuildContext context,
    required bool isDark,
    required Color surfaceColor,
    double bottomInset = 0,
  }) {
    final double screenH = MediaQuery.sizeOf(context).height;
    final double maxPickerH = (screenH - bottomInset - 80).clamp(220.0, 390.0);
    final double pickerHeight = bottomInset > 0 ? maxPickerH : 390.0;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(20),
      ),
      child: Container(
        color: surfaceColor,
        child: EmojiPicker(
          onEmojiSelected: (Category? category, Emoji emoji) {
            Navigator.of(context).pop(emoji.emoji);
          },
          config: Config(
            height: pickerHeight, // ← كان ثابت 390
            // The bundled emoji font supports glyphs absent from older device fonts.
            checkPlatformCompatibility: false,
            locale: Localizations.localeOf(context),
            // البحث أولًا، ثم التصنيفات، ثم الإيموجي.

            viewOrderConfig: const ViewOrderConfig(
              top: EmojiPickerItem.searchBar,
              middle: EmojiPickerItem.emojiView,
              bottom: EmojiPickerItem.categoryBar,
            ),

            emojiTextStyle: const TextStyle(
              fontFamily: 'NotoColorEmoji',
              fontSize: 27,
            ),

            emojiViewConfig: EmojiViewConfig(
              columns: 7,          // كان 8 - خلايا أكبر وأسهل لمسًا
              emojiSizeMax: 32,     // كان 29
              verticalSpacing: 8,   // كان 5
              horizontalSpacing: 4, // كان 2
              gridPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              recentsLimit: 32,
              replaceEmojiOnLimitExceed: true,
              buttonMode: ButtonMode.MATERIAL,
              noRecents: Center(
                child: Text(
                  shellText(context, "لا توجد رموز مستخدمة مؤخرًا"),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),

            categoryViewConfig: CategoryViewConfig(
              initCategory: Category.SMILEYS,
              backgroundColor: surfaceColor,
              iconColor: isDark
                  ? Colors.white54
                  : const Color(0xFF8A8F98),
              iconColorSelected: AppTeal.main,
              indicatorColor: AppTeal.main,
            ),

            skinToneConfig: SkinToneConfig(
              enabled: true,
              rememberSkinTone: true,
              indicatorColor: AppTeal.main,
              dialogBackgroundColor: surfaceColor,
            ),

            // زر البحث → شريط بحث (UI فقط، نفس منطق الحزمة)
            bottomActionBarConfig: BottomActionBarConfig(
              backgroundColor: surfaceColor,
              showBackspaceButton: false,
              showSearchViewButton: false,
              customBottomActionBar: (config, state, showSearchView) {
                return _EmojiPickerSearchBar(
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  onTap: showSearchView,
                );
              },
            ),

            searchViewConfig: SearchViewConfig(
              backgroundColor: surfaceColor,
              hintText: shellText(context, "ابحث عن إيموجي"),
            ),

          ),
        ),
      ),
    );
  }
}

class _EmojiPickerSearchBar extends StatelessWidget {
  const _EmojiPickerSearchBar({
    required this.isDark,
    required this.surfaceColor,
    required this.onTap,
  });

  final bool isDark;
  final Color surfaceColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : const Color(0xFF8A8F98);
    final fill = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFF0F1F3);

    return Material(
      color: surfaceColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            height: 40,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.search_rounded, size: 20, color: muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    shellText(context, "ابحث عن إيموجي"),
                    style: TextStyle(
                      color: muted,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatSearchBar extends StatelessWidget {
  const _ChatSearchBar({
    required this.controller,
    required this.isDark,
    required this.resultCount,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool isDark;
  final int? resultCount;
  final VoidCallback onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;

    final backgroundColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.78);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: 0.08);

    final iconColor = isDark
        ? Colors.white.withValues(alpha: 0.78)
        : Colors.black.withValues(alpha: 0.58);

    final hintColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : Colors.black.withValues(alpha: 0.48);

    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: 4,
        end: 8,
        top: 6,
        bottom: 6,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: 14,
            sigmaY: 14,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 44,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: borderColor,
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDark ? 0.18 : 0.08,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Directionality(
              textDirection: Directionality.of(context),
              child: Row(
                children: [
                  const SizedBox(width: 12),

                  Icon(
                    Icons.search_rounded,
                    size: 21,
                    color: iconColor,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      maxLines: 1,
                      textDirection: Directionality.of(context),
                      textAlign: TextAlign.right,
                      cursorColor: AppTeal.main,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                      onChanged: (_) => onChanged(),
                      decoration: InputDecoration(
                        hintText: shellText(context, "ابحث في المحادثة"),
                        hintStyle: TextStyle(
                          color: hintColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: resultCount != null && hasText
                        ? Container(
                      key: ValueKey(resultCount),
                      margin: const EdgeInsetsDirectional.only(
                        start: 6,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTeal.main.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$resultCount',
                        style: TextStyle(
                          color: AppTeal.main,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                        : const SizedBox(
                      key: ValueKey('empty-result'),
                    ),
                  ),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: hasText
                        ? IconButton(
                      key: const ValueKey('clear-button'),
                      tooltip: shellText(context, "مسح البحث"),
                      splashRadius: 19,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 38,
                        minHeight: 38,
                      ),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 19,
                        color: iconColor,
                      ),
                      onPressed: onClear,
                    )
                        : const SizedBox(
                      key: ValueKey('empty-clear'),
                      width: 10,
                    ),
                  ),

                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


const List<String> kQuickReactionEmojis = ['❤️', '😂', '😮', '😢', '🔥', '👍'];

// ==================== بابل الرسالة ====================

class _MessageBubbleTile extends StatefulWidget {
  const _MessageBubbleTile({
    required this.currentUid,
    required this.mediaScope,
    required this.mediaAuthorized,
    this.onVote,
    this.onRespondEvent,
    required this.message,
    required this.translationService,
    required this.autoTranslate,
    required this.translationTarget,
    required this.mine,
    required this.isLastOverall,
    required this.peerReadAt,
    this.peerDeliveredAt,
    required this.onTapImage,
    required this.onTapViewOnce,
    required this.onTapVideo,
    required this.onTapFile,
    required this.onLongPress,
    required this.onDoubleTap,
    this.accent,
    this.accentGradient,
  });

  final types.Message message;
  final ChatTranslationService translationService;
  final bool autoTranslate;
  final String translationTarget;
  final String currentUid;
  final String mediaScope;
  final bool Function() mediaAuthorized;
  final Future<void> Function(int)? onVote;
  final Future<void> Function(bool)? onRespondEvent;
  final bool mine;
  final bool isLastOverall;
  final DateTime? peerReadAt;
  final DateTime? peerDeliveredAt;
  final VoidCallback onTapViewOnce;
  final ValueChanged<String> onTapImage;
  final ValueChanged<String> onTapVideo;
  final ValueChanged<types.FileMessage> onTapFile;
  final void Function(BuildContext bubbleContext) onLongPress;
  final VoidCallback onDoubleTap;
  final Color? accent;
  final Gradient? accentGradient;

  @override
  State<_MessageBubbleTile> createState() => _MessageBubbleTileState();
}

class _MessageBubbleTileState extends State<_MessageBubbleTile>
    with SingleTickerProviderStateMixin {
  bool _showTime = false;
  bool _showHeart = false;

  void _handleDoubleTap() {
    widget.onDoubleTap();
    setState(() => _showHeart = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  String _timeLabel(int? ms) {
    if (ms == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? shellText(context, "م") : shellText(context, "ص");
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final message = widget.message;
    final mine = widget.mine;

    final quote = (message.metadata?['replyToText'] ?? '').toString();
    final quoteName = (message.metadata?['replyToName'] ?? '').toString();
    final edited = message.metadata?['edited'] == true;
    final reactions =
    Map<String, dynamic>.from(message.metadata?['reactions'] ?? {});
    final counts = <String, int>{};
    void addOne(String key) {
      final k = key.trim();
      if (k.isEmpty || k == '[]') return;
      counts[k] = (counts[k] ?? 0) + 1;
    }

    for (final value in reactions.values) {
      final emoji = chatReaction(value);
      if (emoji != null) addOne(emoji);
    }

    final bubbleColor = mine
        ? (widget.accent ?? AppTeal.main)
        : theme.colorScheme.surface.withValues(alpha: .96);
    final bubbleGradient = mine ? widget.accentGradient : null;
    final textColor =
    mine ? Colors.white : theme.colorScheme.onSurface;

    Widget content;
    if (message.metadata?['richData'] is Map) {
      content = ChatRichMessageCard(data: Map<String,dynamic>.from(message.metadata!['richData'] as Map), currentUid: widget.currentUid, style: TextStyle(color:textColor), onVote:widget.onVote, onRespondEvent:widget.onRespondEvent);
    } else if (message.metadata?['viewOnce'] == true) {
      content = Row(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.looks_one_outlined,color:textColor),const SizedBox(width:8),Text(mediaText(context,message.metadata?['opened']==true?'تم الفتح':'صورة لمرة واحدة',message.metadata?['opened']==true?'Opened':'View-once photo',message.metadata?['opened']==true?'Ouverte':'Photo à vue unique'),style:TextStyle(color:textColor))]);
    } else if (message is types.ImageMessage) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ChatPolicyImage(source: message.uri, scope: widget.mediaScope, authorized: widget.mediaAuthorized, width: 200, height: 240, onTap: () => widget.onTapImage(message.uri)),
      );
    } else if (message is types.VideoMessage) {
      content = ChatVideoThumbnail(url: message.uri,thumbnailUrl:message.metadata?['thumbnailUrl'] as String?, scope: widget.mediaScope, authorized: widget.mediaAuthorized);
    } else if (message is types.AudioMessage) {
      content = ChatAudioPlayer(
        scope: widget.mediaScope,
        url: message.uri,
        mine: mine,
        totalDuration: message.duration,
      );
    } else if (message is types.FileMessage) {
      content = Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.insert_drive_file_outlined, color: textColor),
        const SizedBox(width: 8),
        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(message.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: textColor)),
          Text('${(message.size / 1024).toStringAsFixed(0)} KB', style: TextStyle(color: textColor.withValues(alpha:.75), fontSize:12)),
        ])),
        const SizedBox(width: 6), Icon(Icons.download_rounded, color: textColor, size:20),
      ]);
    } else if (message is types.TextMessage) {
      content = ChatTranslatedText(
        service: widget.translationService, enabled: widget.autoTranslate, target: widget.translationTarget,
        text: message.text,
        style: TextStyle(color: textColor, fontSize: 15.5, height: 1.35,
          fontFamilyFallback: const ['NotoColorEmoji']),
      );
    } else {
      content = const SizedBox.shrink();
    }

    final isMedia =
        message is types.ImageMessage || message is types.VideoMessage;
    final caption=(message.metadata?['caption']??'').toString();
    if(isMedia && caption.isNotEmpty) content=Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[content,Padding(padding:const EdgeInsets.all(8),child:ChatTranslatedText(service:widget.translationService, enabled:widget.autoTranslate,target:widget.translationTarget,text:caption,style:TextStyle(color:theme.colorScheme.onSurface,fontFamilyFallback:const ['NotoColorEmoji'])))]);
    final hasReactions = counts.isNotEmpty;

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: min(420.0, MediaQuery.sizeOf(context).width * .80)),
      padding: isMedia
          ? const EdgeInsets.all(3)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMedia
            ? Colors.transparent
            : (bubbleGradient == null ? bubbleColor : null),
        gradient: isMedia ? null : bubbleGradient,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(22),
          topRight: const Radius.circular(22),
          bottomLeft: Radius.circular(mine ? 22 : 10),
          bottomRight: Radius.circular(mine ? 10 : 22),
        ),
        boxShadow: isMedia
            ? null
            : [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.08 : 0.025),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: content,
    );

    Widget withQuote = bubble;
    if (quote.isNotEmpty) {
      withQuote = Column(
        crossAxisAlignment:
        mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
            constraints: const BoxConstraints(maxWidth: 240),
            decoration: BoxDecoration(
              color: bubbleColor.withValues(alpha: isMedia ? 0.14 : 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: mine
                    ? BorderSide.none
                    : BorderSide(color: AppTeal.main, width: 2.5),
                right: mine
                    ? BorderSide(color: AppTeal.main, width: 2.5)
                    : BorderSide.none,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.reply_rounded,
                    size: 13, color: theme.hintColor.withValues(alpha: 0.7)),
                const SizedBox(width: 5),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (quoteName.isNotEmpty)
                        Text(
                          quoteName,
                          style: TextStyle(
                            color: AppTeal.main,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      Text(
                        quote,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                        TextStyle(fontSize: 12, color: theme.hintColor,
                            fontFamilyFallback: const ['NotoColorEmoji']),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bubble,
        ],
      );
    }

    // ===== شارة الإيموجي العائمة (Tapback) على حافة الفقاعة =====
    Widget bubbleWithReactions = withQuote;
    if (hasReactions) {
      bubbleWithReactions = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
        mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          withQuote,
          Transform.translate(
            offset: Offset(mine ? -6 : 6, -10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final e in counts.entries) ...[
                    Text(
                      e.key,
                      style: const TextStyle(
                        fontFamily: 'NotoColorEmoji',
                        fontSize: 16,
                        height: 1.1,
                      ),
                    ),
                    if (e.value > 1) ...[
                      const SizedBox(width: 3),
                      Text(
                        '${e.value}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                    if (e.key != counts.keys.last) const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }

    // ===== علامة القراءة (أيقونات بدل نص) =====
    Widget? statusRow;
    if ((widget.isLastOverall || message.metadata?['pending'] == true) && mine) {
      final read = widget.peerReadAt != null &&
          (message.createdAt ?? 0) <=
              widget.peerReadAt!.millisecondsSinceEpoch;
      statusRow = Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.metadata?['failed'] == true ? shellText(context, 'تعذر إرسال الرسالة')
                  : message.metadata?['pending'] == true ? shellText(context, 'جارٍ الإرسال')
                  : read ? shellText(context, "شوهدت") : shellText(context, "تم الإرسال"),
              style: TextStyle(fontSize: 10.5, color: theme.hintColor),
            ),
            const SizedBox(width: 3),
            Icon(
              message.metadata?['failed'] == true ? Icons.error_outline : message.metadata?['pending'] == true ? Icons.schedule : (read || (widget.peerDeliveredAt != null && (widget.message.createdAt ?? 0) <= widget.peerDeliveredAt!.millisecondsSinceEpoch)) ? Icons.done_all_rounded : Icons.done_rounded,
              size: 14,
              color: read ? AppTeal.main : theme.hintColor,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment:
      mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (edited)
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 6, right: 6),
            child: Text(
              shellText(context, "معدل"),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: theme.hintColor,
              ),
            ),
          ),
        Builder(
          builder: (bubbleCtx) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (message.metadata?['viewOnce'] == true) { widget.onTapViewOnce(); }
                else if (message is types.ImageMessage) {
                  widget.onTapImage(message.uri);
                } else if (message is types.VideoMessage) {
                  widget.onTapVideo(message.uri);
                } else if (message is types.FileMessage && message.metadata?['local'] != true) {
                  widget.onTapFile(message);
                } else {
                  setState(() => _showTime = !_showTime);
                }
              },
              onLongPress: () => widget.onLongPress(bubbleCtx),
              onDoubleTap: _handleDoubleTap,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  bubbleWithReactions,
                  if (_showHeart)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.5, end: 1.3),
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutBack,
                      builder: (context, scale, _) => Transform.scale(
                        scale: scale,
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.redAccent,
                          size: 54,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        if (edited)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              shellText(context, "تم التعديل"),
              style: TextStyle(
                fontSize: 10,
                color: theme.hintColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: _showTime
              ? Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              _timeLabel(message.createdAt),
              style: TextStyle(fontSize: 10.5, color: theme.hintColor),
            ),
          )
              : const SizedBox.shrink(),
        ),
        if (statusRow != null) statusRow,
      ],
    );
  }
}
// ==================== مؤشر الكتابة ====================

class _TypingBubble extends StatefulWidget {
  const _TypingBubble({required this.isDark});
  final bool isDark;

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> {
  int _dots = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (!mounted) return;
      setState(() => _dots = (_dots + 1) % 3);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF0F0F0),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final active = i <= _dots;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? AppTeal.main
                  : AppTeal.main.withValues(alpha: 0.25),
            ),
          );
        }),
      ),
    );
  }
}

// ==================== فيديو داخل البابل (thumbnail) ====================

// ==================== Composer ====================


enum VoiceRecordingState {
  idle,
  recording,
  paused,
  locked,
  canceling,
  sending,
}

class InstagramComposer extends StatefulWidget {
  const InstagramComposer({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onChanged,
    required this.onCancelReply,
    required this.sending,
    required this.hasText,
    required this.voice,
    required this.onSendVoice,
    this.replyTo,
    this.editing,
    this.onCancelEdit,
    this.peerName = '',
    this.onContentInserted,
    this.onPickImage,
    this.onPickVideo,
    this.onPickFile,
    this.onLocation,
    this.onContact,
    this.onPoll,
    this.onEvent,
    this.onOpenCamera,
    this.onInsertLink,
    this.onSendMedia,
    this.onBeforeStart,
    this.onStartFailed,
    // ── ignored (kept so your current call site compiles) ──
    this.onVoiceStart,
    this.onVoiceFinish,
    this.onVoiceCancel,
    this.recording = false,
    this.recordDuration = '00:00',
    this.voicePaused = false,
    this.onVoicePause,
    this.onVoiceResume,
    this.previewPlaying = false,
    this.onPreviewPlay,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final ValueChanged<String> onChanged;
  final VoidCallback onCancelReply;
  final bool sending;
  final bool hasText;
  final VoiceSessionController voice;
  final Future<void> Function(File file, Duration duration) onSendVoice;
  final types.Message? replyTo;
  final types.Message? editing;
  final VoidCallback? onCancelEdit;
  final String peerName;
  final Future<void> Function(KeyboardInsertedContent content)? onContentInserted;
  final VoidCallback? onPickImage;
  final VoidCallback? onPickVideo;
  final VoidCallback? onPickFile;
  final VoidCallback? onLocation;
  final VoidCallback? onContact, onPoll, onEvent;
  final VoidCallback? onOpenCamera;
  final VoidCallback? onInsertLink;
  final Future<void> Function(List<File> files, String caption)? onSendMedia;
  final Future<bool> Function()? onBeforeStart;
  final VoidCallback? onStartFailed;

  final VoidCallback? onVoiceStart;
  final VoidCallback? onVoiceFinish;
  final VoidCallback? onVoiceCancel;
  final bool recording;
  final String recordDuration;
  final bool voicePaused;
  final VoidCallback? onVoicePause;
  final VoidCallback? onVoiceResume;
  final bool previewPlaying;
  final VoidCallback? onPreviewPlay;

  @override
  State<InstagramComposer> createState() => _InstagramComposerState();
}

class _InstagramComposerState extends State<InstagramComposer> {
  bool _emojiPickerOpen = false;

  Future<void> _showEmojiPicker() async {
    if (_emojiPickerOpen) return;
    _emojiPickerOpen = true;
    try {
      final emoji = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _AllEmojiSheet(),
      );
      if (!mounted || emoji == null || emoji.isEmpty) return;
      final next = insertChatComposerText(widget.controller.value, emoji);
      widget.controller.value = next;
      widget.onChanged(next.text);
    } finally {
      _emojiPickerOpen = false;
    }
  }

  void _showAttachmentSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.42,
          maxChildSize: 0.96,
          builder: (context, scrollController) {
            return _WhatsAppAttachTray(
              isDark: isDark,
              scrollController: scrollController,
              onCamera: () {
                Navigator.pop(ctx);
                widget.onOpenCamera?.call();
              },
              onDocument: () {
                Navigator.pop(ctx);
                widget.onPickFile?.call();
              },
              onLocation: () {
                Navigator.pop(ctx);
                widget.onLocation?.call();
              },
              onContact: () {
                Navigator.pop(ctx);
                widget.onContact?.call();
              },
              onPoll: () {
                Navigator.pop(ctx);
                widget.onPoll?.call();
              },
              onEvent: () {
                Navigator.pop(ctx);
                widget.onEvent?.call();
              },
              onAiImages: () {},
              onSend: (files, caption) async {
                Navigator.pop(ctx);
                await widget.onSendMedia?.call(files, caption);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).colorScheme.surface.withValues(alpha: isDark ? .80 : .76);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Material(
      color: bg,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.editing is types.TextMessage)
              ChatEditingBanner(text: (widget.editing as types.TextMessage).text, onCancel: widget.onCancelEdit)
            else if (widget.replyTo != null)
              _ReplyPreview(
                replyTo: widget.replyTo!,
                peerName: widget.peerName,
                onCancel: widget.onCancelReply,
              ),
            PulseVoiceHost(
              session: widget.voice,
              hasText: widget.hasText,
              sending: widget.sending,
              onSendText: () {
                final t = widget.controller.text.trim();
                if (t.isNotEmpty) widget.onSend(t);
              },
              onSendVoice: widget.onSendVoice,
              onBeforeStart: widget.onBeforeStart,
              onStartFailed: widget.onStartFailed,
              inputBar: _textField(context),
            ),
          ],
        ),
      ),
    )));
  }

  Widget _textField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final field = Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .72);
    final muted = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : const Color(0xFF8E8E93);

    return TextField(
      controller: widget.controller,
      minLines: 1,
      maxLines: 5,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      textCapitalization: TextCapitalization.sentences,
      onChanged: widget.onChanged,
      onSubmitted: (v) {
        final t = v.trim();
        if (t.isNotEmpty && !widget.sending) widget.onSend(t);
      },
      style: TextStyle(
        fontFamilyFallback: const ['NotoColorEmoji'],
        fontSize: 16,
        height: 1.25,
        color: isDark ? Colors.white : Colors.black87,
      ),
      contentInsertionConfiguration: ContentInsertionConfiguration(
        allowedMimeTypes: const [
          'image/gif',
          'image/png',
          'image/jpeg',
          'image/webp',
        ],
        onContentInserted: (c) async {
          await widget.onContentInserted?.call(c);
        },
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: field,
        isDense: true,
        hintText: shellText(context, "Message..."),
        hintStyle: TextStyle(color: muted, fontSize: 16),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        prefixIcon: IconButton(
          tooltip: shellText(context, "ابحث عن إيموجي"),
          onPressed: _showEmojiPicker,
          icon: Icon(Icons.emoji_emotions_outlined, size: 22, color: muted),
        ),
        prefixIconConstraints:
        const BoxConstraints(minWidth: 40, minHeight: 40),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 40),
              onPressed: widget.sending ? null : _showAttachmentSheet,
              icon: Icon(Icons.attach_file_rounded, size: 22, color: muted),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 40),
              onPressed: widget.sending ? null : widget.onOpenCamera,
              icon: Icon(Icons.camera_alt_outlined, size: 22, color: muted),
            ),
            const SizedBox(width: 2),
          ],
        ),
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 40),
      ),
    );
  }
}


const Color kVoiceAccent = Color(0xFF0F766E);
const Color kVoiceDanger = Color(0xFFFF3B30);


enum _PendingAfterStart { none, finish, cancel }

/// Single owner of the microphone session.
///
/// Pause/resume call the recorder's native pause/resume so "متابعة التسجيل"
/// continues the *same* take. Amplitude is a real dBFS stream, not a sine.
class ChatVoiceController extends ChangeNotifier {
  ChatVoiceController({
    required this.onSend,
    required this.onError,
    this.checkBlocked,
    this.minDuration = const Duration(milliseconds: 400),
    this.maxDuration = const Duration(minutes: 2),
    this.barCount = 36,
  });

  final Future<void> Function(File file, Duration duration) onSend;
  final void Function(String message) onError;
  final Future<String?> Function()? checkBlocked;
  final Duration minDuration;
  final Duration maxDuration;
  final int barCount;

  final AudioRecorder recorder = AudioRecorder();

  VoicePhase phase = VoicePhase.idle;
  List<double> bars = const <double>[];
  double liveLevel = 0;
  int barsGen = 0;

  _PendingAfterStart _pending = _PendingAfterStart.none;
  StreamSubscription<Amplitude>? _ampSub;
  Timer? _clock;
  DateTime? _runStartedAt;
  Duration _frozen = Duration.zero;
  String? _path;
  bool _disposed = false;

  bool get isActive => phase != VoicePhase.idle;
  bool get isLive => phase == VoicePhase.recording;
  bool get isPaused => phase == VoicePhase.paused;

  Duration get elapsed {
    if (phase == VoicePhase.recording && _runStartedAt != null) {
      return _frozen + DateTime.now().difference(_runStartedAt!);
    }
    return _frozen;
  }

  Future<void> start() async {
    if (phase == VoicePhase.recording || phase == VoicePhase.starting) return;
    if (phase == VoicePhase.paused) {
      await resume();
      return;
    }

    phase = VoicePhase.starting;
    _pending = _PendingAfterStart.none;
    _frozen = Duration.zero;
    liveLevel = 0;
    bars = List<double>.filled(barCount, 0.1);
    barsGen = 0;
    _emit();

    try {
      final blocked = await checkBlocked?.call();
      if (blocked != null) {
        onError(blocked);
        _idle();
        return;
      }

      if (!await recorder.hasPermission()) {
        onError('يلزم السماح بالميكروفون');
        _idle();
        return;
      }

      if (_pending == _PendingAfterStart.cancel) {
        _idle();
        return;
      }

      final dir = await getTemporaryDirectory();
      _path =
      '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: _path!,
      );

      if (_disposed) {
        try {
          await recorder.stop();
        } catch (_) {}
        return;
      }

      _runStartedAt = DateTime.now();
      phase = VoicePhase.recording;
      _listenAmplitude();
      _startClock();
      _emit();

      if (_pending == _PendingAfterStart.cancel) {
        _pending = _PendingAfterStart.none;
        await cancel();
        return;
      }
      if (_pending == _PendingAfterStart.finish) {
        _pending = _PendingAfterStart.none;
        await finish();
      }
    } catch (e) {
      onError('تعذر بدء التسجيل');
      debugPrint('voice start failed: $e');
      _idle();
    }
  }

  Future<void> pause() async {
    if (phase != VoicePhase.recording) return;
    try {
      await recorder.pause();
    } catch (e) {
      debugPrint('voice pause failed: $e');
      onError('تعذر الإيقاف المؤقت');
      return;
    }
    if (_runStartedAt != null) {
      _frozen += DateTime.now().difference(_runStartedAt!);
      _runStartedAt = null;
    }
    await _ampSub?.cancel();
    _ampSub = null;
    _clock?.cancel();
    _clock = null;
    phase = VoicePhase.paused;
    _emit();
  }

  Future<void> resume() async {
    if (phase != VoicePhase.paused) return;
    try {
      await recorder.resume();
    } catch (e) {
      debugPrint('voice resume failed: $e');
      onError('تعذر متابعة التسجيل');
      return;
    }
    _runStartedAt = DateTime.now();
    phase = VoicePhase.recording;
    _listenAmplitude();
    _startClock();
    _emit();
  }

  Future<void> finish() async {
    if (phase == VoicePhase.starting) {
      _pending = _PendingAfterStart.finish;
      return;
    }
    if (phase != VoicePhase.recording && phase != VoicePhase.paused) return;

    final duration = elapsed;
    _clock?.cancel();
    _clock = null;
    await _ampSub?.cancel();
    _ampSub = null;

    String? path;
    try {
      path = await recorder.stop();
    } catch (_) {}
    path ??= _path;

    phase = VoicePhase.sending;
    _emit();

    if (path == null || duration < minDuration) {
      await _deletePath(path);
      _idle();
      return;
    }

    final file = File(path);
    if (!await file.exists()) {
      _idle();
      return;
    }
    final size = await file.length();
    if (size < 80) {
      await _deletePath(path);
      _idle();
      return;
    }

    try {
      await onSend(file, duration);
    } catch (e) {
      debugPrint('voice send failed: $e');
      onError('تعذر إرسال التسجيل');
    } finally {
      _idle();
    }
  }

  Future<void> cancel() async {
    if (phase == VoicePhase.starting) {
      _pending = _PendingAfterStart.cancel;
      return;
    }
    if (phase == VoicePhase.idle) return;

    _clock?.cancel();
    _clock = null;
    await _ampSub?.cancel();
    _ampSub = null;
    try {
      await recorder.stop();
    } catch (_) {}
    await _deletePath(_path);
    _idle();
  }

  void _listenAmplitude() {
    _ampSub?.cancel();
    _ampSub = recorder
        .onAmplitudeChanged(const Duration(milliseconds: 50))
        .listen((Amplitude amp) {
      if (phase != VoicePhase.recording) return;
      final next = _normalizeDb(amp.current);
      liveLevel += (next - liveLevel) * (next > liveLevel ? 0.55 : 0.22);
      _pushBar(0.08 + liveLevel * 0.92);
      _emit();
    }, onError: (Object e) {
      debugPrint('amplitude stream: $e');
    });
  }

  void _pushBar(double value) {
    if (bars.isEmpty) {
      bars = List<double>.filled(barCount, 0.1);
    }
    final next = List<double>.from(bars);
    for (var i = 0; i < next.length - 1; i++) {
      next[i] = next[i + 1];
    }
    next[next.length - 1] = value.clamp(0.08, 1.0);
    bars = next;
    barsGen++;
  }

  static double _normalizeDb(double db) {
    // Speech sits roughly -50..-8 dBFS. Silence is far below.
    const minDb = -52.0;
    const maxDb = -8.0;
    if (db.isNaN || db.isInfinite) return 0;
    final t = ((db - minDb) / (maxDb - minDb)).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(t);
  }

  void _startClock() {
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (phase != VoicePhase.recording) return;
      if (elapsed >= maxDuration) {
        unawaited(finish());
        return;
      }
      _emit();
    });
  }

  void _idle() {
    _pending = _PendingAfterStart.none;
    _runStartedAt = null;
    _frozen = Duration.zero;
    _path = null;
    liveLevel = 0;
    phase = VoicePhase.idle;
    _emit();
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _deletePath(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    _clock?.cancel();
    unawaited(_ampSub?.cancel());
    unawaited(() async {
      try {
        if (await recorder.isRecording() || await recorder.isPaused()) {
          await recorder.stop();
        }
      } catch (_) {}
      await _deletePath(_path);
      await recorder.dispose();
    }());
    super.dispose();
  }
}

class AmplitudeWaveform extends StatelessWidget {
  const AmplitudeWaveform({
    super.key,
    required this.bars,
    required this.generation,
    required this.color,
    this.frozen = false,
  });

  final List<double> bars;
  final int generation;
  final Color color;
  final bool frozen;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AmpPainter(
        bars: bars,
        generation: generation,
        color: color,
        frozen: frozen,
        textDirection: Directionality.of(context),
      ),
      size: Size.infinite,
    );
  }
}

class _AmpPainter extends CustomPainter {
  _AmpPainter({
    required this.bars,
    required this.generation,
    required this.color,
    required this.frozen,
    required this.textDirection,
  });

  final List<double> bars;
  final int generation;
  final Color color;
  final bool frozen;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || bars.isEmpty) return;
    const gap = 2.2;
    final n = bars.length;
    final barW = (size.width - gap * (n - 1)) / n;
    final mid = size.height / 2;
    final maxH = size.height * 0.94;
    final paint = Paint()..isAntiAlias = true;
    final rtl = textDirection == TextDirection.rtl;

    for (var i = 0; i < n; i++) {
      final amp = bars[i].clamp(0.08, 1.0);
      final h = (amp * maxH).clamp(3.0, maxH);
      final drawI = rtl ? n - 1 - i : i;
      final x = drawI * (barW + gap);
      final w = barW.clamp(1.6, 3.6);
      paint.color = color.withValues(alpha: frozen ? 0.45 : 1);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x + barW / 2, mid),
            width: w,
            height: h,
          ),
          const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AmpPainter old) {
    return old.generation != generation ||
        old.color != color ||
        old.frozen != frozen ||
        old.textDirection != textDirection;
  }
}

class LockFollowData {
  const LockFollowData({
    required this.finger,
    required this.progress,
    required this.canceling,
  });

  final Offset finger;
  final double progress;
  final bool canceling;
}

/// Full-screen overlay: lock bubble glued to the fingertip while swiping up.
class VoiceLockFollowLayer extends StatelessWidget {
  const VoiceLockFollowLayer({super.key, required this.data});

  final ValueListenable<LockFollowData?> data;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LockFollowData?>(
      valueListenable: data,
      builder: (context, vis, _) {
        if (vis == null) return const SizedBox.shrink();
        final ready = vis.progress >= 0.92;
        final scale = 0.82 + vis.progress * 0.32;
        final lift = 58.0 + vis.progress * 18.0;
        final bg = vis.canceling
            ? kVoiceDanger
            : ready
            ? kVoiceAccent
            : Colors.white;
        final fg = vis.canceling || ready
            ? Colors.white
            : const Color(0xFF1C1C1E);
        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                left: vis.finger.dx - 28,
                top: vis.finger.dy - lift - 56,
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: bg,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                            if (ready)
                              BoxShadow(
                                color: kVoiceAccent.withValues(alpha: 0.35),
                                spreadRadius: 6,
                                blurRadius: 0,
                              ),
                          ],
                        ),
                        child: Icon(
                          vis.canceling
                              ? Icons.delete_outline_rounded
                              : Icons.lock_rounded,
                          color: fg,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        vis.canceling
                            ? shellText(context, "إلغاء")
                            : ready
                            ? shellText(context, "أفلت للقفل")
                            : shellText(context, "لأعلى للقفل"),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: vis.canceling ? kVoiceDanger : kVoiceAccent,
                          decoration: TextDecoration.none,
                          shadows: const [
                            Shadow(color: Colors.white70, blurRadius: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class VoiceRecordingDock extends StatelessWidget {
  const VoiceRecordingDock({
    super.key,
    required this.voice,
    required this.locked,
    required this.holding,
    required this.canceling,
    required this.onPause,
    required this.onResume,
    required this.onDelete,
    required this.onSend,
  });

  final ChatVoiceController voice;
  final bool locked;
  final bool holding;
  final bool canceling;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onDelete;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = canceling ? kVoiceDanger : kVoiceAccent;
    final surface = isDark ? const Color(0xFF1D1D24) : Colors.white;
    final paused = voice.isPaused;
    final live = voice.isLive;
    final holdOnly = holding && !locked;
    final sending = voice.phase == VoicePhase.sending;
    final duration = _fmt(voice.elapsed);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: canceling
                  ? kVoiceDanger.withValues(alpha: 0.45)
                  : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04)),
            ),
          ),
          child: Row(
            children: [
              _RoundIcon(
                background: accent,
                icon: paused ? Icons.mic_rounded : Icons.pause_rounded,
                onTap: holdOnly
                    ? null
                    : (paused ? onResume : onPause),
                label: paused ? shellText(context, "متابعة التسجيل") : shellText(context, "إيقاف مؤقت"),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AmplitudeWaveform(
                  bars: voice.bars,
                  generation: voice.barsGen,
                  color: accent,
                  frozen: paused || sending,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                constraints: const BoxConstraints(minWidth: 58),
                padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (live)
                      _LiveDot(color: accent),
                    if (live) const SizedBox(width: 6),
                    Text(
                      duration,
                      style: TextStyle(
                        color: accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 52,
          child: Row(
            children: [
              _PlainIcon(
                icon: Icons.delete_outline_rounded,
                color: canceling
                    ? kVoiceDanger
                    : (isDark ? Colors.white54 : Colors.black45),
                onTap: holdOnly ? null : onDelete,
                label: shellText(context, "حذف التسجيل"),
              ),
              const Spacer(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: locked
                      ? kVoiceAccent.withValues(alpha: 0.12)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  locked ? Icons.lock_rounded : Icons.lock_outline_rounded,
                  color: locked
                      ? kVoiceAccent
                      : (isDark ? Colors.white54 : Colors.black45),
                  size: 21,
                ),
              ),
              const Spacer(),
              Opacity(
                opacity: holdOnly || sending ? 0.45 : 1,
                child: Material(
                  color: kVoiceAccent,
                  shape: const CircleBorder(),
                  elevation: 3,
                  shadowColor: kVoiceAccent.withValues(alpha: 0.35),
                  child: InkWell(
                    onTap: holdOnly || sending ? null : onSend,
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          holdOnly
              ? shellText(context, "أفلت للإرسال · يسار للإلغاء · أعلى للقفل")
              : paused
              ? shellText(context, "متوقف — اضغط المايك لمتابعة نفس التسجيل")
              : locked
              ? shellText(context, "مقفل — يمكنك رفع إصبعك")
              : '',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black45,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot({required this.color});
  final Color color;

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.25).animate(_c),
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.background,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final Color background;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}

class _PlainIcon extends StatelessWidget {
  const _PlainIcon({
    required this.icon,
    required this.color,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: color, size: 25),
      ),
    );
  }
}

String formatVoiceClock(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}


class _RecordingMainCard extends StatefulWidget {
  const _RecordingMainCard({
    required this.isDark,
    required this.isPreview,
    required this.isCancelling,
    required this.recordingColor,
    required this.surfaceColor,
    required this.duration,
    required this.previewPlaying,
    required this.onPauseResume,
    required this.onPreviewPlay,
  });

  final bool isDark;
  final bool isPreview;
  final bool isCancelling;
  final Color recordingColor;
  final Color surfaceColor;
  final String duration;
  final bool previewPlaying;
  final VoidCallback onPauseResume;
  final VoidCallback onPreviewPlay;

  @override
  State<_RecordingMainCard> createState() => _RecordingMainCardState();
}

class _RecordingMainCardState extends State<_RecordingMainCard>
    with TickerProviderStateMixin {
  late final AnimationController _revealController;
  late final AnimationController _motionController;

  late final Animation<double> _revealAnimation;
  late final Animation<double> _motionAnimation;

  @override
  void initState() {
    super.initState();

    // إظهار الخطوط بالتتابع خلال 8 ثوانٍ، دون تكرار.
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..forward();

    // تحريك الموجة باستمرار.
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.linear,
    );

    _motionAnimation = CurvedAnimation(
      parent: _motionController,
      curve: Curves.linear,
    );
  }

  @override
  void dispose() {
    _revealController.dispose();
    _motionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: widget.surfaceColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              widget.isDark ? 0.28 : 0.08,
            ),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Row(
        children: [
          _RoundActionButton(
            backgroundColor: widget.recordingColor,
            icon: widget.isPreview
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
            iconColor: Colors.white,
            onTap: widget.onPauseResume,
            semanticLabel: widget.isPreview
                ? shellText(context, "استئناف التسجيل")
                : shellText(context, "إيقاف مؤقت"),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: widget.isPreview
                ? _PreviewContent(
              isDark: widget.isDark,
              isPlaying: widget.previewPlaying,
              onTap: widget.onPreviewPlay,
            )
                : _LiveRecordingContent(
              color: widget.recordingColor,
              revealAnimation: _revealAnimation,
              motionAnimation: _motionAnimation,
            ),
          ),

          const SizedBox(width: 10),

          _DurationBadge(
            duration: widget.duration,
            color: widget.recordingColor,
            live: !widget.isPreview,
            isDark: widget.isDark,
          ),
        ],
      ),
    );
  }
}



class _LiveRecordingContent extends StatelessWidget {
  const _LiveRecordingContent({
    required this.color,
    required this.revealAnimation,
    required this.motionAnimation,
  });

  final Color color;
  final Animation<double> revealAnimation;
  final Animation<double> motionAnimation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          revealAnimation,
          motionAnimation,
        ]),
        builder: (context, child) {
          return CustomPaint(
            painter: _VoiceWavePainter(
              revealProgress: revealAnimation.value,
              motionProgress: motionAnimation.value,
              color: color,
              active: true,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}



class _PreviewContent extends StatelessWidget {
  const _PreviewContent({
    required this.isDark,
    required this.isPlaying,
    required this.onTap,
  });

  final bool isDark;
  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final secondaryColor = isDark ? Colors.white38 : Colors.black45;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPlaying
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_fill_rounded,
                color: textColor,
                size: 28,
              ),
              const SizedBox(width: 7),
              Text(
                isPlaying ? shellText(context, "جاري التشغيل") : shellText(context, "تشغيل التسجيل"),
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    required this.semanticLabel,
  });

  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: backgroundColor,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(
              icon,
              color: iconColor,
              size: 25,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(
              icon,
              color: color,
              size: 25,
            ),
          ),
        ),
      ),
    );
  }
}


class _VoiceWavePainter extends CustomPainter {
  const _VoiceWavePainter({
    required this.revealProgress,
    required this.motionProgress,
    required this.color,
    required this.active,
  });

  final double revealProgress;
  final double motionProgress;
  final Color color;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    const barCount = 38;
    const gap = 2.4;

    final totalGap = gap * (barCount - 1);
    final barWidth = (size.width - totalGap) / barCount;

    final centerY = size.height / 2;
    final maxHeight = size.height * 0.90;

    // يزداد مرة واحدة فقط من 0 إلى عدد الخطوط الكامل.
    final visibleBars = active
        ? (revealProgress * barCount).ceil().clamp(0, barCount)
        : barCount;

    for (var i = 0; i < barCount; i++) {
      // الخطوط غير الظاهرة لا يتم رسمها.
      if (active && i >= visibleBars) {
        continue;
      }

      final t = i / (barCount - 1);

      // motionProgress مسؤول عن الحركة المستمرة فقط.
      final wave1 = math.sin(
        (t * 8.0 + motionProgress * 2.0) * math.pi,
      );

      final wave2 = math.sin(
        (t * 17.0 - motionProgress * 2.8) * math.pi,
      );

      final wave3 = math.sin(
        (t * 4.0 + motionProgress * 1.5) * math.pi,
      );

      var amplitude = 0.16 +
          ((wave1 + 1) / 2) * 0.35 +
          ((wave2 + 1) / 2) * 0.25 +
          ((wave3 + 1) / 2) * 0.20;

      if (!active) {
        amplitude *= 0.45;
      }

      final edgeFactor = math.sin(t * math.pi) * 0.35 + 0.65;

      final height = (amplitude * maxHeight * edgeFactor)
          .clamp(3.0, maxHeight)
          .toDouble();

      final x = i * (barWidth + gap);

      final rect = Rect.fromCenter(
        center: Offset(
          x + barWidth / 2,
          centerY,
        ),
        width: barWidth.clamp(1.5, 3.5).toDouble(),
        height: height,
      );

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect,
          const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VoiceWavePainter oldDelegate) {
    return oldDelegate.revealProgress != revealProgress ||
        oldDelegate.motionProgress != motionProgress ||
        oldDelegate.color != color ||
        oldDelegate.active != active;
  }
}


class _ReplyPreview extends StatelessWidget {
  const _ReplyPreview({
    required this.replyTo,
    required this.peerName,
    required this.onCancel,
  });

  final types.Message replyTo;
  final String peerName;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = replyTo is types.TextMessage
        ? (replyTo as types.TextMessage).text
        : shellText(context, "وسائط");

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.25),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF0095F6),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shellFormat(context, "Replying to {0}", [peerName]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0095F6),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text.isEmpty ? shellText(context, "Media") : text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.hintColor, fontSize: 13,
                      fontFamilyFallback: const ['NotoColorEmoji']),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}



/// ورقة الوسائط بأسلوب واتساب (الصورة 1):
/// مقبض + بحث + تفاعلاتك + حديثة + شبكة صور + تسمية + إرسال
class _WhatsAppMediaSheet extends StatefulWidget {
  const _WhatsAppMediaSheet({
    required this.isDark,
    required this.onPickImage,
    required this.onPickVideo,
    required this.onPickFile,
    required this.onInsertLink,
    required this.onOpenCamera,
    required this.onReaction,
  });

  final bool isDark;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;
  final VoidCallback onPickFile;
  final VoidCallback onInsertLink;
  final VoidCallback onOpenCamera;
  final ValueChanged<String> onReaction;

  @override
  State<_WhatsAppMediaSheet> createState() => _WhatsAppMediaSheetState();
}

class _WhatsAppMediaSheetState extends State<_WhatsAppMediaSheet> {
  final _searchCtrl = TextEditingController();
  final _captionCtrl = TextEditingController();

  static const _reactions = kQuickReactionEmojis;
  static const _recentEmojis = [
    '😀', '😅', '😮', '😐', '🙌', '🧑‍💻',
    '😟', '😢', '😲', '🤩', '💔', '😂',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF7F7F8);
    final surface = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final muted = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : const Color(0xFF8E8E93);
    final primary = isDark ? Colors.white : const Color(0xFF111111);
    final accent = const Color(0xFF25D366); // أخضر واتساب

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenH = MediaQuery.sizeOf(context).height;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: screenH * 0.72,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // مقبض السحب
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: muted.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // شريط البحث
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(Icons.search_rounded, size: 20, color: muted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          style: TextStyle(color: primary, fontSize: 15),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: shellText(context, "Search"),
                            hintStyle: TextStyle(color: muted, fontSize: 15),
                            contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      if (_searchCtrl.text.isNotEmpty)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                          icon: Icon(Icons.close_rounded,
                              size: 18, color: muted),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Your reactions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      shellText(context, "Your reactions"),
                      style: TextStyle(
                        color: primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      shellText(context, "Customize"),
                      style: TextStyle(
                        color: const Color(0xFF53BDEB),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: _reactions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final e = _reactions[i];
                    return GestureDetector(
                      onTap: () => widget.onReaction(e),
                      child: Text(e, style: const TextStyle(fontSize: 30)),
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              // Recent emojis
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    shellText(context, "Recent"),
                    style: TextStyle(
                      color: primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    for (final e in _recentEmojis)
                      GestureDetector(
                        onTap: () => widget.onReaction(e),
                        child: Text(e, style: const TextStyle(fontSize: 28)),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              Text(
                shellText(context, "Swipe up for filters"),
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 12),

              // شبكة الصور الأخيرة + اختصارات الوسائط
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 3,
                    crossAxisSpacing: 3,
                  ),
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _MediaGridTile(
                        onTap: widget.onOpenCamera,
                        child: Container(
                          color: isDark
                              ? const Color(0xFF3A3A3C)
                              : const Color(0xFFE5E5EA),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_rounded,
                                  color: primary, size: 28),
                              const SizedBox(height: 6),
                              Text(shellText(context, "Camera"),
                                  style: TextStyle(
                                      color: muted, fontSize: 11)),
                            ],
                          ),
                        ),
                      );
                    }
                    if (index == 1) {
                      return _MediaGridTile(
                        onTap: widget.onPickImage,
                        child: Container(
                          color: isDark
                              ? const Color(0xFF3A3A3C)
                              : const Color(0xFFE5E5EA),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_library_rounded,
                                  color: primary, size: 28),
                              const SizedBox(height: 6),
                              Text(shellText(context, "Gallery"),
                                  style: TextStyle(
                                      color: muted, fontSize: 11)),
                            ],
                          ),
                        ),
                      );
                    }
                    final colors = [
                      const Color(0xFF2D5A4A),
                      const Color(0xFF3D4A6B),
                      const Color(0xFF5A3D4A),
                      const Color(0xFF4A5A2D),
                      const Color(0xFF2D3D5A),
                      const Color(0xFF5A4A2D),
                      const Color(0xFF3D5A4A),
                    ];
                    return _MediaGridTile(
                      onTap: widget.onPickImage,
                      child: Container(
                        color: colors[(index - 2) % colors.length],
                        child: Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: Colors.white.withValues(alpha: 0.35),
                            size: 32,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // شريط التسمية + إرسال
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                decoration: BoxDecoration(
                  color: bg,
                  border: Border(
                    top: BorderSide(
                      color: muted.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.image_outlined, size: 20, color: muted),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _captionCtrl,
                                style: TextStyle(color: primary, fontSize: 15),
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: shellText(context, "Add a caption..."),
                                  hintStyle:
                                  TextStyle(color: muted, fontSize: 15),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Material(
                      color: accent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: widget.onPickImage,
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(Icons.send_rounded,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaGridTile extends StatelessWidget {
  const _MediaGridTile({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: child,
        ),
      ),
    );
  }
}
class _WhatsAppAttachTray extends StatefulWidget {
  const _WhatsAppAttachTray({
    required this.isDark,
    required this.scrollController,
    required this.onCamera,
    required this.onDocument,
    required this.onLocation,
    required this.onContact,
    required this.onPoll,
    required this.onEvent,
    required this.onAiImages,
    required this.onSend,
  });

  final bool isDark;
  final ScrollController scrollController;
  final VoidCallback onCamera;
  final VoidCallback onDocument;
  final VoidCallback onLocation;
  final VoidCallback onContact;
  final VoidCallback onPoll;
  final VoidCallback onEvent;
  final VoidCallback onAiImages;
  final Future<void> Function(List<File> files, String caption) onSend;

  @override
  State<_WhatsAppAttachTray> createState() => _WhatsAppAttachTrayState();
}

class _WhatsAppAttachTrayState extends State<_WhatsAppAttachTray> {
  bool _pickingMedia = false;

  bool _isVideo(File file) {
    final path = file.path.toLowerCase();
    return path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.m4v') ||
        path.endsWith('.3gp') ||
        path.endsWith('.webm') ||
        path.endsWith('.mkv');
  }

  Future<void> _pickGallery() async {
    if (_pickingMedia) return;
    setState(() => _pickingMedia = true);

    try {
      final picked = await showChatMediaGallery(context);
      if (picked == null || picked.isEmpty || !mounted) return;

      final files = picked;
      await widget.onSend(files, '');
    } catch (e, st) {
      debugPrint('attachment photo picker failed: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(shellText(context, "تعذر فتح أداة اختيار الصور والفيديو"))),
      );
    } finally {
      if (mounted) setState(() => _pickingMedia = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final colors = Theme.of(context).colorScheme;
    final sheet = colors.surface;
    final label = colors.onSurfaceVariant;
    final handle = colors.outlineVariant;

    final actions = <_AttachAction>[
      _AttachAction(
        shellText(context, "Gallery"),
        Icons.photo_outlined,
        const Color(0xFF3478F6),
        () => unawaited(_pickGallery()),
      ),
      _AttachAction(
        shellText(context, "Camera"),
        Icons.photo_camera_rounded,
        const Color(0xFF34C759),
        widget.onCamera,
      ),
      _AttachAction(
        shellText(context, "Document"),
        Icons.insert_drive_file_rounded,
        const Color(0xFFAF52DE),
        widget.onDocument,
      ),
      _AttachAction(
        shellText(context, "Location"),
        Icons.location_on_rounded,
        const Color(0xFF34C759),
        widget.onLocation,
      ),
      _AttachAction(
        shellText(context, "Contact"),
        Icons.person_outline_rounded,
        const Color(0xFF0A84FF),
        widget.onContact,
      ),
      _AttachAction(
        shellText(context, "Poll"),
        Icons.poll_rounded,
        const Color(0xFFFF9F0A),
        widget.onPoll,
      ),
      _AttachAction(
        shellText(context, "Event"),
        Icons.event_outlined,
        const Color(0xFFFF375F),
        widget.onEvent,
      ),
    ];

    return Material(
      color: sheet,
      elevation: 12,
      shadowColor: Colors.black26,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          ChatMediaGallery(
            controller: widget.scrollController,
            onCamera: widget.onCamera,
            onSelected: (files) => widget.onSend(files, ''),
            header: Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 8), child: Column(children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: handle,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                shellText(context, "إرفاق"),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: actions.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 8,
                  mainAxisExtent: 86,
                ),
                itemBuilder: (_, i) {
                  final action = actions[i];
                  final accent = Color.lerp(action.color, isDark ? Colors.white : Colors.black, isDark ? .3 : .2)!;
                  return GestureDetector(
                    onTap: _pickingMedia
                        ? null
                        : action.onTap,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Color.alphaBlend(accent.withValues(alpha: isDark ? .16 : .09), colors.surfaceContainerLow),
                            borderRadius: BorderRadius.circular(23),
                            border: Border.all(
                              color: colors.outlineVariant.withValues(alpha: .6),
                            ),
                          ),
                          child: Icon(action.icon, color: accent, size: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          shellText(context, action.label),
                          style: TextStyle(
                            color: label,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ])),
          ),
          if (_pickingMedia)
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _AttachAction {
  const _AttachAction(this.label, this.icon, this.color, this.onTap);
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}
class _ModernMessageActionsSheet extends StatefulWidget {
  const _ModernMessageActionsSheet({
    required this.preview,
    required this.isMine,
    required this.starred,
    required this.isText,
  });

  final String preview;
  final bool isMine;
  final bool starred;
  final bool isText;

  @override
  State<_ModernMessageActionsSheet> createState() =>
      _ModernMessageActionsSheetState();
}

class _ModernMessageActionsSheetState extends State<_ModernMessageActionsSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  static const _reactions = kQuickReactionEmojis;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close([String? value]) async {
    await _controller.reverse();
    if (mounted) Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final actions = <_MsgAction>[
      _MsgAction('reply', shellText(context, "رد"), Icons.reply_rounded),
      if (widget.isText) _MsgAction('copy', shellText(context, "نسخ"), Icons.content_copy_rounded),
      if (widget.isText)
        _MsgAction('translate', shellText(context, "ترجمة"), Icons.translate_rounded),
      _MsgAction(
        'star',
        widget.starred ? shellText(context, "إلغاء التمييز") : shellText(context, "تمييز"),
        widget.starred ? Icons.star_rounded : Icons.star_border_rounded,
      ),
      _MsgAction('info', shellText(context, "معلومات"), Icons.info_outline_rounded),
      if (!widget.isText)
        _MsgAction('download', shellText(context, "تحميل"), Icons.download_rounded),
      if (widget.isText && widget.isMine)
        _MsgAction('edit', shellText(context, "تعديل"), Icons.edit_rounded),
      _MsgAction('hide', shellText(context, 'حذف لدي'), Icons.visibility_off_outlined),
      if (widget.isMine)
        _MsgAction('delete', shellText(context, "حذف للجميع"), Icons.delete_outline_rounded,
            destructive: true),
    ];

    final bubbleColor = widget.isMine
        ? AppTeal.main
        : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF0F0F0));
    final bubbleTextColor =
    widget.isMine ? Colors.white : (isDark ? Colors.white : Colors.black87);

    return Directionality(
      textDirection: Directionality.of(context),
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _close(),
          child: Stack(
            children: [
              // ===== خلفية مموّهة =====
              AnimatedBuilder(
                animation: _fade,
                builder: (context, child) => BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 18 * _fade.value,
                    sigmaY: 18 * _fade.value,
                  ),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.35 * _fade.value),
                  ),
                ),
              ),

              // ===== المحتوى العائم فالمنتصف =====
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 32),
                    child: GestureDetector(
                      onTap: () {}, // يمنع إغلاق القائمة عند الضغط على المحتوى نفسه
                      child: ScaleTransition(
                        scale: _scale,
                        child: FadeTransition(
                          opacity: _fade,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: widget.isMine
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              // ===== شريط الإيموجيات العائم =====
                              Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2C2C2E)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.25),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (final e in _reactions)
                                      _ReactionButton(
                                        emoji: e,
                                        onTap: () => _close('react:$e'),
                                      ),
                        // ✅ الجديد
                        InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () async {
                            // FIX: نفس نمط الحماية من لوحة المفاتيح الموجود أصلاً في
                            // _ModernMessageActionsSheet - كان مفقودًا هنا فقط.
                            final emoji = await showModalBottomSheet<String>(
                              context: context,
                              isScrollControlled: true,
                              useRootNavigator: true,
                              backgroundColor: Colors.transparent,
                              builder: (sheetCtx) {
                                return Material(
                                  color: isDark
                                      ? const Color(0xFF1C1C1E)
                                      : Colors.white,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(22),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: const _AllEmojiSheet(),
                                );
                              },
                            );
                            if (!mounted) return;
                            if (emoji != null && emoji.trim().isNotEmpty) {
                              await _close('react:${emoji.trim()}');
                            }
                          },

                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        margin: const EdgeInsetsDirectional.only(start: 4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.1)
                                              : Colors.black.withValues(alpha: 0.07),
                                        ),
                                        child: Icon(
                                          Icons.add_rounded,
                                          size: 20,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // ===== معاينة الرسالة بشكل الفقاعة الحقيقية =====
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                  MediaQuery.of(context).size.width * 0.72,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 11),
                                  decoration: BoxDecoration(
                                    color: bubbleColor,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(18),
                                      topRight: const Radius.circular(18),
                                      bottomLeft: Radius.circular(
                                          widget.isMine ? 18 : 4),
                                      bottomRight: Radius.circular(
                                          widget.isMine ? 4 : 18),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.25),
                                        blurRadius: 14,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    widget.preview.isEmpty
                                        ? shellText(context, "رسالة")
                                        : widget.preview,
                                    maxLines: 5,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: bubbleTextColor,
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // ===== قائمة الخيارات (عمود واحد بأسلوب iOS) =====
                              Container(
                                width: 240,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2C2C2E)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.22),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (var i = 0; i < actions.length; i++) ...[
                                      _ActionRow(
                                        action: actions[i],
                                        isDark: isDark,
                                        onTap: () => _close(actions[i].value),
                                      ),
                                      if (i != actions.length - 1)
                                        Divider(
                                          height: 1,
                                          thickness: 0.6,
                                          indent: 14,
                                          endIndent: 14,
                                          color: (isDark
                                              ? Colors.white
                                              : Colors.black)
                                              .withValues(alpha: 0.08),
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReactionButton extends StatefulWidget {
  const _ReactionButton({required this.emoji, required this.onTap});
  final String emoji;
  final VoidCallback onTap;


  @override
  State<_ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<_ReactionButton> {
  bool _pressed = false;


  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 1.35 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Text(
            widget.emoji,
            style: const TextStyle(fontFamily: 'NotoColorEmoji', fontSize: 24),
          ),
        ),
      ),
    );
  }

}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.action,
    required this.isDark,
    required this.onTap,
  });

  final _MsgAction action;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = action.destructive
        ? const Color(0xFFDC2626)
        : (isDark ? Colors.white : Colors.black87);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Text(
                action.label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 15.5,
                ),
              ),
            ),
            Icon(action.icon, size: 19, color: color),
          ],
        ),
      ),
    );
  }
}

class _MsgAction {
  const _MsgAction(this.value, this.label, this.icon, {this.destructive = false});
  final String value;
  final String label;
  final IconData icon;
  final bool destructive;
}

/// دالة العرض — تستبدل استدعاء showModalBottomSheet القديم
Future<String?> showModernMessageActions(
    BuildContext context, {
      required String preview,
      required bool isMine,
      required bool starred,
      required bool isText,
    }) {
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: shellText(context, 'إغلاق'),
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _ModernMessageActionsSheet(
        preview: preview,
        isMine: isMine,
        starred: starred,
        isText: isText,
      );
    },
  );
}
class _StarredMessagesPage extends StatelessWidget {
  const _StarredMessagesPage({
    required this.messages,
    required this.peerName,
  });

  final List<types.Message> messages;
  final String peerName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(shellFormat(context, "مميز — {0}", [peerName]))),
      body: messages.isEmpty
          ? Center(child: Text(shellText(context, "لا توجد رسائل مميزة")))
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: messages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final m = messages[i];
          final text = m is types.TextMessage
              ? m.text
              : m is types.ImageMessage
              ? shellText(context, "📷 صورة")
              : m is types.VideoMessage
              ? shellText(context, "🎬 فيديو")
              : m is types.AudioMessage
              ? shellText(context, "🎤 صوت")
              : shellText(context, "رسالة");
          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            tileColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.45),
            leading: const Icon(
              Icons.star_rounded,
              color: Color(0xFFF59E0B),
            ),
            title: Text(text),
          );
        },
      ),
    );
  }
}

class _PinnedMessageActionsOverlay extends StatefulWidget {
  const _PinnedMessageActionsOverlay({
    required this.rect,
    required this.message,
    this.canDownload = true,
    required this.preview,
    required this.isMine,
    required this.starred,
    required this.isText,
  });

  final Rect rect;
  final types.Message message;
  final bool canDownload;
  final String preview;
  final bool isMine;
  final bool starred;
  final bool isText;

  @override
  State<_PinnedMessageActionsOverlay> createState() =>
      _PinnedMessageActionsOverlayState();
}

class _PinnedMessageActionsOverlayState extends State<_PinnedMessageActionsOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;

  static const _reactions = kQuickReactionEmojis;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _t = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _close([String? value]) async {
    await _c.reverse();
    if (mounted) Navigator.pop(context, value);
  }

  Widget _overlayBody() {
    final m = widget.message;
    final r = widget.rect;
    if (m is types.ImageMessage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          m.uri,
          width: r.width,
          height: r.height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
          const Icon(Icons.broken_image_outlined),
        ),
      );
    }
    if (m is types.VideoMessage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: r.width,
          height: r.height,
          child: ChatVideoThumbnail(url: m.uri),
        ),
      );
    }
    if (m is types.AudioMessage) {
      return ChatAudioPlayer(
        scope: _currentChatSession(),
        url: m.uri,
        mine: widget.isMine,
        totalDuration: m.duration,
      );
    }
    return Text(
      widget.preview,
      maxLines: 6,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: widget.isMine ? Colors.white : null,
        fontSize: 15,
        height: 1.4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final actions = <_MsgAction>[
      _MsgAction('reply', shellText(context, "رد"), Icons.reply_rounded),
      if (widget.isText) _MsgAction('copy', shellText(context, "نسخ"), Icons.content_copy_rounded),
      if (widget.isText)
        _MsgAction('translate', shellText(context, "ترجمة"), Icons.translate_rounded),
      _MsgAction(
        'star',
        widget.starred ? shellText(context, "إلغاء التمييز") : shellText(context, "تمييز"),
        widget.starred ? Icons.star_rounded : Icons.star_border_rounded,
      ),
      _MsgAction('info', shellText(context, "معلومات"), Icons.info_outline_rounded),
      if (!widget.isText && widget.canDownload)
        _MsgAction('download', shellText(context, "تحميل"), Icons.download_rounded),
      if (widget.isText && widget.isMine)
        _MsgAction('edit', shellText(context, "تعديل"), Icons.edit_rounded),
      _MsgAction('hide', shellText(context, 'حذف لدي'), Icons.visibility_off_outlined),
      if (widget.isMine)
        _MsgAction('delete', shellText(context, "حذف للجميع"), Icons.delete_outline_rounded,
            destructive: true),
    ];


    return Material(color: Colors.transparent, child: Stack(children: [
      Positioned.fill(child: GestureDetector(onTap: _close, child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: ColoredBox(color: Colors.black.withValues(alpha: .28)),
      ))),
      FadeTransition(opacity: _t, child: ChatMessageActionFrame(
        anchor: widget.rect, isMine: widget.isMine,
        preview: Material(color: widget.isMine ? AppTeal.main : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20), clipBehavior: Clip.antiAlias,
          child: Padding(padding: const EdgeInsets.all(14), child: _overlayBody())),
        reactions: Material(color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(28), child: Padding(padding: const EdgeInsets.all(6), child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (final emoji in _reactions) _ReactionButton(emoji: emoji, onTap: () => _close('react:$emoji')),
            IconButton(icon: const Icon(Icons.add_rounded), onPressed: () async {
              final emoji = await showModalBottomSheet<String>(context: context, isScrollControlled: true, useRootNavigator: true, builder: (_) => const _AllEmojiSheet());
              if (mounted && emoji != null && emoji.trim().isNotEmpty) await _close('react:'+emoji.trim());
            }),
          ]))),
        actions: Column(mainAxisSize: MainAxisSize.min, children: [
          for (var i=0; i<actions.length; i++) ...[
            _ActionRow(action: actions[i], isDark: isDark, onTap: () => _close(actions[i].value)),
            if (i<actions.length-1) Divider(height: 1, indent: 16, endIndent: 16, color: theme.colorScheme.outlineVariant.withValues(alpha: .35)),
          ],
        ]),
      )),
    ]));
  }
}
//=========================================================================
class _EditPreview extends StatelessWidget {
  const _EditPreview({required this.text, required this.onCancel});
  final String text;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.25)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.edit_rounded, size: 16, color: Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shellText(context, "تعديل الرسالة"),
                  style: TextStyle(
                    color: Color(0xFFF59E0B),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.hintColor, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class _ChatTranslateSheet extends StatefulWidget {
  const _ChatTranslateSheet({required this.text});
  final String text;

  @override
  State<_ChatTranslateSheet> createState() => _ChatTranslateSheetState();
}

class _ChatTranslateSheetState extends State<_ChatTranslateSheet> {
  static const _langs = <(String, String)>[
    ('auto', 'كشف تلقائي'),
    ('ar', 'العربية'),
    ('fr', 'Français'),
    ('en', 'English'),
    ('es', 'Español'),
    ('de', 'Deutsch'),
    ('tr', 'Türkçe'),
    ('it', 'Italiano'),
  ];

  String _from = 'auto';
  String _to = 'en';
  String? _detected;
  int _generation = 0;
  bool _started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _to = chatTranslationTarget('auto', Localizations.localeOf(context).languageCode);
      _run();
    }
  }
  bool _loading = false;
  String? _result;
  String? _error;

  String _label(String code) =>
      _langs.firstWhere((e) => e.$1 == code, orElse: () => (code, code)).$2;

  Future<void> _pick(bool source) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final items = source ? _langs : _langs.where((e) => e.$1 != 'auto');
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final e in items)
                ListTile(
                  title: Text(shellText(context, e.$2)),
                  trailing: (source ? _from : _to) == e.$1
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => Navigator.pop(ctx, e.$1),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (source) {
        _from = selected;
      } else {
        _to = selected;
      }
      _generation++; _loading = false; _error = null; _detected = null;
      _result = null;
    });
  }

  Future<void> _run() async {
    final generation = ++_generation;
    final source = _from, target = _to;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final out = await ChatTranslationService.translateConservatively(
        widget.text, target, source: source,
      ).timeout(const Duration(seconds: 20));
      if (!mounted || generation != _generation) return;
      setState(() {
        _detected = out.source == 'auto' ? null : out.source;
        _result = out.canReplace(widget.text, target) ? out.text : widget.text;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _error = 'تعذر الترجمة';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            shellText(context, "ترجمة"),
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pick(true),
                  child: Text(shellText(context, _label(_from)), overflow: TextOverflow.ellipsis),
                ),
              ),
              IconButton(
                onPressed: _loading || _from == 'auto'
                    ? null
                    : () => setState(() {
                  final a = _from;
                  _from = _to;
                  _to = a;
                  _result = null;
                }),
                icon: const Icon(Icons.swap_horiz_rounded),
              ),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pick(false),
                  child: Text(shellText(context, _label(_to)), overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(widget.text, maxLines: 6, overflow: TextOverflow.ellipsis),
          ),
          if (_from == 'auto' && _detected != null) Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('${mediaText(context, 'اللغة المكتشفة', 'Detected language', 'Langue détectée')}: ${_label(_detected!)}'),
          ),
          if (_result != null) ...[
            const SizedBox(height: 10),
            Text(_result!, style: const TextStyle(fontSize: 16, height: 1.45)),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(shellText(context, _error!), style: const TextStyle(color: Color(0xFFDC2626))),
          ],
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _loading ? null : _run,
            style: FilledButton.styleFrom(backgroundColor: AppTeal.main),
            child: _loading
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : Text(shellText(context, "ترجمة")),
          ),
          if (_result != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _result!));
                Navigator.pop(context);
              },
              child: Text(shellText(context, "نسخ الترجمة")),
            ),
          ],
        ],
      ),
    );
  }
}


class VoiceAmpPainter extends CustomPainter {
  VoiceAmpPainter({
    required this.bars,
    required this.color,
    required this.frozen,
  });

  final List<double> bars;
  final Color color;
  final bool frozen;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || bars.isEmpty) return;
    const gap = 2.0;
    final n = bars.length;
    final barW = (size.width - gap * (n - 1)) / n;
    final mid = size.height / 2;
    final maxH = size.height * 0.94;
    final paint = Paint()
      ..color = frozen ? color.withValues(alpha: 0.45) : color
      ..isAntiAlias = true;

    for (var i = 0; i < n; i++) {
      final h = (bars[i].clamp(0.08, 1.0) * maxH).clamp(3.0, maxH);
      final x = i * (barW + gap);
      final rect = Rect.fromCenter(
        center: Offset(x + barW / 2, mid),
        width: barW.clamp(1.5, 3.4),
        height: h,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        paint,
      );
    }
  }

  @override

  bool shouldRepaint(covariant VoiceAmpPainter old) => true;
}

// ─────────────────────────────────────────────────────────────
// 3. Lock ghost — follows the finger, no lag
// ─────────────────────────────────────────────────────────────

class VoiceLockGhost extends StatelessWidget {
  const VoiceLockGhost({
    super.key,
    required this.position,
    required this.progress,
    required this.canceling,
    this.primary = const Color(0xFF0E7A72),
    this.danger = const Color(0xFFDC3A2C),
  });

  final Offset position;
  final double progress;
  final bool canceling;
  final Color primary;
  final Color danger;

  @override
  Widget build(BuildContext context) {
    final ready = progress >= 0.92;
    final scale = 0.82 + progress * 0.28;
    final lift = 52.0 + progress * 14.0;
    final bg = canceling
        ? danger
        : ready
        ? primary
        : Colors.white;
    final fg = canceling || ready ? Colors.white : const Color(0xFF14110E);

    return Positioned(
      left: position.dx - 24,
      top: position.dy - lift - 48,
      child: IgnorePointer(
        child: Transform.scale(
          scale: scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (ready ? primary : Colors.black)
                          .withValues(alpha: ready ? 0.32 : 0.14),
                      blurRadius: ready ? 18 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.lock_rounded, color: fg, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                canceling
                    ? shellText(context, "إلغاء")
                    : ready
                    ? shellText(context, "أفلت للقفل")
                    : shellText(context, "لأعلى للقفل"),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: canceling
                      ? danger
                      : ready
                      ? primary
                      : const Color(0xFF6E675E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 4. Floating dock — pause/resume are the recorder, not preview
// ─────────────────────────────────────────────────────────────

class PulseVoiceDock extends StatelessWidget {
  const PulseVoiceDock({
    super.key,
    required this.session,
    required this.locked,
    required this.holding,
    required this.canceling,
    required this.onPause,
    required this.onPreview,
    required this.onResume,
    required this.onDelete,
    required this.onSend,
    this.primary = const Color(0xFF0E7A72),
    this.danger = const Color(0xFFDC3A2C),
  });

  final VoiceSessionController session;
  final bool locked;
  final bool holding;
  final bool canceling;
  final VoidCallback onPause;
  final VoidCallback onPreview;
  final VoidCallback onResume;
  final VoidCallback onDelete;
  final VoidCallback onSend;
  final Color primary;
  final Color danger;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final paused = session.paused;
        final accent = canceling ? danger : primary;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final surface = isDark ? const Color(0xFF1D1D24) : Colors.white;
        final holdOnly = (holding && !locked) || session.busy || session.phase == VoicePhase.starting;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: const Cubic(0.2, 0, 0, 1),
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: canceling
                    ? Border.all(color: danger.withValues(alpha: 0.5))
                    : Border.all(
                  color: Colors.black.withValues(alpha: isDark ? 0.06 : 0.04),
                ),
              ),
              child: Row(
                children: [
                  _RoundBtn(
                    color: accent,
                    onTap: holdOnly
                        ? null
                        : (paused ? (session.canResume ? onResume : null) : onPause),
                    child: session.busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(
                      paused ? Icons.mic_rounded : Icons.pause_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  if (paused) IconButton(
                    key: const ValueKey('voice-preview'),
                    tooltip: shellText(context, 'سماع التسجيل'),
                    onPressed: holdOnly ? null : onPreview,
                    icon: Icon(session.previewPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded, color: accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: CustomPaint(
                        painter: VoiceAmpPainter(
                          bars: List<double>.from(session.bars),
                          color: accent,
                          frozen: paused,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _DurationBadge(
                    duration: _fmt(session.elapsed),
                    color: accent,
                    isDark: isDark,
                    live: session.live,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Opacity(
              opacity: holdOnly ? 0.38 : 1,
              child: SizedBox(
                height: 52,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: holdOnly ? null : onDelete,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: canceling ? danger : Theme.of(context).hintColor,
                      ),
                    ),
                    const Spacer(),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: locked
                            ? primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        locked ? Icons.lock_rounded : Icons.lock_outline_rounded,
                        color: locked ? primary : Theme.of(context).hintColor,
                        size: 21,
                      ),
                    ),
                    const Spacer(),
                    _RoundBtn(
                      color: primary,
                      size: 48,
                      onTap: holdOnly ? null : onSend,
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 21),
                    ),
                  ],
                ),
              ),
            ),
            if (session.lastError != null) Text(
              shellText(context, session.lastError == 'voice-too-short'
                  ? 'التسجيل قصير جدًا. تابع التسجيل قبل الإرسال.'
                  : 'تعذر تنفيذ العملية الصوتية. حاول مجددًا.'),
              style: TextStyle(color: danger, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              paused
                  ? shellText(context, session.elapsed >= kVoiceMaxDuration ? 'وصل التسجيل للحد الأقصى. استمع إليه أو أرسله.' : 'استمع للتسجيل أو اضغط المايك لمتابعته')
                  : holdOnly
                  ? shellText(context, "أفلت للمراجعة · يسار للإلغاء · أعلى للقفل")
                  : locked
                  ? shellText(context, "مقفل — يمكنك رفع إصبعك")
                  : '',
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _DurationBadge extends StatelessWidget {
  const _DurationBadge({
    required this.duration,
    required this.color,
    required this.isDark,
    required this.live,
  });

  final String duration;
  final Color color;
  final bool isDark;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 62),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (live)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsetsDirectional.only(end: 5),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          Text(
            duration,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({
    required this.color,
    required this.child,
    this.onTap,
    this.size = 46,
  });

  final Color color;
  final Widget child;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: size, height: size, child: Center(child: child)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 5. Host — tap = locked, hold + swipe up = floating lock
// ─────────────────────────────────────────────────────────────

class PulseVoiceHost extends StatefulWidget {
  const PulseVoiceHost({
    super.key,
    required this.session,
    required this.hasText,
    required this.sending,
    required this.inputBar,
    required this.onSendText,
    required this.onSendVoice,
    this.onBeforeStart,
    this.onStartFailed,
    this.primary = const Color(0xFF0E7A72),
  });

  final VoiceSessionController session;
  final bool hasText;
  final bool sending;
  final Widget inputBar;
  final VoidCallback onSendText;
  final Future<void> Function(File file, Duration duration) onSendVoice;

  /// Return false to abort (blocked user, etc).
  final Future<bool> Function()? onBeforeStart;
  final VoidCallback? onStartFailed;
  final Color primary;

  @override
  State<PulseVoiceHost> createState() => _PulseVoiceHostState();
}

class _PulseVoiceHostState extends State<PulseVoiceHost> with WidgetsBindingObserver {
  static const _danger = Color(0xFFDC3A2C);

  bool _pressing = false;
  bool _holding = false;
  bool _locked = false;
  bool _canceling = false;
  double _lockProgress = 0;
  Offset? _origin;
  Offset? _pointer;
  int? _pointerId;
  Timer? _holdTimer;
  OverlayEntry? _ghost;
  bool _routeBound = false;
  Future<bool>? _startFuture;
  int _operation = 0;
  bool _finishing = false;
  AppLifecycleState? _appState;

  bool get _showDock =>
      widget.session.recording || _holding || _pressing || _locked;

  @override
  void initState() {
    super.initState();
    _appState = WidgetsBinding.instance.lifecycleState;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appState = state;
    if (state != AppLifecycleState.resumed && (widget.session.live || _startFuture != null)) {
      unawaited(_pauseForReview());
    }
    if (state != AppLifecycleState.resumed && widget.session.previewPlaying) {
      unawaited(widget.session.stopPreview());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _operation++;
    _holdTimer?.cancel();
    _unbindRoute();
    _ghost?.remove();
    super.dispose();
  }

  void _bindRoute() {
    if (_routeBound) return;
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onGlobal);
    _routeBound = true;
  }

  void _unbindRoute() {
    if (!_routeBound) return;
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onGlobal);
    _routeBound = false;
  }

  void _onGlobal(PointerEvent e) {
    if (e.pointer != _pointerId) return;
    if (e is PointerMoveEvent) {
      _onMove(e.position);
    } else if (e is PointerCancelEvent) {
      unawaited(_doCancel());
    } else if (e is PointerUpEvent) {
      _onUp();
    }
  }

  void _onDown(PointerDownEvent e) {
    if (widget.sending || widget.hasText || _finishing || _startFuture != null || _pointerId != null) return;
    if (widget.session.recording) return;
    _pointerId = e.pointer;
    _origin = e.position;
    _pointer = e.position;
    _pressing = true;
    _holding = false;
    _locked = false;
    _canceling = false;
    _lockProgress = 0;
    _bindRoute();
    setState(() {});
    final operation = ++_operation;
    final start = _begin(operation);
    _startFuture = start;
    unawaited(start.whenComplete(() {
      if (identical(_startFuture, start)) _startFuture = null;
    }));
    _holdTimer?.cancel();
    _holdTimer = Timer(kVoiceHoldDelay, _enterHold);
  }

  void _enterHold() {
    if (!_pressing || _locked) return;
    _holding = true;
    HapticFeedback.mediumImpact();
    setState(() {});
    _syncGhost();
  }

  void _onMove(Offset global) {
    if (!_pressing && !_holding) return;
    if (_locked) return;
    _pointer = global;
    final origin = _origin;
    if (origin == null) return;

    final dx = global.dx - origin.dx;
    final dy = global.dy - origin.dy;
    final dist = Offset(dx, dy).distance;

    if (_pressing && !_holding && dist > 12) {
      _holdTimer?.cancel();
      _enterHold();
    }
    if (!_holding || _locked) {
      _syncGhost();
      return;
    }

    final up = math.max(0.0, -dy);
    final left = math.max(0.0, -dx);
    final progress = (up / kVoiceLockDy).clamp(0.0, 1.0);
    final inCancel = left >= kVoiceCancelDx && up < kVoiceLockDy * 0.85;

    if (inCancel != _canceling) {
      HapticFeedback.selectionClick();
    }
    _lockProgress = progress;
    _canceling = inCancel;

    if (progress >= 1 && !inCancel) {
      _locked = true;
      _holding = false;
      _canceling = false;
      HapticFeedback.heavyImpact();
      _removeGhost();
      setState(() {});
      return;
    }
    setState(() {});
    _syncGhost();
  }

  void _onUp() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _unbindRoute();
    _pointerId = null;
    _removeGhost();

    if (_locked) {
      _pressing = false;
      _holding = false;
      setState(() {});
      return;
    }

    if (_holding) {
      final cancel = _canceling;
      _pressing = false;
      _holding = false;
      _canceling = false;
      setState(() {});
      if (cancel) {
        unawaited(_doCancel());
      } else {
        unawaited(_pauseForReview());
      }
      return;
    }

    if (_pressing) {
      _pressing = false;
      _locked = true;
      setState(() {});
      HapticFeedback.lightImpact();
    }
  }

  Future<bool> _begin(int operation) async {
    try {
      if (widget.onBeforeStart != null) {
        final allowed = await widget.onBeforeStart!();
        if (!mounted || operation != _operation) return false;
        if (!allowed) {
          _reset();
          return false;
        }
      }
      if (!mounted || operation != _operation) return false;
      final ok = await widget.session.start();
      if (!mounted || operation != _operation) {
        // The owner disposes its session when the host is unmounted.
        if (mounted) await widget.session.cancel();
        return false;
      }
      if (ok && _appState != null && _appState != AppLifecycleState.resumed) {
        await widget.session.pause();
      }
      if (!ok) {
        _reset();
        widget.onStartFailed?.call();
      }
      return ok;
    } catch (error) {
      debugPrint('voice start failed: $error');
      if (mounted && operation == _operation) {
        _reset();
        widget.onStartFailed?.call();
      }
      return false;
    }
  }

  Future<void> _pauseForReview() async {
    if (_finishing) return;
    _finishing = true;
    final operation = _operation;
    try {
      final start = _startFuture;
      if (start != null && !await start) return;
      if (!mounted || operation != _operation) return;
      _holdTimer?.cancel();
      _unbindRoute();
      _removeGhost();
      _pointerId = null;
      _pressing = false;
      _holding = false;
      _locked = true;
      setState(() {});
      await widget.session.pause();
    } finally { _finishing = false; }
  }

  Future<void> _doSend() async {
    if (_finishing) return;
    _finishing = true;
    final operation = _operation;
    try {
      final start = _startFuture;
      if (start != null && !await start) return;
      if (!mounted || operation != _operation) return;
      final duration = widget.session.elapsed;
      final file = await widget.session.stopForSend();
      if (!mounted || operation != _operation) {
        try { if (file != null && await file.exists()) await file.delete(); } catch (_) {}
        return;
      }
      if (file != null) {
        _reset();
        await widget.onSendVoice(file, duration);
      }
    } finally {
      _finishing = false;
    }
  }

  Future<void> _doCancel() async {
    _operation++;
    _reset();
    final start = _startFuture;
    if (start != null) await start;
    if (mounted) await widget.session.cancel();
  }

  void _reset() {
    _holdTimer?.cancel();
    _unbindRoute();
    _removeGhost();
    _pressing = false;
    _holding = false;
    _locked = false;
    _canceling = false;
    _lockProgress = 0;
    _origin = null;
    _pointer = null;
    _pointerId = null;
    if (mounted) setState(() {});
  }

  void _syncGhost() {
    if (!_holding || _locked || _pointer == null) {
      _removeGhost();
      return;
    }
    _ghost ??= OverlayEntry(
      builder: (_) {
        final p = _pointer;
        if (p == null) return const SizedBox.shrink();
        return IgnorePointer(
          child: Stack(
            children: [
              VoiceLockGhost(
                position: p,
                progress: _lockProgress,
                canceling: _canceling,
                primary: widget.primary,
                danger: _danger,
              ),
            ],
          ),
        );
      },
    );
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    if (_ghost!.mounted) {
      _ghost!.markNeedsBuild();
    } else {
      overlay.insert(_ghost!);
    }
  }

  void _removeGhost() {
    _ghost?.remove();
    _ghost = null;
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primary;

    return ListenableBuilder(
      listenable: widget.session,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: const Cubic(0.2, 0, 0, 1),
              child: _showDock
                  ? Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: PulseVoiceDock(
                  session: widget.session,
                  locked: _locked,
                  holding: _holding,
                  canceling: _canceling,
                  primary: primary,
                  onPause: () => unawaited(_pauseForReview()),
                  onPreview: () => unawaited(widget.session.togglePreview()),
                  onResume: () => unawaited(widget.session.resume()),
                  onDelete: () => unawaited(_doCancel()),
                  onSend: () => unawaited(_doSend()),
                ),
              )
                  : const SizedBox.shrink(),
            ),
            if (_holding)
              Align(
                alignment: AlignmentDirectional.bottomEnd,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 18, bottom: 4),
                  child: _LockTarget(
                    progress: _lockProgress,
                    canceling: _canceling,
                    primary: primary,
                  ),
                ),
              ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _showDock ? 0 : 1,
              child: IgnorePointer(
                ignoring: _showDock,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: widget.inputBar),
                      const SizedBox(width: 8),
                      widget.hasText
                          ? _RoundBtn(
                        color: const Color(0xFF0095F6),
                        onTap: widget.sending ? null : widget.onSendText,
                        child: widget.sending
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                      )
                          : Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: _onDown,
                        child: const _MicVisual(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MicVisual extends StatelessWidget {
  const _MicVisual();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: Color(0xFF0095F6),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
    );
  }
}

class _LockTarget extends StatelessWidget {
  const _LockTarget({
    required this.progress,
    required this.canceling,
    required this.primary,
  });

  final double progress;
  final bool canceling;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final ready = progress >= 0.92;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: canceling
            ? const Color(0xFFDC3A2C).withValues(alpha: 0.12)
            : ready
            ? primary
            : Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
          ),
        ],
      ),
      child: Icon(
        Icons.lock_rounded,
        size: 20,
        color: canceling
            ? const Color(0xFFDC3A2C).withValues(alpha: 0.5)
            : ready
            ? Colors.white
            : Theme.of(context).hintColor,
      ),
    );
  }
}
