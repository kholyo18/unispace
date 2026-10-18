import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../ui/settings/public_profile_service.dart';
import 'community_search_text.dart';

enum ChatSearchFilter { all, text, images, videos, files, links }

class ChatSearchRecord {
  const ChatSearchRecord(this.id, this.data);
  final String id;
  final Map<String, dynamic> data;
}

class ChatSearchBatch {
  const ChatSearchBatch(this.records, {this.cursor, required this.hasMore});
  final List<ChatSearchRecord> records;
  final Object? cursor;
  final bool hasMore;
}

abstract class ChatSearchSource {
  String get uid;
  bool get isCurrent;
  Future<ChatSearchBatch> chats(Object? cursor);
  Future<Map<String, dynamic>?> chat(String id);
  Future<ChatSearchBatch> messages(String chatId, Object? cursor);
}

class FirestoreChatSearchSource implements ChatSearchSource {
  FirestoreChatSearchSource()
      : uid = FirebaseAuth.instance.currentUser?.uid ?? '',
        _session = PublicProfileService.viewerSession;
  @override
  final String uid;
  final String? _session;
  @override
  bool get isCurrent =>
      uid.isNotEmpty &&
      FirebaseAuth.instance.currentUser?.uid == uid &&
      PublicProfileService.viewerSession == _session;
  void _guard() {
    if (!isCurrent) throw StateError('Chat session changed');
  }

  @override
  Future<ChatSearchBatch> chats(Object? cursor) async {
    _guard();
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('chats')
        .where('memberIds', arrayContains: uid)
        .orderBy(FieldPath.documentId)
        .limit(20);
    if (cursor != null)
      query = query.startAfterDocument(cursor as DocumentSnapshot);
    final page = await query.get(const GetOptions(source: Source.server));
    _guard();
    return ChatSearchBatch(
        page.docs.map((d) => ChatSearchRecord(d.id, d.data())).toList(),
        cursor: page.docs.lastOrNull,
        hasMore: page.docs.length == 20);
  }

  @override
  Future<Map<String, dynamic>?> chat(String id) async {
    _guard();
    final doc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(id)
        .get(const GetOptions(source: Source.server));
    _guard();
    return doc.data();
  }

  @override
  Future<ChatSearchBatch> messages(String chatId, Object? cursor) async {
    _guard();
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(40);
    if (cursor != null)
      query = query.startAfterDocument(cursor as DocumentSnapshot);
    final page = await query.get(const GetOptions(source: Source.server));
    _guard();
    return ChatSearchBatch(
        page.docs.map((d) => ChatSearchRecord(d.id, d.data())).toList(),
        cursor: page.docs.lastOrNull,
        hasMore: page.docs.length == 40);
  }
}

class ChatUnifiedSearchHit {
  const ChatUnifiedSearchHit(
      {required this.chatId,
      required this.messageId,
      required this.chatData,
      required this.text,
      required this.type,
      required this.createdAt});
  final String chatId, messageId, text, type;
  final Map<String, dynamic> chatData;
  final DateTime createdAt;
}

class _History {
  _History(this.id);
  final String id;
  Object? cursor;
}

DateTime? _date(Object? value) => value is Timestamp
    ? value.toDate()
    : value is DateTime
        ? value
        : null;
bool _visibleChat(Map<String, dynamic>? data, String uid) =>
    data != null &&
    data['memberIds'] is List &&
    (data['memberIds'] as List).contains(uid) &&
    data['deletedBy_$uid'] != true;

/// Each continuation reads at most five bounded pages. No result is called
/// complete until the member chat list and every accessible history end.
class ChatUnifiedSearchController extends ChangeNotifier {
  ChatUnifiedSearchController(this.source);
  final ChatSearchSource source;
  final List<ChatUnifiedSearchHit> _hits = [];
  List<ChatUnifiedSearchHit> get hits => List.unmodifiable(_hits);
  final Queue<_History> _pending = Queue();
  Object? _chatCursor;
  bool _moreChats = true, loading = false, _disposed = false;
  bool get hasMore => _moreChats || _pending.isNotEmpty;
  int scanned = 0, skippedChats = 0, _generation = 0;
  String query = '';
  ChatSearchFilter filter = ChatSearchFilter.all;
  Object? error;
  void checkSession() {
    if (!source.isCurrent) {
      _generation++;
      _hits.clear();
      _pending.clear();
      _moreChats = false;
      loading = false;
      error = StateError('Chat session changed');
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> search(String text, ChatSearchFilter selected) async {
    _generation++;
    query = normalizeCommunitySearch(text);
    filter = selected;
    _hits.clear();
    _pending.clear();
    _chatCursor = null;
    _moreChats = true;
    scanned = 0;
    skippedChats = 0;
    loading = false;
    error = null;
    if (query.isEmpty && filter == ChatSearchFilter.all) {
      _moreChats = false;
      notifyListeners();
      return;
    }
    await loadMore();
  }

  Future<void> loadMore() async {
    if (_disposed || loading || !hasMore) return;
    checkSession();
    if (!source.isCurrent) return;
    final generation = _generation;
    bool current() =>
        !_disposed && generation == _generation && source.isCurrent;
    loading = true;
    error = null;
    notifyListeners();
    try {
      for (var i = 0; i < 5 && current() && hasMore; i++) {
        if (_pending.isEmpty) {
          final page = await source.chats(_chatCursor);
          if (!current()) break;
          _chatCursor = page.cursor;
          _moreChats = page.hasMore;
          for (final chat in page.records) {
            if (_visibleChat(chat.data, source.uid))
              _pending.add(_History(chat.id));
          }
        } else {
          final history = _pending.first;
          try {
            final chat = await source.chat(history.id);
            if (!current()) break;
            if (!_visibleChat(chat, source.uid)) {
              _pending.removeFirst();
              _hits.removeWhere((h) => h.chatId == history.id);
              skippedChats++;
              continue;
            }
            final page = await source.messages(history.id, history.cursor);
            if (!current()) break;
            scanned += page.records.length;
            for (final message in page.records) {
              final hit = matchChatSearchMessage(
                  chatId: history.id,
                  chat: chat!,
                  message: message,
                  uid: source.uid,
                  query: query,
                  filter: filter);
              if (hit != null &&
                  !_hits.any((h) =>
                      h.chatId == hit.chatId && h.messageId == hit.messageId))
                _hits.add(hit);
            }
            _pending.removeFirst();
            history.cursor = page.cursor;
            if (page.hasMore) _pending.addLast(history);
          } on FirebaseException catch (e) {
            if (e.code != 'permission-denied' && e.code != 'not-found') rethrow;
            if (!current()) break;
            _pending.removeFirst();
            _hits.removeWhere((h) => h.chatId == history.id);
            skippedChats++;
          }
        }
      }
      _hits.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      if (current()) error = e;
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        checkSession();
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}

ChatUnifiedSearchHit? matchChatSearchMessage(
    {required String chatId,
    required Map<String, dynamic> chat,
    required ChatSearchRecord message,
    required String uid,
    required String query,
    required ChatSearchFilter filter}) {
  if (!_visibleChat(chat, uid)) return null;
  final data = message.data, type = (message.data['type'] ?? 'text').toString();
  final created = _date(data['createdAt']);
  final cleared =
      chat['clearedAt'] is Map ? _date((chat['clearedAt'] as Map)[uid]) : null;
  if (created == null ||
      cleared != null && !created.isAfter(cleared) ||
      (data['hiddenBy'] is Map && (data['hiddenBy'] as Map)[uid] == true) ||
      data['deleted'] == true ||
      data['deletedAt'] != null ||
      (data['hiddenBy'] is List && (data['hiddenBy'] as List).contains(uid)) ||
      data['deletedForEveryone'] == true ||
      type == 'deleted' ||
      type == 'viewOnce') return null;
  final text = [data['text'], data['caption'], data['fileName']]
      .whereType<String>()
      .where((v) => v.isNotEmpty)
      .join(' ');
  final allowed = switch (filter) {
    ChatSearchFilter.all => true,
    ChatSearchFilter.text => type == 'text',
    ChatSearchFilter.images => type == 'image' || type == 'gif',
    ChatSearchFilter.videos => type == 'video',
    ChatSearchFilter.files => type == 'file',
    ChatSearchFilter.links =>
      RegExp(r'https?://[^\s]+', caseSensitive: false).hasMatch(text)
  };
  if (!allowed ||
      !normalizeCommunitySearch(text).contains(normalizeCommunitySearch(query)))
    return null;
  return ChatUnifiedSearchHit(
      chatId: chatId,
      messageId: message.id,
      chatData: Map.unmodifiable(chat),
      text: text,
      type: type,
      createdAt: created);
}
