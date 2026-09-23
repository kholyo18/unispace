import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/services/chat_preferences_client.dart';

void main() {
  const uid = '1.viewer.with.`dot';
  late String? currentUid;
  late String? session;
  late Object timestamp;
  late Object deletion;
  late List<Map<String, dynamic>> writes;
  late Future<void> Function(Map<String, dynamic>) writer;
  late ChatPreferencesClient client;
  ChatPreferencesClient make({String owner = uid}) => ChatPreferencesClient(
    expectedUid: owner,
    currentUid: () => currentUid,
    sessionKey: () => session,
    merge: (data) => writer(data),
    serverTimestamp: () => timestamp,
    deleteField: () => deletion,
  );
  setUp(() {
    currentUid = uid;
    session = 'first';
    timestamp = Object();
    deletion = Object();
    writes = [];
    writer = (data) async {
      writes.add(data);
    };
    client = make();
  });
  tearDown(() => client.dispose());
  test(
    'nickname uses a nested exact UID, trims, and never uses dotted field names',
    () async {
      expect(await client.setNickname('  Study friend  '), isTrue);
      expect(writes.single, {
        'nicknames': {uid: 'Study friend'},
      });
    },
  );
  test(
    'empty nickname removal preserves the existing empty-string contract',
    () async {
      await client.setNickname('  ');
      expect(writes.single, {
        'nicknames': {uid: ''},
      });
    },
  );
  for (final value in [true, false]) {
    test(
      'mute writes requested value $value rather than inverting stale state',
      () async {
        await client.setMuted(value);
        expect(writes.single, {
          'muted': {uid: value},
        });
      },
    );
    test(
      'automatic translation remains an explicit own boolean $value',
      () async {
        await client.setAutoTranslate(value);
        expect(writes.single, {
          'autoTranslate': {uid: value},
        });
      },
    );
  }
  test(
    'clear history uses server timestamp under owner, not a message deletion',
    () async {
      await client.clearHistory();
      expect(writes.single, {
        'clearedAt': {uid: same(timestamp)},
      });
    },
  );
  test(
    'solid color atomically removes own previous gradient in exactly one write',
    () async {
      await client.setBubbleColor(0xFF00AA00);
      expect(writes, hasLength(1));
      expect(writes.single, {
        'theme': {
          uid: {'bubbleColor': 0xFF00AA00, 'bubbleGradient': same(deletion)},
        },
      });
    },
  );
  test(
    'gradient atomically removes solid color and copies caller-owned list',
    () async {
      final colors = [0xFF001100, 0xFF002200];
      final pending = client.setBubbleGradient(colors);
      colors[0] = 0;
      await pending;
      expect(writes.single, {
        'theme': {
          uid: {
            'bubbleGradient': [0xFF001100, 0xFF002200],
            'bubbleColor': same(deletion),
          },
        },
      });
    },
  );
  test('preset wallpaper removes only its own prior photo URL', () async {
    await client.setWallpaper('ocean');
    expect(writes.single, {
      'theme': {
        uid: {'wallpaper': 'ocean', 'wallpaperUrl': same(deletion)},
      },
    });
  });
  test('custom wallpaper retains the existing URL contract', () async {
    await client.setWallpaper('photo', photoUrl: 'https://example.test/photo');
    expect(writes.single, {
      'theme': {
        uid: {
          'wallpaper': 'photo',
          'wallpaperUrl': 'https://example.test/photo',
        },
      },
    });
  });
  for (final color in [-1, 0x100000000]) {
    test('invalid ARGB $color never reaches transport', () {
      expect(() => client.setBubbleColor(color), throwsArgumentError);
      expect(writes, isEmpty);
    });
  }
  for (final colors in <List<int>>[
    [],
    [1],
    [1, -1],
    List.filled(7, 1),
  ]) {
    test('invalid gradient ${colors.join(',')} never reaches transport', () {
      expect(() => client.setBubbleGradient(colors), throwsArgumentError);
      expect(writes, isEmpty);
    });
  }
  test('invalid wallpaper combinations never reach transport', () {
    expect(() => client.setWallpaper(''), throwsArgumentError);
    expect(() => client.setWallpaper('photo'), throwsArgumentError);
    expect(
      () => client.setWallpaper('photo', photoUrl: ''),
      throwsArgumentError,
    );
    expect(
      () => client.setWallpaper('mint', photoUrl: 'url'),
      throwsArgumentError,
    );
    expect(writes, isEmpty);
  });
  test('wrong user cannot write or receive successful completion', () async {
    currentUid = 'other';
    expect(await client.setMuted(true), isFalse);
    expect(writes, isEmpty);
  });
  test('same UID with a different local session is rejected', () async {
    session = 'new';
    expect(await client.clearHistory(), isFalse);
    expect(writes, isEmpty);
  });
  test('missing original session cannot adopt a later session', () async {
    client.dispose();
    session = null;
    client = make();
    session = 'later';
    expect(await client.setNickname('x'), isFalse);
    expect(writes, isEmpty);
  });
  test('empty owner never writes', () async {
    client.dispose();
    currentUid = '';
    client = make(owner: '');
    expect(await client.setMuted(true), isFalse);
    expect(writes, isEmpty);
  });
  test('dispose suppresses future work and may be repeated', () async {
    client.dispose();
    client.dispose();
    expect(await client.setMuted(true), isFalse);
    expect(writes, isEmpty);
  });
  test('write failure is reported and does not poison a later retry', () async {
    writer = (_) async {
      throw StateError('test only');
    };
    await expectLater(client.setMuted(true), throwsStateError);
    writer = (data) async {
      writes.add(data);
    };
    expect(await client.setMuted(false), isTrue);
    expect(writes, hasLength(1));
  });
  test('rapid changes are serialized without duplicate writes', () async {
    final first = Completer<void>();
    writer = (data) {
      writes.add(data);
      return writes.length == 1 ? first.future : Future<void>.value();
    };
    final a = client.setMuted(true);
    final b = client.setMuted(false);
    await Future<void>.delayed(Duration.zero);
    expect(writes, hasLength(1));
    first.complete();
    expect(await a, isTrue);
    expect(await b, isTrue);
    expect(writes, [
      {
        'muted': {uid: true},
      },
      {
        'muted': {uid: false},
      },
    ]);
  });
  test(
    'account switch blocks queued work and suppresses stale in-flight success',
    () async {
      final done = Completer<void>();
      writer = (data) {
        writes.add(data);
        return done.future;
      };
      final a = client.setMuted(true);
      final b = client.setNickname('never');
      await Future<void>.delayed(Duration.zero);
      currentUid = 'other';
      session = 'next';
      done.complete();
      expect(await a, isFalse);
      expect(await b, isFalse);
      expect(writes, hasLength(1));
    },
  );
  test('disposing in flight blocks queued work', () async {
    final done = Completer<void>();
    writer = (data) {
      writes.add(data);
      return done.future;
    };
    final a = client.setMuted(true);
    final b = client.clearHistory();
    await Future<void>.delayed(Duration.zero);
    client.dispose();
    done.complete();
    expect(await a, isFalse);
    expect(await b, isFalse);
    expect(writes, hasLength(1));
  });
  test(
    'clear timestamp is generated only when its queued write starts',
    () async {
      final done = Completer<void>();
      writer = (data) {
        writes.add(data);
        return writes.length == 1 ? done.future : Future<void>.value();
      };
      final a = client.setMuted(true);
      final b = client.clearHistory();
      await Future<void>.delayed(Duration.zero);
      final newest = Object();
      timestamp = newest;
      done.complete();
      await a;
      await b;
      expect((writes.last['clearedAt'] as Map)[uid], same(newest));
    },
  );
  test('reading own preferences never falls back to another member', () {
    final p = ChatPreferencesSnapshot.fromData({
      'nicknames': {'other': 'secret'},
      'theme': {
        'other': {'wallpaper': 'photo'},
      },
    }, uid);
    expect(p.nickname, '');
    expect(p.wallpaper, 'default');
    expect(p.wallpaperUrl, '');
  });
  test(
    'reader and actual client payload agree for nickname and theme',
    () async {
      await client.setNickname('friend');
      await client.setBubbleGradient([1, 2]);
      final data = <String, dynamic>{};
      for (final w in writes) {
        data.addAll(w);
      }
      final p = ChatPreferencesSnapshot.fromData(data, uid);
      expect(p.nickname, 'friend');
      expect(p.bubbleGradient, [1, 2]);
    },
  );
  test('literal legacy dotted fields are ignored, not silently promoted', () {
    final p = ChatPreferencesSnapshot.fromData({
      'nicknames.$uid': 'legacy',
    }, uid);
    expect(p.nickname, '');
  });
  for (final value in [null, true, 7, 'broken', <Object>[]]) {
    test('malformed preference containers $value cannot crash the reader', () {
      final p = ChatPreferencesSnapshot.fromData({
        for (final k in [
          'nicknames',
          'muted',
          'theme',
          'clearedAt',
          'autoTranslate',
          'autoTranslateLang',
        ])
          k: value,
      }, uid);
      expect(p.nickname, '');
      expect(p.muted, isFalse);
      expect(p.bubbleGradient, isNull);
      expect(p.bubbleColor, 0xFF0D9488);
      expect(p.clearedAt, isNull);
    });
  }
  test('malformed owner theme is ignored', () {
    final p = ChatPreferencesSnapshot.fromData({
      'theme': {uid: 'bad'},
    }, uid);
    expect(p.wallpaper, 'default');
    expect(p.bubbleColor, 0xFF0D9488);
  });
  test(
    'unsafe theme leaf types and invalid colors fall back without casting',
    () {
      final p = ChatPreferencesSnapshot.fromData({
        'theme': {
          uid: {
            'wallpaper': [],
            'wallpaperUrl': true,
            'bubbleColor': -1,
            'bubbleGradient': [1, 'bad'],
          },
        },
      }, uid);
      expect(p.wallpaper, 'default');
      expect(p.wallpaperUrl, '');
      expect(p.bubbleColor, 0xFF0D9488);
      expect(p.bubbleGradient, isNull);
    },
  );
  test('reader keeps valid values and cutoff identity', () {
    final p = ChatPreferencesSnapshot.fromData({
      'nicknames': {uid: 'n'},
      'muted': {uid: true},
      'autoTranslate': {uid: true},
      'autoTranslateLang': {uid: 'fr'},
      'clearedAt': {uid: timestamp},
      'theme': {
        uid: {'wallpaper': 'photo', 'wallpaperUrl': 'url', 'bubbleColor': 0},
      },
    }, uid);
    expect(p.nickname, 'n');
    expect(p.muted, isTrue);
    expect(p.autoTranslate, isTrue);
    expect(p.autoTranslateLang, 'fr');
    expect(p.clearedAt, same(timestamp));
    expect(p.wallpaper, 'photo');
    expect(p.wallpaperUrl, 'url');
    expect(p.bubbleColor, 0);
  });
}
