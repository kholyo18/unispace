import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:UniSpace/services/chat_translation.dart';

void main() {
  Map<String, dynamic> response(
          {Object? dictionary,
          Object? definitions,
          String source = 'en',
          String translation = 'bonjour'}) =>
      {
        'src': source,
        'confidence': 1.0,
        'sentences': [
          {'trans': translation}
        ],
        if (dictionary != null) 'dict': dictionary,
        if (definitions != null) 'definitions': definitions,
      };
  List<Map<String, dynamic>> dictionary(String word) => [
        {
          'base_form': word,
          'entry': [
            {'word': 'bonjour'}
          ]
        },
      ];
  Future<String> translate(Object body, {String text = 'hello'}) async {
    final client = MockClient((_) async => http.Response(jsonEncode(body), 200,
        headers: {'content-type': 'application/json; charset=utf-8'}));
    final service = ChatTranslationService(client: client);
    try {
      return (await service.translate(text, 'fr', isCurrent: () => true)).text;
    } finally {
      service.dispose();
      client.close();
    }
  }

  test('accepts an exact dictionary entry and requests lexical fields',
      () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'translate.googleapis.com');
      expect(request.url.queryParametersAll['dt'], ['t', 'bd', 'md']);
      expect(request.url.queryParameters['q'], 'hello');
      return http.Response(
          jsonEncode(response(dictionary: dictionary('Hello!'))), 200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    });
    final service = ChatTranslationService(client: client);
    expect((await service.translate('hello', 'fr', isCurrent: () => true)).text,
        'bonjour');
    service.dispose();
    client.close();
  });

  test(
      'high language confidence without a dictionary cannot translate nonsense',
      () async {
    expect(await translate(response(), text: 'qzvxxjkp'), 'qzvxxjkp');
  });

  test('random Arabic letters are not replaced by Latin transliteration',
      () async {
    expect(
        await translate(response(source: 'ar', translation: 'al anla'),
            text: 'الانلا'),
        'الانلا');
  });
  test('rejects an entry for a corrected or different word', () async {
    expect(
        await translate(response(dictionary: dictionary('hello')),
            text: 'helllo'),
        'helllo');
  });

  test('accepts exact source definition when bilingual dictionary is absent',
      () async {
    expect(
        await translate(response(definitions: [
          {
            'base_form': 'hello',
            'entry': [
              {'gloss': 'a greeting'}
            ]
          },
        ])),
        'bonjour');
  });

  test('preserves valid but uncovered words and malformed lexical evidence',
      () async {
    for (final body in [
      response(dictionary: []),
      response(dictionary: [
        {'base_form': 'hello', 'entry': []}
      ]),
      response(dictionary: [
        {
          'base_form': 'hello',
          'entry': [
            {'word': ''}
          ]
        }
      ]),
      response(dictionary: [
        {'base_form': 'hello', 'entry': 'unexpected'}
      ]),
      response(definitions: [
        {
          'base_form': 'another',
          'entry': [
            {'gloss': 'a greeting'}
          ]
        }
      ]),
      {'dict': dictionary('hello'), 'src': 'en'},
      [],
    ]) {
      expect(await translate(body), 'hello');
    }
  });

  test('does not confuse handles, codes and emoji with dictionary words',
      () async {
    final client =
        MockClient((_) async => throw StateError('must not request'));
    final service = ChatTranslationService(client: client);
    for (final text in ['@hello', 'abc123', '12345', '😀']) {
      expect((await service.translate(text, 'fr', isCurrent: () => true)).text,
          text);
    }
    service.dispose();
    client.close();
  });

  test('Arabic and French exact lexical entries are supported', () async {
    expect(
        await translate(response(dictionary: dictionary('مرحبا'), source: 'ar'),
            text: 'مرحبا'),
        'bonjour');
    final client = MockClient((_) async => http.Response(
        jsonEncode(response(
            dictionary: dictionary('école'),
            source: 'fr',
            translation: 'school')),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'}));
    final service = ChatTranslationService(client: client);
    expect((await service.translate('école', 'en', isCurrent: () => true)).text,
        'school');
    service.dispose();
    client.close();
  });

  test('failure or invalid provider JSON preserves original', () async {
    for (final failure in [false, true]) {
      final client = MockClient((_) async {
        if (failure) throw http.ClientException('offline');
        return http.Response('not json', 503);
      });
      final service = ChatTranslationService(client: client);
      expect(
          (await service.translate('hello', 'fr', isCurrent: () => true)).text,
          'hello');
      service.dispose();
      client.close();
    }
  });
  test('manual translation preserves explicit source language', () async {
    final client = MockClient((request) async {
      expect(request.url.queryParameters['sl'], 'en');
      return http.Response(
          jsonEncode(response(dictionary: dictionary('hello'))), 200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    });
    final result = await ChatTranslationService.translateConservatively(
        'hello', 'fr',
        source: 'en', client: client);
    expect(result.text, 'bonjour');
    client.close();
  });
}
