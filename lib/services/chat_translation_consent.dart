import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const chatTranslationConsentVersion = 1;
String _consentKey(String uid) =>
    'chat_translation_consent_${Uri.encodeComponent(uid)}';

Future<bool> hasChatTranslationConsent(String uid) async {
  if (uid.isEmpty) return false;
  final prefs = await SharedPreferences.getInstance();
  return prefs.get(_consentKey(uid)) == chatTranslationConsentVersion;
}

Future<void> recordChatTranslationConsent(String uid) async {
  if (uid.isEmpty) throw ArgumentError.value(uid, 'uid');
  final prefs = await SharedPreferences.getInstance();
  if (!await prefs.setInt(_consentKey(uid), chatTranslationConsentVersion)) {
    throw StateError('Translation consent could not be saved');
  }
}

String chatTranslationDisclosure(String language) => switch (language) {
      'ar' =>
        'عند تفعيل الترجمة، تُرسل نصوص الرسائل الخاصة والتعليقات المرفقة بالوسائط التي تُعرض للترجمة إلى خدمة Google للترجمة، بما فيها النصوص التي أرسلها الآخرون. لا تُرسل ملفات الصور أو الصوت أو الفيديو لهذه الخدمة. هذا اختياري؛ يمكنك تعطيل الترجمة من معلومات المحادثة. لا تتغير الرسالة الأصلية. عند تعطيلها تتوقف طلبات الترجمة الجديدة، لكن لا يمكن سحب النصوص التي أُرسلت بالفعل إلى Google.',
      'fr' =>
        'Lorsque la traduction est activée, le texte des messages privés et les légendes des médias affichés pour traduction sont envoyés au service de traduction Google, y compris les textes envoyés par d’autres personnes. Les fichiers image, audio et vidéo ne sont pas envoyés à ce service. Cette fonction est facultative et peut être désactivée dans les informations de la conversation. Le message original reste inchangé. La désactivation arrête les nouvelles demandes, mais ne retire pas les textes déjà envoyés à Google.',
      _ =>
        'When translation is enabled, private message text and media captions displayed for translation are sent to Google’s translation service, including text sent by other people. Image, audio and video files are not sent to this service. This is optional and can be disabled in conversation information. The original message is unchanged. Disabling stops new translation requests but cannot recall text already sent to Google.',
    };

String chatTranslationDisclosureTitle(String language) => switch (language) {
      'ar' => 'الترجمة الاختيارية عبر Google',
      'fr' => 'Traduction facultative par Google',
      _ => 'Optional translation with Google',
    };

/// Dismissal and back navigation never imply consent. Caller records consent
/// only after checking that the account still matches the one opening this UI.
Future<bool> confirmChatTranslation(BuildContext context) async {
  final language = Localizations.localeOf(context).languageCode;
  return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
                title: Text(chatTranslationDisclosureTitle(language)),
                content: SingleChildScrollView(
                    child: Text(chatTranslationDisclosure(language))),
                actions: [
                  TextButton(
                      key: const ValueKey('translation-consent-cancel'),
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: Text(language == 'ar'
                          ? 'إلغاء'
                          : language == 'fr'
                              ? 'Annuler'
                              : 'Cancel')),
                  FilledButton(
                      key: const ValueKey('translation-consent-enable'),
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: Text(language == 'ar'
                          ? 'الموافقة وتفعيل الترجمة'
                          : language == 'fr'
                              ? 'Accepter et activer'
                              : 'Agree and enable')),
                ],
              )) ??
      false;
}

