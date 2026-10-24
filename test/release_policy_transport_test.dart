import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:UniSpace/config/app_links.dart';
import 'package:UniSpace/services/release_policy.dart';
void main() {
  test('public startup check needs no auth or App Check and preserves required version', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), 'https://europe-west1-example-project.cloudfunctions.net/readReleasePolicy');
      expect(request.method, 'POST'); expect(request.followRedirects, false);
      expect(request.headers.containsKey('authorization'), false);
      expect(request.headers.containsKey('x-firebase-appcheck'), false);
      expect(jsonDecode(request.body), {'data': {}});
      return http.Response(jsonEncode({'result': {'enabled': true, 'minimumBuild': 8, 'storeUrl': AppLinks.storeUrl}}),200);
    });
    final policy = await ReleasePolicy.fetchFrom(client, projectId: 'example-project');
    expect(policy.allows(7), false); expect(policy.allows(8), true);
  });
  for (final status in [301,401,403,404,503]) {
    test('HTTP $status cannot admit an unknown version', () async {
      await expectLater(ReleasePolicy.fetchFrom(MockClient((_) async => http.Response('error',status)), projectId:'example-project'),
        throwsA(isA<FirebaseFunctionsException>()));
    });
  }
  for(final body in ['{}','{"result":{"enabled":false}}','not-json']) {
    test('invalid body fails closed: $body', () async {
      await expectLater(ReleasePolicy.fetchFrom(MockClient((_) async => http.Response(body,200)),projectId:'example-project'), throwsFormatException);
    });
  }
}
