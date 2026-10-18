import 'package:cloud_functions/cloud_functions.dart';

/// completeSignupProfile is idempotent for the same user and username.
/// Retry only transient transport failures, never authentication or validation.
Future<T> retrySignupSave<T>({
  required Future<T> Function() save,
  required bool Function() isCurrentUser,
  Future<void> Function(Duration)? wait,
}) async {
  for (var attempt = 0;; attempt++) {
    if (!isCurrentUser()) {
      throw FirebaseFunctionsException(
          code: 'unauthenticated', message: 'Account changed.');
    }
    try {
      return await save();
    } on FirebaseFunctionsException catch (error) {
      if (attempt != 0 ||
          !const {'unavailable', 'deadline-exceeded'}.contains(error.code)) {
        rethrow;
      }
      await (wait ?? Future<void>.delayed)(const Duration(seconds: 1));
    }
  }
}
