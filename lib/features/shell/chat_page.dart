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
import 'package:UniSpace/main.dart';
import 'package:flutter/services.dart';
import 'package:translator/translator.dart';
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
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:emojis/emoji.dart' as ue;
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart'
    show consolidateHttpClientResponseBytes, ValueNotifier, ValueListenable;


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

Color _chatWallpaperColor(String id, bool isDark) {
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
    required this.bubbleColor,
    required this.autoTranslate,
    required this.autoTranslateLang,
    required this.startedAt,
    required this.messages,
    required this.onSearch,
    required this.onOpenProfile,
    required this.onToggleMute,
    required this.onClear,
    this.onWallpaperChanged,
    this.onBubbleColorChanged,
    this.onBubbleGradientChanged,
    this.onWallpaperUrlChanged,
  });

  final String chatId;
  final String peerId;
  final String peerName;
  final String? peerPhotoUrl;
  final bool muted;
  final String nickname;
  final String wallpaper;
  final int bubbleColor;
  final bool autoTranslate;
  final String autoTranslateLang;
  final DateTime? startedAt;
  final List<types.Message> messages;
  final VoidCallback onSearch;
  final VoidCallback onOpenProfile;
  final VoidCallback onToggleMute;
  final VoidCallback onClear;
  final ValueChanged<String>? onWallpaperChanged;
  final ValueChanged<int>? onBubbleColorChanged;
  final ValueChanged<List<int>?>? onBubbleGradientChanged;
  final ValueChanged<String>? onWallpaperUrlChanged;

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

  DocumentReference<Map<String, dynamic>> get _chat =>
      FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _nick = TextEditingController(text: widget.nickname);
    _muted = widget.muted;
    _auto = widget.autoTranslate;
    _lang = widget.autoTranslateLang;
    _wallpaper = widget.wallpaper;
    _bubble = widget.bubbleColor;
  }

  @override
  void dispose() {
    _nick.dispose();
    super.dispose();
  }

  Future<void> _patch(Map<String, dynamic> data) async {
    if (_uid.isEmpty) return;
    try {
      await _chat.set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('theme patch failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حفظ المظهر: $e')),
      );
    }
  }
  Future<void> _editNickname() async {
    final ctrl = TextEditingController(text: _nick.text);
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16, 0, 16, 16 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'الاسم البديل',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const SizedBox(height: 6),
              const Text('يظهر لك في المحادثة فقط، وليس للطرف الآخر.'),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: widget.peerName,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                style: FilledButton.styleFrom(backgroundColor: AppTeal.main),
                child: const Text('حفظ'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, ''),
                child: const Text('إزالة الاسم البديل'),
              ),
            ],
          ),
        );
      },
    );
    ctrl.dispose();
    if (value == null) return;
    _nick.text = value;
    setState(() {});
    await _saveNick(value);
  }
  Future<void> _saveNick(String v) async {
    await _patch({'nicknames.$_uid': v.trim()});
  }

  Future<void> _block() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حظر هذا الحساب؟'),
        content: const Text('لن يتمكن من مراسلتك وستُخفى المحادثة.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حظر'),
          ),
        ],
      ),
    );
    if (ok != true || _uid.isEmpty) return;
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    batch.set(
      db.collection('users').doc(_uid).collection('blocked_accounts').doc(widget.peerId),
      {
        'blockedId': widget.peerId,
        'source': 'chat',
        'blockedAt': FieldValue.serverTimestamp(),
      },
    );
    batch.set(
      db.collection('users').doc(widget.peerId).collection('blocked_by').doc(_uid),
      {
        'blockerId': _uid,
        'blockedAt': FieldValue.serverTimestamp(),
      },
    );
    await batch.commit();
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
        const SnackBar(content: Text('تم إرسال التبليغ')),
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
    switch (id) {
      case 'mint':
        return 'نعناع';
      case 'dusk':
        return 'بنفسجي';
      case 'paper':
        return 'ورق';
      case 'night':
        return 'ليلي';
      default:
        return 'افتراضي';
    }
  }

  Future<void> _openWallpaperSheet() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const wallpaperStyles = <_WallpaperStyle>[
      _WallpaperStyle(
        id: 'default',
        label: 'افتراضي',
        color: Color(0xFFF5F7FA),
      ),
      _WallpaperStyle(
        id: 'mint',
        label: 'نعناع',
        gradient: LinearGradient(
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
        label: 'محيط',
        gradient: LinearGradient(
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
        label: 'لافندر',
        gradient: LinearGradient(
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
        label: 'غروب',
        gradient: LinearGradient(
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
        label: 'مرجاني',
        gradient: LinearGradient(
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
        label: 'سماء',
        gradient: LinearGradient(
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
        label: 'غابة',
        gradient: LinearGradient(
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
        label: 'وردي',
        gradient: LinearGradient(
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
        label: 'رملي',
        gradient: LinearGradient(
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
        label: 'منتصف الليل',
        gradient: LinearGradient(
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
        label: 'جرافيت',
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF334155),
            Color(0xFF0F172A),
          ],
        ),
      ),
    ];
    const bubbleStyles = <_BubbleStyle>[
      _BubbleStyle(
        id: 'teal',
        label: 'فيروزي',
        color: Color(0xFF0D9488),
      ),
      _BubbleStyle(
        id: 'blue',
        label: 'أزرق',
        color: Color(0xFF2563EB),
      ),
      _BubbleStyle(
        id: 'violet',
        label: 'بنفسجي',
        color: Color(0xFF7C3AED),
      ),
      _BubbleStyle(
        id: 'green',
        label: 'أخضر',
        color: Color(0xFF16A34A),
      ),
      _BubbleStyle(
        id: 'pink',
        label: 'وردي',
        color: Color(0xFFE11D48),
      ),
      _BubbleStyle(
        id: 'orange',
        label: 'برتقالي',
        color: Color(0xFFF97316),
      ),
      _BubbleStyle(
        id: 'yellow',
        label: 'ذهبي',
        color: Color(0xFFEAB308),
      ),
      _BubbleStyle(
        id: 'cyan',
        label: 'سماوي',
        color: Color(0xFF0891B2),
      ),
      _BubbleStyle(
        id: 'indigo',
        label: 'نيلي',
        color: Color(0xFF4F46E5),
      ),
      _BubbleStyle(
        id: 'red',
        label: 'أحمر',
        color: Color(0xFFDC2626),
      ),
      _BubbleStyle(
        id: 'lime',
        label: 'ليموني',
        color: Color(0xFF65A30D),
      ),
      _BubbleStyle(
        id: 'dark',
        label: 'داكن',
        color: Color(0xFF0F172A),
      ),
      _BubbleStyle(
        id: 'sunset',
        label: 'غروب',
        gradient: LinearGradient(
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
        label: 'توت',
        gradient: LinearGradient(
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
        label: 'موج',
        gradient: LinearGradient(
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
        label: 'نعناع',
        gradient: LinearGradient(
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
        label: 'ناري',
        gradient: LinearGradient(
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
                                        const Text(
                                          'مظهر المحادثة',
                                          style: TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'اختر ألوانًا وخلفيات تناسبك',
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

                              const _CompactSectionTitle(
                                icon: Icons.palette_outlined,
                                title: 'لون الفقاعات',
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
                                      setSheetState(() {
                                        if (style.gradient != null) {
                                          selectedBubbleGradient = style.id;
                                        } else {
                                          selectedBubble = style.color!.value;
                                          selectedBubbleGradient = null;
                                        }
                                      });

                                      setState(() {
                                        if (style.gradient != null) {
                                          _bubbleGradientKey = style.id;
                                        } else {
                                          _bubble = style.color!.value;
                                          _bubbleGradientKey = null;
                                        }
                                      });

                                      if (style.gradient != null) {
                                        final colors = _gradientColors(style.gradient!);
                                        widget.onBubbleGradientChanged?.call(colors);
                                        await _patch({
                                          'theme.$_uid.bubbleGradient': colors,
                                          'theme.$_uid.bubbleColor': FieldValue.delete(),
                                        });
                                      } else {
                                        final c = style.color!.value;
                                        widget.onBubbleColorChanged?.call(c);
                                        await _patch({
                                          'theme.$_uid.bubbleColor': c,
                                          'theme.$_uid.bubbleGradient': FieldValue.delete(),
                                        });
                                      }

                                      if (style.gradient != null) {
                                        await _patch({
                                          'theme.$_uid.bubbleGradient':
                                          _gradientColors(style.gradient!),
                                          'theme.$_uid.bubbleColor':
                                          FieldValue.delete(),
                                        });
                                      } else {
                                        await _patch({
                                          'theme.$_uid.bubbleColor':
                                          style.color!.value,
                                          'theme.$_uid.bubbleGradient':
                                          FieldValue.delete(),
                                        });
                                      }
                                    },
                                  );
                                },
                              ),

                              const SizedBox(height: 24),

                              Row(
                                children: [
                                  const Expanded(
                                    child: _CompactSectionTitle(
                                      icon: Icons.wallpaper_outlined,
                                      title: 'خلفية المحادثة',
                                    ),
                                  ),
                                  if (selectedWallpaper == 'photo')
                                    _SelectedLabel(
                                      label: 'صورة مخصصة',
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
                              if (index == wallpaperStyles.length) {
                                return _CompactCustomWallpaperOption(
                                  selected: selectedWallpaper == 'photo',
                                  imageUrl: _wallpaperUrl,
                                  onTap: () async {
                                    Navigator.of(sheetContext).pop();
                                    await _pickCustomWallpaper();
                                  },
                                );
                              }

                              final style = wallpaperStyles[index];

                              return _CompactWallpaperOption(
                                style: style,
                                selected: selectedWallpaper == style.id,
                                isDark: isDark,
                                onTap: () async {
                                  setSheetState(() {
                                    selectedWallpaper = style.id;
                                  });

                                  setState(() {
                                    _wallpaper = style.id;
                                    _wallpaperGradientKey = style.id;
                                    _wallpaperUrl = null;
                                  });
                                  widget.onWallpaperChanged?.call(style.id);
                                  await _patch({
                                    'theme.$_uid.wallpaper': style.id,
                                    'theme.$_uid.wallpaperUrl':
                                    FieldValue.delete(),
                                  });

                                  if (sheetContext.mounted) {
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
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 72,
      );
      if (picked == null || _uid.isEmpty) return;
      final ref = FirebaseStorage.instance
          .ref()
          .child('chats/${widget.chatId}/wallpaper/$_uid.jpg');
      await ref.putFile(
        File(picked.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await ref.getDownloadURL();
      setState(() => _wallpaper = 'photo');
      widget.onWallpaperUrlChanged?.call(url);
      await _patch({
        'theme.$_uid.wallpaper': 'photo',
        'theme.$_uid.wallpaperUrl': url,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تعيين الخلفية: $e')),
      );
    }
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
                  title: 'تفاصيل المحادثة',
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
                        muted: _muted,
                      ),

                      const SizedBox(height: 18),

                      _SimpleSettingsGroup(
                        title: 'الإشعارات والترجمة',
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
                            title: const Text('كتم الإشعارات'),
                            subtitle: Text(
                              _muted
                                  ? 'الإشعارات مكتومة'
                                  : 'الإشعارات مفعّلة',
                            ),
                            value: _muted,
                            onChanged: (value) {
                              setState(() => _muted = value);
                              widget.onToggleMute();
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
                            title: const Text('ترجمة تلقائية'),
                            subtitle: Text(
                              _auto
                                  ? 'تتم ترجمة الرسائل تلقائياً'
                                  : 'الترجمة التلقائية متوقفة',
                            ),
                            value: _auto,
                            onChanged: (value) async {
                              setState(() => _auto = value);
                              await _patch({
                                'autoTranslate.$_uid': value,
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      _SimpleSettingsGroup(
                        title: 'التخصيص',
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            leading: const Icon(Icons.badge_outlined),
                            title: const Text('الاسم البديل'),
                            subtitle: Text(
                              _nick.text.trim().isEmpty
                                  ? 'يظهر لك فقط'
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
                            title: const Text('مظهر المحادثة'),
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
                        title: 'المحتوى المشترك',
                        children: [
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
                                      text: 'وسائط ${media.isEmpty ? '' : media.length}',
                                    ),
                                    Tab(
                                      text: 'منشورات ${posts.isEmpty ? '' : posts.length}',
                                    ),
                                    Tab(
                                      text: 'روابط ${links.isEmpty ? '' : links.length}',
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: TabBarView(
                                    children: [
                                      _ChatSharedGrid(
                                        items: media,
                                        empty: 'لا توجد وسائط',
                                      ),
                                      _ChatSharedGrid(
                                        items: posts,
                                        empty: 'لا توجد منشورات',
                                      ),
                                      _ChatSharedGrid(
                                        items: links,
                                        empty: 'لا توجد روابط',
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
                        title: 'إجراءات الحساب',
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            leading: const Icon(
                              Icons.flag_outlined,
                              color: Color(0xFFB45309),
                            ),
                            title: const Text('إبلاغ'),
                            subtitle: const Text(
                              'الإبلاغ عن هذا الحساب',
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
                            title: const Text(
                              'حظر',
                              style: TextStyle(
                                color: Color(0xFFDC2626),
                              ),
                            ),
                            subtitle: const Text(
                              'منع الحساب من مراسلتك',
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
      label: 'اختيار ${style.label}',
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
                      decoration: BoxDecoration(
                        color: style.color ??
                            (isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white),
                        gradient: style.gradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
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
              hasImage ? 'الصورة الخاصة' : 'من المعرض',
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
            tooltip: 'إغلاق',
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

  const _SimpleProfileHeader({
    required this.name,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppTeal.main.withOpacity(0.14),
            child: Text(
              name.trim().isEmpty
                  ? '?'
                  : name.trim().characters.first.toUpperCase(),
              style:  TextStyle(
                color: AppTeal.main,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),
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
                  muted ? 'الإشعارات مكتومة' : 'إعدادات المحادثة',
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
        final text = m is types.TextMessage ? m.text : 'منشور';
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

  // ألوان الوضع الفاتح (التصميم الأصلي)
  static const Color _lightPage = Color(0xffFAFAFA);
  static const Color _lightBorder = Color(0xffD7D7D7);
  static const Color _lightSecondary = Color(0xff777777);
  static const Color _lightPrimary = Color(0xff202020);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ——— ألوان متكيّفة مع الثيم ———
  Color _page(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? Theme.of(context).scaffoldBackgroundColor : _lightPage;
  }

  Color _border(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark
        ? Theme.of(context).dividerColor.withValues(alpha: 0.45)
        : _lightBorder;
  }

  Color _secondary(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : _lightSecondary;
  }

  Color _primary(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? Theme.of(context).colorScheme.onSurface : _lightPrimary;
  }

  Color _card(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? Theme.of(context).colorScheme.surface : Colors.white;
  }

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
            'سجّل الدخول أولاً',
            style: TextStyle(color: _primary(context)),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _page(context),
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context: context, uid: currentUser.uid),
              SizedBox( height: 20,),
              _buildSearchField(context),
              // فاصل تحت حيز البحث
              Padding(
                padding: const EdgeInsets.only(top: 25),
                child: Divider(
                  radius: BorderRadius.all(Radius.circular(20)),
                  height: 2,
                  endIndent: 10,
                  indent: 10,
                  thickness: 2,
                  color: _border(context),
                ),
              ),
              Expanded(
                child: _buildBody(uid: currentUser.uid),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar({
    required BuildContext context,
    required String uid,
  }) {
    final primary = _primary(context);
    final canPop = Navigator.of(context).canPop();

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 24, 18),
      child: Row(
        children: [

            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.arrow_back_rounded, color: primary),
            ),
            _buildProfileAvatar(context, uid),
          Expanded(
            child: Center(
              child: Text(
                'Chat',
                style: TextStyle(
                  color: primary,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .2,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: primary, width: 1.4),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(Icons.add, size: 17, color: primary),
            ),
          ),
        ],
      ),
    );
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
              border: Border.all(color: primary, width: 1.2),
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
    final border = _border(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        height: 45,
        child: TextField(
          controller: _searchController,
          textDirection: TextDirection.rtl,
          style: TextStyle(color: primary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search',
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
              borderRadius: BorderRadius.circular(7),
              borderSide: BorderSide(color: border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: BorderSide(color: primary, width: 1),
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
                      'Conversation',
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
              child: GestureDetector(
                onTap: () => setState(() => _requestsExpanded = false),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Request',
                      style: TextStyle(
                        color: primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 5),
                      Text(
                        '$count',
                        style: TextStyle(
                          color: secondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(width: 3),
                    Icon(
                      Icons.keyboard_arrow_up,
                      color: secondary,
                      size: 17,
                    ),
                  ],
                ),
              ),
            )
            // مغلق: Conversation يسار + Request يمين
                : Row(
              children: [
                Text(
                  'Conversation',
                  style: TextStyle(
                    color: primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _requestsExpanded = true),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Request',
                        style: TextStyle(
                          color: secondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 5),
                        Text(
                          '$count',
                          style: TextStyle(
                            color: secondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(width: 3),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: secondary,
                        size: 17,
                      ),
                    ],
                  ),
                ),
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
              'تعذر تحميل الطلبات',
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
              'No requests',
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
          separatorBuilder: (_, __) => const SizedBox(height: 17),
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
      stream: _firestore
          .collection('chats')
          .where('memberIds', arrayContains: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'تعذر تحميل المحادثات',
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
          if (data['deletedBy_$uid'] == true) return false;
          if (_searchText.isEmpty) return true;

          final members = Map<String, dynamic>.from(data['members'] ?? {});
          final memberIds =
          (data['memberIds'] as List? ?? []).map((e) => e.toString());
          final peerId = memberIds.firstWhere(
                (id) => id != uid,
            orElse: () => '',
          );
          final peer = Map<String, dynamic>.from(members[peerId] ?? {});
          final name = _readName(peer).toLowerCase();
          final lastMessage =
              data['lastMessage']?.toString().toLowerCase() ?? '';
          return name.contains(_searchText) || lastMessage.contains(_searchText);
        }).toList();

        if (filteredChats.isEmpty) {
          return _buildEmptyState(
            title: 'No conversations',
            subtitle: 'Start a new conversation.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 15, 24, 35),
          itemCount: filteredChats.length,
          separatorBuilder: (_, __) => const SizedBox(height: 17),
          itemBuilder: (context, index) {
            final doc = filteredChats[index];
            return _ChatRow(
              document: doc,
              myUid: uid,
              primary: _primary(context),
              secondary: _secondary(context),
              card: _card(context),
              onLongPress: (globalPosition) {
                _showChatActions(
                  context: context,
                  globalPosition: globalPosition,
                  chatId: doc.id,
                  pinned: doc.data()['pinned_$uid'] == true,
                  muted: doc.data()['muted_$uid'] == true,
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
    required bool pinned,
    required bool muted,
  }) async {
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
                pinned ? 'Unpin conversation' : 'Pin conversation',
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
                muted ? 'Unmute conversation' : 'Mute conversation',
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
                'Delete conversation',
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

    if (selected == null || !mounted) return;

    final uid = _auth.currentUser!.uid;
    final ref = _firestore.collection('chats').doc(chatId);

    switch (selected) {
      case 'pin':
        await ref.set({'pinned_$uid': !pinned}, SetOptions(merge: true));
        break;
      case 'mute':
        await ref.set({'muted_$uid': !muted}, SetOptions(merge: true));
        break;
      case 'delete':
        await ref.set({'deletedBy_$uid': true}, SetOptions(merge: true));
        break;
    }
  }
}

class _ChatRow extends StatefulWidget {
  const _ChatRow({
    required this.document,
    required this.myUid,
    required this.onLongPress,
    required this.primary,
    required this.secondary,
    required this.card,
  });

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
    final data = widget.document.data();
    final members = Map<String, dynamic>.from(data['members'] ?? {});
    final memberIds =
    (data['memberIds'] as List? ?? []).map((e) => e.toString());
    final peerId = memberIds.firstWhere(
          (id) => id != widget.myUid,
      orElse: () => '',
    );
    final peer = Map<String, dynamic>.from(members[peerId] ?? {});

    final name = _ChatPageState._readName(peer);
    final photoUrl = _ChatPageState._readPhoto(peer);
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
        if (peerId.isEmpty) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatThreadScreen(
              chatId: widget.document.id,
              peerId: peerId,
              peerName: name,
              peerPhotoUrl: photoUrl,
            ),
          ),
        );
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: _pressed
                ? widget.secondary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _Avatar(
                photoUrl: photoUrl,
                primary: widget.primary,
                card: widget.card,
              ),
              const SizedBox(width: 15),
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
                              fontSize: 15,
                              fontWeight: unread > 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (pinned)
                          Padding(
                            padding: const EdgeInsets.only(left: 5),
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
                                ? 'No messages yet'
                                : lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
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
                        if (unread > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: widget.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
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
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(senderId).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final name = _ChatPageState._readName(data);
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
                await FirebaseFirestore.instance
                    .collection('messageRequests')
                    .doc(requestId)
                    .update({'status': 'accepted'});
              },
              icon: Icon(Icons.check, color: primary, size: 20),
            ),
            IconButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('messageRequests')
                    .doc(requestId)
                    .update({'status': 'rejected'});
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
        color: card,
        border: Border.all(color: primary, width: 1.1),
        image: photoUrl != null && photoUrl!.isNotEmpty
            ? DecorationImage(
          image: NetworkImage(photoUrl!),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: photoUrl == null || photoUrl!.isEmpty
          ? Icon(Icons.person_outline, color: primary, size: 25)
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

  var myName = (me.displayName ?? '').trim();
  if (myName.isEmpty) myName = 'طالب UniSpace';

  final id = directChatId(me.uid, peerId);
  final ref = FirebaseFirestore.instance.collection('chats').doc(id);
  final blockedReason = await chatMessagingBlockedReason(peerId);
  if (blockedReason != null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(blockedReason)),
      );
    }
    return;
  }

  if (await isPeerUnavailable(peerId)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن مراسلة هذا الحساب')),
      );
    }
    return;
  }
  try {
    await ref.set({
      'type': 'direct',
      'memberIds': [me.uid, peerId],
      'members': {
        me.uid: {'name': myName, 'photoUrl': me.photoURL},
        peerId: {'name': peerName, 'photoUrl': peerPhotoUrl},
      },
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  } catch (e) {
    debugPrint('openDirectChat failed: $e');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تعذر فتح المحادثة.')),
    );
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
  final me = FirebaseAuth.instance.currentUser?.uid;
  if (me == null || peerId.isEmpty || peerId == me) return 'غير مسموح';
  try {
    final blocked = await FirebaseFirestore.instance
        .collection('users')
        .doc(me)
        .collection('blocked_accounts')
        .doc(peerId)
        .get();
    final blockedBy = await FirebaseFirestore.instance
        .collection('users')
        .doc(me)
        .collection('blocked_by')
        .doc(peerId)
        .get();
    if (blocked.exists || blockedBy.exists) {
      return 'لا يمكن الإرسال بسبب الحظر';
    }

    final peerDoc =
    await FirebaseFirestore.instance.collection('users').doc(peerId).get();
    final privacy =
    Map<String, dynamic>.from(peerDoc.data()?['privacy'] ?? {});
    final who = (privacy['whoCanMessage'] ?? 'everyone').toString();
    if (who == 'nobody') return 'هذا الحساب لا يستقبل رسائل';
    if (who == 'followers' || who == 'mutual') {
      final iFollow = await FirebaseFirestore.instance
          .collection('users')
          .doc(peerId)
          .collection('followers')
          .doc(me)
          .get();
      if (!iFollow.exists) return 'لا يمكن مراسلة هذا الحساب';
      if (who == 'mutual') {
        final theyFollow = await FirebaseFirestore.instance
            .collection('users')
            .doc(me)
            .collection('followers')
            .doc(peerId)
            .get();
        if (!theyFollow.exists) {
          return 'المراسلة للمتابعين بالتبادل فقط';
        }
      }
    }
  } catch (e) {
    debugPrint('chatMessagingBlockedReason: $e');
  }
  return null;
}

// ==================== شاشة المحادثة (مبنية من الصفر، ستايل انستغرام) ====================

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
  types.Message? _replyTo;
  types.Message? _editing;
  bool _searching = false;
  final _searchCtrl = TextEditingController();
  final _inputCtrl = TextEditingController();
  final _translator = GoogleTranslator();
  bool _sending = false;
  bool _hasText = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _chatSub;
  Timer? _typingIdle;
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
  String _autoTranslateLang = 'ar';
  DateTime? _chatStartedAt;



  static const double _cancelDistance = 90.0;
  static const double _lockDistance = 75.0;
  static const Duration _minimumVoiceDuration =
  Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _voice = VoiceSessionController();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _me = types.User(id: uid, firstName: 'أنا');
    _peer = types.User(
      id: widget.peerId,
      firstName: widget.peerName,
      imageUrl: widget.peerPhotoUrl,
    );

    _inputCtrl.addListener(() {
      final has = _inputCtrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    if (uid.isNotEmpty) {
      unawaited(
        FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set(
          {
            'unread.$uid': 0,
            'lastReadAt.$uid': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        ),
      );
    }
    _chatSub = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .snapshots()
        .listen((doc) {
      if (!mounted) return;
      final data = doc.data() ?? {};
      final map = Map<String, dynamic>.from(data['typing'] ?? {});
      final raw = map[widget.peerId];
      var typing = false;
      if (raw is Timestamp) {
        typing = DateTime.now().difference(raw.toDate()).inSeconds < 4;
      }

      final readRaw = Map<String, dynamic>.from(data['lastReadAt'] ?? {});
      final rr = readRaw[widget.peerId];
      DateTime? peerRead;
      if (rr is Timestamp) peerRead = rr.toDate();

      final mutedMap = Map<String, dynamic>.from(data['muted'] ?? {});
      final clearedRaw = Map<String, dynamic>.from(data['clearedAt'] ?? {});
      final cr = clearedRaw[_me.id];

      setState(() {
        _peerTyping = typing;
        _peerReadAt = peerRead;
        _muted = mutedMap[_me.id] == true;
        final nick = Map<String, dynamic>.from(data['nicknames'] ?? {});
        final themeMap = Map<String, dynamic>.from(data['theme'] ?? {});
        final mineTheme = Map<String, dynamic>.from(themeMap[_me.id] ?? {});
        final autoMap = Map<String, dynamic>.from(data['autoTranslate'] ?? {});
        final langMap = Map<String, dynamic>.from(data['autoTranslateLang'] ?? {});
        final started = data['createdAt'];
        _nickname = (nick[_me.id] ?? '').toString();
        _wallpaper = (mineTheme['wallpaper'] ?? 'default').toString();
        _wallpaperUrl = (mineTheme['wallpaperUrl'] ?? '').toString();
        _bubbleColor = (mineTheme['bubbleColor'] as num?)?.toInt() ?? 0xFF0D9488;
        final rawG = mineTheme['bubbleGradient'];
        if (rawG is List && rawG.length >= 2) {
          _bubbleGradient = rawG
              .map((e) => Color((e as num).toInt()))
              .toList();
        } else {
          _bubbleGradient = null;
        }
        _autoTranslate = autoMap[_me.id] == true;
        _autoTranslateLang = (langMap[_me.id] ?? 'ar').toString();
        _chatStartedAt = started is Timestamp ? started.toDate() : null;
        _clearedAt = cr is Timestamp ? cr.toDate() : null;
      });
    });
    _sub = _msgs.orderBy('createdAt', descending: true).snapshots().listen((snap) {
      if (!mounted) return;
      setState(() => _messages = snap.docs.map(_toMessage).toList());
      if (_me.id.isEmpty) return;
      unawaited(
        FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
          'lastReadAt.${_me.id}': FieldValue.serverTimestamp(),
          'unread.${_me.id}': 0,
        }, SetOptions(merge: true)),
      );
    }, onError: (e) => debugPrint('messages stream error: $e'));

    _peerSub = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.peerId)
        .snapshots()
        .listen((doc) {
      if (!mounted) return;
      final raw = doc.data()?['lastActiveAt'];
      setState(() {
        _peerLastActive = raw is Timestamp ? raw.toDate() : null;
      });
    });

    _touchMyPresence();
  }

  void _touchMyPresence() {
    final uid = _me.id;
    if (uid.isEmpty) return;
    unawaited(
      FirebaseFirestore.instance.collection('users').doc(uid).set({
        'lastActiveAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
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
            const SnackBar(content: Text('التسجيل قصير أو غير صالح')),
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
    _voice.dispose();
    _sub?.cancel();
    _peerSub?.cancel();
    _chatSub?.cancel();
    _typingIdle?.cancel();
    _recordTicker?.cancel();
    _inputCtrl.dispose();
    _searchCtrl.dispose();
    unawaited(_recorder.dispose());
    unawaited(_previewPlayer.dispose());
    _voice.dispose();
    super.dispose();
  }


  Future<void> _toggleMute() async {
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
      'muted.${_me.id}': !_muted,
    }, SetOptions(merge: true));
  }

  Future<void> _clearChat() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مسح المحادثة؟'),
        content: const Text('تُمسح عندك فقط. الطرف الآخر يبقي الرسائل.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('مسح'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
      'clearedAt.${_me.id}': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _onComposerChanged(String _) {
    if (_me.id.isEmpty) return;
    FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
      'typing.${_me.id}': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    _typingIdle?.cancel();
    _typingIdle = Timer(const Duration(seconds: 3), () {
      FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
        'typing.${_me.id}': FieldValue.delete(),
      }, SetOptions(merge: true));
    });
  }

  types.Message _toMessage(QueryDocumentSnapshot<Map<String, dynamic>> d,) {
    final data = d.data();
    final authorId = (data['authorId'] ?? '').toString();
    final created = data['createdAt'];
    final replyText = (data['replyToText'] ?? '').toString();
    final author = authorId == _peer.id ? _peer : types.User(id: authorId);
    final createdAt = created is Timestamp
        ? created.millisecondsSinceEpoch
        : DateTime.now().millisecondsSinceEpoch;
    final meta = <String, dynamic>{
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
      status = seen ? types.Status.seen : types.Status.sent;
    }

    final type = (data['type'] ?? 'text').toString();
    if (type == 'image') {
      return types.ImageMessage(
        id: d.id,
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
        id: d.id,
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
        id: d.id,
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
        id: d.id,
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
        id: d.id,
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
      id: d.id,
      author: author,
      createdAt: createdAt,
      text: (data['text'] ?? '').toString(),
      showStatus: authorId == _me.id,
      status: status,
      metadata: meta,
    );
  }

  List<types.Message> get _visibleMessages {
    final q = _searchCtrl.text.trim().toLowerCase();
    var list = q.isEmpty
        ? List<types.Message>.from(_messages)
        : _messages.where((m) {
      if (m is! types.TextMessage) return false;
      return m.text.toLowerCase().contains(q);
    }).toList();
    if (_clearedAt != null) {
      final cut = _clearedAt!.millisecondsSinceEpoch;
      list = list.where((m) => (m.createdAt ?? 0) > cut).toList();
    }
    return list;
  }

  void _stopSearch() {
    _searchCtrl.clear();
    setState(() => _searching = false);
  }


  Future<void> _sendKeyboardImage({required Uint8List bytes, required String mimeType,}) async {
    if (_me.id.isEmpty || _sending) return;

    final reason = await chatMessagingBlockedReason(widget.peerId);
    if (reason != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reason)));
      return;
    }

    final isGif = mimeType.toLowerCase().contains('gif');
    setState(() => _sending = true);

    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final ext = isGif ? 'gif' : 'jpg';
      final contentType = isGif ? 'image/gif' : (mimeType.isEmpty ? 'image/jpeg' : mimeType);

      final ref = FirebaseStorage.instance
          .ref()
          .child('chats/${widget.chatId}/images/$id.$ext');

      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      final url = await ref.getDownloadURL();

      await _msgs.add({
        'authorId': _me.id,
        'type': isGif ? 'gif' : 'image',
        if (isGif) 'gifUrl': url else 'imageUrl': url,
        'size': bytes.length,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
        'lastMessage': isGif ? 'GIF' : '📷 صورة',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': _me.id,
        'unread.${widget.peerId}': FieldValue.increment(1),
      }, SetOptions(merge: true));

      _touchMyPresence();
    } catch (e) {
      debugPrint('keyboard image failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إرسال الصورة: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
  Future<void> _uploadVoice(File file, {required Duration duration,}) async {
    try {
      if (!mounted) return;

      setState(() {
        _sending = true;
        _voiceState = VoiceRecordingState.sending;
      });

      final id = DateTime.now()
          .millisecondsSinceEpoch
          .toString();

      final ref = FirebaseStorage.instance
          .ref()
          .child('chats/${widget.chatId}/audio/$id.m4a');

      await ref.putFile(
        file,
        SettableMetadata(
          contentType: 'audio/mp4',
        ),
      );

      final url = await ref.getDownloadURL();
      final size = await file.length();

      await _msgs.add({
        'authorId': _me.id,
        'type': 'audio',
        'audioUrl': url,
        'size': size,
        'durationMs': duration.inMilliseconds,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .set(
        {
          'lastMessage': '🎤 رسالة صوتية',
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastSenderId': _me.id,
          'unread.${widget.peerId}':
          FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );

      _touchMyPresence();
    } catch (error, stackTrace) {
      debugPrint('uploadVoice failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر إرسال التسجيل: $error'),
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
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
  }

  Future<void> _send(String raw) async {
    final t = raw.trim();
    if (t.isEmpty || _me.id.isEmpty || _sending) return;
    final reason = await chatMessagingBlockedReason(widget.peerId);
    if (reason != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reason)));
      return;
    }
    if (_editing != null) {
      await _commitEdit(t);
      return;
    }
    setState(() => _sending = true);
    final reply = _replyTo;
    _inputCtrl.clear();
    setState(() => _replyTo = null);
    try {
      await _msgs.add({
        'authorId': _me.id,
        'text': t,
        'type': 'text',
        'createdAt': FieldValue.serverTimestamp(),
        if (reply != null) 'replyToId': reply.id,
        if (reply != null)
          'replyToText': reply is types.TextMessage ? reply.text : '',
        if (reply != null) 'replyToAuthorId': reply.author.id,
        if (reply != null)
          'replyToName': reply.author.id == _peer.id
              ? (widget.peerName ?? 'طالب')
              : 'أنت',
      });
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'lastMessage': t,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': _me.id,
        'unread.${widget.peerId}': FieldValue.increment(1),
      });
      final short = t.length > 70 ? '${t.substring(0, 70)}…' : t;
      final peerMuted = Map<String, dynamic>.from(
        (await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatId)
            .get())
            .data()?['muted'] ??
            {},
      )[widget.peerId] ==
          true;
      if (!peerMuted) {
        unawaited(pushNotification(
          toUid: widget.peerId,
          type: 'message',
          actorName: (FirebaseAuth.instance.currentUser?.displayName ?? '')
              .trim()
              .isEmpty
              ? 'طالب UniSpace'
              : FirebaseAuth.instance.currentUser!.displayName!,
          actorPhotoUrl: FirebaseAuth.instance.currentUser?.photoURL,
          message: short,
          chatId: widget.chatId,
          docId: 'chat_${widget.chatId}',
        ));
      }
      _touchMyPresence();
      unawaited(
        FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
          'typing.${_me.id}': FieldValue.delete(),
        }, SetOptions(merge: true)),
      );
    } catch (e) {
      debugPrint('send failed: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _downloadMedia(types.Message m) async {
    String? url;
    var name = 'media';
    if (m is types.ImageMessage) {
      url = m.uri;
      name = 'img_${m.id}.jpg';
    } else if (m is types.VideoMessage) {
      url = m.uri;
      name = 'vid_${m.id}.mp4';
    } else if (m is types.AudioMessage) {
      url = m.uri;
      name = 'aud_${m.id}.m4a';
    } else if (m is types.FileMessage) {
      url = m.uri;
      name = m.name.isEmpty ? 'file_${m.id}' : m.name;
    }
    if (url == null || url.isEmpty) return;

    try {
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse(url));
      final res = await req.close();
      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }
      final bytes = await consolidateHttpClientResponseBytes(res);
      client.close();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم التحميل')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر التحميل: $e')),
      );
    }
  }

  Future<void> _showActions(types.Message message, BuildContext bubbleContext) async {
    final mine = message.author.id == _me.id;
    final text = message is types.TextMessage ? message.text : '';
    final isText = message is types.TextMessage;
    final starred = message.metadata?['starred'] == true;
    final preview = text.isEmpty
        ? (message is types.ImageMessage
        ? '📷 صورة'
        : message is types.VideoMessage
        ? '🎬 فيديو'
        : message is types.AudioMessage
        ? '🎤 رسالة صوتية'
        : 'رسالة')
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
      barrierLabel: 'message_actions',
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (_, __, ___) => _PinnedMessageActionsOverlay(
        rect: rect,
        message: message,
        preview: preview,
        isMine: mine,
        starred: starred,
        isText: isText,
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
          const SnackBar(content: Text('تم النسخ')),
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
    try {
      types.Message? msg;
      for (final m in _messages) {
        if (m.id == id) {
          msg = m;
          break;
        }
      }

      final raw = Map<String, dynamic>.from(msg?.metadata?['reactions'] ?? {});
      final mine = <String>[];
      final existing = raw[_me.id];
      if (existing is List) {
        mine.addAll(existing.map((e) => e.toString()));
      } else if (existing != null && existing.toString().isNotEmpty) {
        mine.add(existing.toString());
      }

      if (mine.contains(emoji)) {
        mine.remove(emoji);
      } else {
        mine.add(emoji);
      }

      await _msgs.doc(id).update({
        'reactions.${_me.id}': mine.isEmpty ? FieldValue.delete() : mine,
      });
    } catch (e) {
      debugPrint('react failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حفظ التفاعل: $e')),
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
      _inputCtrl.clear();
      _hasText = false;
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
      await _msgs.doc(msg.id).update({
        'text': text.trim(),
        'editedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      _cancelEdit();
    } catch (e) {
      debugPrint('edit failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تعديل الرسالة')),
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

  void _showInfo(types.Message message) {
    final created = message.createdAt == null
        ? '—'
        : DateTime.fromMillisecondsSinceEpoch(message.createdAt!).toLocal().toString();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('معلومات الرسالة',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 12),
            Text('أُرسلت: $created'),
            if (message.metadata?['edited'] == true)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('تم التعديل'),
              ),
          ],
        ),
      ),
    );
  }



  Future<void> _delete(String id) async {
    try {
      await _msgs.doc(id).delete();
    } catch (e) {
      debugPrint('delete failed: $e');
    }
  }

  void _openPeerProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          userId: widget.peerId,
          initialName: widget.peerName,
          initialPhotoUrl: widget.peerPhotoUrl,
        ),
      ),
    );
  }

  void _openImageFullscreen(String url) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _ChatFullscreenImage(url: url),
      ),
    );
  }

  void _openVideoFullscreen(String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _ChatFullscreenVideo(url: url),
      ),
    );
  }


  Future<void> _openCamera() async {
    if (_me.id.isEmpty || _sending) return;

    final reason = await chatMessagingBlockedReason(widget.peerId);
    if (reason != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reason)));
      return;
    }

    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null) return;

    await _uploadAndSendImage(picked);
  }

  Future<void> _uploadAndSendImage(XFile picked) async {
    setState(() => _sending = true);
    try {
      final bytes = await picked.readAsBytes();
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance
          .ref()
          .child('chats/${widget.chatId}/images/$id.jpg');

      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();

      await _msgs.add({
        'authorId': _me.id,
        'type': 'image',
        'imageUrl': url,
        'size': bytes.length,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
        'lastMessage': '📷 صورة',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': _me.id,
        'unread.${widget.peerId}': FieldValue.increment(1),
      }, SetOptions(merge: true));

      _touchMyPresence();
    } catch (e, st) {
      debugPrint('send image failed: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إرسال الصورة: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickVideo() async {
    if (_me.id.isEmpty || _sending) return;

    final reason = await chatMessagingBlockedReason(widget.peerId);
    if (reason != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reason)));
      return;
    }

    final picked = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );
    if (picked == null) return;

    setState(() => _sending = true);
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final file = File(picked.path);
      final ref = FirebaseStorage.instance
          .ref()
          .child('chats/${widget.chatId}/videos/$id.mp4');

      if (await file.exists()) {
        await ref.putFile(file, SettableMetadata(contentType: 'video/mp4'));
      } else {
        final bytes = await picked.readAsBytes();
        await ref.putData(bytes, SettableMetadata(contentType: 'video/mp4'));
      }

      final url = await ref.getDownloadURL();
      final size = await picked.length();

      await _msgs.add({
        'authorId': _me.id,
        'type': 'video',
        'videoUrl': url,
        'size': size,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
        'lastMessage': '🎬 فيديو',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': _me.id,
        'unread.${widget.peerId}': FieldValue.increment(1),
      }, SetOptions(merge: true));

      _touchMyPresence();
    } catch (e, st) {
      debugPrint('send video failed: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إرسال الفيديو: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickFile() async {
    if (_me.id.isEmpty || _sending) return;

    final reason = await chatMessagingBlockedReason(widget.peerId);
    if (reason != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reason)));
      return;
    }

    // يتطلب: file_picker في pubspec.yaml
    // file_picker: ^8.0.0
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر قراءة الملف')),
      );
      return;
    }

    // حد أقصى ~20MB
    if (bytes.length > 20 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حجم الملف كبير جداً (الحد 20MB)')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final name = (file.name).trim().isEmpty ? 'file' : file.name;
      final safeName = name.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      final ref = FirebaseStorage.instance
          .ref()
          .child('chats/${widget.chatId}/files/$id\_$safeName');

      await ref.putData(
        bytes,
        SettableMetadata(
          contentType: file.extension != null
              ? 'application/octet-stream'
              : 'application/octet-stream',
          customMetadata: {'originalName': name},
        ),
      );
      final url = await ref.getDownloadURL();

      await _msgs.add({
        'authorId': _me.id,
        'type': 'file',
        'fileUrl': url,
        'fileName': name,
        'size': bytes.length,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
        'lastMessage': '📎 $name',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': _me.id,
        'unread.${widget.peerId}': FieldValue.increment(1),
      }, SetOptions(merge: true));

      _touchMyPresence();
    } catch (e, st) {
      debugPrint('send file failed: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إرسال الملف: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
  Future<void> _openWhatsAppGallery() async {
    if (_me.id.isEmpty || _sending) return;

    final reason = await chatMessagingBlockedReason(widget.peerId);
    if (reason != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reason)));
      return;
    }

    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        pageBuilder: (ctx, __, ___) => _WhatsAppGalleryPage(
          onOpenCamera: () async {
            Navigator.of(ctx).pop();
            final shot = await ImagePicker().pickImage(
              source: ImageSource.camera,
              imageQuality: 88,
            );
            if (shot == null || !mounted) return;
            await _uploadAndSendImage(shot);
          },
          onSend: (files, caption) async {
            for (final file in files) {
              final path = file.path.toLowerCase();
              final isVideo = path.endsWith('.mp4') ||
                  path.endsWith('.mov') ||
                  path.endsWith('.m4v');
              if (isVideo) {
                setState(() => _sending = true);
                try {
                  final id = DateTime.now().millisecondsSinceEpoch.toString();
                  final ref = FirebaseStorage.instance
                      .ref()
                      .child('chats/${widget.chatId}/videos/$id.mp4');
                  await ref.putFile(
                    file,
                    SettableMetadata(contentType: 'video/mp4'),
                  );
                  final url = await ref.getDownloadURL();
                  final size = await file.length();
                  await _msgs.add({
                    'authorId': _me.id,
                    'type': 'video',
                    'videoUrl': url,
                    'size': size,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  await FirebaseFirestore.instance
                      .collection('chats')
                      .doc(widget.chatId)
                      .set({
                    'lastMessage': '🎬 فيديو',
                    'lastMessageAt': FieldValue.serverTimestamp(),
                    'lastSenderId': _me.id,
                    'unread.${widget.peerId}': FieldValue.increment(1),
                  }, SetOptions(merge: true));
                  _touchMyPresence();
                } finally {
                  if (mounted) setState(() => _sending = false);
                }
              } else {
                await _uploadAndSendImage(XFile(file.path));
              }
            }
            final t = caption.trim();
            if (t.isNotEmpty) await _send(t);
          },
        ),
      ),
    );
  }
  Future<void> _insertLink() async {
    if (_me.id.isEmpty || _sending) return;

    final controller = TextEditingController();
    final link = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('إدراج رابط'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              hintText: 'https://...',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) {
              final t = v.trim();
              if (t.isNotEmpty) Navigator.pop(ctx, t);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final t = controller.text.trim();
                if (t.isNotEmpty) Navigator.pop(ctx, t);
              },
              child: const Text('إرسال'),
            ),
          ],
        );
      },
    );

    if (link == null || link.isEmpty) return;

    // نرسله كرسالة نصية (يمكن لاحقاً تمييز type: link)
    var url = link;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    await _send(url);
  }




  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final messages = _visibleMessages;

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: _chatWallpaperColor(_wallpaper, isDark),
      appBar: AppBar(
        backgroundColor: _wallpaper == 'photo' && _wallpaperUrl.isNotEmpty
            ? Colors.black.withValues(alpha: 0.25)
            : _chatWallpaperColor(_wallpaper, isDark).withValues(alpha: 0.92),
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
              : messages.length,
          onChanged: () => setState(() {}),
          onClear: () {
            _searchCtrl.clear();
            setState(() {});
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
                    ? const Icon(Icons.person_outline, size: 18)
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
                          : (widget.peerName ?? 'محادثة'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                      ),
                    ),
                    if (_peerTyping)
                      Text(
                        'يكتب الآن…',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTeal.main,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else if (_peerLastActive != null)
                      Text(
                        DateTime.now()
                            .difference(_peerLastActive!)
                            .inMinutes <
                            3
                            ? 'متصل الآن'
                            : 'آخر ظهور ${_chatTimeAgo(_peerLastActive)}',
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
              tooltip: 'بحث',
              icon: const Icon(Icons.search_rounded),
              onPressed: () => setState(() => _searching = true),
            ),
            IconButton(
              tooltip: 'المزيد',
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _ChatDetailsPage(
                    chatId: widget.chatId,
                    peerId: widget.peerId,
                    peerName: widget.peerName ?? 'محادثة',
                    peerPhotoUrl: widget.peerPhotoUrl,
                    muted: _muted,
                    nickname: _nickname,
                    wallpaper: _wallpaper,
                    bubbleColor: _bubbleColor,
                    autoTranslate: _autoTranslate,
                    autoTranslateLang: _autoTranslateLang,
                    startedAt: _chatStartedAt,
                    messages: _messages,
                    onSearch: () {
                      Navigator.pop(context);
                      setState(() => _searching = true);
                    },
                    onOpenProfile: _openPeerProfile,
                    onToggleMute: _toggleMute,
                    onClear: _clearChat,
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
      body: DecoratedBox(
          decoration: chatWallpaperDecoration(
            id: _wallpaper,
            url: _wallpaperUrl,
            isDark: isDark,
          ),
          child: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
              child: Text(
                'لا توجد رسائل بعد',
                style: TextStyle(color: theme.hintColor),
              ),
            )
                : ListView.builder(
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

                return Padding(
                  padding: EdgeInsets.only(
                    top: sameGroupAsOlder ? 3 : 12,
                  ),
                  child: Align(
                    alignment: mine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: _SwipeToReply(
                      mine: mine,
                      onReply: () {
                        HapticFeedback.mediumImpact();
                        setState(() => _replyTo = message);
                      },
                      child: _MessageBubbleTile(
                        message: message,
                        mine: mine,
                        isLastOverall: isLastOverall,
                        peerReadAt: _peerReadAt,
                        onTapImage: _openImageFullscreen,
                        onTapVideo: _openVideoFullscreen,
                        onLongPress: (ctx) => _showActions(message, ctx),
                        onDoubleTap: () => _quickReact(message),
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
                );
              },
            ),
          ),
          if (_peerTyping)
            Padding(
              padding: const EdgeInsets.only(right: 14, bottom: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: _TypingBubble(isDark: isDark),
              ),
            ),
          InstagramComposer(
            controller: _inputCtrl,
            replyTo: _replyTo,
            peerName: widget.peerName ?? '',
            sending: _sending,
            hasText: _hasText,
            voice: _voice,
            onSendVoice: (file, duration) => _uploadVoice(file, duration: duration),
            onBeforeStart: () async {
              final reason = await chatMessagingBlockedReason(widget.peerId);
              if (reason != null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reason)));
                }
                return false;
              }
              return true;
            },
            onStartFailed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('يلزم السماح بالميكروفون')),
              );
            },

            onCancelReply: () => setState(() => _replyTo = null),
            onSend: _send,
            onChanged: _onComposerChanged,

            onSendMedia: (files, caption) async {
              for (final file in files) {
                final path = file.path.toLowerCase();
                final isVideo = path.endsWith('.mp4') ||
                    path.endsWith('.mov') ||
                    path.endsWith('.m4v');
                if (isVideo) {
                  // نفس منطق الفيديو عندك في _openWhatsAppGallery
                } else {
                  await _uploadAndSendImage(XFile(file.path));
                }
              }
              final t = caption.trim();
              if (t.isNotEmpty) await _send(t);
            },
            onPickImage: () => unawaited(_openWhatsAppGallery()),
            onPickVideo: () => unawaited(_pickVideo()),
            onPickFile: () => unawaited(_pickFile()),
            onOpenCamera: () => unawaited(_openCamera()),
            onInsertLink: () => unawaited(_insertLink()),

            onContentInserted: (c) async {
              final data = c.data;
              if (data == null || data.isEmpty) return;
              await _sendKeyboardImage(bytes: data, mimeType: c.mimeType);
            },
          ),


        ],
      )
        ),
    );
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
            checkPlatformCompatibility: true,
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
              noRecents: const Center(
                child: Text(
                  'لا توجد رموز مستخدمة مؤخرًا',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),

            categoryViewConfig: CategoryViewConfig(
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
              hintText: 'ابحث عن إيموجي',
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
                    'ابحث عن إيموجي',
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
              textDirection: TextDirection.rtl,
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
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      cursorColor: AppTeal.main,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                      onChanged: (_) => onChanged(),
                      decoration: InputDecoration(
                        hintText: 'ابحث في المحادثة',
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
                      tooltip: 'مسح البحث',
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
    required this.message,
    required this.mine,
    required this.isLastOverall,
    required this.peerReadAt,
    required this.onTapImage,
    required this.onTapVideo,
    required this.onLongPress,
    required this.onDoubleTap,
    this.accent,
    this.accentGradient,
  });

  final types.Message message;
  final bool mine;
  final bool isLastOverall;
  final DateTime? peerReadAt;
  final ValueChanged<String> onTapImage;
  final ValueChanged<String> onTapVideo;
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
    final period = dt.hour >= 12 ? 'م' : 'ص';
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

    for (final v in reactions.values) {
      if (v is List) {
        for (final e in v) {
          addOne(e.toString());
        }
      } else {
        addOne(v.toString());
      }
    }

    final bubbleColor = mine
        ? (widget.accent ?? AppTeal.main)
        : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF0F0F0));
    final bubbleGradient = mine ? widget.accentGradient : null;
    final textColor =
    mine ? Colors.white : (isDark ? Colors.white : Colors.black);

    Widget content;
    if (message is types.ImageMessage) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          message.uri,
          width: 200,
          height: 240,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 200,
            height: 240,
            color: Colors.grey.shade300,
            child: const Icon(Icons.broken_image_outlined),
          ),
        ),
      );
    } else if (message is types.VideoMessage) {
      content = _ChatVideoThumb(url: message.uri);
    } else if (message is types.AudioMessage) {
      content = _ChatAudioPlayer(
        url: message.uri,
        mine: mine,
        totalDuration: message.duration,
      );
    } else if (message is types.TextMessage) {
      content = Text(
        message.text,
        style: TextStyle(color: textColor, fontSize: 15.5, height: 1.35),
      );
    } else {
      content = const SizedBox.shrink();
    }

    final isMedia =
        message is types.ImageMessage || message is types.VideoMessage;
    final hasReactions = counts.isNotEmpty;

    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: isMedia
          ? const EdgeInsets.all(3)
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMedia
            ? Colors.transparent
            : (bubbleGradient == null ? bubbleColor : null),
        gradient: isMedia ? null : bubbleGradient,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(mine ? 18 : 4),
          bottomRight: Radius.circular(mine ? 4 : 18),
        ),
        boxShadow: isMedia
            ? null
            : [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
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
                        TextStyle(fontSize: 12, color: theme.hintColor),
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
    if (widget.isLastOverall && mine) {
      final read = widget.peerReadAt != null &&
          (message.createdAt ?? 0) <=
              widget.peerReadAt!.millisecondsSinceEpoch;
      statusRow = Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              read ? 'شوهدت' : 'تم الإرسال',
              style: TextStyle(fontSize: 10.5, color: theme.hintColor),
            ),
            const SizedBox(width: 3),
            Icon(
              read ? Icons.done_all_rounded : Icons.done_rounded,
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
              'معدل',
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
                if (message is types.ImageMessage) {
                  widget.onTapImage(message.uri);
                } else if (message is types.VideoMessage) {
                  widget.onTapVideo(message.uri);
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
              'تم التعديل',
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

class _ChatVideoThumb extends StatefulWidget {
  const _ChatVideoThumb({required this.url});
  final String url;

  @override
  State<_ChatVideoThumb> createState() => _ChatVideoThumbState();
}

class _ChatVideoThumbState extends State<_ChatVideoThumb> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await c.initialize();
      await c.setVolume(0);
      await c.pause();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() => _controller = c);
    } catch (e) {
      debugPrint('video thumb init failed: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 200,
        height: 240,
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (c != null && c.value.isInitialized)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: c.value.size.width,
                  height: c.value.size.height,
                  child: VideoPlayer(c),
                ),
              )
            else
              const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatFullscreenVideo extends StatefulWidget {
  const _ChatFullscreenVideo({required this.url});
  final String url;

  @override
  State<_ChatFullscreenVideo> createState() => _ChatFullscreenVideoState();
}

class _ChatFullscreenVideoState extends State<_ChatFullscreenVideo> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    await c.initialize();
    await c.setVolume(1);
    await c.play();
    if (!mounted) {
      await c.dispose();
      return;
    }
    setState(() => _controller = c);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: c == null || !c.value.isInitialized
            ? const CircularProgressIndicator(color: Colors.white)
            : AspectRatio(
          aspectRatio: c.value.aspectRatio,
          child: GestureDetector(
            onTap: () => setState(() {
              c.value.isPlaying ? c.pause() : c.play();
            }),
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(c),
                if (!c.value.isPlaying)
                  const Icon(Icons.play_arrow_rounded, color: Colors.white70, size: 64),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatFullscreenImage extends StatelessWidget {
  const _ChatFullscreenImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.network(url, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== مشغّل صوتي داخل البابل ====================

class _ChatAudioPlayer extends StatefulWidget {
  const _ChatAudioPlayer({
    required this.url,
    required this.mine,
    required this.totalDuration,
  });

  final String url;
  final bool mine;
  final Duration totalDuration;

  @override
  State<_ChatAudioPlayer> createState() => _ChatAudioPlayerState();
}

class _ChatAudioPlayerState extends State<_ChatAudioPlayer> {
  VideoPlayerController? _controller;
  bool _loading = false;
  double _speed = 1.0;
  static const List<double> _speeds = [1.0, 1.5, 2.0];

  // عدد أعمدة الموجة الصوتية
  static const int _barCount = 32;
  late final List<double> _waveform = _generateWaveform(widget.url, _barCount);

  // توليد موجة ثابتة (نفس الشكل دايمًا لنفس الرابط) بدل تحليل الملف فعليًا
  static List<double> _generateWaveform(String seed, int count) {
    final rnd = Random(seed.hashCode);
    return List.generate(count, (i) {
      // نمزج قيمة عشوائية مع منحنى ناعم باش يبان طبيعي وماشي عشوائي بحت
      final base = 0.35 + rnd.nextDouble() * 0.65;
      final envelope = sin((i / count) * pi); // يخلي الأطراف أقصر من الوسط
      return (base * (0.5 + envelope * 0.5)).clamp(0.18, 1.0);
    });
  }

  Future<void> _ensureLoaded() async {
    if (_controller != null) return;
    setState(() => _loading = true);
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await c.initialize();
      await c.setPlaybackSpeed(_speed);
      c.addListener(_onTick);
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _loading = false;
      });
    } catch (e) {
      debugPrint('audio init failed: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  Future<void> _togglePlay() async {
    await _ensureLoaded();
    final c = _controller;
    if (c == null) return;
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      if (c.value.position >= c.value.duration) {
        await c.seekTo(Duration.zero);
      }
      await c.play();
    }
    setState(() {});
  }

  Future<void> _seekToRatio(double ratio) async {
    await _ensureLoaded();
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final duration = c.value.duration;
    if (duration.inMilliseconds <= 0) return;
    await c.seekTo(duration * ratio.clamp(0.0, 1.0));
    setState(() {});
  }

  Future<void> _cycleSpeed() async {
    final currentIndex = _speeds.indexOf(_speed);
    final next = _speeds[(currentIndex + 1) % _speeds.length];
    setState(() => _speed = next);
    final c = _controller;
    if (c != null && c.value.isInitialized) {
      await c.setPlaybackSpeed(next);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final c = _controller;
    final isPlaying = c?.value.isPlaying ?? false;
    final position = c?.value.position ?? Duration.zero;
    final duration = (c?.value.duration.inMilliseconds ?? 0) > 0
        ? c!.value.duration
        : widget.totalDuration;
    final ratio = duration.inMilliseconds == 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

    // ألوان تتكيف مع فقاعة "أنا" (ملوّنة) أو فقاعة الطرف الآخر
    final Color fg = widget.mine
        ? Colors.white
        : (isDark ? Colors.white : Colors.black87);
    final Color playedColor = widget.mine
        ? Colors.white
        : theme.colorScheme.primary;
    final Color unplayedColor = fg.withValues(alpha: widget.mine ? 0.35 : 0.22);
    final Color buttonBg = widget.mine
        ? Colors.white.withValues(alpha: 0.22)
        : theme.colorScheme.primary.withValues(alpha: 0.12);

    final displayedPosition =
    duration.inMilliseconds > 0 ? position : Duration.zero;
    final timeLabel =
    isPlaying || position.inMilliseconds > 0 ? displayedPosition : duration;

    return Container(
    height: 42,
      width: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ===== زر التشغيل الدائري =====
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: buttonBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _loading
                    ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fg,
                  ),
                )
                    : Icon(
                  isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: fg,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ===== الموجة الصوتية + الوقت =====
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(padding: EdgeInsetsGeometry.only(top: 0),child:
                SizedBox(
                  height: 26,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) {
                          final r =
                          (details.localPosition.dx / constraints.maxWidth)
                              .clamp(0.0, 1.0);
                          _seekToRatio(r);
                        },
                        onHorizontalDragUpdate: (details) {
                          final r =
                          (details.localPosition.dx / constraints.maxWidth)
                              .clamp(0.0, 1.0);
                          _seekToRatio(r);
                        },
                        child: CustomPaint(
                          size: Size(constraints.maxWidth, 26),
                          painter: _WaveformPainter(
                            bars: _waveform,
                            progress: ratio,
                            playedColor: playedColor,
                            unplayedColor: unplayedColor,
                          ),
                        ),
                      );
                    },
                  ),
                )),
                const SizedBox(height: 0),
                Row(
                  children: [
                    Text(
                      _fmt(timeLabel),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: fg.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // ===== زر تغيير السرعة =====
          GestureDetector(
            onTap: _cycleSpeed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: buttonBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_speed == _speed.roundToDouble() ? _speed.toInt() : _speed}x',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// رسّام الموجة الصوتية: أعمدة بارتفاعات متفاوتة، تتلون حسب التقدم
class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.bars,
    required this.progress,
    required this.playedColor,
    required this.unplayedColor,
  });

  final List<double> bars;
  final double progress; // 0..1
  final Color playedColor;
  final Color unplayedColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;

    final barCount = bars.length;
    const gapRatio = 0.35; // نسبة الفراغ بين الأعمدة
    final totalWidth = size.width;
    final barWidth = totalWidth / (barCount + (barCount - 1) * gapRatio);
    final gap = barWidth * gapRatio;

    final playedBars = (progress * barCount).floor();
    final partial = (progress * barCount) - playedBars;

    for (var i = 0; i < barCount; i++) {
      final x = i * (barWidth + gap);
      final barHeight = bars[i] * size.height;
      final top = (size.height - barHeight) / 2;

      Color color;
      if (i < playedBars) {
        color = playedColor;
      } else if (i == playedBars && partial > 0) {
        color = Color.lerp(unplayedColor, playedColor, partial) ?? unplayedColor;
      } else {
        color = unplayedColor;
      }

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.playedColor != playedColor ||
        oldDelegate.unplayedColor != unplayedColor;
  }
}





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
    this.peerName = '',
    this.onContentInserted,
    this.onPickImage,
    this.onPickVideo,
    this.onPickFile,
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
  final String peerName;
  final Future<void> Function(KeyboardInsertedContent content)? onContentInserted;
  final VoidCallback? onPickImage;
  final VoidCallback? onPickVideo;
  final VoidCallback? onPickFile;
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
  void _showAttachmentSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.46,
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
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('الموقع قريبًا')),
                );
              },
              onContact: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('جهات الاتصال قريبًا')),
                );
              },
              onPoll: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('الاستطلاع قريبًا')),
                );
              },
              onEvent: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('الحدث قريبًا')),
                );
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
    final bg = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);

    return Material(
      color: bg,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.replyTo != null)
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
    );
  }

  Widget _textField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final field = isDark ? const Color(0xFF262626) : Colors.white;
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
        hintText: 'Message...',
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
        prefixIcon:
        Icon(Icons.emoji_emotions_outlined, size: 22, color: muted),
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
                            ? 'إلغاء'
                            : ready
                            ? 'أفلت للقفل'
                            : 'لأعلى للقفل',
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
                label: paused ? 'متابعة التسجيل' : 'إيقاف مؤقت',
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
                label: 'حذف التسجيل',
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
              ? 'أفلت للإرسال · يسار للإلغاء · أعلى للقفل'
              : paused
              ? 'متوقف — اضغط المايك لمتابعة نفس التسجيل'
              : locked
              ? 'مقفل — يمكنك رفع إصبعك'
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
                ? 'استئناف التسجيل'
                : 'إيقاف مؤقت',
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
                isPlaying ? 'جاري التشغيل' : 'تشغيل التسجيل',
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
        : 'وسائط';

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
                  'Replying to $peerName',
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
                  text.isEmpty ? 'Media' : text,
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
                            hintText: 'Search',
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
                      'Your reactions',
                      style: TextStyle(
                        color: primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Customize',
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
                    'Recent',
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
                'Swipe up for filters',
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
                              Text('Camera',
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
                              Text('Gallery',
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
                                  hintText: 'Add a caption...',
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
  final _captionCtrl = TextEditingController();
  final List<AssetEntity> _assets = [];
  final List<AssetEntity> _selected = [];
  final Map<String, File> _edited = {};

  AssetPathEntity? _album;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _sending = false;
  double _extent = 0.46;

  /// 0 = ورقة صغيرة (الأزرار) ، 1 = شاشة كاملة (المعرض)
  double get _t {
    const minE = 0.46;
    const maxE = 0.90;
    final raw = ((_extent - minE) / (maxE - minE)).clamp(0.0, 1.0);
    return Curves.easeInOutCubic.transform(raw);
  }

  @override
  void initState() {
    super.initState();
    _boot();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _captionCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    final c = widget.scrollController;
    if (!c.hasClients || !_hasMore || _loadingMore) return;
    if (c.position.pixels > c.position.maxScrollExtent - 500) {
      _loadMore();
    }
  }

  Future<void> _boot() async {
    try {
      final perm = await PhotoManager.requestPermissionExtend();
      if (!perm.hasAccess) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final filter = FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
        videoOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
      );

      final paths = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        onlyAll: true,
        filterOption: filter,
      );
      if (paths.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      _album = paths.first;
      await _loadMore(reset: true);
    } catch (e) {
      debugPrint('attach recents failed: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore({bool reset = false}) async {
    final album = _album;
    if (album == null) return;
    if (_loadingMore) return;
    _loadingMore = true;

    try {
      if (reset) _assets.clear();
      final start = _assets.length;
      final next = await album.getAssetListRange(
        start: start,
        end: start + 80,
      );
      if (!mounted) return;
      setState(() {
        _assets.addAll(next);
        _hasMore = next.length >= 80;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      debugPrint('load more failed: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _toggle(AssetEntity asset) {
    setState(() {
      final i = _selected.indexWhere((e) => e.id == asset.id);
      if (i >= 0) {
        _selected.removeAt(i);
      } else {
        _selected.add(asset);
      }
    });
  }

  int _selIndex(AssetEntity a) =>
      _selected.indexWhere((e) => e.id == a.id);

  Future<void> _openEditor() async {
    if (_selected.isEmpty) return;

    final files = <File>[];
    for (final a in _selected) {
      final edited = _edited[a.id];
      if (edited != null) {
        files.add(edited);
        continue;
      }
      final f = await a.file;
      if (f != null) files.add(f);
    }
    if (files.isEmpty || !mounted) return;

    final result = await Navigator.of(context).push<_EditorResult>(
      MaterialPageRoute(
        builder: (_) => _WhatsAppImageEditorPage(
          files: files,
          initialIndex: files.length - 1,
          caption: _captionCtrl.text,
        ),
      ),
    );
    if (result == null) return;

    _captionCtrl.text = result.caption;
    for (var i = 0; i < _selected.length && i < result.files.length; i++) {
      _edited[_selected[i].id] = result.files[i];
    }
    setState(() {});

    if (result.send) await _send();
  }

  Future<void> _send() async {
    if (_selected.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final files = <File>[];
      for (final a in _selected) {
        files.add(_edited[a.id] ?? (await a.file)!);
      }
      await widget.onSend(files, _captionCtrl.text);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final t = _t;
    final inv = 1.0 - t;

    final sheet = Color.lerp(
      isDark ? const Color(0xFF1C1C1E) : Colors.white,
      isDark ? const Color(0xFF111111) : Colors.white,
      t,
    )!;
    final pill = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final label = isDark ? Colors.white70 : const Color(0xFF3C3C43);
    final handle = isDark ? Colors.white24 : const Color(0xFFC7C7CC);

    final actions = <_AttachAction>[
      _AttachAction('Gallery', Icons.photo_outlined, const Color(0xFF3478F6), () {}),
      _AttachAction('Location', Icons.location_on_rounded, const Color(0xFF34C759), widget.onLocation),
      _AttachAction('Document', Icons.insert_drive_file_rounded, const Color(0xFFAF52DE), widget.onDocument),
      _AttachAction('Poll', Icons.poll_rounded, const Color(0xFFFF9F0A), widget.onPoll),

    ];

    final radius = 22.0 * inv;

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (n) {
        if ((_extent - n.extent).abs() > 0.002) {
          setState(() => _extent = n.extent);
        }
        return false;
      },
      child: Material(
        color: sheet,
        elevation: 12 * inv,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Transform.scale(
              scale: 1.0 + (0.15 * t),
              child: Container(
                width: 36 + (8 * t),
                height: 4,
                decoration: BoxDecoration(
                  color: handle,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            // رأس Recents يظهر تدريجيًا
            ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: t,
                child: Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, 12 * inv),
                    child: SizedBox(
                      height: 48,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                          ),
                          const Expanded(
                            child: Center(
                              child: Text(
                                'Recents',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFF111111)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'HD',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // شبكة الأزرار تختفي وتنكمش سينمائيًا
            ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: inv,
                child: Opacity(
                  opacity: (1.0 - t * 1.35).clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, -18 * t),
                    child: Transform.scale(
                      scale: 1.0 - (0.06 * t),
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: actions.length,
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 8,
                            mainAxisExtent: 84,
                          ),
                          itemBuilder: (_, i) {
                            final a = actions[i];
                            return GestureDetector(
                              onTap: a.label == 'Gallery' ? null : a.onTap,
                              behavior: HitTestBehavior.opaque,
                              child: Column(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: pill,
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.08)
                                            : const Color(0xFFE5E5EA),
                                      ),
                                    ),
                                    child: Icon(a.icon, color: a.color, size: 24),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    a.label,
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
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // شبكة كل الصور — تكبر مع السحب
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                controller: widget.scrollController,
                padding: EdgeInsets.fromLTRB(2 * t, 0, 2 * t, 8),
                itemCount: _assets.length + 1,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 1.5 + (4.5 * inv),
                  crossAxisSpacing: 1.5 + (4.5 * inv),
                ),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return GestureDetector(
                      onTap: widget.onCamera,
                      child: ColoredBox(
                        color: isDark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFE5E5EA),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_camera_rounded,
                              color: isDark ? Colors.white : const Color(0xFF111111),
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Camera',
                              style: TextStyle(
                                color: label,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final asset = _assets[i - 1];
                  return _AttachPhotoCell(
                    asset: asset,
                    selectedIndex: _selIndex(asset),
                    onTap: () => _toggle(asset),
                  );
                },
              ),
            ),

            // شريط التسمية يظهر مع التمدد أو عند وجود اختيار
            ClipRect(
              child: Align(
                alignment: Alignment.bottomCenter,
                heightFactor: (_selected.isNotEmpty ? 1.0 : t).clamp(0.0, 1.0),
                child: Opacity(
                  opacity: (_selected.isNotEmpty ? 1.0 : t).clamp(0.0, 1.0),
                  child: _AttachCaptionBar(
                    selected: _selected,
                    captionCtrl: _captionCtrl,
                    sending: _sending,
                    onEdit: _openEditor,
                    onSend: _send,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachPhotoCell extends StatelessWidget {
  const _AttachPhotoCell({
    required this.asset,
    required this.selectedIndex,
    required this.onTap,
  });

  final AssetEntity asset;
  final int selectedIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = selectedIndex >= 0;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<Uint8List?>(
            future: asset.thumbnailDataWithSize(const ThumbnailSize(300, 300)),
            builder: (_, snap) {
              if (!snap.hasData || snap.data == null) {
                return const ColoredBox(color: Color(0xFFE5E5EA));
              }
              return Image.memory(
                snap.data!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              );
            },
          ),
          if (asset.type == AssetType.video)
            const Positioned(
              left: 6,
              bottom: 6,
              child: Icon(Icons.videocam, color: Colors.white, size: 16),
            ),
          Positioned(
            top: 6,
            right: 6,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF25D366)
                    : Colors.black.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.6),
              ),
              child: selected
                  ? Text(
                '${selectedIndex + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachCaptionBar extends StatelessWidget {
  const _AttachCaptionBar({
    required this.selected,
    required this.captionCtrl,
    required this.sending,
    required this.onEdit,
    required this.onSend,
  });

  final List<AssetEntity> selected;
  final TextEditingController captionCtrl;
  final bool sending;
  final VoidCallback onEdit;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Row(
          children: [
            GestureDetector(
              onTap: selected.isEmpty ? null : onEdit,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: selected.isEmpty
                      ? const ColoredBox(
                    color: Color(0xFFF2F2F7),
                    child: Icon(Icons.image_outlined,
                        color: Color(0xFF8E8E93)),
                  )
                      : FutureBuilder<Uint8List?>(
                    future: selected.last.thumbnailDataWithSize(
                      const ThumbnailSize(120, 120),
                    ),
                    builder: (_, snap) {
                      if (!snap.hasData || snap.data == null) {
                        return const ColoredBox(color: Color(0xFFE5E5EA));
                      }
                      return Image.memory(snap.data!, fit: BoxFit.cover);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: captionCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Add a caption...',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: selected.isEmpty || sending ? null : onSend,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected.isEmpty
                      ? const Color(0xFFB9E6C9)
                      : const Color(0xFF25D366),
                  shape: BoxShape.circle,
                ),
                child: sending
                    ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.send_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
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
class _WhatsAppGalleryPage extends StatefulWidget {
  const _WhatsAppGalleryPage({
    required this.onSend,
    this.onOpenCamera,
  });

  final Future<void> Function(List<File> files, String caption) onSend;
  final VoidCallback? onOpenCamera;

  @override
  State<_WhatsAppGalleryPage> createState() => _WhatsAppGalleryPageState();
}

class _WhatsAppGalleryPageState extends State<_WhatsAppGalleryPage> {
  final _captionCtrl = TextEditingController();
  final _scroll = ScrollController();

  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _album;
  List<AssetEntity> _assets = [];
  final List<AssetEntity> _selected = [];
  bool _loading = true;
  bool _hd = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _boot();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool _loadingMore = false;

  Future<void> _boot() async {
    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.hasAccess) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يلزم السماح بالوصول للصور')),
        );
      }
      return;
    }

    // مهم: ignoreSize وإلا كثير من الصور تُستبعد
    final filter = FilterOptionGroup(
      imageOption: const FilterOption(
        sizeConstraint: SizeConstraint(ignoreSize: true),
      ),
      videoOption: const FilterOption(
        sizeConstraint: SizeConstraint(ignoreSize: true),
      ),
    );

    // onlyAll: true = ألبوم Recents / كل الصور
    final all = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: true,
      filterOption: filter,
    );

    final rest = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: false,
      filterOption: filter,
    );

    if (!mounted) return;

    _albums = [
      ...all,
      ...rest.where((a) => all.every((b) => b.id != a.id)),
    ];

    if (_albums.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    _album = _albums.first;
    await _loadPage(reset: true);
  }

  Future<void> _loadPage({bool reset = false}) async {
    final album = _album;
    if (album == null) return;
    if (_loadingMore) return;

    if (reset) {
      _assets = [];
      if (mounted) setState(() => _loading = true);
    } else {
      _loadingMore = true;
    }

    try {
      final start = _assets.length;
      final next = await album.getAssetListRange(
        start: start,
        end: start + 80,
      );
      if (!mounted) return;
      setState(() {
        if (reset) _assets = next;
        else _assets.addAll(next);
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      debugPrint('gallery load failed: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }



  void _onScroll() {
    if (_scroll.position.pixels >
        _scroll.position.maxScrollExtent - 400) {
      _loadPage();
    }
  }

  void _toggle(AssetEntity asset) {
    setState(() {
      final i = _selected.indexWhere((e) => e.id == asset.id);
      if (i >= 0) {
        _selected.removeAt(i);
      } else {
        _selected.add(asset);
      }
    });
  }

  int _indexOf(AssetEntity asset) =>
      _selected.indexWhere((e) => e.id == asset.id);

  Future<void> _pickAlbum() async {
    final chosen = await showModalBottomSheet<AssetPathEntity>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return ListView.builder(
          itemCount: _albums.length,
          itemBuilder: (_, i) {
            final a = _albums[i];
            return ListTile(
              title: Text(a.name.isEmpty ? 'Recents' : a.name),
              trailing: FutureBuilder<int>(
                future: a.assetCountAsync,
                builder: (_, snap) => Text('${snap.data ?? ''}'),
              ),
              onTap: () => Navigator.pop(ctx, a),
            );
          },
        );
      },
    );
    if (chosen == null) return;
    setState(() => _album = chosen);
    await _loadPage(reset: true);
  }

  Future<void> _openEditor() async {
    if (_selected.isEmpty) return;

    final files = <File>[];
    for (final a in _selected) {
      final edited = _editedReplacements[a.id]; // أو _edited في الـ tray
      if (edited != null) {
        files.add(edited);
        continue;
      }
      final f = await a.file;
      if (f != null) files.add(f);
    }
    if (files.isEmpty || !mounted) return;

    final result = await Navigator.of(context).push<_EditorResult>(
      MaterialPageRoute(
        builder: (_) => _WhatsAppImageEditorPage(
          files: files,
          initialIndex: files.length - 1,
          caption: _captionCtrl.text,
        ),
      ),
    );
    if (result == null) return;

    _captionCtrl.text = result.caption;
    for (var i = 0; i < _selected.length && i < result.files.length; i++) {
      _editedReplacements[_selected[i].id] = result.files[i];
    }
    setState(() {});

    if (result.send) await _send();
  }

  final Map<String, File> _editedReplacements = {};

  Future<void> _send() async {
    if (_selected.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final files = <File>[];
      for (final a in _selected) {
        final edited = _editedReplacements[a.id];
        if (edited != null) {
          files.add(edited);
          continue;
        }
        final f = await a.file;
        if (f != null) files.add(f);
      }
      if (files.isEmpty) return;
      Navigator.of(context).pop();
      await widget.onSend(files, _captionCtrl.text);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _album == null
        ? 'Recents'
        : (_album!.name.isEmpty ? 'Recents' : _album!.name);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 26),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickAlbum,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Icon(Icons.expand_more_rounded),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => setState(() => _hd = !_hd),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _hd
                                ? const Color(0xFF111111)
                                : const Color(0xFFC7C7CC),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'HD',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: _hd
                                ? const Color(0xFF111111)
                                : const Color(0xFF8E8E93),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading && _assets.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _assets.isEmpty
                  ? const Center(
                child: Text(
                  'لا توجد صور في المعرض',
                  style: TextStyle(color: Color(0xFF8E8E93)),
                ),
              )
                  : GridView.builder(
                controller: _scroll,
                padding: EdgeInsets.zero,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 1.5,
                  crossAxisSpacing: 1.5,
                ),
                itemCount: _assets.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return GestureDetector(
                      onTap: widget.onOpenCamera,
                      child: const ColoredBox(
                        color: Color(0xFFE5E5EA),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_camera_rounded, size: 28),
                            SizedBox(height: 4),
                            Text('Camera', style: TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  }
                  final asset = _assets[i - 1];
                  return _GalleryCell(
                    asset: asset,
                    selectedIndex: _indexOf(asset),
                    onTap: () => _toggle(asset),
                  );
                },
              ),
            ),
            _GalleryCaptionBar(
              selected: _selected,
              captionCtrl: _captionCtrl,
              sending: _sending,
              onEdit: _openEditor,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryCell extends StatelessWidget {
  const _GalleryCell({
    required this.asset,
    required this.selectedIndex,
    required this.onTap,
  });

  final AssetEntity asset;
  final int selectedIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = selectedIndex >= 0;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<Uint8List?>(
            future: asset.thumbnailDataWithSize(
              const ThumbnailSize(300, 300),
            ),
            builder: (context, snap) {
              if (!snap.hasData || snap.data == null) {
                return const ColoredBox(color: Color(0xFFE5E5EA));
              }
              return Image.memory(snap.data!, fit: BoxFit.cover);
            },
          ),
          if (asset.type == AssetType.video)
            Positioned(
              left: 6,
              bottom: 6,
              child: Row(
                children: [
                  const Icon(Icons.videocam, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _fmt(asset.videoDuration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                    ),
                  ),
                ],
              ),
            ),
          Positioned(
            top: 6,
            right: 6,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF25D366)
                    : Colors.black.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.6),
              ),
              child: selected
                  ? Text(
                '${selectedIndex + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _GalleryCaptionBar extends StatelessWidget {
  const _GalleryCaptionBar({
    required this.selected,
    required this.captionCtrl,
    required this.sending,
    required this.onEdit,
    required this.onSend,
  });

  final List<AssetEntity> selected;
  final TextEditingController captionCtrl;
  final bool sending;
  final VoidCallback onEdit;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: selected.isEmpty ? null : onEdit,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _ThumbStack(selected: selected),
                if (selected.isNotEmpty)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, size: 13),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: captionCtrl,
                decoration: const InputDecoration(
                  hintText: 'Add a caption...',
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: selected.isEmpty || sending ? null : onSend,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected.isEmpty
                        ? const Color(0xFFB9E6C9)
                        : const Color(0xFF25D366),
                    shape: BoxShape.circle,
                  ),
                  child: sending
                      ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 22),
                ),
                if (selected.isNotEmpty)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        '${selected.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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

class _ThumbStack extends StatelessWidget {
  const _ThumbStack({required this.selected});
  final List<AssetEntity> selected;

  @override
  Widget build(BuildContext context) {
    if (selected.isEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.image_outlined, color: Color(0xFF8E8E93)),
      );
    }
    final last = selected.last;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 44,
        height: 44,
        child: FutureBuilder<Uint8List?>(
          future: last.thumbnailDataWithSize(const ThumbnailSize(120, 120)),
          builder: (_, snap) {
            if (!snap.hasData || snap.data == null) {
              return const ColoredBox(color: Color(0xFFE5E5EA));
            }
            return Image.memory(snap.data!, fit: BoxFit.cover);
          },
        ),
      ),
    );
  }
}

/// واجهة تعديل الصورة (تدوير + فلاتر) — زر القلم يفتحها
class _EditorResult {
  const _EditorResult({
    required this.files,
    required this.caption,
    this.send = false,
  });
  final List<File> files;
  final String caption;
  final bool send;
}

class _OverlayText {
  _OverlayText({
    required this.text,
    required this.pos,
    this.color = Colors.white,
  });
  String text;
  Offset pos;
  Color color;
}

class _SlideEdit {
  int turns = 0;
  int filter = 0;
  Rect? crop; // نسبة 0..1 داخل الصورة
  final strokes = <List<Offset>>[];
  final texts = <_OverlayText>[];
}

class _WhatsAppImageEditorPage extends StatefulWidget {
  const _WhatsAppImageEditorPage({
    required this.files,
    this.initialIndex = 0,
    this.caption = '',
  });

  final List<File> files;
  final int initialIndex;
  final String caption;

  @override
  State<_WhatsAppImageEditorPage> createState() =>
      _WhatsAppImageEditorPageState();
}

class _WhatsAppImageEditorPageState extends State<_WhatsAppImageEditorPage> {
  static const _filters = <List<double>?>[
    null,
    <double>[
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0, 0, 0, 1, 0,
    ],
    <double>[
      1.2, 0, 0, 0, 0,
      0, 1.05, 0, 0, 0,
      0, 0, 0.85, 0, 0,
      0, 0, 0, 1, 0,
    ],
    <double>[
      0.85, 0, 0, 0, 0,
      0, 1.0, 0, 0, 0,
      0, 0, 1.2, 0, 0,
      0, 0, 0, 1, 0,
    ],
  ];

  late final List<File> _files;
  late final List<_SlideEdit> _edits;
  late int _index;
  late final TextEditingController _captionCtrl;

  final _boundary = GlobalKey();
  String _tool = 'none'; // none | draw | text | crop
  Color _drawColor = Colors.white;
  Offset? _cropStart;
  Rect? _cropDrag;
  bool _hd = true;
  bool _saving = false;

  _SlideEdit get _cur => _edits[_index];

  @override
  void initState() {
    super.initState();
    _files = List<File>.from(widget.files);
    _edits = List.generate(_files.length, (_) => _SlideEdit());
    _index = widget.initialIndex.clamp(0, _files.length - 1);
    _captionCtrl = TextEditingController(text: widget.caption);
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<File> _exportSlide(int i) async {
    // نبدّل مؤقتاً للشريحة ثم نلتقط
    final prev = _index;
    if (i != _index) {
      setState(() => _index = i);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    final box =
    _boundary.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    File out = _files[i];
    if (box != null) {
      final img = await box.toImage(pixelRatio: _hd ? 2.5 : 1.5);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      if (data != null) {
        final dir = await getTemporaryDirectory();
        out = File(
          '${dir.path}/edit_${i}_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await out.writeAsBytes(data.buffer.asUint8List());
      }
    }
    if (prev != _index && mounted) setState(() => _index = prev);
    return out;
  }

  Future<void> _finish({required bool send}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final out = <File>[];
      for (var i = 0; i < _files.length; i++) {
        out.add(await _exportSlide(i));
      }
      if (!mounted) return;
      Navigator.pop(
        context,
        _EditorResult(
          files: out,
          caption: _captionCtrl.text,
          send: send,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _onDraw(Offset p, Size size, {required bool end}) {
    if (_tool != 'draw') return;
    final n = Offset(p.dx / size.width, p.dy / size.height);
    setState(() {
      if (_cur.strokes.isEmpty || end && _cur.strokes.last.isEmpty) {
        _cur.strokes.add([n]);
      } else if (!end) {
        if (_cur.strokes.last.isEmpty) {
          _cur.strokes.add([n]);
        }
        _cur.strokes.last.add(n);
      }
    });
  }

  void _startStroke(Offset p, Size size) {
    if (_tool != 'draw') return;
    final n = Offset(p.dx / size.width, p.dy / size.height);
    setState(() => _cur.strokes.add([n]));
  }

  void _addText() async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('نص', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: const InputDecoration(
            hintText: 'اكتب هنا',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
    if (text == null || text.isEmpty) return;
    setState(() {
      _cur.texts.add(_OverlayText(text: text, pos: const Offset(0.5, 0.5)));
      _tool = 'text';
    });
  }

  Widget _circleBtn({
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: active
              ? Colors.white.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final edit = _cur;

    Widget picture = Image.file(_files[_index], fit: BoxFit.contain);
    final matrix = _filters[edit.filter];
    if (matrix != null) {
      picture = ColorFiltered(
        colorFilter: ColorFilter.matrix(matrix),
        child: picture,
      );
    }
    picture = RotatedBox(quarterTurns: edit.turns, child: picture);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // شريط الأدوات العلوي
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Row(
                children: [
                  _circleBtn(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  _circleBtn(
                    icon: Icons.download_rounded,
                    onTap: () async {
                      await _exportSlide(_index);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم حفظ النسخة المعدّلة')),
                      );
                    },
                  ),
                  _circleBtn(
                    icon: Icons.hd_outlined,
                    active: _hd,
                    onTap: () => setState(() => _hd = !_hd),
                  ),
                  _circleBtn(
                    icon: Icons.crop_rotate_rounded,
                    active: _tool == 'crop',
                    onTap: () => setState(() {
                      _tool = _tool == 'crop' ? 'none' : 'crop';
                      if (_tool == 'crop' && edit.crop == null) {
                        edit.crop = const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8);
                      }
                    }),
                  ),
                  _circleBtn(
                    icon: Icons.emoji_emotions_outlined,
                    onTap: () => setState(
                          () => edit.filter =
                          (edit.filter + 1) % _filters.length,
                    ),
                  ),
                  _circleBtn(
                    icon: Icons.text_fields_rounded,
                    active: _tool == 'text',
                    onTap: _addText,
                  ),
                  _circleBtn(
                    icon: Icons.edit_rounded,
                    active: _tool == 'draw',
                    onTap: () => setState(
                          () => _tool = _tool == 'draw' ? 'none' : 'draw',
                    ),
                  ),
                ],
              ),
            ),

            // الصورة + الرسم + النص + القص
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final size = Size(box.maxWidth, box.maxHeight);
                  return GestureDetector(
                    onPanStart: (d) {
                      if (_tool == 'draw') {
                        _startStroke(d.localPosition, size);
                      } else if (_tool == 'crop') {
                        _cropStart = d.localPosition;
                      }
                    },
                    onPanUpdate: (d) {
                      if (_tool == 'draw') {
                        final n = Offset(
                          (d.localPosition.dx / size.width).clamp(0, 1),
                          (d.localPosition.dy / size.height).clamp(0, 1),
                        );
                        setState(() => edit.strokes.last.add(n));
                      } else if (_tool == 'crop' && _cropStart != null) {
                        final a = _cropStart!;
                        final b = d.localPosition;
                        final r = Rect.fromPoints(a, b);
                        setState(() {
                          edit.crop = Rect.fromLTRB(
                            (r.left / size.width).clamp(0, 1),
                            (r.top / size.height).clamp(0, 1),
                            (r.right / size.width).clamp(0, 1),
                            (r.bottom / size.height).clamp(0, 1),
                          );
                        });
                      }
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Center(
                          child: RepaintBoundary(
                            key: _boundary,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                picture,
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _StrokePainter(edit.strokes),
                                  ),
                                ),
                                for (final tx in edit.texts)
                                  Positioned(
                                    left: tx.pos.dx * size.width - 40,
                                    top: tx.pos.dy * size.height - 16,
                                    child: GestureDetector(
                                      onPanUpdate: (d) {
                                        setState(() {
                                          tx.pos = Offset(
                                            (tx.pos.dx + d.delta.dx / size.width)
                                                .clamp(0.05, 0.95),
                                            (tx.pos.dy + d.delta.dy / size.height)
                                                .clamp(0.05, 0.95),
                                          );
                                        });
                                      },
                                      child: Text(
                                        tx.text,
                                        style: TextStyle(
                                          color: tx.color,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          shadows: const [
                                            Shadow(
                                              blurRadius: 8,
                                              color: Colors.black87,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (_tool == 'crop' && edit.crop != null)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _CropPainter(edit.crop!),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // أسفل: فلاتر + شرائح + تسمية + إرسال
            GestureDetector(
              onVerticalDragEnd: (d) {
                if ((d.primaryVelocity ?? 0) < -200) {
                  setState(() =>
                  edit.filter = (edit.filter + 1) % _filters.length);
                }
              },
              child: Column(
                children: [
                  const Icon(Icons.keyboard_arrow_up_rounded,
                      color: Colors.white54),
                  const Text(
                    'Swipe up for filters',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  if (_files.length > 1)
                    SizedBox(
                      height: 56,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _files.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final sel = i == _index;
                          return GestureDetector(
                            onTap: () => setState(() => _index = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: sel ? Colors.white : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.file(
                                  _files[i],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.image_outlined,
                              color: Colors.white54, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _captionCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Add a caption...',
                                hintStyle: TextStyle(color: Colors.white38),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'You',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _saving ? null : () => _finish(send: true),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Color(0xFF25D366),
                              shape: BoxShape.circle,
                            ),
                            child: _saving
                                ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Icon(Icons.send_rounded,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  _StrokePainter(this.strokes);
  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final s in strokes) {
      if (s.length < 2) continue;
      final path = Path()
        ..moveTo(s.first.dx * size.width, s.first.dy * size.height);
      for (final o in s.skip(1)) {
        path.lineTo(o.dx * size.width, o.dy * size.height);
      }
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter old) => true;
}

class _CropPainter extends CustomPainter {
  _CropPainter(this.crop);
  final Rect crop;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTRB(
      crop.left * size.width,
      crop.top * size.height,
      crop.right * size.width,
      crop.bottom * size.height,
    );
    final overlay = Path()
      ..addRect(Offset.zero & size)
      ..addRect(r)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      overlay,
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );
    canvas.drawRect(
      r,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _CropPainter old) => old.crop != crop;
}


// ==================== شيت خيارات الرسالة ====================

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
      _MsgAction('reply', 'رد', Icons.reply_rounded),
      if (widget.isText) _MsgAction('copy', 'نسخ', Icons.content_copy_rounded),
      if (widget.isText)
        _MsgAction('translate', 'ترجمة', Icons.translate_rounded),
      _MsgAction(
        'star',
        widget.starred ? 'إلغاء التمييز' : 'تمييز',
        widget.starred ? Icons.star_rounded : Icons.star_border_rounded,
      ),
      _MsgAction('info', 'معلومات', Icons.info_outline_rounded),
      if (!widget.isText)
        _MsgAction('download', 'تحميل', Icons.download_rounded),
      if (widget.isText && widget.isMine)
        _MsgAction('edit', 'تعديل', Icons.edit_rounded),
      if (widget.isMine)
        _MsgAction('delete', 'حذف', Icons.delete_outline_rounded,
            destructive: true),
    ];

    final bubbleColor = widget.isMine
        ? AppTeal.main
        : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF0F0F0));
    final bubbleTextColor =
    widget.isMine ? Colors.white : (isDark ? Colors.white : Colors.black87);

    return Directionality(
      textDirection: TextDirection.rtl,
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
                                        ? 'رسالة'
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
    barrierLabel: 'message_actions',
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
      appBar: AppBar(title: Text('مميز — $peerName')),
      body: messages.isEmpty
          ? const Center(child: Text('لا توجد رسائل مميزة'))
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: messages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final m = messages[i];
          final text = m is types.TextMessage
              ? m.text
              : m is types.ImageMessage
              ? '📷 صورة'
              : m is types.VideoMessage
              ? '🎬 فيديو'
              : m is types.AudioMessage
              ? '🎤 صوت'
              : 'رسالة';
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
    required this.preview,
    required this.isMine,
    required this.starred,
    required this.isText,
  });

  final Rect rect;
  final types.Message message;
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
          child: _ChatVideoThumb(url: m.uri),
        ),
      );
    }
    if (m is types.AudioMessage) {
      return _ChatAudioPlayer(
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
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final menuW = min(240.0, size.width - 24);
    double menuLeft = widget.isMine
        ? widget.rect.right - menuW
        : widget.rect.left;
    menuLeft = menuLeft.clamp(12.0, size.width - menuW - 12);

    final reactW = min(220.0, size.width - 24);
    double reactLeft = widget.isMine
        ? widget.rect.right - reactW
        : widget.rect.left;
    reactLeft = reactLeft.clamp(12.0, size.width - reactW - 12);

    const reactH = 52.0;
    const menuH = 280.0;
    const gap = 10.0;

    var top = widget.rect.top;
    final spaceAbove = widget.rect.top - pad.top;
    final spaceBelow = size.height - pad.bottom - widget.rect.bottom;

    var reactAbove = spaceAbove >= reactH + gap;
    if (!reactAbove && spaceBelow < menuH + gap) {
      reactAbove = spaceAbove > spaceBelow;
    }

    final need = (reactAbove ? reactH + gap : 0) +
        widget.rect.height +
        gap +
        (reactAbove ? menuH : reactH + gap + menuH);
    final overflow = (widget.rect.top + need) - (size.height - pad.bottom);
    if (overflow > 0) top -= overflow;
    if (top < pad.top + (reactAbove ? reactH + gap : 0)) {
      top = pad.top + (reactAbove ? reactH + gap : 0);
    }

    final lift = top - widget.rect.top;

    final actions = <_MsgAction>[
      _MsgAction('reply', 'رد', Icons.reply_rounded),
      if (widget.isText) _MsgAction('copy', 'نسخ', Icons.content_copy_rounded),
      if (widget.isText)
        _MsgAction('translate', 'ترجمة', Icons.translate_rounded),
      _MsgAction(
        'star',
        widget.starred ? 'إلغاء التمييز' : 'تمييز',
        widget.starred ? Icons.star_rounded : Icons.star_border_rounded,
      ),
      _MsgAction('info', 'معلومات', Icons.info_outline_rounded),
      if (!widget.isText)
        _MsgAction('download', 'تحميل', Icons.download_rounded),
      if (widget.isText && widget.isMine)
        _MsgAction('edit', 'تعديل', Icons.edit_rounded),
      if (widget.isMine)
        _MsgAction('delete', 'حذف', Icons.delete_outline_rounded,
            destructive: true),
    ];

    final bubbleColor = widget.isMine
        ? AppTeal.main
        : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF0F0F0));
    final bubbleTextColor =
    widget.isMine ? Colors.white : (isDark ? Colors.white : Colors.black87);

    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, _) {
          final v = _t.value;
          final m = widget.message;
          return Stack(
            children: [
              GestureDetector(
                onTap: _close,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 7 * v, sigmaY: 7 * v),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.16 * v),
                  ),
                ),
              ),
              Positioned(
                left: widget.rect.left,
                top: widget.rect.top + lift * v,
                width: widget.rect.width,
                child: Opacity(
                  opacity: 0.2 + 0.8 * v,
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - v)),
                    child: Container(
                      padding: (m is types.ImageMessage ||
                          m is types.VideoMessage)
                          ? EdgeInsets.zero
                          : const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: (m is types.ImageMessage ||
                            m is types.VideoMessage)
                            ? Colors.transparent
                            : bubbleColor,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft:
                          Radius.circular(widget.isMine ? 18 : 4),
                          bottomRight:
                          Radius.circular(widget.isMine ? 4 : 18),
                        ),
                      ),
                      child: _overlayBody(),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                top: widget.rect.top +
                    lift * v +
                    (reactAbove ? -(64 + gap) : widget.rect.height + gap),
                child: Opacity(
                  opacity:
                  Interval(0.15, 1, curve: Curves.easeOut).transform(v),
                  child: Transform.translate(
                    offset: Offset(0, (1 - v) * (reactAbove ? 14 : -14)),
                    child: Align(
                      alignment: widget.isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Material(
                        color: isDark
                            ? const Color(0xFF2C2C2E)
                            : Colors.white,
                        elevation: 8,
                        shadowColor: Colors.black26,
                        borderRadius: BorderRadius.circular(28),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final e in _reactions)
                                _ReactionButton(
                                  emoji: e,
                                  onTap: () => _close('react:$e'),
                                ),
                              Container(
                                width: 1,
                                height: 22,
                                margin:
                                const EdgeInsets.symmetric(horizontal: 4),
                                color: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.12),
                              ),
                              InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () async {
                                  final emoji =
                                  await showModalBottomSheet<String>(
                                    context: context,
                                    isScrollControlled: true,
                                    useRootNavigator: true,
                                    backgroundColor: isDark
                                        ? const Color(0xFF1C1C1E)
                                        : Colors.white,
                                    builder: (_) => const _AllEmojiSheet(),
                                  );
                                  if (!mounted) return;
                                  if (emoji != null &&
                                      emoji.trim().isNotEmpty) {
                                    await _close('react:${emoji.trim()}');
                                  }
                                },
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark
                                        ? Colors.white
                                        .withValues(alpha: 0.10)
                                        : const Color(0xFFF2F2F2),
                                  ),
                                  child: Icon(
                                    Icons.add_rounded,
                                    size: 22,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
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
              Positioned(
                left: menuLeft,
                width: menuW,
                top: widget.rect.top +
                    lift * v +
                    widget.rect.height +
                    gap +
                    (reactAbove ? 0 : reactH + gap),
                child: Opacity(
                  opacity: Interval(0.28, 1, curve: Curves.easeOut).transform(v),
                  child: Transform.translate(
                    offset: Offset(0, (1 - v) * 22),
                    child: Container(
                      width: menuW,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
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
                                color: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.08),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
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
                const Text(
                  'تعديل الرسالة',
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
  String _to = 'ar';
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
                  title: Text(e.$2),
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
    if (selected == null) return;
    setState(() {
      if (source) {
        _from = selected;
      } else {
        _to = selected;
      }
      _result = null;
    });
  }

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tr = GoogleTranslator();
      final out = await tr.translate(
        widget.text,
        from: _from,
        to: _to,
      );
      if (!mounted) return;
      setState(() {
        _result = out.text;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
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
          const Text(
            'ترجمة',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pick(true),
                  child: Text(_label(_from), overflow: TextOverflow.ellipsis),
                ),
              ),
              IconButton(
                onPressed: _from == 'auto'
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
                  child: Text(_label(_to), overflow: TextOverflow.ellipsis),
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
          if (_result != null) ...[
            const SizedBox(height: 10),
            Text(_result!, style: const TextStyle(fontSize: 16, height: 1.45)),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Color(0xFFDC2626))),
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
                : const Text('ترجمة'),
          ),
          if (_result != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _result!));
                Navigator.pop(context);
              },
              child: const Text('نسخ الترجمة'),
            ),
          ],
        ],
      ),
    );
  }
}


const int kVoiceBarCount = 40;
const Duration kVoiceHoldDelay = Duration(milliseconds: 180);
const double kVoiceLockDy = 78;
const double kVoiceCancelDx = 68;
const Duration kVoiceMinDuration = Duration(milliseconds: 400);
const Duration kVoiceMaxDuration = Duration(seconds: 60);

enum VoicePhase { idle, starting, recording, paused, sending }

// ─────────────────────────────────────────────────────────────
// 1. Session — state machine + real amplitude
// ─────────────────────────────────────────────────────────────

class VoiceSessionController extends ChangeNotifier {
  final AudioRecorder recorder = AudioRecorder();

  VoicePhase phase = VoicePhase.idle;
  String? path;
  bool finishAfterStart = false;
  bool cancelAfterStart = false;

  final List<double> bars = List<double>.filled(kVoiceBarCount, 0.1);
  double liveLevel = 0;

  DateTime? runStartedAt;
  Duration frozen = Duration.zero;
  StreamSubscription<Amplitude>? _ampSub;
  Timer? _clock;
  String? lastError;
  bool _alive = true;

  void _emit() {
    if (_alive) notifyListeners();
  }

  bool get recording =>
      phase == VoicePhase.recording ||
          phase == VoicePhase.paused ||
          phase == VoicePhase.starting ||
          phase == VoicePhase.sending;

  bool get paused => phase == VoicePhase.paused;
  bool get live => phase == VoicePhase.recording;

  Duration get elapsed {
    if (phase == VoicePhase.recording && runStartedAt != null) {
      return frozen + DateTime.now().difference(runStartedAt!);
    }
    return frozen;
  }

  void _resetBars() {
    for (var i = 0; i < bars.length; i++) {
      bars[i] = 0.1;
    }
    liveLevel = 0;
  }

  static double ampToLevel(double current, double max) {
    final a = current.isFinite ? current : 0.0;
    final m = max.isFinite ? max : a;

    double linear;
    if (a < 0 || m < 0) {
      final db = a < 0 ? a : m;
      const floor = -60.0;
      const ceil = -8.0;
      linear = ((db - floor) / (ceil - floor)).clamp(0.0, 1.0);
    } else if (math.max(a, m) <= 1.0001) {
      linear = math.max(a, m).clamp(0.0, 1.0);
    } else {
      linear = (math.max(a, m) / 32767.0).clamp(0.0, 1.0);
    }
    return math.pow(linear, 0.42).toDouble();
  }

  void _ingestAmp(double current, double max) {
    final target = ampToLevel(current, max);
    final k = target > liveLevel ? 0.78 : 0.32;
    liveLevel += (target - liveLevel) * k;
    final v = (0.07 + liveLevel * 0.93).clamp(0.07, 1.0);
    bars.removeAt(0);
    bars.add(v);
  }

  void _listenAmplitude() {
    _ampSub?.cancel();
    try {
      _ampSub = recorder
          .onAmplitudeChanged(const Duration(milliseconds: 40))
          .listen((amp) {
        if (phase != VoicePhase.recording) return;
        _ingestAmp(amp.current, amp.max);
        _emit();
      }, onError: (_) {});
    } catch (_) {}
  }

  void _startClock() {
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!_alive || phase != VoicePhase.recording) return;
      unawaited(_pollAmplitude());
    });
  }

  Future<void> _pollAmplitude() async {
    if (phase != VoicePhase.recording) return;
    try {
      final amp = await recorder.getAmplitude();
      _ingestAmp(amp.current, amp.max);
      _emit();
    } catch (_) {
      _emit();
    }
  }

  /// Returns false on missing permission (no throw).
  Future<bool> start() async {
    if (phase == VoicePhase.recording || phase == VoicePhase.starting) {
      return true;
    }
    if (phase == VoicePhase.paused) {
      await resume();
      return true;
    }

    phase = VoicePhase.starting;
    lastError = null;
    finishAfterStart = false;
    cancelAfterStart = false;
    path = null;
    frozen = Duration.zero;
    runStartedAt = null;
    _resetBars();
    _emit();

    try {
      if (!await recorder.hasPermission()) {
        lastError = 'mic-permission';
        phase = VoicePhase.idle;
        _emit();
        return false;
      }

      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: filePath,
      );

      path = filePath;
      runStartedAt = DateTime.now();
      phase = VoicePhase.recording;
      _listenAmplitude();
      _startClock();
      _emit();

      if (cancelAfterStart) {
        await cancel();
        return false;
      }
      if (finishAfterStart) {
        await stopForSend();
      }
      return true;
    } catch (e) {
      lastError = e.toString();
      phase = VoicePhase.idle;
      _emit();
      return false;
    }
  }


  Future<void> pause() async {
    if (phase != VoicePhase.recording) return;
    try {
      await recorder.pause();
    } catch (e) {
      debugPrint('voice pause unsupported: $e');
      return;
    }
    if (runStartedAt != null) {
      frozen += DateTime.now().difference(runStartedAt!);
      runStartedAt = null;
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
      lastError = e.toString();
      _emit();
      return;
    }
    runStartedAt = DateTime.now();
    phase = VoicePhase.recording;
    _listenAmplitude();
    _startClock();
    _emit();
  }

  Future<File?> stopForSend() async {
    if (phase == VoicePhase.starting) {
      finishAfterStart = true;
      return null;
    }
    if (phase != VoicePhase.recording && phase != VoicePhase.paused) {
      return null;
    }

    if (phase == VoicePhase.recording && runStartedAt != null) {
      frozen += DateTime.now().difference(runStartedAt!);
      runStartedAt = null;
    }
    final duration = frozen;
    phase = VoicePhase.sending;
    _emit();

    String? stopped;
    try {
      stopped = await recorder.stop();
    } catch (_) {}
    final uploadPath =
    (stopped != null && stopped.isNotEmpty) ? stopped : path;
    _tearDown(keepFile: true);

    if (uploadPath == null) return null;
    final file = File(uploadPath);
    if (!await file.exists()) return null;
    if (duration < kVoiceMinDuration) {
      try {
        await file.delete();
      } catch (_) {}
      return null;
    }
    return file;
  }

  Future<void> cancel() async {
    if (phase == VoicePhase.starting) {
      cancelAfterStart = true;
      return;
    }
    try {
      await recorder.stop();
    } catch (_) {}
    final p = path;
    _tearDown(keepFile: false);
    if (p != null) {
      try {
        final f = File(p);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }

  void _tearDown({required bool keepFile}) {
    _ampSub?.cancel();
    _ampSub = null;
    _clock?.cancel();
    _clock = null;
    if (!keepFile) path = null;
    phase = VoicePhase.idle;
    frozen = Duration.zero;
    runStartedAt = null;
    finishAfterStart = false;
    cancelAfterStart = false;
    _resetBars();
    _emit();
  }

  @override
  void dispose() {
    _alive = false;
    unawaited(_shutdown());
    super.dispose();
  }

  Future<void> _shutdown() async {
    try {
      if (await recorder.isRecording() || await recorder.isPaused()) {
        await recorder.stop();
      }
    } catch (_) {}
    await _ampSub?.cancel();
    _clock?.cancel();
    await recorder.dispose();
  }
}

// ─────────────────────────────────────────────────────────────
// 2. Waveform — bar height = amplitude, no fake sine
// ─────────────────────────────────────────────────────────────

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
                    ? 'إلغاء'
                    : ready
                    ? 'أفلت للقفل'
                    : 'لأعلى للقفل',
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
        final holdOnly = holding && !locked;

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
                        : (paused ? onResume : onPause),
                    child: Icon(
                      paused ? Icons.mic_rounded : Icons.pause_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
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
            const SizedBox(height: 4),
            Text(
              paused
                  ? 'متوقف — اضغط المايك لمتابعة نفس التسجيل'
                  : holdOnly
                  ? 'أفلت للإرسال · يسار للإلغاء · أعلى للقفل'
                  : locked
                  ? 'مقفل — يمكنك رفع إصبعك'
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

class _PulseVoiceHostState extends State<PulseVoiceHost> {
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

  bool get _showDock =>
      widget.session.recording || _holding || _pressing || _locked;

  @override
  void dispose() {
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
    } else if (e is PointerUpEvent || e is PointerCancelEvent) {
      _onUp();
    }
  }

  void _onDown(PointerDownEvent e) {
    if (widget.sending || widget.hasText) return;
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
    unawaited(_begin());
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
        unawaited(_doSend());
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

  Future<void> _begin() async {
    if (widget.onBeforeStart != null) {
      final ok = await widget.onBeforeStart!();
      if (!ok) {
        _reset();
        return;
      }
    }
    final ok = await widget.session.start();
    if (!ok) {
      _reset();
      widget.onStartFailed?.call();
    }
  }

  Future<void> _doSend() async {
    final duration = widget.session.elapsed;
    final file = await widget.session.stopForSend();
    _reset();
    if (file != null) {
      await widget.onSendVoice(file, duration);
    }
  }

  Future<void> _doCancel() async {
    await widget.session.cancel();
    _reset();
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
        if (widget.session.elapsed >= kVoiceMaxDuration &&
            widget.session.live) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (widget.session.live) unawaited(_doSend());
          });
        }

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
                  onPause: () => unawaited(widget.session.pause()),
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
