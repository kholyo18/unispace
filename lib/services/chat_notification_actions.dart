import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

typedef NotificationActionCall = Future<Map<String, dynamic>> Function(Map<String, dynamic> data);

class ChatNotificationActions {
  ChatNotificationActions()
      : _identity = (() async {
          final auth = FirebaseAuth.instance, user = FirebaseAuth.instance.currentUser;
          if (user == null) return null;
          final result = await user.getIdTokenResult();
          final sid = result.claims?['sid'];
          if (auth.currentUser?.uid != user.uid || sid is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(sid)) return null;
          return '${user.uid}:$sid';
        }),
        _call = ((data) async => (await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('handleChatNotificationAction').call<Map<String, dynamic>>(data)).data);

  ChatNotificationActions.forTesting({required Future<String?> Function() identity, required NotificationActionCall call})
      : _identity = identity, _call = call;
  final Future<String?> Function() _identity;
  final NotificationActionCall _call;

  Future<void> perform(Map<String, dynamic> payload, String action, {String? input}) async {
    final recipient = payload['recipientId'];
    final session = await _identity();
    if (recipient is! String || session == null || !session.startsWith('$recipient:')) {
      throw FirebaseFunctionsException(code: 'unauthenticated', message: 'Sign in to the notified account.');
    }
    if (!['reply', 'markRead'].contains(action) || payload['type'] != 'message' ||
        ['notificationId', 'chatId', 'messageId'].any((key) => payload[key] is! String ||
          !RegExp(r'^[A-Za-z0-9_-]{1,260}$').hasMatch(payload[key] as String)) ||
        (action == 'reply' && (input == null || input.trim().isEmpty || input.length > 10000))) {
      throw FirebaseFunctionsException(code: 'invalid-argument', message: 'Invalid notification action.');
    }
    if (await _identity() != session) {
      throw FirebaseFunctionsException(code: 'unauthenticated', message: 'The session changed.');
    }
    final result = await _call({
      'notificationId': payload['notificationId'], 'chatId': payload['chatId'], 'messageId': payload['messageId'],
      'action': action, if (action == 'reply') 'text': input!.trim(),
    });
    if (await _identity() != session) {
      throw FirebaseFunctionsException(code: 'unauthenticated', message: 'The session changed.');
    }
    if (result['action'] != action || (action == 'markRead' && result['notificationId'] != payload['notificationId']) ||
        (action == 'reply' && result['messageId'] is! String)) {
      throw FirebaseFunctionsException(code: 'data-loss', message: 'Unconfirmed notification action.');
    }
  }
}

int chatNotificationLocalId(String value) {
  var hash = 0x811c9dc5;
  for (final unit in value.codeUnits) { hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff; }
  return hash;
}

String chatNotificationActionText(String locale, String key) {
  const words = <String, List<String>>{
    'Reply': ['رد', 'Répondre'],
    'Mark as read': ['تحديد كمقروء', 'Marquer comme lu'],
    'Write a reply': ['اكتب ردًا', 'Écrire une réponse'],
    'Reply sent': ['تم إرسال الرد', 'Réponse envoyée'],
    'Marked as read': ['تم التحديد كمقروء', 'Marqué comme lu'],
    'Action failed. Open the conversation to retry.': ['تعذر تنفيذ الإجراء. افتح المحادثة للمحاولة مجددًا.', 'Action impossible. Ouvrez la conversation pour réessayer.'],
    'Retry': ['إعادة المحاولة', 'Réessayer'],
    'Sign in to the notified account.': ['سجّل الدخول إلى الحساب الذي تلقى الإشعار.', 'Connectez-vous au compte destinataire.'],
    'You have a new message': ['لديك رسالة جديدة', 'Vous avez un nouveau message'],
  };
  final language = locale.split(RegExp('[-_]')).first;
  final row = words[key];
  return row == null || language == 'en' ? key : language == 'ar' ? row[0] : language == 'fr' ? row[1] : key;
}
