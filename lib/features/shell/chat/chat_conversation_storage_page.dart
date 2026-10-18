import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../services/chat_media_policy.dart';
import '../../../services/chat_local_persistence.dart';

/// Manages only ordinary downloaded image buffers. The encrypted store is used
/// solely as a session guard, never purged or edited by cache cleanup.
class ChatConversationStoragePage extends StatelessWidget {
  const ChatConversationStoragePage(
      {super.key,
      required this.scope,
      required this.title,
      required this.authorized,
      this.protectedStore,
      this.cache});
  final String scope, title;
  final bool Function() authorized;
  final ChatLocalStorage? protectedStore;
  final ChatImageMemoryCache? cache;
  ChatImageMemoryCache get _cache => cache ?? chatImageMemoryCache;
  bool get _allowed => authorized() && (protectedStore?.isCurrent ?? true);
  String _s(BuildContext c, String ar, String fr, String en) =>
      switch (Localizations.localeOf(c).languageCode) {
        'ar' => ar,
        'fr' => fr,
        _ => en
      };
  String _size(int bytes) => bytes < 1024
      ? '$bytes B'
      : bytes < 1024 * 1024
          ? '${(bytes / 1024).toStringAsFixed(1)} KB'
          : '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  void _evictDecoded(Uint8List bytes) {
    MemoryImage(bytes).evict();
    ResizeImage.resizeIfNeeded(720, null, MemoryImage(bytes)).evict();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(_s(context, 'تخزين المحادثة',
                'Stockage de la discussion', 'Conversation storage'))),
        body: ListenableBuilder(
            listenable: _cache,
            builder: (context, _) {
              if (!_allowed)
                return Center(
                    child: Text(_s(
                        context,
                        'المحادثة غير متاحة',
                        'Discussion indisponible',
                        'Conversation unavailable')));
              final entries =
                  _cache.describeScope(scope, authorized: () => _allowed);
              final total =
                  entries.fold<int>(0, (sum, item) => sum + item.bytes);
              return ListView(padding: const EdgeInsets.all(16), children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text(
                    '${_s(context, 'صور مؤقتة في الذاكرة', 'Images temporaires en mémoire', 'Temporary images in RAM')}: ${_size(total)}'),
                const SizedBox(height: 8),
                Text(_s(
                    context,
                    'هذه أحجام بيانات الصور المؤقتة، وليست مساحة القرص أو كامل ذاكرة التطبيق. تبقى الرسائل والمسودات والمرفقات المنتظرة محفوظة.',
                    'Ces tailles concernent les images temporaires, pas le disque ni toute la mémoire de l’application. Messages, brouillons et envois en attente sont conservés.',
                    'These sizes cover temporary image bytes, not disk space or total app memory. Messages, drafts and queued attachments are preserved.')),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                    onPressed: entries.isEmpty
                        ? null
                        : () {
                            if (!_allowed) return;
                            _cache.clearScope(scope, onRemoved: _evictDecoded);
                          },
                    icon: const Icon(Icons.cleaning_services_outlined),
                    label: Text(_s(
                        context,
                        'مسح صور هذه المحادثة المؤقتة',
                        'Effacer les images temporaires',
                        'Clear this conversation’s image cache'))),
                const SizedBox(height: 16),
                Text(
                    _s(context, 'الأكبر أولًا',
                        'Les plus volumineuses en premier', 'Largest first'),
                    style: Theme.of(context).textTheme.titleMedium),
                if (entries.isEmpty)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(_s(
                          context,
                          'لا توجد صور مؤقتة لهذه المحادثة',
                          'Aucune image temporaire pour cette discussion',
                          'No cached images for this conversation'))),
                for (final item in entries)
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.name,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(_size(item.bytes)),
                      trailing: IconButton(
                          tooltip: _s(
                              context,
                              'مسح الصورة المؤقتة',
                              'Effacer l’image temporaire',
                              'Clear cached image'),
                          onPressed: () {
                            if (!_allowed) return;
                            _cache.removeScopedEntry(scope, item.id,
                                authorized: () => _allowed,
                                onRemoved: _evictDecoded);
                          },
                          icon: const Icon(Icons.delete_outline))),
              ]);
            }),
      );
}
