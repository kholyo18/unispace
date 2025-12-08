<p align="center">
  <img src="assets/brand/logo-horizontal.svg" width="720" alt="UniSpace Logo"/>
</p>
<p align="center">
  <img src="assets/screenshots/UniSpace_mockup.png" width="720" alt="UniSpace App Preview"/>
</p>

# UniSpace 🎓💬
حساب المعدّل الجامعي + شات طلابي (Online عبر Firebase أو Offline محليًا).  
تطبيق Flutter بالألوان الأساسية **أخضر** `#16A34A` و **أزرق** `#2563EB`.

![Platform](https://img.shields.io/badge/Flutter-3.x-blue)
![Firebase](https://img.shields.io/badge/Firebase-Core%20%7C%20Auth%20%7C%20Firestore%20%7C%20Messaging-ffca28)
![License](https://img.shields.io/badge/License-MIT-green)

> التطبيق يشتغل حتى بدون إعداد Firebase (وضع Offline)، وعند تفعيل Firebase ينتقل تلقائيًا إلى وضع Online.

---

## ✨ المزايا
- 🧮 **حاسبة المعدّل**: مواد / معاملات / أجزاء (TD/TP/EXAM) + استدراك + مواد إقصائية + تقريب.
- 💬 **شات طلابي**: قنوات/DM، إرسال رسائل، يعمل:
    - **Online**: Firestore (إن وُجدت إعدادات Firebase).
    - **Offline**: LocalStore (ذاكرة + حفظ تلقائي).
- 🧩 **قوالب جاهزة** للتخصصات + **تعديل سريع** للإعدادات.
- 💾 **حفظ تلقائي** للـ TermData عبر `shared_preferences`.
- 🔁 **تصدير/استيراد JSON** من داخل التطبيق (Clipboard).
- 🔔 تهيئة **Firebase Messaging** (Snackbar في المقدمة لتجارب أولية).
- 📄 (اختياري) توليد PDF لاحقًا عند تفعيل حزمتَي `pdf` و `printing`.

---

## 📦 المتطلبات
- Flutter 3.22+
- Dart SDK 3.4+
- JDK 17
- Android SDK (compile/target 34)

---

## 🚀 التشغيل السريع
```bash
# 1) جلب الحزم
flutter pub get

# 2) (اختياري) ربط Firebase تلقائيًا لجميع المنصات التي تريدها
dart pub global activate flutterfire_cli
flutterfire configure   # يولّد lib/firebase_options.dart

# 3) تشغيل
flutter run   # اختر جهاز Android أو Web
