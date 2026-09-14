import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Coalesce requests from one event-loop turn only. No persistent URL cache.
class PostMediaLinks {
  static final Map<String, Map<String, Map<String, Completer<String>>>> _pending = {};

  static Future<String> read(String postId, String source) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Future.error(StateError('Authentication required'));
    final posts = _pending.putIfAbsent(uid, () => {});
    final existing = posts[postId];
    if (existing != null) {
      return existing.putIfAbsent(source, () => Completer<String>()).future;
    }
    final requests = <String, Completer<String>>{source: Completer<String>()};
    posts[postId] = requests;
    scheduleMicrotask(() {
      posts.remove(postId);
      if (posts.isEmpty) _pending.remove(uid);
      _flush(uid, postId, requests);
    });
    return requests[source]!.future;
  }

  static Future<void> _flush(String uid, String postId, Map<String, Completer<String>> requests) async {
    final sources = requests.keys.toList();
    for (var offset = 0; offset < sources.length; offset += 10) {
      final urls = sources.skip(offset).take(10).toList();
      try {
        if (uid != FirebaseAuth.instance.currentUser?.uid) throw StateError('Account changed');
        final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
            .httpsCallable('readPostMediaBatch').call({'postId': postId, 'urls': urls});
        if (uid != FirebaseAuth.instance.currentUser?.uid) throw StateError('Account changed');
        final data = Map<String, dynamic>.from(response.data as Map);
        final rows = data['items'] as List;
        final links = <String, String>{};
        for (final row in rows) {
          final item = Map<String, dynamic>.from(row as Map);
          final source = item['source'], url = item['url'], expiry = item['expiresAt'];
          if (source is! String || !urls.contains(source) || links.containsKey(source) ||
              url is! String || Uri.tryParse(url)?.scheme != 'https' || expiry is! num ||
              expiry <= DateTime.now().millisecondsSinceEpoch) {
            throw StateError('Invalid media authorization');
          }
          links[source] = url;
        }
        if (links.length != urls.length) throw StateError('Incomplete media authorization');
        for (final source in urls) { requests[source]!.complete(links[source]!); }
      } catch (error, stack) {
        for (final source in urls) { requests[source]!.completeError(error, stack); }
      }
    }
  }
}
