// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ar locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'ar';

  static String m0(specialty, level) =>
      "التخصص: ${specialty} | المستوى: ${level}";

  static String m1(date) => "تم الحظر في ${date}";

  static String m2(count) => "تعليقات (${count})";

  static String m3(max) => "يرجى عدم تجاوز ${max} حرفًا";

  static String m4(min) => "يرجى إدخال ${min} أحرف على الأقل";

  static String m5(fileName) => "هل تريد حذف ${fileName} من هذا الجهاز؟";

  static String m6(size) => "التخزين المؤقت: ${size}";

  static String m7(size) => "الإجمالي المستخدم: ${size}";

  static String m8(size) => "المستخدم: ${size}";

  static String m9(date) => "آخر تحديث ${date}";

  static String m10(subject) => "تذكير: ${subject} بعد 24 ساعة";

  static String m11(subject) => "تذكير: ${subject} بعد ساعتين";

  static String m12(subject) => "تذكير: ${subject} بعد 30 دقيقة";

  static String m13(type) => "النوع: ${type}";

  static String m14(seconds) => "إرسال الرمز خلال ${seconds}ث";

  static String m15(masked) => "أدخل بريدك الحالي للتأكيد. التلميح: ${masked}";

  static String m16(masked) => "راجع البريد الجديد: ${masked}";

  static String m17(date) => "آخر تغيير كلمة المرور: ${date}";

  static String m18(days, hours) =>
      "يمكنك تغيير الاسم بعد: ${days} يوم / ${hours} ساعة";

  static String m19(hours) => "يمكنك تغيير الاسم بعد: ${hours} ساعة";

  static String m20(maskedEmail) =>
      "سنرسل رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني المسجل: ${maskedEmail}";

  static String m21(current, total) => "الخطوة ${current} من ${total}";

  static String m22(seconds) => "إعادة الإرسال بعد ${seconds}ث";

  static String m23(e) => "تعذر الإرسال: ${e}";

  static String m24(days) => "منذ ${days} ي";

  static String m25(hours) => "منذ ${hours} س";

  static String m26(minutes) => "منذ ${minutes} د";

  static String m27(start, end) => "${start} → ${end}";

  static String m28(minutes) => "${minutes} دقيقة";

  static String m29(subject) => "جلسة تركيز: ${subject}";

  static String m30(subject) => "اختبار تجريبي: ${subject}";

  static String m31(subject) => "اختبار تدريبي: ${subject}";

  static String m32(subject) => "مراجعة ملخصة: ${subject}";

  static String m33(count) => "المحاولات المتبقية: ${count}";

  static String m34(email) =>
      "أدخل الرمز المكوّن من 6 أرقام المرسل إلى ${email}.";

  static String m35(seconds) => "إعادة الإرسال خلال ${seconds}ث";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "aboutApp": MessageLookupByLibrary.simpleMessage("حول التطبيق"),
    "aboutAppDescription": MessageLookupByLibrary.simpleMessage(
      "منصة جامعية ذكية تهدف إلى مساعدة الطلبة على تنظيم دراستهم، حساب المعدلات، تتبع الامتحانات، والتخطيط للمراجعة بطريقة سهلة وفعالة.",
    ),
    "aboutAppDetails": MessageLookupByLibrary.simpleMessage(
      "UniSpace لا يجمع بيانات شخصية خارج Firebase. جميع البيانات آمنة.",
    ),
    "aboutAppFeatureExams": MessageLookupByLibrary.simpleMessage(
      "رزنامة الامتحانات",
    ),
    "aboutAppFeatureGpa": MessageLookupByLibrary.simpleMessage(
      "حساب المعدل الجامعي بدقة",
    ),
    "aboutAppFeatureNotes": MessageLookupByLibrary.simpleMessage(
      "تدوين الملاحظات الدراسية",
    ),
    "aboutAppFeatureReviewPlan": MessageLookupByLibrary.simpleMessage(
      "مخطط المراجعة الذكي",
    ),
    "aboutAppFeatureStudents": MessageLookupByLibrary.simpleMessage(
      "موجّه خصيصًا للطلبة الجامعيين",
    ),
    "aboutAppFooter": MessageLookupByLibrary.simpleMessage(
      "تم التطوير باستخدام Flutter",
    ),
    "aboutAppSummary": MessageLookupByLibrary.simpleMessage(
      "منصة لحساب المعدل الجامعي والتواصل مع الطلبة وتدوين الملاحظات.",
    ),
    "aboutAppViewLicenses": MessageLookupByLibrary.simpleMessage(
      "الاطلاع على التراخيص",
    ),
    "academicCollegeLabel": MessageLookupByLibrary.simpleMessage("الكلية"),
    "academicLevelLabel": MessageLookupByLibrary.simpleMessage("المستوى"),
    "academicMajorLabel": MessageLookupByLibrary.simpleMessage("التخصص"),
    "academicSettingsDescription": MessageLookupByLibrary.simpleMessage(
      "حدّث الكلية والتخصص والمستوى.",
    ),
    "academicSettingsSaved": MessageLookupByLibrary.simpleMessage(
      "تم حفظ الإعدادات الأكاديمية.",
    ),
    "academicSettingsTitle": MessageLookupByLibrary.simpleMessage(
      "الإعدادات الأكاديمية",
    ),
    "academicShortcutDeleteCancel": MessageLookupByLibrary.simpleMessage(
      "إلغاء",
    ),
    "academicShortcutDeleteConfirm": MessageLookupByLibrary.simpleMessage(
      "حذف",
    ),
    "academicShortcutDeleteConfirmBody": MessageLookupByLibrary.simpleMessage(
      "هل تريد حذف الاختصار الأكاديمي؟ يمكنك إضافته مرة أخرى لاحقًا.",
    ),
    "academicShortcutDeleteConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "تأكيد الحذف",
    ),
    "academicShortcutDeleteSuccess": MessageLookupByLibrary.simpleMessage(
      "تم حذف الاختصار بنجاح.",
    ),
    "academicShortcutDeleteTitle": MessageLookupByLibrary.simpleMessage(
      "حذف الاختصار",
    ),
    "academicShortcutDetails": m0,
    "academicShortcutEdit": MessageLookupByLibrary.simpleMessage("تعديل"),
    "academicShortcutEmptyAction": MessageLookupByLibrary.simpleMessage(
      "إضافة اختصار",
    ),
    "academicShortcutEmptyTitle": MessageLookupByLibrary.simpleMessage(
      "لم يتم إعداد اختصار أكاديمي بعد.",
    ),
    "academicShortcutGo": MessageLookupByLibrary.simpleMessage("انتقال"),
    "academicShortcutNotFound": MessageLookupByLibrary.simpleMessage(
      "لم نعثر على هذا التخصص. يرجى تحديث الإعدادات الأكاديمية.",
    ),
    "academicShortcutTitle": MessageLookupByLibrary.simpleMessage(
      "اختصارك الأكاديمي",
    ),
    "academicclass": MessageLookupByLibrary.simpleMessage("القسم"),
    "accounting": MessageLookupByLibrary.simpleMessage("محاسبة"),
    "accountingTaxation": MessageLookupByLibrary.simpleMessage("محاسبة وجباية"),
    "activeSessionNow": MessageLookupByLibrary.simpleMessage("الآن"),
    "activeSessionsEmpty": MessageLookupByLibrary.simpleMessage(
      "لا توجد جلسات أخرى نشطة",
    ),
    "activeSessionsHint": MessageLookupByLibrary.simpleMessage(
      "إدارة الجلسات تتطلب خدمة خلفية آمنة.",
    ),
    "activeSessionsTitle": MessageLookupByLibrary.simpleMessage(
      "الجلسات النشطة",
    ),
    "add": MessageLookupByLibrary.simpleMessage("إضافة"),
    "addExam": MessageLookupByLibrary.simpleMessage("إضافة امتحان"),
    "advancedPublicLaw": MessageLookupByLibrary.simpleMessage("قانون عام معمق"),
    "algeriaLabel": MessageLookupByLibrary.simpleMessage("الجزائر"),
    "arabic": MessageLookupByLibrary.simpleMessage("العربية"),
    "archive": MessageLookupByLibrary.simpleMessage("الأرشيف"),
    "basicEducation": MessageLookupByLibrary.simpleMessage("التعليم الأساسي"),
    "basicEducationDept": MessageLookupByLibrary.simpleMessage(
      "قسم التعليم الأساسي",
    ),
    "basicUnit": MessageLookupByLibrary.simpleMessage("الوحدة الأساسية"),
    "blockAccount": MessageLookupByLibrary.simpleMessage("حظر الحساب"),
    "blockedUsersAddAction": MessageLookupByLibrary.simpleMessage("حظر"),
    "blockedUsersAddHint": MessageLookupByLibrary.simpleMessage(
      "أدخل معرّف المستخدم أو البريد",
    ),
    "blockedUsersAddTitle": MessageLookupByLibrary.simpleMessage("حظر مستخدم"),
    "blockedUsersEmpty": MessageLookupByLibrary.simpleMessage(
      "لا يوجد مستخدمون محظورون",
    ),
    "blockedUsersHint": MessageLookupByLibrary.simpleMessage(
      "ستظهر هنا الحسابات المحظورة.",
    ),
    "blockedUsersSince": m1,
    "blockedUsersTitle": MessageLookupByLibrary.simpleMessage(
      "المستخدمون المحظورون",
    ),
    "businessAdministration": MessageLookupByLibrary.simpleMessage(
      "إدارة أعمال",
    ),
    "businessLaw": MessageLookupByLibrary.simpleMessage("قانون الأعمال"),
    "calculate": MessageLookupByLibrary.simpleMessage("احسب"),
    "cancel": MessageLookupByLibrary.simpleMessage("إلغاء"),
    "changeLanguage": MessageLookupByLibrary.simpleMessage("تغيير اللغة"),
    "changeTheme": MessageLookupByLibrary.simpleMessage("تغيير المظهر"),
    "checkNow": MessageLookupByLibrary.simpleMessage("تحقق الآن"),
    "chooseLanguage": MessageLookupByLibrary.simpleMessage("اختر اللغة"),
    "chooseTheme": MessageLookupByLibrary.simpleMessage("اختر المظهر"),
    "clipboard": MessageLookupByLibrary.simpleMessage("الحافظة"),
    "close": MessageLookupByLibrary.simpleMessage("إغلاق"),
    "coefficient": MessageLookupByLibrary.simpleMessage("معامل:"),
    "comment": MessageLookupByLibrary.simpleMessage("تعليق"),
    "comments": MessageLookupByLibrary.simpleMessage("التعليقات"),
    "commentsCount": m2,
    "commercialSciences": MessageLookupByLibrary.simpleMessage("علوم تجارية"),
    "commercialSciencesDept": MessageLookupByLibrary.simpleMessage(
      "قسم علوم تجارية",
    ),
    "commonCore": MessageLookupByLibrary.simpleMessage("جذع مشترك"),
    "commonCore1": MessageLookupByLibrary.simpleMessage("جذع مشترك"),
    "community": MessageLookupByLibrary.simpleMessage("المجتمع"),
    "confirmDeleteExam": MessageLookupByLibrary.simpleMessage(
      "هل تريد حذف هذا الامتحان؟",
    ),
    "contactCategoryFeature": MessageLookupByLibrary.simpleMessage(
      "اقتراح ميزة جديدة",
    ),
    "contactCategoryImprovement": MessageLookupByLibrary.simpleMessage("تحسين"),
    "contactCategoryIssue": MessageLookupByLibrary.simpleMessage("مشكلة"),
    "contactCategoryLabel": MessageLookupByLibrary.simpleMessage("الفئة"),
    "contactCategoryOther": MessageLookupByLibrary.simpleMessage("أخرى"),
    "contactCategoryReport": MessageLookupByLibrary.simpleMessage("بلاغ"),
    "contactCopied": MessageLookupByLibrary.simpleMessage("تم نسخ الرسالة"),
    "contactCopyAction": MessageLookupByLibrary.simpleMessage("نسخ"),
    "contactCopyDialogBody": MessageLookupByLibrary.simpleMessage(
      "انسخ الرسالتك وأرسلها إلى الدعم عبر البريد.",
    ),
    "contactCopyDialogTitle": MessageLookupByLibrary.simpleMessage(
      "نسخ الرسالة",
    ),
    "contactDescriptionHint": MessageLookupByLibrary.simpleMessage(
      "اشرح التفاصيل لنساعدك بسرعة",
    ),
    "contactDescriptionLabel": MessageLookupByLibrary.simpleMessage("الوصف"),
    "contactIncludeUserInfo": MessageLookupByLibrary.simpleMessage(
      "تضمين معلومات الحساب",
    ),
    "contactMailOpened": MessageLookupByLibrary.simpleMessage(
      "تم فتح البريد لإرسال رسالتك",
    ),
    "contactMailUnavailable": MessageLookupByLibrary.simpleMessage(
      "تعذر فتح تطبيق البريد. يمكنك نسخ الرسالة.",
    ),
    "contactMetadataAppVersion": MessageLookupByLibrary.simpleMessage(
      "إصدار التطبيق",
    ),
    "contactMetadataEmail": MessageLookupByLibrary.simpleMessage(
      "البريد الإلكتروني",
    ),
    "contactMetadataHeader": MessageLookupByLibrary.simpleMessage(
      "بيانات إضافية",
    ),
    "contactMetadataLocale": MessageLookupByLibrary.simpleMessage("اللغة"),
    "contactMetadataName": MessageLookupByLibrary.simpleMessage("الاسم"),
    "contactMetadataPlatform": MessageLookupByLibrary.simpleMessage("المنصة"),
    "contactMetadataTimestamp": MessageLookupByLibrary.simpleMessage("الوقت"),
    "contactMetadataUserId": MessageLookupByLibrary.simpleMessage(
      "معرّف المستخدم",
    ),
    "contactScreenshotPlaceholder": MessageLookupByLibrary.simpleMessage(
      "إرفاق لقطة شاشة",
    ),
    "contactScreenshotSoon": MessageLookupByLibrary.simpleMessage("قريبًا"),
    "contactSend": MessageLookupByLibrary.simpleMessage("إرسال"),
    "contactSendFailure": MessageLookupByLibrary.simpleMessage(
      "تعذر إرسال رسالتك. يرجى المحاولة مرة أخرى.",
    ),
    "contactSendSuccess": MessageLookupByLibrary.simpleMessage("تم الإرسال ✅"),
    "contactSending": MessageLookupByLibrary.simpleMessage("جارٍ الإرسال..."),
    "contactSubjectHint": MessageLookupByLibrary.simpleMessage(
      "ملخص قصير لطلبك",
    ),
    "contactSubjectLabel": MessageLookupByLibrary.simpleMessage("الموضوع"),
    "contactUs": MessageLookupByLibrary.simpleMessage("تواصل معنا"),
    "contactUsSubtitle": MessageLookupByLibrary.simpleMessage(
      "يسعدنا سماع رسالتك. أرسل رسالتك إلى الدعم.",
    ),
    "contactUserInfoUnavailable": MessageLookupByLibrary.simpleMessage(
      "لا توجد معلومات مستخدم مسجّل الدخول",
    ),
    "contactValidationMaxLength": m3,
    "contactValidationMinLength": m4,
    "contactValidationRequired": MessageLookupByLibrary.simpleMessage(
      "هذا الحقل مطلوب",
    ),
    "content": MessageLookupByLibrary.simpleMessage("المحتوى"),
    "copyText": MessageLookupByLibrary.simpleMessage("نسخ النص"),
    "corporateFinance": MessageLookupByLibrary.simpleMessage("مالية المؤسسة"),
    "corporateFinancialManagement": MessageLookupByLibrary.simpleMessage(
      "التسيير المالي للمؤسسات",
    ),
    "createPost": MessageLookupByLibrary.simpleMessage("نشر"),
    "createPoste": MessageLookupByLibrary.simpleMessage("أنشئ منشوراً"),
    "credits": MessageLookupByLibrary.simpleMessage("رصيد:"),
    "criminalLaw": MessageLookupByLibrary.simpleMessage(
      "القانون الجنائي والعلوم الجنائية",
    ),
    "currentDeviceTitle": MessageLookupByLibrary.simpleMessage("الجهاز الحالي"),
    "dangerZone": MessageLookupByLibrary.simpleMessage("منطقة الخطر"),
    "dark": MessageLookupByLibrary.simpleMessage("داكن"),
    "darkMode": MessageLookupByLibrary.simpleMessage("الوضع الداكن"),
    "delete": MessageLookupByLibrary.simpleMessage("حذف"),
    "deleteExam": MessageLookupByLibrary.simpleMessage("حذف الامتحان"),
    "department": MessageLookupByLibrary.simpleMessage("القسم"),
    "deptArabicLangLit": MessageLookupByLibrary.simpleMessage(
      "قسم اللغة والأدب العربي",
    ),
    "deptEnglishLangLit": MessageLookupByLibrary.simpleMessage(
      "قسم اللغة والأدب الإنجليزي",
    ),
    "deptFrenchLangLit": MessageLookupByLibrary.simpleMessage(
      "قسم اللغة والأدب الفرنسي",
    ),
    "deviceActiveNow": MessageLookupByLibrary.simpleMessage("نشط الآن"),
    "devicePrimary": MessageLookupByLibrary.simpleMessage("الجهاز الأساسي"),
    "downloadsCacheClearFailed": MessageLookupByLibrary.simpleMessage(
      "تعذر مسح التخزين المؤقت.",
    ),
    "downloadsCacheCleared": MessageLookupByLibrary.simpleMessage(
      "تم مسح التخزين المؤقت.",
    ),
    "downloadsClearAllAction": MessageLookupByLibrary.simpleMessage(
      "مسح جميع التنزيلات",
    ),
    "downloadsClearAllDialogBody": MessageLookupByLibrary.simpleMessage(
      "سيؤدي ذلك إلى إزالة جميع الملفات التي تم تنزيلها من هذا الجهاز.",
    ),
    "downloadsClearAllDialogConfirm": MessageLookupByLibrary.simpleMessage(
      "مسح الكل",
    ),
    "downloadsClearAllDialogTitle": MessageLookupByLibrary.simpleMessage(
      "مسح جميع التنزيلات؟",
    ),
    "downloadsClearAllFailed": MessageLookupByLibrary.simpleMessage(
      "تعذر مسح جميع التنزيلات.",
    ),
    "downloadsClearAllSuccess": MessageLookupByLibrary.simpleMessage(
      "تم مسح جميع التنزيلات.",
    ),
    "downloadsClearCache": MessageLookupByLibrary.simpleMessage(
      "مسح التخزين المؤقت",
    ),
    "downloadsClearCacheDialogBody": MessageLookupByLibrary.simpleMessage(
      "سيؤدي ذلك إلى إزالة الملفات المخزنة مؤقتاً من هذا الجهاز. يمكنك تنزيلها لاحقاً.",
    ),
    "downloadsClearCacheDialogConfirm": MessageLookupByLibrary.simpleMessage(
      "مسح التخزين المؤقت",
    ),
    "downloadsClearCacheDialogTitle": MessageLookupByLibrary.simpleMessage(
      "هل تريد مسح التخزين المؤقت؟",
    ),
    "downloadsDeleteDialogBody": m5,
    "downloadsDeleteDialogTitle": MessageLookupByLibrary.simpleMessage(
      "حذف التنزيل؟",
    ),
    "downloadsDeleteFailed": MessageLookupByLibrary.simpleMessage(
      "تعذر حذف التنزيل.",
    ),
    "downloadsDeleteSuccess": MessageLookupByLibrary.simpleMessage(
      "تم حذف التنزيل.",
    ),
    "downloadsDescription": MessageLookupByLibrary.simpleMessage(
      "اعرض الملفات التي تم تنزيلها ونظّف التخزين المؤقت.",
    ),
    "downloadsEmptyHint": MessageLookupByLibrary.simpleMessage(
      "ستظهر العناصر المحمّلة هنا.",
    ),
    "downloadsEmptyTitle": MessageLookupByLibrary.simpleMessage(
      "لا توجد تنزيلات بعد",
    ),
    "downloadsExploreCta": MessageLookupByLibrary.simpleMessage(
      "استكشف المحتوى",
    ),
    "downloadsFilterAll": MessageLookupByLibrary.simpleMessage("الكل"),
    "downloadsFilterFiles": MessageLookupByLibrary.simpleMessage("ملفات"),
    "downloadsFilterImages": MessageLookupByLibrary.simpleMessage("صور"),
    "downloadsLoadFailed": MessageLookupByLibrary.simpleMessage(
      "تعذر تحميل التنزيلات.",
    ),
    "downloadsRefreshList": MessageLookupByLibrary.simpleMessage(
      "تحديث القائمة",
    ),
    "downloadsSortLabel": MessageLookupByLibrary.simpleMessage("الترتيب حسب"),
    "downloadsSortNewest": MessageLookupByLibrary.simpleMessage("الأحدث"),
    "downloadsSortOldest": MessageLookupByLibrary.simpleMessage("الأقدم"),
    "downloadsStorageCacheLabel": MessageLookupByLibrary.simpleMessage(
      "التخزين المؤقت: 0 MB",
    ),
    "downloadsStorageCacheLabelValue": m6,
    "downloadsStorageInfo": MessageLookupByLibrary.simpleMessage(
      "سيتم احتساب الأحجام تلقائياً لاحقاً.",
    ),
    "downloadsStorageInfoValue": m7,
    "downloadsStorageTitle": MessageLookupByLibrary.simpleMessage(
      "مساحة التنزيلات",
    ),
    "downloadsStorageUserLabel": MessageLookupByLibrary.simpleMessage(
      "المستخدم: 0 MB",
    ),
    "downloadsStorageUserLabelValue": m8,
    "downloadsTitle": MessageLookupByLibrary.simpleMessage("التنزيلات"),
    "downloadsUpdatedAt": m9,
    "drawerSectionAccount": MessageLookupByLibrary.simpleMessage("الحساب"),
    "drawerSectionApp": MessageLookupByLibrary.simpleMessage("التطبيق"),
    "drawerSectionContent": MessageLookupByLibrary.simpleMessage("المحتوى"),
    "drawerSectionStudent": MessageLookupByLibrary.simpleMessage("الطالب"),
    "economics": MessageLookupByLibrary.simpleMessage("علوم اقتصادية"),
    "economicsDept": MessageLookupByLibrary.simpleMessage("قسم علوم اقتصادية"),
    "editExam": MessageLookupByLibrary.simpleMessage("تعديل الامتحان"),
    "editProfile": MessageLookupByLibrary.simpleMessage("تعديل الملف الشخصي"),
    "editWeights": MessageLookupByLibrary.simpleMessage("تعديل الأوزان"),
    "email": MessageLookupByLibrary.simpleMessage("البريد الإلكتروني"),
    "emailAlreadyInUseError": MessageLookupByLibrary.simpleMessage(
      "البريد الإلكتروني مستخدم بالفعل.",
    ),
    "emailAuthDisabledError": MessageLookupByLibrary.simpleMessage(
      "تم تعطيل تسجيل الدخول بالبريد الإلكتروني.",
    ),
    "emailHidden": MessageLookupByLibrary.simpleMessage("البريد مخفي"),
    "emailNotVerified": MessageLookupByLibrary.simpleMessage(
      "البريد غير موثّق",
    ),
    "emailNotVerifiedYet": MessageLookupByLibrary.simpleMessage(
      "لم يتم تأكيد البريد الإلكتروني بعد. يرجى فتح البريد الإلكتروني والضغط على رابط التحقق، ثم العودة إلى التطبيق والمحاولة مجددًا.",
    ),
    "emailUnavailable": MessageLookupByLibrary.simpleMessage("البريد غير متاح"),
    "emailVerified": MessageLookupByLibrary.simpleMessage("البريد موثّق"),
    "energyMiningLaw": MessageLookupByLibrary.simpleMessage(
      "قانون الطاقة والمناجم",
    ),
    "examCalendar": MessageLookupByLibrary.simpleMessage("رزنامة الامتحانات"),
    "examNote": MessageLookupByLibrary.simpleMessage("ملاحظة"),
    "examReminder24h": m10,
    "examReminder2h": m11,
    "examReminder30m": m12,
    "examRoom": MessageLookupByLibrary.simpleMessage("القاعة"),
    "examSubject": MessageLookupByLibrary.simpleMessage("المادة"),
    "examSubjectRequired": MessageLookupByLibrary.simpleMessage(
      "يرجى إدخال المادة",
    ),
    "exploratoryUnit": MessageLookupByLibrary.simpleMessage(
      "الوحدة الاستكشافية",
    ),
    "faculties": MessageLookupByLibrary.simpleMessage("الكليات"),
    "faculty": MessageLookupByLibrary.simpleMessage("الكلية"),
    "facultyArtsLanguages": MessageLookupByLibrary.simpleMessage(
      "كلية الآداب واللغات الأجنبية",
    ),
    "facultyEconomics": MessageLookupByLibrary.simpleMessage(
      "كلية العلوم الاقتصادية والتجارية وعلوم التسيير",
    ),
    "facultyLawPolitical": MessageLookupByLibrary.simpleMessage(
      "كلية الحقوق والعلوم السياسية",
    ),
    "fail": MessageLookupByLibrary.simpleMessage(" راسب"),
    "familyLaw": MessageLookupByLibrary.simpleMessage("قانون الأسرة"),
    "favoritesAddAction": MessageLookupByLibrary.simpleMessage("حفظ"),
    "favoritesAddHint": MessageLookupByLibrary.simpleMessage(
      "أدخل معرّف العنصر",
    ),
    "favoritesAddTitle": MessageLookupByLibrary.simpleMessage("إضافة مفضلة"),
    "favoritesAddTypeHint": MessageLookupByLibrary.simpleMessage(
      "النوع (اختياري)",
    ),
    "favoritesAdded": MessageLookupByLibrary.simpleMessage("تم حفظ المفضلة."),
    "favoritesDescription": MessageLookupByLibrary.simpleMessage(
      "ستظهر عناصر الحفظ هنا.",
    ),
    "favoritesEmptyHint": MessageLookupByLibrary.simpleMessage(
      "احفظ المنشورات أو الملفات لتظهر هنا.",
    ),
    "favoritesEmptyTitle": MessageLookupByLibrary.simpleMessage(
      "لا توجد مفضلات بعد",
    ),
    "favoritesRemoved": MessageLookupByLibrary.simpleMessage("تم حذف المفضلة."),
    "favoritesSignInHint": MessageLookupByLibrary.simpleMessage(
      "تُزامن المفضلات مع حسابك عند تسجيل الدخول.",
    ),
    "favoritesSignInTitle": MessageLookupByLibrary.simpleMessage(
      "سجّل الدخول لحفظ المفضلات",
    ),
    "favoritesTitle": MessageLookupByLibrary.simpleMessage("المفضلة"),
    "favoritesTypeLabel": m13,
    "finance": MessageLookupByLibrary.simpleMessage("مالية"),
    "financeInternationalTrade": MessageLookupByLibrary.simpleMessage(
      "مالية وتجارة دولية",
    ),
    "financialAccounting": MessageLookupByLibrary.simpleMessage(
      "علوم مالية ومحاسبة",
    ),
    "financialAccountingDept": MessageLookupByLibrary.simpleMessage(
      "قسم علوم مالية ومحاسبة",
    ),
    "financialManagement": MessageLookupByLibrary.simpleMessage(
      "الإدارة المالية",
    ),
    "followComment": MessageLookupByLibrary.simpleMessage("متابعة التعليق"),
    "following": MessageLookupByLibrary.simpleMessage("يتابع"),
    "fontSizeDescription": MessageLookupByLibrary.simpleMessage(
      "اختر الحجم المناسب للقراءة.",
    ),
    "fontSizeLarge": MessageLookupByLibrary.simpleMessage("كبير"),
    "fontSizeMedium": MessageLookupByLibrary.simpleMessage("متوسط"),
    "fontSizePreviewLabel": MessageLookupByLibrary.simpleMessage("معاينة"),
    "fontSizePreviewText": MessageLookupByLibrary.simpleMessage(
      "النص التجريبي السريع للقفز فوق الكسل.",
    ),
    "fontSizeSmall": MessageLookupByLibrary.simpleMessage("صغير"),
    "fontSizeTitle": MessageLookupByLibrary.simpleMessage("حجم الخط"),
    "forgotPassword": MessageLookupByLibrary.simpleMessage(
      "هل نسيت كلمة السر؟",
    ),
    "genericAuthError": MessageLookupByLibrary.simpleMessage(
      "حدث خطأ غير متوقع. حاول مرة أخرى.",
    ),
    "gpu": MessageLookupByLibrary.simpleMessage("حساب المعدل الاكاديمي"),
    "guestUser": MessageLookupByLibrary.simpleMessage("زائر"),
    "hashtag": MessageLookupByLibrary.simpleMessage("#"),
    "hide": MessageLookupByLibrary.simpleMessage("إخفاء"),
    "home": MessageLookupByLibrary.simpleMessage("الرئيسية"),
    "homeSubtitle": MessageLookupByLibrary.simpleMessage(
      "تصفح الكليات، احسب معدلك، شارك أفكارك، ودوّن ملاحظاتك بسهولة.",
    ),
    "horizontalUnit": MessageLookupByLibrary.simpleMessage("الوحدة الأفقية"),
    "hotelTourismMarketing": MessageLookupByLibrary.simpleMessage(
      "تسويق فندقي وسياحي",
    ),
    "humanResourcesManagement": MessageLookupByLibrary.simpleMessage(
      "إدارة موارد بشرية",
    ),
    "internationalCooperation": MessageLookupByLibrary.simpleMessage(
      "التعاون الدولي",
    ),
    "internationalEconomics": MessageLookupByLibrary.simpleMessage(
      "اقتصاد دولي",
    ),
    "internationalRelations": MessageLookupByLibrary.simpleMessage(
      "علاقات دولية",
    ),
    "invalidEmailError": MessageLookupByLibrary.simpleMessage(
      "البريد الإلكتروني غير صالح",
    ),
    "invalidEmailValidation": MessageLookupByLibrary.simpleMessage(
      "يرجى إدخال بريد إلكتروني صالح.",
    ),
    "law": MessageLookupByLibrary.simpleMessage("حقوق"),
    "legalProfessionsLaw": MessageLookupByLibrary.simpleMessage(
      "قانون المهن القانونية والقضائية",
    ),
    "light": MessageLookupByLibrary.simpleMessage("فاتح"),
    "lightMode": MessageLookupByLibrary.simpleMessage("الوضع الفاتح"),
    "localAdministration": MessageLookupByLibrary.simpleMessage(
      "الإدارة المحلية",
    ),
    "login": MessageLookupByLibrary.simpleMessage("تسجيل الدخول"),
    "logout": MessageLookupByLibrary.simpleMessage("تسجيل الخروج"),
    "logoutAllConfirm": MessageLookupByLibrary.simpleMessage("تسجيل الخروج"),
    "logoutAllDevices": MessageLookupByLibrary.simpleMessage(
      "تسجيل الخروج من جميع الأجهزة",
    ),
    "logoutAllDevicesPrompt": MessageLookupByLibrary.simpleMessage(
      "سنقوم بتسجيل خروج هذا الجهاز. لإلغاء جلسات الأجهزة الأخرى فعّل الخدمة الخلفية.",
    ),
    "logoutAllFailed": MessageLookupByLibrary.simpleMessage(
      "تعذر تسجيل الخروج من جميع الأجهزة.",
    ),
    "logoutAllLocalOnly": MessageLookupByLibrary.simpleMessage(
      "تم تسجيل الخروج هنا. فعّل الخدمة الخلفية لإلغاء جلسات الأجهزة الأخرى.",
    ),
    "logoutAllOtherDevices": MessageLookupByLibrary.simpleMessage(
      "تسجيل خروج الأجهزة الأخرى",
    ),
    "logoutAllSuccess": MessageLookupByLibrary.simpleMessage(
      "تم تسجيل الخروج من جميع الأجهزة.",
    ),
    "major": MessageLookupByLibrary.simpleMessage("التخصص"),
    "majors": MessageLookupByLibrary.simpleMessage("تخصصات"),
    "manageDevicesDescription": MessageLookupByLibrary.simpleMessage(
      "اطلع على أماكن تسجيل الدخول وأزل الوصول عند الحاجة.",
    ),
    "manageDevicesHint": MessageLookupByLibrary.simpleMessage(
      "راجع الجلسات والأجهزة النشطة.",
    ),
    "manageDevicesTitle": MessageLookupByLibrary.simpleMessage("إدارة الأجهزة"),
    "managementSciences": MessageLookupByLibrary.simpleMessage("علوم التسيير"),
    "managementSciencesDept": MessageLookupByLibrary.simpleMessage(
      "قسم علوم التسيير",
    ),
    "maritimePortLaw": MessageLookupByLibrary.simpleMessage(
      "القانون البحري والمينائي",
    ),
    "marketing": MessageLookupByLibrary.simpleMessage("تسويق"),
    "mediaUrl": MessageLookupByLibrary.simpleMessage("رابط صورة/فيديو"),
    "methodologicalUnit": MessageLookupByLibrary.simpleMessage(
      "الوحدة المنهجية",
    ),
    "monetaryFinancialEconomics": MessageLookupByLibrary.simpleMessage(
      "اقتصاد نقدي ومالي",
    ),
    "mood": MessageLookupByLibrary.simpleMessage("المزاج"),
    "name": MessageLookupByLibrary.simpleMessage("الاسم"),
    "networkError": MessageLookupByLibrary.simpleMessage(
      "مشكلة في الشبكة. حاول مرة أخرى.",
    ),
    "newPost": MessageLookupByLibrary.simpleMessage("منشور جديد"),
    "noExamsDay": MessageLookupByLibrary.simpleMessage(
      "لا توجد امتحانات لهذا اليوم",
    ),
    "noMajorsYet": MessageLookupByLibrary.simpleMessage("لا تخصصات مسجّلة بعد"),
    "noNotesYet": MessageLookupByLibrary.simpleMessage("لا توجد ملاحظات بعد"),
    "noPostsYet": MessageLookupByLibrary.simpleMessage("لا توجد منشورات بعد"),
    "noSubjectsThisSemester": MessageLookupByLibrary.simpleMessage(
      "لا توجد مواد في هذا الفصل.",
    ),
    "notRegistered": MessageLookupByLibrary.simpleMessage("غير مسجّل"),
    "note": MessageLookupByLibrary.simpleMessage("ملاحظة"),
    "notesTdTpExam": MessageLookupByLibrary.simpleMessage(
      "العلامات (TD/TP/EXAM)",
    ),
    "notificationsAnnouncements": MessageLookupByLibrary.simpleMessage(
      "الإعلانات",
    ),
    "notificationsAnnouncementsHint": MessageLookupByLibrary.simpleMessage(
      "ابقَ على اطلاع بأخبار الحرم الجامعي.",
    ),
    "notificationsCommunity": MessageLookupByLibrary.simpleMessage(
      "تحديثات المجتمع",
    ),
    "notificationsCommunityHint": MessageLookupByLibrary.simpleMessage(
      "تنبيهات نشاط المجتمع.",
    ),
    "notificationsDisabledHint": MessageLookupByLibrary.simpleMessage(
      "فعّل الإشعارات لإدارة التذكيرات والتنبيهات.",
    ),
    "notificationsEnabled": MessageLookupByLibrary.simpleMessage(
      "تفعيل الإشعارات",
    ),
    "notificationsEnabledHint": MessageLookupByLibrary.simpleMessage(
      "استلم تنبيهات للتحديثات والتذكيرات.",
    ),
    "notificationsExamReminders": MessageLookupByLibrary.simpleMessage(
      "تذكيرات الامتحانات",
    ),
    "notificationsExamRemindersHint": MessageLookupByLibrary.simpleMessage(
      "تنبيهات محلية للامتحانات المجدولة.",
    ),
    "notificationsSettingsDescription": MessageLookupByLibrary.simpleMessage(
      "تحكم في الإشعارات والتنبيهات.",
    ),
    "notificationsSettingsTitle": MessageLookupByLibrary.simpleMessage(
      "الإشعارات",
    ),
    "oneMajor": MessageLookupByLibrary.simpleMessage("تخصص واحد"),
    "otherNotes": MessageLookupByLibrary.simpleMessage("باقي الملاحظات"),
    "otherSessionsSignedOutSuccess": MessageLookupByLibrary.simpleMessage(
      "تم تسجيل الخروج من الأجهزة الأخرى.",
    ),
    "otpCooldownLabel": m14,
    "otpSentFailed": MessageLookupByLibrary.simpleMessage(
      "تعذر إرسال رابط التأكيد الآن.",
    ),
    "otpSentSuccess": MessageLookupByLibrary.simpleMessage(
      "تم إرسال رابط التأكيد. تحقق من بريدك.",
    ),
    "pass": MessageLookupByLibrary.simpleMessage(" ناجح"),
    "password": MessageLookupByLibrary.simpleMessage("كلمة المرور"),
    "pinNote": MessageLookupByLibrary.simpleMessage("تثبيت الملاحظة"),
    "pinned": MessageLookupByLibrary.simpleMessage("مثبّتة"),
    "politicalAdministrativeOrgs": MessageLookupByLibrary.simpleMessage(
      "تنظيمات سياسية وإدارية",
    ),
    "politicalSciences": MessageLookupByLibrary.simpleMessage("علوم سياسية"),
    "post": MessageLookupByLibrary.simpleMessage("تم نشر منشورك ✅"),
    "posted": MessageLookupByLibrary.simpleMessage("نشر"),
    "posts": MessageLookupByLibrary.simpleMessage("المنشورات"),
    "privacyAccountOverviewSection": MessageLookupByLibrary.simpleMessage(
      "نظرة عامة على الحساب",
    ),
    "privacyAppVersionLabel": MessageLookupByLibrary.simpleMessage(
      "إصدار التطبيق",
    ),
    "privacyApproxLocationLabel": MessageLookupByLibrary.simpleMessage(
      "الموقع التقريبي",
    ),
    "privacyChangePasswordNowNote": MessageLookupByLibrary.simpleMessage(
      "يرجى تغيير كلمة المرور فوراً. التحقق بخطوتين: قريباً.",
    ),
    "privacyChangePasswordTitle": MessageLookupByLibrary.simpleMessage(
      "تغيير كلمة المرور",
    ),
    "privacyConfirmNewPasswordHelper": MessageLookupByLibrary.simpleMessage(
      "أعد إدخال كلمة المرور الجديدة للتأكيد.",
    ),
    "privacyConfirmNewPasswordLabel": MessageLookupByLibrary.simpleMessage(
      "تأكيد كلمة المرور الجديدة",
    ),
    "privacyConnectionTypeLabel": MessageLookupByLibrary.simpleMessage(
      "نوع الاتصال",
    ),
    "privacyContinue": MessageLookupByLibrary.simpleMessage("متابعة"),
    "privacyContinueAction": MessageLookupByLibrary.simpleMessage("متابعة"),
    "privacyCopyFullIp": MessageLookupByLibrary.simpleMessage("نسخ IP الكامل"),
    "privacyCopyIpSuccess": MessageLookupByLibrary.simpleMessage(
      "تم نسخ IP الكامل بأمان.",
    ),
    "privacyCurrentPasswordHelper": MessageLookupByLibrary.simpleMessage(
      "أدخل كلمة المرور الحالية لإثبات ملكية الحساب.",
    ),
    "privacyCurrentPasswordLabel": MessageLookupByLibrary.simpleMessage(
      "كلمة المرور الحالية",
    ),
    "privacyDateTimeLabel": MessageLookupByLibrary.simpleMessage(
      "التاريخ والوقت",
    ),
    "privacyDeviceLabel": MessageLookupByLibrary.simpleMessage("الجهاز"),
    "privacyEditNameTitle": MessageLookupByLibrary.simpleMessage("تعديل الاسم"),
    "privacyEmailConfirmLabel": MessageLookupByLibrary.simpleMessage(
      "تأكيد البريد الإلكتروني الجديد",
    ),
    "privacyEmailConfirmMismatch": MessageLookupByLibrary.simpleMessage(
      "البريدان غير متطابقين.",
    ),
    "privacyEmailCurrentLabel": MessageLookupByLibrary.simpleMessage(
      "البريد الإلكتروني الحالي",
    ),
    "privacyEmailCurrentMismatch": MessageLookupByLibrary.simpleMessage(
      "البريد الحالي غير مطابق.",
    ),
    "privacyEmailFlowSecurityNote": MessageLookupByLibrary.simpleMessage(
      "ملاحظة أمنية: لا تتم مشاركة كلمة المرور أو حفظها داخل التطبيق.",
    ),
    "privacyEmailFlowSendLink": MessageLookupByLibrary.simpleMessage(
      "إرسال رابط تغيير البريد",
    ),
    "privacyEmailFlowStep1Help": m15,
    "privacyEmailFlowStep2Help": MessageLookupByLibrary.simpleMessage(
      "سنرسل رابط تغيير البريد إلى بريدك الحالي للتحقق.",
    ),
    "privacyEmailFlowStep3Help": MessageLookupByLibrary.simpleMessage(
      "أدخل البريد الإلكتروني الجديد ثم قم بتأكيده.",
    ),
    "privacyEmailFlowStep4Help": m16,
    "privacyEmailFlowTitle": MessageLookupByLibrary.simpleMessage(
      "تغيير البريد الإلكتروني",
    ),
    "privacyEmailNewLabel": MessageLookupByLibrary.simpleMessage(
      "البريد الإلكتروني الجديد",
    ),
    "privacyEmailRowTitle": MessageLookupByLibrary.simpleMessage(
      "البريد الإلكتروني",
    ),
    "privacyEmailSaved": MessageLookupByLibrary.simpleMessage(
      "تم تحديث البريد الإلكتروني محليًا.",
    ),
    "privacyEmailValidationRequired": MessageLookupByLibrary.simpleMessage(
      "يرجى إدخال البريد الجديد وتأكيده.",
    ),
    "privacyEnterConfirmToMatch": MessageLookupByLibrary.simpleMessage(
      "قم بإدخال التأكيد للتحقق من التطابق.",
    ),
    "privacyFirstName": MessageLookupByLibrary.simpleMessage("الاسم"),
    "privacyIpAddressLabel": MessageLookupByLibrary.simpleMessage("عنوان IP"),
    "privacyIpUnavailable": MessageLookupByLibrary.simpleMessage(
      "عنوان IP غير متوفر.",
    ),
    "privacyLastName": MessageLookupByLibrary.simpleMessage("اللقب"),
    "privacyLastPasswordChangeAt": m17,
    "privacyLastPasswordChangeTitle": MessageLookupByLibrary.simpleMessage(
      "آخر تغيير كلمة المرور",
    ),
    "privacyLastPasswordChangeUnavailable":
        MessageLookupByLibrary.simpleMessage(
          "آخر تغيير كلمة المرور: غير متوفر",
        ),
    "privacyLoadFailed": MessageLookupByLibrary.simpleMessage(
      "تعذر تحميل بيانات الخصوصية.",
    ),
    "privacyLoadingLastChange": MessageLookupByLibrary.simpleMessage(
      "جارِ تحميل بيانات آخر تغيير...",
    ),
    "privacyManufacturerLabel": MessageLookupByLibrary.simpleMessage(
      "الشركة المصنّعة",
    ),
    "privacyNameRowTitle": MessageLookupByLibrary.simpleMessage("الاسم واللقب"),
    "privacyNameRuleAllowed": MessageLookupByLibrary.simpleMessage(
      "يمكنك تغيير الاسم مرة واحدة شهريًا.",
    ),
    "privacyNameRuleBlockedDays": m18,
    "privacyNameRuleBlockedHours": m19,
    "privacyNameSaved": MessageLookupByLibrary.simpleMessage(
      "تم تحديث الاسم بنجاح.",
    ),
    "privacyNameValidationLong": MessageLookupByLibrary.simpleMessage(
      "الحد الأقصى 40 حرفًا",
    ),
    "privacyNameValidationRequired": MessageLookupByLibrary.simpleMessage(
      "هذا الحقل مطلوب",
    ),
    "privacyNameValidationShort": MessageLookupByLibrary.simpleMessage(
      "يجب أن يكون الاسم حرفين على الأقل",
    ),
    "privacyNetworkCellular": MessageLookupByLibrary.simpleMessage(
      "بيانات الهاتف",
    ),
    "privacyNewPasswordHelper": MessageLookupByLibrary.simpleMessage(
      "يجب أن تحتوي على 8 أحرف على الأقل.",
    ),
    "privacyNewPasswordLabel": MessageLookupByLibrary.simpleMessage(
      "كلمة المرور الجديدة",
    ),
    "privacyNoAuditDataYet": MessageLookupByLibrary.simpleMessage(
      "لا توجد بيانات متاحة بعد.",
    ),
    "privacyNoEmailLinked": MessageLookupByLibrary.simpleMessage(
      "لا يوجد بريد إلكتروني مرتبط بالحساب.",
    ),
    "privacyNotAvailable": MessageLookupByLibrary.simpleMessage("غير متوفر"),
    "privacyOperatingSystemLabel": MessageLookupByLibrary.simpleMessage(
      "نظام التشغيل",
    ),
    "privacyOtherSessionsRevokedPrecaution":
        MessageLookupByLibrary.simpleMessage(
          "تم إنهاء الجلسات الأخرى كإجراء احترازي.",
        ),
    "privacyPasswordMismatchError": MessageLookupByLibrary.simpleMessage(
      "كلمتا المرور غير متطابقتين.",
    ),
    "privacyPasswordMustDifferError": MessageLookupByLibrary.simpleMessage(
      "يجب أن تكون كلمة المرور الجديدة مختلفة عن الحالية.",
    ),
    "privacyPasswordNewLengthError": MessageLookupByLibrary.simpleMessage(
      "كلمة المرور الجديدة يجب أن تتكون من 8 أحرف على الأقل.",
    ),
    "privacyPasswordReauthFailedGeneric": MessageLookupByLibrary.simpleMessage(
      "تعذر التحقق من الهوية، حاول لاحقًا.",
    ),
    "privacyPasswordStrengthLabel": MessageLookupByLibrary.simpleMessage(
      "قوة كلمة المرور: ",
    ),
    "privacyPasswordStrengthMedium": MessageLookupByLibrary.simpleMessage(
      "متوسط",
    ),
    "privacyPasswordStrengthStrong": MessageLookupByLibrary.simpleMessage(
      "قوي",
    ),
    "privacyPasswordStrengthWeak": MessageLookupByLibrary.simpleMessage("ضعيف"),
    "privacyPasswordUpdateAction": MessageLookupByLibrary.simpleMessage(
      "تحديث",
    ),
    "privacyPasswordUpdateConfirmBody": MessageLookupByLibrary.simpleMessage(
      "هل تريد تحديث كلمة المرور؟",
    ),
    "privacyPasswordUpdateConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "تأكيد التحديث",
    ),
    "privacyPasswordUpdateFailed": MessageLookupByLibrary.simpleMessage(
      "تعذر تحديث كلمة المرور، حاول لاحقًا.",
    ),
    "privacyPasswordUpdateRequiresSignin": MessageLookupByLibrary.simpleMessage(
      "تعذر تحديث كلمة المرور، يرجى تسجيل الدخول مرة أخرى.",
    ),
    "privacyPasswordUpdateSuccess": MessageLookupByLibrary.simpleMessage(
      "تم تحديث كلمة المرور بنجاح.",
    ),
    "privacyPasswordsMatch": MessageLookupByLibrary.simpleMessage(
      "كلمتا المرور متطابقتان.",
    ),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage("سياسة الخصوصية"),
    "privacyPolicyBody": MessageLookupByLibrary.simpleMessage(
      "نحن في UniSpace نولي أهمية كبيرة لخصوصية المستخدمين، ونلتزم بحماية بياناتهم واحترام خصوصيتهم. توضح هذه السياسة كيفية التعامل مع المعلومات عند استخدام التطبيق.\n\n1) البيانات التي نقوم بجمعها\nقد نقوم بجمع الحد الأدنى من البيانات الضرورية فقط لتشغيل التطبيق بشكل صحيح، وتشمل:\n- البريد الإلكتروني: يُستخدم لإنشاء الحساب وتسجيل الدخول والتحقق من هوية المستخدم.\n- اسم المستخدم أو الاسم الشخصي: الذي يختاره المستخدم داخل التطبيق.\nلا نقوم بجمع أي بيانات إضافية دون علم المستخدم أو موافقته.\n\n2) البيانات المحلية داخل الجهاز\nقد يتيح التطبيق للمستخدم إدخال بيانات دراسية مثل:\n- المعدلات\n- الملاحظات\n- معلومات تنظيم الدراسة أو الامتحانات\nمهم جدًا:\n- هذه البيانات يتم حفظها محليًا على جهاز المستخدم فقط.\n- لا يتم إرسالها إلى خوادمنا.\n- لا نقوم بالوصول إليها أو جمعها أو مشاركتها.\n- تبقى تحت تحكم المستخدم الكامل.\n\n3) استخدام البيانات\nنستخدم البيانات التي يتم جمعها فقط من أجل:\n- تمكين المستخدم من إنشاء حساب وتسجيل الدخول.\n- تحسين تجربة استخدام التطبيق.\n- ضمان أمان الحساب ومنع الاستخدام غير المصرح به.\n\n4) مشاركة البيانات\n- لا نقوم ببيع أو تأجير أو مشاركة بيانات المستخدمين مع أي طرف ثالث.\n- لا يتم مشاركة أي معلومات شخصية إلا إذا كان ذلك مطلوبًا قانونيًا.\n\n5) خدمات الطرف الثالث\nيستخدم التطبيق خدمات موثوقة مثل Firebase من Google لأغراض المصادقة وتأمين الحسابات.\nتخضع هذه الخدمات لسياسات الخصوصية الخاصة بها، ونلتزم باستخدامها وفق أفضل ممارسات الأمان.\n\n6) أمان البيانات\nنطبق إجراءات أمان مناسبة لحماية بيانات المستخدم من الوصول غير المصرح به أو التعديل أو الفقدان.\n\n7) خصوصية الأطفال\nتطبيق UniSpace موجه للطلبة الجامعيين ولا يستهدف الأطفال دون سن 13 عامًا، ولا نقوم بجمع أي بيانات عنهم عن قصد.\n\n8) التعديلات على سياسة الخصوصية\nقد نقوم بتحديث سياسة الخصوصية من وقت لآخر.\nسيتم إعلام المستخدم بأي تغييرات جوهرية داخل التطبيق.\n\n9) التواصل معنا\nإذا كان لديك أي استفسار بخصوص سياسة الخصوصية، يمكنك التواصل معنا من خلال قسم \"تواصل معنا\" داخل التطبيق.\n\nباستخدامك لتطبيق UniSpace، فإنك توافق على سياسة الخصوصية هذه.",
    ),
    "privacyPolicyTitle": MessageLookupByLibrary.simpleMessage(
      "سياسة الخصوصية – UniSpace",
    ),
    "privacyReauthCopyIpReason": MessageLookupByLibrary.simpleMessage(
      "تحقق من هويتك لنسخ IP الكامل",
    ),
    "privacyReauthFailed": MessageLookupByLibrary.simpleMessage(
      "تعذر التحقق من كلمة المرور. حاول مجددًا.",
    ),
    "privacyReauthSubtitle": MessageLookupByLibrary.simpleMessage(
      "لحماية حسابك، يرجى إدخال كلمة المرور الحالية قبل المتابعة.",
    ),
    "privacyReauthTitle": MessageLookupByLibrary.simpleMessage(
      "تأكيد كلمة السر",
    ),
    "privacyResetEmailHint": MessageLookupByLibrary.simpleMessage(
      "قد يصل البريد خلال دقيقة، وتأكد من مجلد الرسائل غير المرغوب فيها.",
    ),
    "privacyResetLinkFailed": MessageLookupByLibrary.simpleMessage(
      "تعذر إرسال الرابط، حاول لاحقًا.",
    ),
    "privacyResetLinkSent": MessageLookupByLibrary.simpleMessage(
      "تم إرسال رابط إعادة التعيين إلى بريدك الإلكتروني.",
    ),
    "privacyResetPasswordDialogBody": m20,
    "privacyRevokeSessionsFailed": MessageLookupByLibrary.simpleMessage(
      "تعذر إنهاء جميع الجلسات حالياً.",
    ),
    "privacySaveNewPassword": MessageLookupByLibrary.simpleMessage(
      "حفظ كلمة المرور الجديدة",
    ),
    "privacySecurityAlertBody": MessageLookupByLibrary.simpleMessage(
      "إذا لم تكن أنت من غيّر كلمة المرور، سنقوم بتسجيل الخروج من جميع الجلسات فوراً. هل تريد المتابعة؟",
    ),
    "privacySecurityAlertTitle": MessageLookupByLibrary.simpleMessage(
      "تحذير أمني شديد",
    ),
    "privacySegmentTitle": MessageLookupByLibrary.simpleMessage("الخصوصية"),
    "privacySendResetLinkAction": MessageLookupByLibrary.simpleMessage(
      "إرسال الرابط",
    ),
    "privacySettingsDescription": MessageLookupByLibrary.simpleMessage(
      "تحكم في ما يراه الآخرون في ملفك.",
    ),
    "privacySettingsTitle": MessageLookupByLibrary.simpleMessage("الخصوصية"),
    "privacyStepOf": m21,
    "privacyTabSubtitle": MessageLookupByLibrary.simpleMessage(
      "تحكم في بيانات حسابك بأمان",
    ),
    "privacyTabTitle": MessageLookupByLibrary.simpleMessage("الخصوصية"),
    "privacyThisWasNotMe": MessageLookupByLibrary.simpleMessage("هذا ليس أنا"),
    "privacyUnknown": MessageLookupByLibrary.simpleMessage("غير معروف"),
    "privacyViewDetails": MessageLookupByLibrary.simpleMessage(
      "عرض التفاصيل ⌄",
    ),
    "privateLaw": MessageLookupByLibrary.simpleMessage("قانون خاص"),
    "profile": MessageLookupByLibrary.simpleMessage("الملف الشخصي"),
    "profileVisibilityPrivate": MessageLookupByLibrary.simpleMessage("خاص"),
    "profileVisibilityPublic": MessageLookupByLibrary.simpleMessage("عام"),
    "profileVisibilityTitle": MessageLookupByLibrary.simpleMessage(
      "ظهور الملف الشخصي",
    ),
    "publicLaw": MessageLookupByLibrary.simpleMessage("قانون عام"),
    "publish": MessageLookupByLibrary.simpleMessage("نشر"),
    "quickCalc": MessageLookupByLibrary.simpleMessage("الحساب السريع"),
    "quickCalc2": MessageLookupByLibrary.simpleMessage("حساب سريع"),
    "rateApp": MessageLookupByLibrary.simpleMessage("قيّم التطبيق"),
    "rateAppFailed": MessageLookupByLibrary.simpleMessage(
      "تعذر فتح المتجر الآن.",
    ),
    "register": MessageLookupByLibrary.simpleMessage("تسجيل"),
    "reminder24h": MessageLookupByLibrary.simpleMessage("قبل 24 ساعة"),
    "reminder2h": MessageLookupByLibrary.simpleMessage("قبل ساعتين"),
    "reminder30m": MessageLookupByLibrary.simpleMessage("قبل 30 دقيقة"),
    "reminders": MessageLookupByLibrary.simpleMessage("التذكيرات"),
    "report": MessageLookupByLibrary.simpleMessage("إبلاغ"),
    "resendVerificationCooldown": m22,
    "resendVerificationEmail": MessageLookupByLibrary.simpleMessage(
      "إعادة إرسال رسالة التحقق",
    ),
    "resetFailed": m23,
    "resetLinkFailed": MessageLookupByLibrary.simpleMessage(
      "تعذر إرسال الرابط، أعد المحاولة",
    ),
    "resetLinkSentSuccess": MessageLookupByLibrary.simpleMessage(
      "إذا كان البريد مرتبطًا بحساب، سيصلك رابط إعادة التعيين. تحقق أيضًا من الرسائل غير المرغوب فيها.",
    ),
    "resetPassword": MessageLookupByLibrary.simpleMessage(
      "إعادة تعيين كلمة المرور",
    ),
    "resetPasswordHelper": MessageLookupByLibrary.simpleMessage(
      "أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة التعيين.",
    ),
    "resetPasswordTitle": MessageLookupByLibrary.simpleMessage(
      "إعادة تعيين كلمة السر",
    ),
    "resetSent": MessageLookupByLibrary.simpleMessage(
      "تم إرسال رابط إعادة التعيين",
    ),
    "save": MessageLookupByLibrary.simpleMessage("حفظ"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("حفظ التغييرات"),
    "saveExam": MessageLookupByLibrary.simpleMessage("حفظ الامتحان"),
    "savePost": MessageLookupByLibrary.simpleMessage("حفظ المنشور"),
    "searchClipboard": MessageLookupByLibrary.simpleMessage(
      "ابحث داخل الحافظة…",
    ),
    "searchFaculty": MessageLookupByLibrary.simpleMessage("ابحث عن كلية..."),
    "searchNoResults": MessageLookupByLibrary.simpleMessage("لا توجد نتائج"),
    "searchStartTyping": MessageLookupByLibrary.simpleMessage(
      "ابدأ بالكتابة للبحث",
    ),
    "sections": MessageLookupByLibrary.simpleMessage("الأقسام"),
    "securityCenterTitle": MessageLookupByLibrary.simpleMessage("الأمان"),
    "securityPrivacyTitle": MessageLookupByLibrary.simpleMessage(
      "الأمان والخصوصية",
    ),
    "securitySegmentTitle": MessageLookupByLibrary.simpleMessage("الأمان"),
    "sendOtpNow": MessageLookupByLibrary.simpleMessage("أرسل الرمز الآن"),
    "sendResetLink": MessageLookupByLibrary.simpleMessage("إرسال الرابط"),
    "sendResetLinkLoading": MessageLookupByLibrary.simpleMessage(
      "جارٍ الإرسال...",
    ),
    "servicesMarketing": MessageLookupByLibrary.simpleMessage("تسويق الخدمات"),
    "sessionAgoDays": m24,
    "sessionAgoHours": m25,
    "sessionAgoMinutes": m26,
    "sessionDeviceNameLabel": MessageLookupByLibrary.simpleMessage(
      "اسم الجهاز",
    ),
    "sessionLastActivityLabel": MessageLookupByLibrary.simpleMessage(
      "آخر نشاط",
    ),
    "sessionLoginDateLabel": MessageLookupByLibrary.simpleMessage(
      "تاريخ الدخول",
    ),
    "sessionModelLabel": MessageLookupByLibrary.simpleMessage("الموديل"),
    "sessionNetworkLabel": MessageLookupByLibrary.simpleMessage("الشبكة"),
    "sessionPlatformLabel": MessageLookupByLibrary.simpleMessage("المنصة"),
    "sessionSignOutFailed": MessageLookupByLibrary.simpleMessage(
      "تعذر تسجيل خروج هذه الجلسة.",
    ),
    "sessionSignedOutSuccess": MessageLookupByLibrary.simpleMessage(
      "تم تسجيل خروج الجلسة بنجاح.",
    ),
    "sessionTrustedDevice": MessageLookupByLibrary.simpleMessage("جهاز موثوق"),
    "sessionUnknownDevice": MessageLookupByLibrary.simpleMessage(
      "جهاز غير معروف",
    ),
    "sessionVersionLabel": MessageLookupByLibrary.simpleMessage("الإصدار"),
    "share": MessageLookupByLibrary.simpleMessage("مشاركة"),
    "shareApp": MessageLookupByLibrary.simpleMessage("شارك التطبيق"),
    "shareAppMessage": MessageLookupByLibrary.simpleMessage(
      "جرّب UniSpace لأدوات الدراسة الذكية ومجتمع الطلبة!",
    ),
    "showEmailInProfileHint": MessageLookupByLibrary.simpleMessage(
      "السماح للآخرين برؤية بريدك.",
    ),
    "showEmailInProfileTitle": MessageLookupByLibrary.simpleMessage(
      "إظهار البريد في الملف",
    ),
    "signInRequired": MessageLookupByLibrary.simpleMessage(
      "يرجى تسجيل الدخول للمتابعة.",
    ),
    "signOut": MessageLookupByLibrary.simpleMessage("تسجيل الخروج"),
    "smartReviewActionAddExam": MessageLookupByLibrary.simpleMessage(
      "إضافة امتحان",
    ),
    "smartReviewActionAddSubjects": MessageLookupByLibrary.simpleMessage(
      "إضافة مواد",
    ),
    "smartReviewActionClearPlan": MessageLookupByLibrary.simpleMessage(
      "مسح الخطة",
    ),
    "smartReviewActionLater": MessageLookupByLibrary.simpleMessage("لاحقاً"),
    "smartReviewBottomSheetBody": MessageLookupByLibrary.simpleMessage(
      "أضف المواد ومواعيد الامتحانات لنخصص جدولك.",
    ),
    "smartReviewBottomSheetTitle": MessageLookupByLibrary.simpleMessage(
      "قبل إنشاء خطتك",
    ),
    "smartReviewChipExams": MessageLookupByLibrary.simpleMessage(
      "مرتكز على الامتحانات",
    ),
    "smartReviewChipReminders": MessageLookupByLibrary.simpleMessage("تذكيرات"),
    "smartReviewChipSimple": MessageLookupByLibrary.simpleMessage(
      "سهل التطبيق",
    ),
    "smartReviewChipTime": MessageLookupByLibrary.simpleMessage(
      "إدارة وقت ذكية",
    ),
    "smartReviewCtaCreate": MessageLookupByLibrary.simpleMessage(
      "إنشاء خطة مراجعة",
    ),
    "smartReviewEmptyNoExamsBody": MessageLookupByLibrary.simpleMessage(
      "أضف امتحاناً واحداً على الأقل لننشئ خطة مراجعة مركزة.",
    ),
    "smartReviewEmptyNoExamsTitle": MessageLookupByLibrary.simpleMessage(
      "لا توجد امتحانات قادمة",
    ),
    "smartReviewEmptyNoPlanBody": MessageLookupByLibrary.simpleMessage(
      "سنولّد جدولاً لمدة 7 أيام بناءً على أقرب امتحان ووقت الدراسة.",
    ),
    "smartReviewEmptyNoPlanTitle": MessageLookupByLibrary.simpleMessage(
      "جاهز لإنشاء خطتك",
    ),
    "smartReviewPlanCleared": MessageLookupByLibrary.simpleMessage(
      "تم حذف الخطة",
    ),
    "smartReviewPlanComingSoon": MessageLookupByLibrary.simpleMessage("قريباً"),
    "smartReviewPlanCtaCreate": MessageLookupByLibrary.simpleMessage(
      "إنشاء خطة مراجعة",
    ),
    "smartReviewPlanDescription": MessageLookupByLibrary.simpleMessage(
      "أنشئ خطة مراجعة مركزة بناءً على الامتحانات القادمة وأهدافك الدراسية.",
    ),
    "smartReviewPlanRange": m27,
    "smartReviewPlanSectionTitle": MessageLookupByLibrary.simpleMessage("خطتك"),
    "smartReviewPlanTitle": MessageLookupByLibrary.simpleMessage(
      "مخطط المراجعة الذكي",
    ),
    "smartReviewPreviewItem1": MessageLookupByLibrary.simpleMessage(
      "اليوم · جلستان تركيز (٤٥ دقيقة)",
    ),
    "smartReviewPreviewItem2": MessageLookupByLibrary.simpleMessage(
      "غداً · اختبار تجريبي + مراجعة",
    ),
    "smartReviewPreviewItem3": MessageLookupByLibrary.simpleMessage(
      "هذا الأسبوع · ركّز على المواد الأصعب",
    ),
    "smartReviewPreviewTitle": MessageLookupByLibrary.simpleMessage(
      "معاينة الأسبوع",
    ),
    "smartReviewSubtitle": MessageLookupByLibrary.simpleMessage(
      "حوّل الامتحانات القادمة إلى خطة يومية متوازنة وسهلة.",
    ),
    "smartReviewTaskDuration": m28,
    "smartReviewTaskFocusTitle": m29,
    "smartReviewTaskMockTitle": m30,
    "smartReviewTaskPracticeTitle": m31,
    "smartReviewTaskSummaryTitle": m32,
    "smartReviewTipsBody": MessageLookupByLibrary.simpleMessage(
      "نحلّل الامتحانات والوقت المتبقي والصعوبة لبناء جلسات يومية واقعية.",
    ),
    "smartReviewTipsTitle": MessageLookupByLibrary.simpleMessage("كيف يعمل"),
    "smartReviewTitle": MessageLookupByLibrary.simpleMessage(
      "مخطط المراجعة الذكي",
    ),
    "soon": MessageLookupByLibrary.simpleMessage("قريباً"),
    "startDiscussion": MessageLookupByLibrary.simpleMessage(
      "ابدأ النقاش الأول في المجتمع وشارك تجربتك مع زملائك.",
    ),
    "studyResults": MessageLookupByLibrary.simpleMessage("نتائج الدراسة"),
    "system": MessageLookupByLibrary.simpleMessage("حسب النظام"),
    "systemMode": MessageLookupByLibrary.simpleMessage("حسب النظام"),
    "taxLaw": MessageLookupByLibrary.simpleMessage("قانون جبائي"),
    "title": MessageLookupByLibrary.simpleMessage("العنوان"),
    "tooManyRequestsError": MessageLookupByLibrary.simpleMessage(
      "طلبات كثيرة، حاول لاحقًا",
    ),
    "trustedDevicesTitle": MessageLookupByLibrary.simpleMessage(
      "الأجهزة الموثوقة",
    ),
    "twoFactorAttemptsRemaining": m33,
    "twoFactorAuthHint": MessageLookupByLibrary.simpleMessage(
      "يتطلب رمز تحقق عند تسجيل الدخول.",
    ),
    "twoFactorAuthTitle": MessageLookupByLibrary.simpleMessage(
      "المصادقة الثنائية",
    ),
    "twoFactorBackToLogin": MessageLookupByLibrary.simpleMessage(
      "العودة لتسجيل الدخول",
    ),
    "twoFactorChallengeMissing": MessageLookupByLibrary.simpleMessage(
      "تعذر العثور على جلسة التحقق. سجّل الدخول مجددًا.",
    ),
    "twoFactorCodeExpired": MessageLookupByLibrary.simpleMessage(
      "انتهت صلاحية الرمز. اطلب رمزًا جديدًا.",
    ),
    "twoFactorCodeHint": MessageLookupByLibrary.simpleMessage("رمز من 6 أرقام"),
    "twoFactorCodeIncorrect": MessageLookupByLibrary.simpleMessage(
      "الرمز غير صحيح. حاول مرة أخرى.",
    ),
    "twoFactorCodeInvalidFormat": MessageLookupByLibrary.simpleMessage(
      "أدخل رمزًا صالحًا من 6 أرقام.",
    ),
    "twoFactorCodeLabel": MessageLookupByLibrary.simpleMessage("رمز التحقق"),
    "twoFactorCodeSent": MessageLookupByLibrary.simpleMessage(
      "تم إرسال رمز التحقق إلى بريدك.",
    ),
    "twoFactorConfirmButton": MessageLookupByLibrary.simpleMessage("تأكيد"),
    "twoFactorDisabledToast": MessageLookupByLibrary.simpleMessage(
      "تم إيقاف المصادقة الثنائية.",
    ),
    "twoFactorEnableConfirmBody": MessageLookupByLibrary.simpleMessage(
      "سيُطلب منك إدخال رمز لمرة واحدة يتم إرساله إلى بريدك بعد تسجيل الدخول بكلمة المرور.",
    ),
    "twoFactorEnableConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "تفعيل المصادقة الثنائية؟",
    ),
    "twoFactorEnabledToast": MessageLookupByLibrary.simpleMessage(
      "تم تفعيل المصادقة الثنائية.",
    ),
    "twoFactorGenericError": MessageLookupByLibrary.simpleMessage(
      "تعذر إتمام التحقق. حاول مرة أخرى.",
    ),
    "twoFactorOtpDescription": m34,
    "twoFactorOtpTitle": MessageLookupByLibrary.simpleMessage(
      "رمز التحقق عبر البريد",
    ),
    "twoFactorResendCode": MessageLookupByLibrary.simpleMessage(
      "إعادة إرسال الرمز",
    ),
    "twoFactorResendCooldown": MessageLookupByLibrary.simpleMessage(
      "يرجى الانتظار قبل إعادة الإرسال.",
    ),
    "twoFactorResendIn": m35,
    "twoFactorSendFailed": MessageLookupByLibrary.simpleMessage(
      "فشل إرسال رمز التحقق.",
    ),
    "twoFactorTooManyAttempts": MessageLookupByLibrary.simpleMessage(
      "محاولات فاشلة كثيرة. حاول لاحقًا.",
    ),
    "twoFactorVerifiedSuccess": MessageLookupByLibrary.simpleMessage(
      "اكتملت المصادقة الثنائية بنجاح.",
    ),
    "unblockUser": MessageLookupByLibrary.simpleMessage("إلغاء الحظر"),
    "university": MessageLookupByLibrary.simpleMessage("الجامعة"),
    "userDisabledError": MessageLookupByLibrary.simpleMessage(
      "هذا الحساب معطل.",
    ),
    "userInfo": MessageLookupByLibrary.simpleMessage("معلومات المستخدم"),
    "userNotFoundError": MessageLookupByLibrary.simpleMessage(
      "لا يوجد حساب بهذا البريد",
    ),
    "verificationEmailSent": MessageLookupByLibrary.simpleMessage(
      "تم إرسال رسالة التحقق.",
    ),
    "verifyEmailHelper": MessageLookupByLibrary.simpleMessage(
      "افتح رسالة التحقق في بريدك واضغط على الرابط، ثم ارجع للتطبيق واضغط تحقق الآن.",
    ),
    "verifyEmailTitle": MessageLookupByLibrary.simpleMessage(
      "تأكيد البريد الإلكتروني",
    ),
    "verifyEmailToContinue": MessageLookupByLibrary.simpleMessage(
      "يرجى تأكيد بريدك الإلكتروني للمتابعة.",
    ),
    "viewAll": MessageLookupByLibrary.simpleMessage("عرض الكل"),
    "weakPasswordError": MessageLookupByLibrary.simpleMessage(
      "كلمة المرور ضعيفة.",
    ),
    "welcomeEmoji": MessageLookupByLibrary.simpleMessage("مرحباً بك 👋"),
    "welcomeUniSpace": MessageLookupByLibrary.simpleMessage(
      "مرحبًا بك في UniSpace",
    ),
    "writeComment": MessageLookupByLibrary.simpleMessage("اكتب تعليقك…"),
    "writeYourComment": MessageLookupByLibrary.simpleMessage("اكتب تعليقك"),
    "wrongPasswordError": MessageLookupByLibrary.simpleMessage(
      "كلمة المرور غير صحيحة.",
    ),
  };
}
