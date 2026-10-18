import 'package:flutter/widgets.dart';

String chatComposeText(BuildContext context, String key) =>
    chatComposeTextForLocale(Localizations.localeOf(context).languageCode, key);

String chatComposeTextForLocale(String language, String key) {
  final values = chatComposeCatalog[key];
  return values == null
      ? key
      : values[language == 'ar'
          ? 0
          : language == 'fr'
              ? 2
              : 1];
}

const chatComposeCatalog = <String, List<String>>{
  'title': ['محادثة جديدة', 'New conversation', 'Nouvelle conversation'],
  'search': [
    'ابحث بالاسم أو اسم المستخدم',
    'Search by name or username',
    'Rechercher par nom ou identifiant'
  ],
  'start': [
    'ابحث عن شخص لبدء محادثة معه.',
    'Find someone to start a conversation.',
    'Recherchez une personne pour discuter.'
  ],
  'empty': [
    'لم نعثر على أشخاص. جرّب اسمًا آخر.',
    'No people found. Try another name.',
    'Aucune personne trouvée. Essayez un autre nom.'
  ],
  'failed': [
    'تعذر البحث. تحقق من الاتصال وأعد المحاولة.',
    'Search failed. Check your connection and try again.',
    'La recherche a échoué. Vérifiez votre connexion et réessayez.'
  ],
  'unauthenticated': [
    'انتهت الجلسة. سجّل الدخول ثم أعد البحث.',
    'Your session ended. Sign in and search again.',
    'Votre session a expiré. Reconnectez-vous puis relancez la recherche.'
  ],
  'limited': [
    'طلبات بحث كثيرة. انتظر دقيقة ثم أعد المحاولة.',
    'Too many searches. Wait a minute and try again.',
    'Trop de recherches. Patientez une minute puis réessayez.'
  ],
  'retry': ['إعادة المحاولة', 'Try again', 'Réessayer'],
  'clear': ['مسح البحث', 'Clear search', 'Effacer la recherche'],
  'loading': [
    'جارٍ البحث عن أشخاص',
    'Searching for people',
    'Recherche de personnes'
  ],
  'truncated': [
    'النتائج محدودة. اكتب اسمًا أدق للعثور على الشخص.',
    'Results are limited. Enter a more specific name.',
    'Résultats limités. Saisissez un nom plus précis.'
  ],
};
