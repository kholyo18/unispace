import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';

class ChatTranslation {
  const ChatTranslation(this.text, this.source);
  final String text, source;

  /// Basic output checks only. Isolated-word lexical evidence is checked by
  /// ChatTranslationService before constructing an accepted result.
  bool canReplace(String original, String target) {
    final language = source.trim().toLowerCase();
    return !const ['', 'auto', 'und', 'unknown'].contains(language) &&
        language != target.trim().toLowerCase() &&
        text.trim().isNotEmpty &&
        text.trim().toLowerCase() != original.trim().toLowerCase();
  }
}

typedef ChatTranslate = Future<ChatTranslation> Function(
    String text, String target);

/// Memory-only, conversation-scoped cache. Never changes the stored message.
class ChatTranslationService {
  ChatTranslationService({ChatTranslate? translate, http.Client? client})
      : _translate = translate ??
            ((text, target) =>
                translateConservatively(text, target, client: client));
  final ChatTranslate _translate;
  final _cache = LinkedHashMap<(String, String), ChatTranslation>();
  Future<void> _tail = Future.value();
  bool _closed = false;
  static Future<ChatTranslation> translateConservatively(
      String text, String target,
      {String source = 'auto', http.Client? client}) async {
    // Whole sentences keep the existing contextual translator. Isolated words
    // require lexical evidence; language detection alone accepts invented words.
    if (!RegExp(r'\s').hasMatch(text.trim())) {
      return _dictionaryTranslation(text, target,
          source: source, client: client);
    }
    final result =
        await GoogleTranslator().translate(text, from: source, to: target);
    return ChatTranslation(result.text, result.sourceLanguage.code);
  }

  static String _lexicalKey(String text) => text
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'^[.,!?;:،؛؟…"“”«»()]+|[.,!?;:،؛؟…"“”«»()]+$'), '');

  static Future<ChatTranslation> _dictionaryTranslation(
      String text, String target,
      {required String source, http.Client? client}) async {
    final original = ChatTranslation(text, 'auto');
    final key = _lexicalKey(text);
    // Do not turn handles, identifiers, numbers or emoji into guessed words.
    if (!RegExp(r"^[\p{L}\p{M}]+(?:['’\-][\p{L}\p{M}]+)*$", unicode: true)
        .hasMatch(key)) return original;
    try {
      // Same endpoint used by translator. Dictionary fields are undocumented:
      // any missing/changed schema must preserve the original, never guess.
      final uri = Uri.https('translate.googleapis.com', '/translate_a/single', {
        'client': 'gtx',
        'sl': source,
        'tl': target,
        'q': text,
        'dj': '1',
        'dt': ['t', 'bd', 'md'],
      });
      final response = await (client == null ? http.get(uri) : client.get(uri))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return original;
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return original;
      bool hasExactEntry(Object? groups, String meaningField) {
        if (groups is! List) return false;
        return groups.any((group) =>
            group is Map &&
            group['base_form'] is String &&
            _lexicalKey(group['base_form'] as String) == key &&
            group['entry'] is List &&
            (group['entry'] as List).any((entry) =>
                entry is Map &&
                entry[meaningField] is String &&
                (entry[meaningField] as String).trim().isNotEmpty));
      }

      if (!hasExactEntry(body['dict'], 'word') &&
          !hasExactEntry(body['definitions'], 'gloss')) return original;
      final sentences = body['sentences'];
      final detectedSource = body['src'];
      if (sentences is! List || detectedSource is! String) return original;
      final translated = StringBuffer();
      for (final sentence in sentences) {
        if (sentence is Map && sentence['trans'] is String) {
          translated.write(sentence['trans']);
        }
      }
      final result = ChatTranslation(translated.toString(), detectedSource);
      return result.canReplace(text, target) ? result : original;
    } catch (_) {
      // An unavailable dictionary is not permission to invent a translation.
      return original;
    }
  }

  Future<ChatTranslation> translate(String text, String target,
      {required bool Function() isCurrent}) {
    final future = _tail.then((_) async {
      if (_closed || !isCurrent()) throw StateError('Translation cancelled');
      final key = (text, target);
      final cached = _cache.remove(key);
      if (cached != null) {
        _cache[key] = cached;
        return cached;
      }
      final proposed =
          await _translate(text, target).timeout(const Duration(seconds: 20));
      final result = proposed.canReplace(text, target)
          ? proposed
          : ChatTranslation(text, proposed.source);
      if (_closed || !isCurrent()) throw StateError('Translation cancelled');
      _cache[key] = result;
      if (_cache.length > 100) _cache.remove(_cache.keys.first);
      return result;
    });
    _tail = future.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return future;
  }

  void dispose() {
    _closed = true;
    _cache.clear();
  }
}

String chatTranslationTarget(String saved, String locale) =>
    const ['ar', 'fr', 'en', 'es', 'de', 'tr', 'it'].contains(saved)
        ? saved
        : const ['ar', 'fr', 'en'].contains(locale)
            ? locale
            : 'en';
