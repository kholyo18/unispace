import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/services/post_media_links.dart';

Map<String, dynamic> response({String post = 'post', int? expiry}) => {
      'post': {
        'id': post,
        'data': {'title': 'fresh'}
      },
      'items': [
        {
          'source': 'source',
          'url': 'https://storage.googleapis.com/b/v?generation=1',
          'expiresAt': expiry ?? DateTime.now().millisecondsSinceEpoch + 60000
        }
      ],
    };
void main() {
  PostMediaGrant parse(Map<String, dynamic> data) =>
      PostMediaGrant.fromResponse(
          viewer: 'viewer',
          postId: 'post',
          sources: ['source'],
          response: data);
  test('grant is scoped and sealed before a later navigation can reuse it', () {
    final grant = parse(response());
    expect(grant.data['title'], 'fresh');
    expect(grant.link('viewer', 'post', 'source'), startsWith('https:'));
    expect(grant.link('other', 'post', 'source'), isNull);
    expect(grant.link('viewer', 'other', 'source'), isNull);
    expect(grant.link('viewer', 'post', 'other'), isNull);
    grant.seal();
    expect(grant.link('viewer', 'post', 'source'), isNull);
    grant.seal();
    expect(grant.link('viewer', 'post', 'source'), isNull);
  });
  test('wrong post, expired or incomplete grants fail closed', () {
    expect(() => parse(response(post: 'other')), throwsStateError);
    expect(() => parse(response(expiry: 1)), throwsStateError);
    expect(() => parse({...response(), 'items': []}), throwsStateError);
    final valid = response();
    expect(
        () => parse({
              ...valid,
              'items': [...valid['items'], ...valid['items']]
            }),
        throwsStateError);
  });
}
