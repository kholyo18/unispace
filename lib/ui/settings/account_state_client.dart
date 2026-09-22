/// Production account-lifecycle request logic with injectable network boundaries.
/// The server, not this client, is the authorization authority.
class AccountStateClient {
  AccountStateClient({
    required this.currentUid,
    required this.sessionKey,
    required this.invoke,
  });

  final String? Function() currentUid;
  final String? Function() sessionKey;
  final Future<Map<String, dynamic>> Function(
    String function, Map<String, dynamic> data,
  ) invoke;

  String _begin(String expectedUid) {
    if (expectedUid.isEmpty || expectedUid.length > 128 ||
        expectedUid.contains('/') || expectedUid == '.' || expectedUid == '..') {
      throw ArgumentError.value(expectedUid, 'expectedUid');
    }
    final session = sessionKey();
    if (currentUid() != expectedUid || session == null) {
      throw StateError('Account changed. Sign in again.');
    }
    return session;
  }

  Future<void> change(String expectedUid, String action) async {
    if (!const {'deactivate', 'reactivate', 'freeze', 'unfreeze'}.contains(action)) {
      throw ArgumentError.value(action, 'action');
    }
    final session = _begin(expectedUid);
    final result = await invoke('setOwnAccountState', {'action': action, 'expectedUid': expectedUid});
    if (currentUid() != expectedUid || sessionKey() != session) {
      throw StateError('Account changed during request.');
    }
    if (!const {'active', 'disabled'}.contains(result['accountStatus']) ||
        result['frozen'] is! bool || result['revision'] is! int ||
        (result['revision'] as int) < 1 || result['changed'] is! bool) {
      throw StateError('Invalid lifecycle response.');
    }
  }

  Future<void> requestDeletion(String expectedUid) async {
    final session = _begin(expectedUid);
    final result = await invoke('requestAccountDeletion', {'confirm': true, 'expectedUid': expectedUid});
    // The server may have deleted Auth and caused a local sign-out already.
    // A replacement login must never be signed out by the old request.
    final uid = currentUid();
    if (uid != null && (uid != expectedUid || sessionKey() != session)) {
      throw StateError('Account changed during deletion request.');
    }
    if (result['status'] != 'pending' || result['deletionWithinDays'] is! int ||
        (result['deletionWithinDays'] as int) <= 0) {
      throw StateError('Deletion request was not confirmed.');
    }
  }
}
