import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/services/chat_group_link.dart';
void main() {
  final token=List.filled(64,'a').join();
  test('accepts only complete group invitation route', () {
    expect(isChatGroupJoinLink(Uri.parse('unispace://group/join?groupId=group_1&token=$token')),isTrue);
    for(final link in ['https://group/join?groupId=group_1&token=$token','unispace://group/other?groupId=group_1&token=$token','unispace://group/join?groupId=../g&token=$token','unispace://group/join?groupId=group_1&token=short','unispace://group/join?groupId=group_1&groupId=group_2&token=$token','unispace://group/join?groupId=group_1&token=$token#extra']) {
      expect(isChatGroupJoinLink(Uri.parse(link)),isFalse,reason:link);
    }
  });
}
