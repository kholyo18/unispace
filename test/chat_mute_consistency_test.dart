import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/services/chat_preferences_client.dart';

void main() {
  const uid = 'viewer.with.`dots';
  bool read(Map<String, dynamic> data, [String owner = uid]) =>
      ChatPreferencesSnapshot.fromData(data, owner).muted;

  test('MUTECONSISTENCYREGRESSION: legacy mute is visible in detail reader',
      () {
    expect(read({'muted_$uid': true}), isTrue);
  });

  for (final value in [true, false]) {
    test(
      'MUTECONSISTENCYREGRESSION: explicit $value writes both representations atomically',
      () async {
        final writes = <Map<String, dynamic>>[];
        final client = ChatPreferencesClient(
          expectedUid: uid,
          currentUid: () => uid,
          sessionKey: () => 'menu-session',
          merge: (data) async => writes.add(data),
          serverTimestamp: Object.new,
          deleteField: Object.new,
        );
        addTearDown(client.dispose);
        expect(await client.setMuted(value), isTrue);
        expect(writes, [
          {
            'muted': {uid: value},
            'muted_$uid': value,
          },
        ]);
      },
    );
  }

  test('canonical-only mute and unmute retain their meaning', () {
    for (final value in [true, false]) {
      expect(
          read({
            'muted': {uid: value}
          }),
          value);
    }
  });
  test('either existing true wins a conflict until explicit reconciliation',
      () {
    expect(
        read({
          'muted': {uid: true},
          'muted_$uid': false
        }),
        isTrue);
    expect(
        read({
          'muted': {uid: false},
          'muted_$uid': true
        }),
        isTrue);
  });
  test('both false and entirely missing are unmuted', () {
    expect(
        read({
          'muted': {uid: false},
          'muted_$uid': false
        }),
        isFalse);
    expect(read({}), isFalse);
  });
  test('non-boolean values do not become mute decisions', () {
    for (final value in <Object?>[null, 'true', 1, 0, [], {}]) {
      expect(
          read({
            'muted': {uid: value},
            'muted_$uid': value
          }),
          isFalse);
    }
  });
  test('malformed canonical containers cannot hide a recognized legacy mute',
      () {
    for (final value in <Object?>[null, true, 'bad', 7, []]) {
      expect(read({'muted': value, 'muted_$uid': true}), isTrue);
      expect(read({'muted': value}), isFalse);
    }
  });
  test('unrecognized literal dotted keys are not promoted into preferences',
      () {
    expect(
        read({
          'muted.$uid': true,
          'muted': {
            'viewer': {'with': true}
          }
        }),
        isFalse);
  });
  test('peer canonical and flat preferences are never borrowed', () {
    expect(
        read({
          'muted': {'peer': true},
          'muted_peer': true
        }),
        isFalse);
  });
  test('UID punctuation is an exact segment in both recognized representations',
      () {
    expect(
        read({
          'muted': {uid: true}
        }),
        isTrue);
    expect(read({'muted_$uid': true}), isTrue);
    expect(
        read({
          'muted_viewer': true,
          'muted': {'viewer': true}
        }),
        isFalse);
  });
  test('empty owner has no mute preference even when an empty key exists', () {
    expect(
        read({
          'muted': {'': true},
          'muted_': true
        }, ''),
        isFalse);
  });
}
