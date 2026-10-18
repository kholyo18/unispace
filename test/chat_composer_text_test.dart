import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/shell/chat/chat_composer_text.dart';

void main() {
  test('inserts full ZWJ emoji at caret without changing Arabic text', () {
    const emoji = '👨‍👩‍👧‍👦';
    const original = TextEditingValue(text: 'مرحبا عالم',
      selection: TextSelection.collapsed(offset: 6));
    final next = insertChatComposerText(original, emoji);
    expect(next.text, 'مرحبا '+emoji+'عالم');
    expect(next.selection.baseOffset, 6 + emoji.length);
  });

  test('replaces reversed selection and preserves skin tone and flag sequences', () {
    const emoji = '👍🏽🇩🇿';
    const original = TextEditingValue(text: 'Bonjour OLD world',
      selection: TextSelection(baseOffset: 11, extentOffset: 8));
    final next = insertChatComposerText(original, emoji);
    expect(next.text, 'Bonjour '+emoji+' world');
    expect(next.selection, TextSelection.collapsed(offset: 8 + emoji.length));
  });

  test('appends with no valid selection and ends stale IME composition', () {
    const original = TextEditingValue(text: 'سلام',
      composing: TextRange(start: 0, end: 4));
    final next = insertChatComposerText(original, '🫠');
    expect(next.text, 'سلام🫠');
    expect(next.selection.baseOffset, next.text.length);
    expect(next.composing, TextRange.empty);
  });

  test('empty picker result preserves selection and composition', () {
    const original = TextEditingValue(text: 'hello',
      selection: TextSelection.collapsed(offset: 2),
      composing: TextRange(start: 0, end: 5));
    expect(insertChatComposerText(original, ''), original);
  });
}
