import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/chat_unified_search.dart';

class ChatUnifiedSearchPage extends StatefulWidget {
  const ChatUnifiedSearchPage({super.key, required this.onOpen, this.source});
  final Future<void> Function(ChatUnifiedSearchHit hit) onOpen;
  final ChatSearchSource? source;
  @override
  State<ChatUnifiedSearchPage> createState() => _ChatUnifiedSearchPageState();
}

class _ChatUnifiedSearchPageState extends State<ChatUnifiedSearchPage> {
  late final ChatUnifiedSearchController search;
  final input = TextEditingController();
  Timer? debounce, sessionCheck;
  bool opening = false;
  String t(String ar, String en, String fr) =>
      switch (Localizations.localeOf(context).languageCode) {
        'ar' => ar,
        'fr' => fr,
        _ => en
      };
  @override
  void initState() {
    super.initState();
    search = ChatUnifiedSearchController(
        widget.source ?? FirestoreChatSearchSource());
    search.addListener(update);
    sessionCheck = Timer.periodic(
        const Duration(seconds: 2), (_) => search.checkSession());
  }

  void update() {
    if (mounted) setState(() {});
  }

  void run() {
    debounce?.cancel();
    unawaited(search.search(input.text, search.filter));
  }

  String label(ChatSearchFilter f) => switch (f) {
        ChatSearchFilter.all => t('الكل', 'All', 'Tout'),
        ChatSearchFilter.text => t('النصوص', 'Text', 'Textes'),
        ChatSearchFilter.images => t('الصور', 'Images', 'Images'),
        ChatSearchFilter.videos => t('الفيديو', 'Videos', 'Vidéos'),
        ChatSearchFilter.files => t('الملفات', 'Files', 'Fichiers'),
        ChatSearchFilter.links => t('الروابط', 'Links', 'Liens')
      };
  String name(ChatUnifiedSearchHit hit) {
    final data = hit.chatData;
    if (data['type'] == 'group')
      return data['name']?.toString() ?? t('مجموعة', 'Group', 'Groupe');
    final members = data['members'];
    if (members is Map) {
      for (final entry in members.entries) {
        if (entry.key != search.source.uid && entry.value is Map) {
          final peer = entry.value as Map;
          return (peer['name'] ??
                  peer['displayName'] ??
                  peer['firstName'] ??
                  t('محادثة', 'Conversation', 'Conversation'))
              .toString();
        }
      }
    }
    return t('محادثة', 'Conversation', 'Conversation');
  }

  Future<void> open(ChatUnifiedSearchHit hit) async {
    if (opening) return;
    setState(() => opening = true);
    try {
      search.checkSession();
      if (!search.source.isCurrent) return;
      final chat = await search.source.chat(hit.chatId);
      if (!mounted) return;
      if (!search.source.isCurrent ||
          chat == null ||
          !(chat['memberIds'] as List? ?? []).contains(search.source.uid) ||
          chat['deletedBy_${search.source.uid}'] == true)
        throw StateError('Unavailable');
      await widget.onOpen(hit);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(t(
                'تعذر فتح الرسالة. أعد البحث للتحقق من توفرها.',
                'Unable to open message. Search again to check availability.',
                'Impossible d’ouvrir le message. Relancez la recherche.'))));
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  @override
  void dispose() {
    debounce?.cancel();
    sessionCheck?.cancel();
    search.removeListener(update);
    search.dispose();
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active =
        search.query.isNotEmpty || search.filter != ChatSearchFilter.all;
    return Scaffold(
        appBar: AppBar(
            title: Text(t('البحث في المحادثات', 'Search conversations',
                'Rechercher dans les discussions'))),
        body: SafeArea(
            child: Column(children: [
          Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                  controller: input,
                  autofocus: true,
                  onChanged: (_) {
                    debounce?.cancel();
                    debounce = Timer(const Duration(milliseconds: 350), run);
                  },
                  onSubmitted: (_) => run(),
                  decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: t('كلمة أو اسم ملف', 'Word or file name',
                          'Mot ou nom de fichier'),
                      suffixIcon: IconButton(
                          tooltip: t('مسح', 'Clear', 'Effacer'),
                          onPressed: () {
                            input.clear();
                            run();
                          },
                          icon: const Icon(Icons.close)),
                      border: const OutlineInputBorder()))),
          SizedBox(
              height: 48,
              child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final f in ChatSearchFilter.values)
                      Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: ChoiceChip(
                              label: Text(label(f)),
                              selected: search.filter == f,
                              onSelected: (_) {
                                search.filter = f;
                                run();
                              }))
                  ])),
          if (search.loading) const LinearProgressIndicator(),
          if (active)
            Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                    '${search.hits.length} ${t('نتيجة', 'results', 'résultats')} · ${search.scanned} ${t('رسالة مفحوصة', 'messages checked', 'messages examinés')}\n${search.hasMore ? t('البحث غير مكتمل بعد', 'Search is not complete yet', 'Recherche encore incomplète') : t('اكتمل البحث في السجل المتاح', 'Available history searched', 'Historique accessible parcouru')}',
                    textAlign: TextAlign.center)),
          if (search.skippedChats > 0)
            Text(t(
                'بعض المحادثات لم تعد متاحة',
                'Some conversations are no longer available',
                'Certaines discussions ne sont plus accessibles')),
          if (search.error != null)
            Padding(
                padding: const EdgeInsets.all(8),
                child: Text(t(
                    'تعذر إكمال البحث. تحقق من الاتصال والجلسة ثم أعد المحاولة.',
                    'Search interrupted. Check your connection and session, then retry.',
                    'Recherche interrompue. Vérifiez la connexion et la session, puis réessayez.'))),
          Expanded(
              child: search.hits.isEmpty
                  ? Center(
                      child: Text(active
                          ? t(
                              'لا توجد نتائج في الجزء المفحوص',
                              'No results in the checked history',
                              'Aucun résultat dans l’historique examiné')
                          : t(
                              'أدخل نصًا أو اختر نوع الوسائط',
                              'Enter text or choose a media type',
                              'Saisissez un texte ou choisissez un média')))
                  : ListView.builder(
                      itemCount: search.hits.length,
                      itemBuilder: (context, index) {
                        final hit = search.hits[index];
                        return ListTile(
                            enabled: !opening,
                            key: ValueKey('${hit.chatId}:${hit.messageId}'),
                            leading: const Icon(Icons.chat_bubble_outline),
                            title: Text(
                                hit.text.isEmpty
                                    ? switch (hit.type) {
                                        'image' ||
                                        'gif' =>
                                          label(ChatSearchFilter.images),
                                        'video' =>
                                          label(ChatSearchFilter.videos),
                                        'file' => label(ChatSearchFilter.files),
                                        _ => t('رسالة', 'Message', 'Message')
                                      }
                                    : hit.text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                                '${name(hit)} · ${MaterialLocalizations.of(context).formatShortDate(hit.createdAt)}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => open(hit));
                      })),
          if (active && search.hasMore)
            Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                    onPressed: search.loading ? null : search.loadMore,
                    icon: const Icon(Icons.search),
                    label: Text(t('متابعة البحث', 'Continue searching',
                        'Poursuivre la recherche')))),
        ])));
  }
}
