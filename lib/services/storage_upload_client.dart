/// Production upload coordinator. Authorization always comes from the server.
/// Tests inject transport/storage boundaries, not a fake authorization decision.
class StorageUploadClient {
  StorageUploadClient({
    required this.currentUid,
    required this.sessionKey,
    required this.invoke,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  final String? Function() currentUid;
  final String? Function() sessionKey;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>) invoke;
  final DateTime Function() now;

  Future<T> upload<T>({
    required String expectedUid,
    required String path,
    required String bucket,
    required String contentType,
    required int size,
    required Future<T> Function(Map<String, String> metadata) send,
  }) async {
    final session = sessionKey();
    if (expectedUid.isEmpty || currentUid() != expectedUid || session == null) {
      throw StateError('تغيّر الحساب. سجّل الدخول مجددًا.');
    }
    if (path.isEmpty || path.length > 1024 || bucket.isEmpty ||
        contentType.isEmpty || size <= 0 || size > 200 * 1024 * 1024) {
      throw ArgumentError('ملف الرفع غير صالح أو يتجاوز الحجم المسموح.');
    }
    void guard() {
      if (currentUid() != expectedUid || sessionKey() != session) {
        throw StateError('تغيّر الحساب أثناء رفع الملف.');
      }
    }
    final grant = await invoke({
      'expectedUid': expectedUid, 'path': path, 'contentType': contentType, 'size': size,
    });
    guard();
    final id = grant['grantId'];
    final expiry = grant['expiresAt'];
    final time = now().millisecondsSinceEpoch;
    if (id is! String || !RegExp(r'^[A-Za-z0-9_-]{20}$').hasMatch(id) ||
        grant['uid'] != expectedUid || grant['path'] != path || grant['bucket'] != bucket ||
        grant['size'] != size || grant['contentType'] != contentType || expiry is! int ||
        expiry <= time || expiry > time + const Duration(minutes: 31).inMilliseconds) {
      throw StateError('تعذر التحقق من إذن رفع الملف.');
    }
    final result = await send({'uploadGrantId': id, 'uploadedBy': expectedUid});
    guard();
    return result;
  }
}
