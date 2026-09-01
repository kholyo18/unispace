import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import 'package:UniSpace/main.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:UniSpace/features/shell/UniSpace_App.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Future<String> translateSubject(BuildContext context, String subject) async {
//   try {
//     // جلب اللغة المختارة من التطبيق
//     final lang = UniSpaceApp.of(context)._locale.languageCode;
//
//     // إذا كانت العربية → نعيد النص كما هو
//     if (lang == 'ar') return subject;
//
//     // ترجمة للنص حسب اللغة المختارة
//     var translation = await translator.translate(subject, to: lang);
//     return translation.text;
//   } catch (e) {
//     // fallback عند حدوث خطأ
//     return subject;
//   }
// }
// final translator = GoogleTranslator(); // كائن الترجمة
// class AutoTranslate {
//   static final translator = GoogleTranslator();
//
//   static Future<String> tr(BuildContext context, String text) async {
//     final lang = UniSpaceApp.of(context)._locale.languageCode;
//
//     // إذا كانت نفس اللغة → لا حاجة للترجمة
//     if (lang == 'ar') return text;
//
//     try {
//       final translation = await translator.translate(text, to: lang);
//       return translation.text;
//     } catch (_) {
//       return text; // إذا فشلت الترجمة
//     }
//   }
// }




