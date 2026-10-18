import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/services/chat_reaction.dart';

void main() {
  test('new choice replaces previous reaction and repeat removes it', () {
    expect(nextChatReaction(['❤️'], '👍'), ['👍']);
    expect(nextChatReaction(['👍'], '👍'), isEmpty);
    expect(nextChatReaction(null, '❤️'), ['❤️']);
  });
  test('legacy multiple reactions resolve to a single most recent choice', () {
    expect(chatReaction(['❤️', '👍', '😂']), '😂');
    expect(nextChatReaction(['❤️', '👍', '😂'], '🔥'), ['🔥']);
    expect(nextChatReaction(['❤️', '👍', '😂'], '😂'), isEmpty);
    expect(chatReaction('❤️'), '❤️');
    expect(chatReaction([null, 2, '']), isNull);
  });
}
