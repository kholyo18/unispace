import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/ui/settings/public_profile_reader.dart';

Map<String, dynamic> projected({bool canView = true}) => {
  'displayName': 'Student',
  'canViewContent': canView,
  'privacy': {'privateAccount': !canView},
};

void main() {
  test('concurrent reads share one request but later reads reauthorize', () async {
    var calls = 0;
    final pending = Completer<Map<String, dynamic>>();
    final reader = PublicProfileReader(sessionKey: () => 'alice:1', fetchProfile: (_) {
      calls++;
      return calls == 1 ? pending.future : Future.value(projected(canView: false));
    });
    final first = reader.load('bob');
    final second = reader.load('bob');
    expect(calls, 1);
    pending.complete(projected());
    expect((await first)['canViewContent'], true);
    expect((await second)['canViewContent'], true);
    expect((await reader.load('bob'))['canViewContent'], false);
    expect(calls, 2);
  });

  test('in-flight requests never cross login sessions', () async {
    var session = 'alice:1';
    final pending = Completer<Map<String, dynamic>>();
    var calls = 0;
    final reader = PublicProfileReader(sessionKey: () => session, fetchProfile: (_) {
      calls++;
      return calls == 1 ? pending.future : Future.value(projected(canView: false));
    });
    final old = reader.load('bob');
    final rejected = expectLater(old, throwsStateError);
    session = 'alice:2';
    expect((await reader.load('bob'))['canViewContent'], false);
    pending.complete(projected());
    await rejected;
    expect(calls, 2);
  });

  test('failed in-flight reads can be retried', () async {
    var calls = 0;
    final reader = PublicProfileReader(sessionKey: () => 'alice:1', fetchProfile: (_) async {
      if (++calls == 1) throw StateError('offline');
      return projected();
    });
    await expectLater(reader.load('bob'), throwsStateError);
    expect((await reader.load('bob'))['canViewContent'], true);
    expect(calls, 2);
  });
  test('loads the authorized projection and never requests additional fields', () async {
    final requested = <String>[];
    final reader = PublicProfileReader(sessionKey: () => 'alice:1', fetchProfile: (id) async {
      requested.add(id);
      return projected();
    });
    expect((await reader.load('bob'))['displayName'], 'Student');
    expect(requested, ['bob']);
  });

  test('unauthenticated reads fail without contacting the server', () async {
    var calls = 0;
    final reader = PublicProfileReader(sessionKey: () => null, fetchProfile: (_) async {
      calls++;
      return projected();
    });
    await expectLater(reader.load('bob'), throwsStateError);
    expect(calls, 0);
  });

  test('invalid identifiers fail before calling the server', () async {
    var calls = 0;
    final reader = PublicProfileReader(sessionKey: () => 'alice:1', fetchProfile: (_) async {
      calls++;
      return projected();
    });
    for (final id in ['', '.', '..', 'users/bob', 'b' * 129]) {
      await expectLater(reader.load(id), throwsArgumentError);
    }
    expect(calls, 0);
  });

  test('switching accounts during a request rejects the old response', () async {
    String? session = 'alice:1';
    final response = Completer<Map<String, dynamic>>();
    final reader = PublicProfileReader(sessionKey: () => session, fetchProfile: (_) => response.future);
    final pending = expectLater(reader.load('bob'), throwsStateError);
    session = 'charlie:2';
    response.complete(projected());
    await pending;
  });

  test('signing out during a request rejects the old response', () async {
    String? session = 'alice:1';
    final response = Completer<Map<String, dynamic>>();
    final reader = PublicProfileReader(sessionKey: () => session, fetchProfile: (_) => response.future);
    final pending = expectLater(reader.load('bob'), throwsStateError);
    session = null;
    response.complete(projected());
    await pending;
  });

  test('a new login to the same account cannot receive the previous session response', () async {
    var session = 'alice:1';
    final response = Completer<Map<String, dynamic>>();
    final reader = PublicProfileReader(sessionKey: () => session, fetchProfile: (_) => response.future);
    final pending = expectLater(reader.load('bob'), throwsStateError);
    session = 'alice:3';
    response.complete(projected());
    await pending;
  });

  test('malformed projections are rejected rather than treated as public', () async {
    for (final bad in <Map<String, dynamic>>[
      {}, {'canViewContent': 'true', 'privacy': {}}, {'canViewContent': true},
      {'canViewContent': true, 'privacy': []},
    ]) {
      final reader = PublicProfileReader(sessionKey: () => 'alice:1', fetchProfile: (_) async => bad);
      await expectLater(reader.load('bob'), throwsStateError);
    }
  });

  test('server failures propagate without a raw-document fallback', () async {
    final error = StateError('authorization denied');
    final reader = PublicProfileReader(sessionKey: () => 'alice:1', fetchProfile: (_) => Future.error(error));
    await expectLater(reader.load('bob'), throwsA(same(error)));
  });

  test('a private reduced profile is still an available account', () async {
    final reader = PublicProfileReader(sessionKey: () => 'alice:1', fetchProfile: (_) async => projected(canView: false));
    expect(await reader.isUnavailable('bob'), false);
  });

  test('failed availability checks fail closed', () async {
    final reader = PublicProfileReader(sessionKey: () => 'alice:1', fetchProfile: (_) async => throw StateError('offline'));
    expect(await reader.isUnavailable('bob'), true);
  });

  test('each load reauthorizes and observes privacy changes', () async {
    var public = true;
    var calls = 0;
    final reader = PublicProfileReader(sessionKey: () => 'alice:1', fetchProfile: (_) async {
      calls++;
      return projected(canView: public);
    });
    expect((await reader.load('bob'))['canViewContent'], true);
    public = false;
    expect((await reader.load('bob'))['canViewContent'], false);
    expect(calls, 2);
  });

  test('batch lookup trims and deduplicates IDs and returns only unavailable ones', () async {
    final requested = <String>[];
    final reader = PublicProfileReader(sessionKey: () => 'alice:1', fetchProfile: (id) async {
      requested.add(id);
      if (id == 'missing') throw StateError('not found');
      return projected();
    });
    expect(await reader.unavailableUserIds([' bob ', 'bob', '', 'missing']), {'missing'});
    expect(requested, ['bob', 'missing']);
  });

  test('batch lookup never exceeds five concurrent requests', () async {
    var running = 0;
    var maximum = 0;
    final reader = PublicProfileReader(sessionKey: () => 'alice:1', fetchProfile: (_) async {
      running++;
      if (running > maximum) maximum = running;
      await Future<void>.delayed(const Duration(milliseconds: 1));
      running--;
      return projected();
    });
    expect(await reader.unavailableUserIds(List.generate(16, (i) => 'user$i')), isEmpty);
    expect(maximum, 5);
    expect(running, 0);
  });

  test('unauthenticated batch returns no permission to contact any supplied user', () async {
    var calls = 0;
    final reader = PublicProfileReader(sessionKey: () => null, fetchProfile: (_) async {
      calls++;
      return projected();
    });
    expect(await reader.unavailableUserIds(['bob', 'carl']), {'bob', 'carl'});
    expect(calls, 0);
  });

  test('a session change during a batch invalidates the entire result', () async {
    var session = 'alice:1';
    final reader = PublicProfileReader(sessionKey: () => session, fetchProfile: (_) async {
      session = 'charlie:2';
      return projected();
    });
    expect(await reader.unavailableUserIds(['bob', 'carl']), {'bob', 'carl'});
  });

  test('watch reauthorizes each refresh and observes privacy changes', () async {
    var calls = 0;
    final reader = PublicProfileReader(sessionKey: () => 'alice:1', fetchProfile: (_) async {
      calls++;
      return projected(canView: calls == 1);
    });
    final values = await reader.watch('bob', interval: const Duration(milliseconds: 1)).take(2).toList();
    expect(values.map((value) => value['canViewContent']).toList(), [true, false]);
    expect(calls, 2);
  });

  test('watch does not rebind itself to a replacement login', () async {
    var session = 'alice:1';
    var calls = 0;
    final reader = PublicProfileReader(sessionKey: () => session, fetchProfile: (_) async {
      calls++;
      return projected();
    });
    final iterator = StreamIterator(reader.watch('bob', interval: const Duration(milliseconds: 1)));
    expect(await iterator.moveNext(), true);
    session = 'alice:3';
    await expectLater(iterator.moveNext(), throwsStateError);
    await iterator.cancel();
    expect(calls, 1);
  });
  test('hidden profile skips polling but resumes fresh authorization when visible', () async {
    var visible = false;
    var calls = 0;
    final first = Completer<void>();
    final next = Completer<void>();
    final reader = PublicProfileReader(sessionKey: () => 'alice:1', fetchProfile: (_) async {
      calls++;
      return projected();
    });
    final sub = reader.watch('bob', interval: const Duration(milliseconds: 5),
      shouldRefresh: () => visible).listen((_) {
        if (!first.isCompleted) first.complete(); else if (!next.isCompleted) next.complete();
      });
    await first.future;
    await Future<void>.delayed(const Duration(milliseconds: 25));
    expect(calls, 1);
    visible = true;
    await next.future.timeout(const Duration(seconds: 1));
    await sub.cancel();
    expect(calls, 2);
  });

}
