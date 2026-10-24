import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ProtectedUploadSnapshot {
  const ProtectedUploadSnapshot(
      this.bytesTransferred, this.totalBytes, this.state);
  final int bytesTransferred, totalBytes;
  final TaskState state;
}

class ProtectedUploadRequest {
  const ProtectedUploadRequest(this.uri, this.headers);
  final Uri uri;
  final Map<String, String> headers;
}

abstract class ProtectedUploadTransport {
  Future<void> send(ProtectedUploadRequest request, Stream<List<int>> source,
      int size, void Function(int) progress, void Function() guard);
  void close();
}

/// Streams disk chunks directly into the signed PUT. It never buffers a video
/// as one byte array, follows redirects, or sends Firebase credentials to GCS.
class HttpProtectedUploadTransport implements ProtectedUploadTransport {
  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 30);
  HttpClientRequest? _request;
  @override
  Future<void> send(ProtectedUploadRequest upload, Stream<List<int>> source,
      int size, void Function(int) progress, void Function() guard) async {
    guard();
    final request = await _client.putUrl(upload.uri);
    _request = request;
    request.followRedirects = false;
    for (final header in upload.headers.entries) {
      request.headers.set(header.key, header.value);
    }
    request.contentLength = size;
    var sent = 0;
    await request.addStream(source.map((chunk) {
      guard();
      sent += chunk.length;
      if (sent > size) throw StateError('Upload file changed.');
      progress(sent);
      return chunk;
    })).timeout(const Duration(minutes: 5));
    guard();
    if (sent != size) throw StateError('Upload file changed.');
    final response = await request.close().timeout(const Duration(seconds: 60));
    await response.drain<void>().timeout(const Duration(seconds: 30));
    guard();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FirebaseException(
          plugin: 'firebase_storage',
          code: 'upload-failed',
          message: 'The protected upload was not accepted. Retry the upload.');
    }
  }

  @override
  void close() {
    _request?.abort();
    _client.close(force: true);
  }
}

class ProtectedUploadTask {
  ProtectedUploadTask(
      {required this.totalBytes, ProtectedUploadTransport? transport})
      : _transport = transport ?? HttpProtectedUploadTransport(),
        _snapshot = ProtectedUploadSnapshot(0, totalBytes, TaskState.running);
  final int totalBytes;
  final ProtectedUploadTransport _transport;
  final _events = StreamController<ProtectedUploadSnapshot>.broadcast();
  ProtectedUploadSnapshot _snapshot;
  ProtectedUploadSnapshot get snapshot => _snapshot;
  Stream<ProtectedUploadSnapshot> get snapshotEvents => _events.stream;
  bool _canceled = false,
      _finished = false,
      _finalizing = false,
      _started = false;

  void _emit(int bytes, TaskState state) {
    _snapshot = ProtectedUploadSnapshot(bytes, totalBytes, state);
    if (!_events.isClosed) _events.add(_snapshot);
  }

  Future<bool> cancel() async {
    // Once the server commit starts it cannot be safely cancelled client-side.
    if (_finished || _finalizing) return false;
    _canceled = true;
    _transport.close();
    _emit(_snapshot.bytesTransferred, TaskState.canceled);
    unawaited(_events.close());
    return true;
  }

  Future<T> run<T>(
      {required Future<ProtectedUploadRequest> Function() prepare,
      required Stream<List<int>> Function() source,
      required Future<T> Function() finalize,
      required void Function() guard}) async {
    if (_started) throw StateError('Upload already started.');
    _started = true;
    void check() {
      if (_canceled) {
        throw FirebaseException(
            plugin: 'firebase_storage',
            code: 'canceled',
            message: 'Upload cancelled.');
      }
      guard();
    }

    try {
      check();
      _emit(0, TaskState.running);
      final request = await prepare();
      check();
      await _transport.send(request, source(), totalBytes,
          (bytes) => _emit(bytes, TaskState.running), check);
      check();
      _finalizing = true;
      final result = await finalize();
      check();
      _finished = true;
      _emit(totalBytes, TaskState.success);
      return result;
    } catch (_) {
      _finished = true;
      _emit(_snapshot.bytesTransferred,
          _canceled ? TaskState.canceled : TaskState.error);
      if (_canceled) {
        throw FirebaseException(
            plugin: 'firebase_storage',
            code: 'canceled',
            message: 'Upload cancelled.');
      }
      rethrow;
    } finally {
      _transport.close();
      // A paused UI listener must not hold up a committed upload result.
      unawaited(_events.close());
    }
  }
}

typedef ProtectedUploadInvoke = Future<Map<String, dynamic>> Function(
    String method, Map<String, dynamic> data);

/// Identity and grant validation shared by bytes and disk upload entry points.
class ProtectedUploadCoordinator {
  ProtectedUploadCoordinator(
      {required this.currentUid,
      required this.sessionKey,
      required this.invoke,
      this.transportFactory});
  final String? Function() currentUid, sessionKey;
  final ProtectedUploadInvoke invoke;
  final ProtectedUploadTransport Function()? transportFactory;
  static String locator(String bucket, String path) =>
      'https://firebasestorage.googleapis.com/v0/b/${Uri.encodeComponent(bucket)}/o/${Uri.encodeComponent(path)}?alt=media';

  Future<Map<String, dynamic>> upload(
      {required String path,
      required String bucket,
      required String contentType,
      required int size,
      required Stream<List<int>> Function() source,
      void Function(ProtectedUploadTask)? onTask}) async {
    final uid = currentUid(), session = sessionKey();
    if (uid == null || uid.isEmpty || session == null) {
      throw StateError('Sign in again.');
    }
    if (size <= 0 ||
        size > 200 * 1024 * 1024 ||
        path.isEmpty ||
        bucket.isEmpty ||
        contentType.isEmpty) {
      throw ArgumentError('Invalid upload file.');
    }
    void guard() {
      if (currentUid() != uid || sessionKey() != session) {
        throw StateError('Account changed during upload.');
      }
    }

    final task = ProtectedUploadTask(
        totalBytes: size, transport: transportFactory?.call());
    late String grantId;
    try {
      onTask?.call(task);
    } catch (_) {
      await task.cancel();
      rethrow;
    }
    return task.run(
        guard: guard,
        source: source,
        prepare: () async {
          final grant = await invoke('prepareProtectedUpload', {
            'expectedUid': uid,
            'path': path,
            'contentType': contentType,
            'size': size,
          });
          guard();
          final id = grant['grantId'], expiry = grant['expiresAt'];
          final now = DateTime.now().millisecondsSinceEpoch;
          final url = Uri.tryParse(
              grant['uploadUrl'] is String ? grant['uploadUrl'] as String : '');
          final staging = 'private_upload_staging/$uid/$id';
          if (id is! String ||
              !RegExp(r'^[A-Za-z0-9_-]{20}$').hasMatch(id) ||
              grant['uid'] != uid ||
              grant['bucket'] != bucket ||
              grant['path'] != path ||
              grant['contentType'] != contentType ||
              grant['size'] != size ||
              grant['stagingPath'] != staging ||
              expiry is! int ||
              expiry <= now ||
              expiry > now + 301000 ||
              url == null ||
              url.scheme != 'https' ||
              url.userInfo.isNotEmpty ||
              url.fragment.isNotEmpty ||
              url.host != 'storage.googleapis.com' ||
              url.path != '/$bucket/$staging' ||
              url.query.isEmpty) {
            throw StateError('Invalid protected upload grant.');
          }
          final expectedHeaders = <String, String>{
            'Content-Type': contentType,
            'Content-Length': '$size',
            'x-goog-if-generation-match': '0',
            'x-goog-meta-uploadedby': uid,
            'x-goog-meta-uploadgrantid': id
          };
          final headers = grant['uploadHeaders'];
          if (headers is! Map ||
              headers.length != expectedHeaders.length ||
              expectedHeaders.entries.any((e) => headers[e.key] != e.value)) {
            throw StateError('Invalid upload headers.');
          }
          grantId = id;
          return ProtectedUploadRequest(url, expectedHeaders);
        },
        finalize: () async {
          guard();
          final result =
              await invoke('finalizeProtectedUpload', {'grantId': grantId});
          guard();
          if (result['uid'] != uid ||
              result['path'] != path ||
              result['bucket'] != bucket ||
              result['url'] != locator(bucket, path)) {
            throw StateError('Invalid upload receipt.');
          }
          return result;
        });
  }
}
