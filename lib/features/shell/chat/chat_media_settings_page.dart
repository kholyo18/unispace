import 'package:flutter/material.dart';
import '../../../services/chat_media_policy.dart';

class ChatMediaSettingsPage extends StatefulWidget {
  const ChatMediaSettingsPage({super.key});
  @override
  State<ChatMediaSettingsPage> createState() => _ChatMediaSettingsPageState();
}

class _ChatMediaSettingsPageState extends State<ChatMediaSettingsPage> {
  bool _busy = true;
  String? _error;
  String _s(String ar, String fr, String en) =>
      switch (Localizations.localeOf(context).languageCode) {
        'ar' => ar,
        'fr' => fr,
        _ => en
      };
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await chatMediaPolicy.load();
    } catch (_) {}
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _save(bool wifi, bool mobile, [int? cacheMiB]) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await chatMediaPolicy.save(
          wifi: wifi, mobile: mobile, cacheMiB: cacheMiB);
    } catch (_) {
      if (mounted)
        _error = _s('تعذر حفظ الإعداد', 'Impossible d’enregistrer',
            'Could not save setting');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(
                _s('وسائط المحادثات', 'Médias des discussions', 'Chat media'))),
        body: ListenableBuilder(
            listenable: chatImageMemoryCache,
            builder: (context, _) => ListView(children: [
                  Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_s(
                          'التحميل التلقائي للصور والصور المصغرة العادية. يبقى تحميل الفيديو والصوت عند الطلب.',
                          'Chargement automatique des images et miniatures ordinaires. Les vidéos et audios se chargent à la demande.',
                          'Automatically load ordinary images and thumbnails. Video and audio load on demand.'))),
                  SwitchListTile(
                      title: const Text('Wi-Fi'),
                      value: chatMediaPolicy.wifi,
                      onChanged: _busy
                          ? null
                          : (value) => _save(value, chatMediaPolicy.mobile)),
                  SwitchListTile(
                      title: Text(_s(
                          'بيانات الهاتف', 'Données mobiles', 'Mobile data')),
                      value: chatMediaPolicy.mobile,
                      onChanged: _busy
                          ? null
                          : (value) => _save(chatMediaPolicy.wifi, value)),
                  Padding(
                      padding: const EdgeInsets.all(16),
                      child: DropdownButtonFormField<int>(
                        key: ValueKey(chatMediaPolicy.cacheMiB),
                        initialValue: chatMediaPolicy.cacheMiB,
                        decoration: InputDecoration(
                            labelText: _s(
                                'حد الصور المؤقتة',
                                'Limite des images temporaires',
                                'Image buffer limit')),
                        items: [8, 24, 48]
                            .map((value) => DropdownMenuItem(
                                value: value, child: Text('$value MB')))
                            .toList(),
                        onChanged: _busy
                            ? null
                            : (value) {
                                if (value != null)
                                  _save(chatMediaPolicy.wifi,
                                      chatMediaPolicy.mobile, value);
                              },
                      )),
                  ListTile(
                      title: Text(_s(
                          'صور محفوظة مؤقتًا في الذاكرة',
                          'Images temporaires en mémoire',
                          'Temporary image buffers')),
                      subtitle: Text(
                          '${(chatImageMemoryCache.sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB / ${chatMediaPolicy.cacheMiB} MB')),
                  Padding(
                      padding: const EdgeInsets.all(16),
                      child: OutlinedButton(
                          onPressed: () {
                            chatImageMemoryCache.clear();
                            PaintingBinding.instance.imageCache.clear();
                            PaintingBinding.instance.imageCache
                                .clearLiveImages();
                          },
                          child: Text(_s(
                              'مسح الصور المؤقتة',
                              'Effacer les images temporaires',
                              'Clear temporary images')))),
                  if (_error != null)
                    Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_error!)),
                ])),
      );
}
