import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

String _s(BuildContext context, String ar, String fr, String en) =>
    switch (Localizations.localeOf(context).languageCode) {
      'ar' => ar,
      'fr' => fr,
      _ => en
    };

bool isVisibleStarredMessage(
    Map<String, dynamic> data, String uid, DateTime? clearedAt) {
  if ((data['starredBy'] as Map?)?[uid] != true ||
      (data['hiddenBy'] as Map?)?[uid] == true ||
      data['deleted'] == true ||
      data['deletedAt'] != null ||
      data['type'] == 'viewOnce') return false;
  final created = data['createdAt'];
  return clearedAt == null ||
      created is Timestamp && created.toDate().isAfter(clearedAt);
}

class ChatStarredMessagesPage extends StatefulWidget {
  const ChatStarredMessagesPage(
      {super.key,
      required this.chatId,
      required this.ownerUid,
      required this.isCurrent});
  final String chatId, ownerUid;
  final bool Function() isCurrent;
  @override
  State<ChatStarredMessagesPage> createState() =>
      _ChatStarredMessagesPageState();
}

class _ChatStarredMessagesPageState extends State<ChatStarredMessagesPage> {
  late final _chat = FirebaseFirestore.instance
      .collection('chats')
      .doc(widget.chatId)
      .snapshots();
  late final _stars = FirebaseFirestore.instance
      .collection('chats')
      .doc(widget.chatId)
      .collection('messages')
      .where('starredBy.${widget.ownerUid}', isEqualTo: true)
      .snapshots();
  StreamSubscription<User?>? _auth;
  bool _revoked = false;
  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance.userChanges().listen((user) {
      if (mounted && (user?.uid != widget.ownerUid || !widget.isCurrent()))
        setState(() => _revoked = true);
    });
  }

  @override
  void dispose() {
    _auth?.cancel();
    super.dispose();
  }

  Widget _unavailable() => Center(
      child: Text(_s(context, 'المحادثة غير متاحة', 'Discussion indisponible',
          'Conversation unavailable')));
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(_s(context, 'الرسائل المميزة بنجمة', 'Messages favoris',
                'Starred messages'))),
        body: _revoked || !widget.isCurrent()
            ? _unavailable()
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _chat,
                builder: (context, chat) {
                  if (chat.hasError) return _unavailable();
                  if (!chat.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final data = chat.data!.data();
                  if (data == null ||
                      !(data['memberIds'] as List? ?? [])
                          .contains(widget.ownerUid)) return _unavailable();
                  final cleared = (data['clearedAt'] as Map?)?[widget.ownerUid];
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _stars,
                      builder: (context, snapshot) {
                        if (snapshot.hasError)
                          return Center(
                              child: Text(_s(
                                  context,
                                  'تعذر تحميل الرسائل المميزة',
                                  'Impossible de charger les favoris',
                                  'Could not load starred messages')));
                        if (!snapshot.hasData)
                          return const Center(
                              child: CircularProgressIndicator());
                        final docs = snapshot.data!.docs
                            .where((d) => isVisibleStarredMessage(
                                d.data(),
                                widget.ownerUid,
                                cleared is Timestamp ? cleared.toDate() : null))
                            .toList()
                          ..sort((a, b) => ((b.data()['createdAt']
                                          as Timestamp?)
                                      ?.millisecondsSinceEpoch ??
                                  0)
                              .compareTo((a.data()['createdAt'] as Timestamp?)
                                      ?.millisecondsSinceEpoch ??
                                  0));
                        if (docs.isEmpty)
                          return Center(
                              child: Text(_s(
                                  context,
                                  'لا توجد رسائل مميزة',
                                  'Aucun message favori',
                                  'No starred messages')));
                        return ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: docs.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final message = docs[index].data();
                              final type = message['type'];
                              final text =
                                  (message['text'] as String? ?? '').trim();
                              final caption =
                                  (message['caption'] as String? ?? '').trim();
                              final preview = text.isNotEmpty
                                  ? text
                                  : caption.isNotEmpty
                                      ? caption
                                      : switch (type) {
                                          'image' || 'gif' => _s(context,
                                              'صورة', 'Photo', 'Photo'),
                                          'video' => _s(context, 'فيديو',
                                              'Vidéo', 'Video'),
                                          'audio' => _s(context, 'تسجيل صوتي',
                                              'Message vocal', 'Voice message'),
                                          'poll' =>
                                            (message['question'] as String?) ??
                                                _s(context, 'استطلاع',
                                                    'Sondage', 'Poll'),
                                          'file' =>
                                            (message['fileName'] as String?) ??
                                                _s(context, 'ملف', 'Fichier',
                                                    'File'),
                                          _ => _s(context, 'رسالة', 'Message',
                                              'Message'),
                                        };
                              return ListTile(
                                  leading: const Icon(Icons.star_rounded,
                                      color: Colors.amber),
                                  title: Text(preview),
                                  trailing: IconButton(
                                      icon:
                                          const Icon(Icons.star_border_rounded),
                                      tooltip: _s(context, 'إلغاء التمييز',
                                          'Retirer des favoris', 'Unstar'),
                                      onPressed: () async {
                                        if (_revoked || !widget.isCurrent())
                                          return;
                                        try {
                                          await docs[index].reference.update({
                                            'starredBy.${widget.ownerUid}':
                                                FieldValue.delete()
                                          });
                                        } catch (_) {
                                          if (context.mounted)
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text(_s(
                                                        context,
                                                        'تعذر إلغاء التمييز',
                                                        'Impossible de retirer le favori',
                                                        'Could not unstar message'))));
                                        }
                                      }));
                            });
                      });
                },
              ),
      );
}
