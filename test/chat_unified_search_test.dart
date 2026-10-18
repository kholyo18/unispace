import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/services/chat_unified_search.dart';

class Source implements ChatSearchSource {
  @override
  String uid = 'me';
  @override
  bool isCurrent = true;
  int messageReads = 0;
  Completer<ChatSearchBatch>? gate;
  Map<String, dynamic> data = {
    'memberIds': ['me', 'other']
  };
  @override
  Future<Map<String, dynamic>?> chat(String id) async => data;
  @override
  Future<ChatSearchBatch> chats(Object? cursor) async =>
      ChatSearchBatch([ChatSearchRecord('chat', data)], hasMore: false);
  @override
  Future<ChatSearchBatch> messages(String id, Object? cursor) async {
    messageReads++;
    if (gate != null) return gate!.future;
    final page = (cursor as int? ?? 0) + 1;
    return ChatSearchBatch([
      ChatSearchRecord('$page', {
        'type': 'text',
        'text': 'école أهلاً',
        'createdAt': DateTime(2026, 1, page)
      })
    ], cursor: page, hasMore: page < 7);
  }
}

void main() {
  test(
      'bounded continuation reports partial progress and eventually all history',
      () async {
    final source = Source();
    final search = ChatUnifiedSearchController(source);
    await search.search('ecole', ChatSearchFilter.text);
    expect(source.messageReads, 4);
    expect(search.hits.length, 4);
    expect(search.hasMore, true);
    await search.loadMore();
    expect(search.hits.length, 7);
    expect(search.hasMore, false);
    expect(search.scanned, 7);
    search.dispose();
  });
  test('hidden cleared deleted and view-once content never becomes results',
      () {
    final chat = {
      'memberIds': ['me'],
      'clearedAt': {'me': DateTime(2026, 1, 2)}
    };
    ChatUnifiedSearchHit? match(Map<String, dynamic> fields) =>
        matchChatSearchMessage(
            chatId: 'c',
            chat: chat,
            message: ChatSearchRecord('m', {
              'createdAt': DateTime(2026, 1, 3),
              'text': 'secret',
              'type': 'text',
              ...fields
            }),
            uid: 'me',
            query: 'secret',
            filter: ChatSearchFilter.all);
    expect(match({}), isNotNull);
    expect(
        match({
          'hiddenBy': {'me': true}
        }),
        isNull);
    expect(match({'createdAt': DateTime(2026, 1, 2)}), isNull);
    expect(match({'type': 'viewOnce'}), isNull);
    expect(match({'deleted': true}), isNull);
  });
  test('filters use content type and visible text without searching media URLs',
      () {
    ChatUnifiedSearchHit? match(
            String type, ChatSearchFilter filter, Map<String, dynamic> extra) =>
        matchChatSearchMessage(
            chatId: 'c',
            chat: {
              'memberIds': ['me']
            },
            message: ChatSearchRecord(
                'm', {'createdAt': DateTime(2026), 'type': type, ...extra}),
            uid: 'me',
            query: '',
            filter: filter);
    expect(match('image', ChatSearchFilter.images, {}), isNotNull);
    expect(match('video', ChatSearchFilter.images, {}), isNull);
    expect(match('file', ChatSearchFilter.files, {'fileName': 'report.pdf'}),
        isNotNull);
    expect(
        match('text', ChatSearchFilter.links, {'text': 'https://example.com'}),
        isNotNull);
    expect(
        match('image', ChatSearchFilter.links,
            {'imageUrl': 'https://private/token'}),
        isNull);
  });
  test('account switching discards an in-flight response and existing hits',
      () async {
    final source = Source();
    final search = ChatUnifiedSearchController(source);
    source.gate = Completer();
    final pending = search.search('ecole', ChatSearchFilter.text);
    await Future<void>.delayed(Duration.zero);
    source.isCurrent = false;
    source.gate!.complete(ChatSearchBatch([
      ChatSearchRecord('secret', {'createdAt': DateTime(2026), 'text': 'ecole'})
    ], hasMore: false));
    await pending;
    expect(search.hits, isEmpty);
    expect(search.hasMore, false);
    search.dispose();
  });
  test('membership loss removes previous matching messages', () async {
    final source = Source();
    final search = ChatUnifiedSearchController(source);
    await search.search('اهلا', ChatSearchFilter.text);
    expect(search.hits, isNotEmpty);
    source.data = {
      'memberIds': ['other']
    };
    await search.loadMore();
    expect(search.hits, isEmpty);
    expect(search.skippedChats, 1);
    search.dispose();
  });
  test('new query suppresses stale in-flight results', () async {
    final source = Source();
    final search = ChatUnifiedSearchController(source);
    source.gate = Completer();
    final old = search.search('ecole', ChatSearchFilter.text);
    await Future<void>.delayed(Duration.zero);
    await search.search('', ChatSearchFilter.all);
    source.gate!.complete(ChatSearchBatch([
      ChatSearchRecord('old', {'createdAt': DateTime(2026), 'text': 'ecole'})
    ], hasMore: false));
    await old;
    expect(search.hits, isEmpty);
    expect(search.loading, false);
    search.dispose();
  });
}
