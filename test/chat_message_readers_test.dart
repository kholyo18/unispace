import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/services/chat_message_readers.dart';
import 'package:UniSpace/features/shell/chat/chat_message_info_sheet.dart';

void main() {
  final created = DateTime(2026, 10, 17, 10);
  final conversation = <String, dynamic>{
    'memberIds': ['sender', 'read', 'before', 'private', 'read'],
    'members': {
      'read': {'name': 'Reader Name'},
      'before': {'name': 'Other'}
    },
    'lastReadAt': {
      'sender': created,
      'read': created,
      'before': created.subtract(const Duration(seconds: 1)),
      'removed': created.add(const Duration(hours: 1)),
    },
    // Delivery and presence must never imply a read.
    'lastDeliveredAt': {'private': created.add(const Duration(hours: 1))},
  };
  List<ChatMessageReader> readers(
          {Map<String, dynamic>? data,
          String viewer = 'sender',
          bool pending = false,
          bool failed = false,
          int? time}) =>
      chatMessageReaders(
        conversation: data ?? conversation,
        viewerId: viewer,
        authorId: 'sender',
        createdAt: time ?? created.millisecondsSinceEpoch,
        timestamp: (value) => value is DateTime ? value : null,
        pending: pending,
        failed: failed,
      );
  test('projects only shared covering receipts for current members, once each',
      () {
    final result = readers();
    expect(result.map((reader) => reader.uid), ['read']);
    expect(result.single.name, 'Reader Name');
  });
  test('does not disclose readers for another author or revoked membership',
      () {
    expect(readers(viewer: 'read'), isEmpty);
    expect(readers(viewer: ''), isEmpty);
    expect(
        readers(data: {
          ...conversation,
          'memberIds': ['read']
        }),
        isEmpty);
  });
  test(
      'missing private receipts, invalid markers and pending messages stay unknown',
      () {
    expect(readers(pending: true), isEmpty);
    expect(readers(failed: true), isEmpty);
    expect(
        readers(data: {
          ...conversation,
          'lastReadAt': {'read': 'not a timestamp'}
        }),
        isEmpty);
    expect(readers(data: {...conversation, 'lastReadAt': null}), isEmpty);
    expect(
        chatMessageReaders(
            conversation: conversation,
            viewerId: 'sender',
            authorId: 'sender',
            createdAt: null,
            timestamp: (value) => value is DateTime ? value : null),
        isEmpty);
    expect(
        readers(
            time:
                created.add(const Duration(seconds: 1)).millisecondsSinceEpoch),
        isEmpty);
  });
  test('unknown member name stays empty rather than exposing raw ID', () {
    final result = readers(data: {...conversation, 'members': {}});
    expect(result.single.name, isEmpty);
  });

  Widget app(
          {required String language,
          List<ChatMessageReader>? rows,
          bool mine = true}) =>
      MaterialApp(
        locale: Locale(language),
        supportedLocales: const [Locale('ar'), Locale('fr'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
            body: ChatMessageInfoSheet(
                message: types.TextMessage(
                    id: 'm',
                    author: const types.User(id: 'sender'),
                    text: 'Hidden content',
                    createdAt: created.millisecondsSinceEpoch,
                    status: types.Status.sent),
                senderName: 'Sender',
                isMine: mine,
                readers: rows)),
      );
  for (final language in ['ar', 'fr', 'en']) {
    testWidgets('reader names and private empty state localized: $language',
        (tester) async {
      await tester.pumpWidget(app(language: language, rows: readers()));
      expect(find.text('Reader Name'), findsOneWidget);
      expect(
          find.text(language == 'ar'
              ? 'قرأها'
              : language == 'fr'
                  ? 'Lu par'
                  : 'Read by'),
          findsOneWidget);
      expect(find.text('Hidden content'), findsNothing);
      await tester.pumpWidget(app(language: language, rows: const []));
      expect(
          find.text(language == 'ar'
              ? 'لا توجد تأكيدات قراءة مشتركة حتى الآن'
              : language == 'fr'
                  ? 'Aucune confirmation de lecture partagée pour le moment'
                  : 'No shared read receipts yet'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('incoming or omitted readers do not show reader identities',
      (tester) async {
    await tester.pumpWidget(app(language: 'en', rows: readers(), mine: false));
    expect(find.text('Reader Name'), findsNothing);
    expect(find.text('Read by'), findsNothing);
    await tester.pumpWidget(app(language: 'en'));
    expect(find.text('Read by'), findsNothing);
  });
}
