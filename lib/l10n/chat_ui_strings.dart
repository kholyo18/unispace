import 'package:flutter/widgets.dart';

String chatUiText(BuildContext context, String key) =>
    ChatUiStrings.text(Localizations.localeOf(context).languageCode, key);

class ChatUiStrings {
  static const values = <String, List<String>>{
    'Groups': ['المجموعات', 'Groups', 'Groupes'],
    'Group': ['مجموعة', 'Group', 'Groupe'],
    'New conversation': [
      'إنشاء محادثة',
      'New conversation',
      'Nouvelle conversation'
    ],
    'New message': ['رسالة جديدة', 'New message', 'Nouveau message'],
    'Unread messages': [
      'رسائل غير مقروءة',
      'Unread messages',
      'Messages non lus'
    ],
    'Conversation unavailable': [
      'لم تعد هذه المحادثة متاحة لك.',
      'This conversation is no longer available to you.',
      'Cette conversation ne vous est plus accessible.'
    ],
  };
  static String text(String locale, String key) =>
      values[key]?[locale == 'ar'
          ? 0
          : locale == 'fr'
              ? 2
              : 1] ??
      key;
}
