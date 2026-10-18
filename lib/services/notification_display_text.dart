/// Matches the app's supported locale selection; only these values reach the server.
String notificationLanguageCode(String value) {
  final code = value.toLowerCase().split(RegExp('[-_]')).first;
  return const ['ar', 'en', 'fr'].contains(code) ? code : 'en';
}

/// Translates only app-authored notification templates at the display boundary.
/// Actor names, announcement text, and other supplied content are not translated.
String localizedNotificationBody(
  String languageCode, {
  required String type,
  String? fallback,
}) {
  final template = _notificationBodies[type];
  if (template != null) return _pick(languageCode, template);
  if (fallback != null && fallback.isNotEmpty) return fallback;
  return _pick(languageCode, const [
    'لديك إشعار جديد',
    'You have a new notification',
    'Vous avez une nouvelle notification'
  ]);
}

String localizedNotificationChannelName(String languageCode) =>
    _pick(languageCode, const [
      'إشعارات UniSpace',
      'UniSpace notifications',
      'Notifications UniSpace'
    ]);

String localizedNotificationChannelDescription(String languageCode) =>
    _pick(languageCode, const [
      'متابعة، تعليقات، إعجابات',
      'Follows, comments, likes',
      'Abonnements, commentaires, mentions J’aime'
    ]);

String _pick(String languageCode, List<String> values) =>
    values[languageCode == 'ar'
        ? 0
        : languageCode == 'fr'
            ? 2
            : 1];

// These types correspond to the reviewed app-authored server push templates.
const _notificationBodies = <String, List<String>>{
  'message': ['لديك رسالة جديدة', 'You have a new message', 'Vous avez un nouveau message'],
  'new_post': [
    'نشر منشوراً جديداً',
    'Shared a new post',
    'A publié une nouvelle publication'
  ],
  'like': ['أعجب بمنشورك', 'Liked your post', 'A aimé votre publication'],
  'like_comment': [
    'أعجب بتعليقك',
    'Liked your comment',
    'A aimé votre commentaire'
  ],
  'comment': [
    'علّق على منشورك',
    'Commented on your post',
    'A commenté votre publication'
  ],
  'reply': [
    'رد على تعليقك',
    'Replied to your comment',
    'A répondu à votre commentaire'
  ],
  'repost': ['أعاد نشر محتوى', 'Reposted content', 'A repartagé du contenu'],
  'follow': [
    'بدأ بمتابعتك',
    'Started following you',
    'A commencé à vous suivre'
  ],
  'follow_request': [
    'طلب متابعتك',
    'Requested to follow you',
    'A demandé à vous suivre'
  ],
  'follow_accepted': [
    'قبل طلب المتابعة',
    'Accepted your follow request',
    'A accepté votre demande d’abonnement'
  ],
};
