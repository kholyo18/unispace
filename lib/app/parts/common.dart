part of '../../main.dart';

Future<void> openPdf(String filePath) async {
  final result = await OpenFilex.open(filePath);
  print(result); // Optional: لمراجعة حالة الفتح
}

// ============================================================================
// Branding
// ============================================================================

Color appTeal(BuildContext context) {
  try {
    return UniSpaceApp.of(context).tealColor;
  } catch (_) {
    return kDefaultTeal;
  }
}

Color appTealLight(BuildContext context) {
  return Color.lerp(appTeal(context), Colors.white, 0.55)!;
}

Color appTealDark(BuildContext context) {
  return Color.lerp(appTeal(context), Colors.black, 0.35)!;
}

// ============================================================================
// Bootstrap
// ============================================================================
Future<String> translateSubject(BuildContext context, String subject) async {
  try {
    // جلب اللغة المختارة من التطبيق
    final lang = UniSpaceApp.of(context)._locale.languageCode;

    // إذا كانت العربية → نعيد النص كما هو
    if (lang == 'ar') return subject;

    // ترجمة للنص حسب اللغة المختارة
    var translation = await translator.translate(subject, to: lang);
    return translation.text;
  } catch (e) {
    // fallback عند حدوث خطأ
    return subject;
  }
}

final translator = GoogleTranslator(); // كائن الترجمة

class AutoTranslate {
  static final translator = GoogleTranslator();

  static Future<String> tr(BuildContext context, String text) async {
    final lang = UniSpaceApp.of(context)._locale.languageCode;

    // إذا كانت نفس اللغة → لا حاجة للترجمة
    if (lang == 'ar') return text;

    try {
      final translation = await translator.translate(text, to: lang);
      return translation.text;
    } catch (_) {
      return text; // إذا فشلت الترجمة
    }
  }
}

