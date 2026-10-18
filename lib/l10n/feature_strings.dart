import 'package:flutter/widgets.dart';

// Static UI translations. Canonical academic identifiers remain unchanged.
String featureText(BuildContext context, String key) =>
    featureTextForLanguage(Localizations.localeOf(context).languageCode, key);

String featureTextForLanguage(String languageCode, String key) {
  final values = _featureCatalog[key];
  if (values == null) return key;
  return values[languageCode == 'ar'
      ? 0
      : languageCode == 'fr'
          ? 2
          : 1];
}

typedef FeatureLegalSection = ({String heading, String body});

List<FeatureLegalSection> featureLegalSections(
    BuildContext context, String policy, List<FeatureLegalSection> arabic) {
  final language = Localizations.localeOf(context).languageCode;
  if (language == 'ar') return arabic;
  return _legalSections['$policy/${language == 'fr' ? 'fr' : 'en'}']!;
}

const _featureCatalog = <String, List<String>>{
  "ابحث عن تخصصك, قم بادخال علاماتك واضطلع على معدلك": [
    "ابحث عن تخصصك, قم بادخال علاماتك واضطلع على معدلك",
    "Find your major, enter your grades and view your average",
    "Trouvez votre spécialité, saisissez vos notes et consultez votre moyenne"
  ],
  "مسح": ["مسح", "Clear", "Effacer"],
  "اختر كليتك وتخصصك للوصول السريع إلى حساب المعدل والمواد.": [
    "اختر كليتك وتخصصك للوصول السريع إلى حساب المعدل والمواد.",
    "Choose your faculty and major for quick access to grades and subjects.",
    "Choisissez votre faculté et votre spécialité pour accéder rapidement aux notes et aux matières."
  ],
  "الكليات": ["الكليات", "Faculties", "Facultés"],
  "لا توجد كليات متاحة حالياً": [
    "لا توجد كليات متاحة حالياً",
    "No faculties available yet",
    "Aucune faculté disponible pour le moment"
  ],
  "جامعي": ["جامعي", "University", "Universitaire"],
  "بياناتك الأكاديمية": [
    "بياناتك الأكاديمية",
    "Your academic details",
    "Vos informations universitaires"
  ],
  "ابدأ الكتابة لاختيار الكلية": [
    "ابدأ الكتابة لاختيار الكلية",
    "Start typing to choose a faculty",
    "Commencez à saisir pour choisir une faculté"
  ],
  "اختر الكلية أولاً": [
    "اختر الكلية أولاً",
    "Choose a faculty first",
    "Choisissez d’abord une faculté"
  ],
  "اختر القسم": [
    "اختر القسم",
    "Choose a department",
    "Choisissez un département"
  ],
  "اختر القسم أولاً": [
    "اختر القسم أولاً",
    "Choose a department first",
    "Choisissez d’abord un département"
  ],
  "اختر التخصص": ["اختر التخصص", "Choose a major", "Choisissez une spécialité"],
  "يُملأ تلقائيًا": [
    "يُملأ تلقائيًا",
    "Filled in automatically",
    "Renseigné automatiquement"
  ],
  "أضف مادة": ["أضف مادة", "Add a subject", "Ajouter une matière"],
  "حذف": ["حذف", "Delete", "Supprimer"],
  "المادة": ["المادة", "Subject", "Matière"],
  "لا توجد مسارات": ["لا توجد مسارات", "No tracks", "Aucun parcours"],
  "مسار واحد": ["مسار واحد", "One track", "Un parcours"],
  "عرض المسارات": ["عرض المسارات", "View tracks", "Voir les parcours"],
  "التخصصات الأكاديمية المتاحة": [
    "التخصصات الأكاديمية المتاحة",
    "Available academic majors",
    "Spécialités universitaires disponibles"
  ],
  "تخصص": ["تخصص", "Major", "Spécialité"],
  "مسار": ["مسار", "Track", "Parcours"],
  "مستوى": ["مستوى", "Level", "Niveau"],
  "لا توجد أقسام متاحة حاليًا": [
    "لا توجد أقسام متاحة حاليًا",
    "No departments available yet",
    "Aucun département disponible pour le moment"
  ],
  "لا توجد مسارات متاحة حاليًا": [
    "لا توجد مسارات متاحة حاليًا",
    "No tracks available yet",
    "Aucun parcours disponible pour le moment"
  ],
  "حفظ": ["حفظ", "Save", "Enregistrer"],
  "كشف النقاط": ["كشف النقاط", "Grade report", "Relevé de notes"],
  "الفصل 1": ["الفصل 1", "Semester 1", "Semestre 1"],
  "الفصل 2": ["الفصل 2", "Semester 2", "Semestre 2"],
  "مواد أخرى": ["مواد أخرى", "Other subjects", "Autres matières"],
  "إطفاء شاشة التلفاز": [
    "إطفاء شاشة التلفاز",
    "Turn off the television screen",
    "Éteindre l’écran du téléviseur"
  ],
  "تشغيل شاشة التلفاز": [
    "تشغيل شاشة التلفاز",
    "Turn on the television screen",
    "Allumer l’écran du téléviseur"
  ],
  "إطفاء الشاشة": ["إطفاء الشاشة", "Turn off the screen", "Éteindre l’écran"],
  "تشغيل الشاشة": ["تشغيل الشاشة", "Turn on the screen", "Allumer l’écran"],
  "قواعد المجتمع": [
    "قواعد المجتمع",
    "Community guidelines",
    "Règles de la communauté"
  ],
  "قواعد مجتمع UniSpace": [
    "قواعد مجتمع UniSpace",
    "UniSpace community guidelines",
    "Règles de la communauté UniSpace"
  ],
  "سياسة الخصوصية": [
    "سياسة الخصوصية",
    "Privacy policy",
    "Politique de confidentialité"
  ],
  "سياسة الخصوصية – UniSpace": [
    "سياسة الخصوصية – UniSpace",
    "Privacy policy – UniSpace",
    "Politique de confidentialité – UniSpace"
  ],
  "الإصدار 1.0 — نافذ من 18 سبتمبر 2026": [
    "الإصدار 1.0 — نافذ من 18 سبتمبر 2026",
    "Version 1.0 — effective 18 September 2026",
    "Version 1.0 — applicable à compter du 18 septembre 2026"
  ],
  "تأكيد طلب حذف الحساب": [
    "تأكيد طلب حذف الحساب",
    "Confirm account deletion request",
    "Confirmer la demande de suppression du compte"
  ],
  "إلغاء": ["إلغاء", "Cancel", "Annuler"],
  "تأكيد الطلب": ["تأكيد الطلب", "Confirm request", "Confirmer la demande"],
  "تم تسجيل الطلب": [
    "تم تسجيل الطلب",
    "Request submitted",
    "Demande enregistrée"
  ],
  "حسنًا": ["حسنًا", "OK", "D’accord"],
  "انتهت جلسة الدخول. سجّل الدخول مجددًا ثم أعد المحاولة.": [
    "انتهت جلسة الدخول. سجّل الدخول مجددًا ثم أعد المحاولة.",
    "Your session has expired. Sign in again and retry.",
    "Votre session a expiré. Reconnectez-vous puis réessayez."
  ],
  "تعذر تأكيد الطلب. أعد المحاولة.": [
    "تعذر تأكيد الطلب. أعد المحاولة.",
    "Could not confirm the request. Try again.",
    "Impossible de confirmer la demande. Réessayez."
  ],
  "تعذر تسجيل طلب الحذف الآن.": [
    "تعذر تسجيل طلب الحذف الآن.",
    "Could not submit the deletion request right now.",
    "Impossible d’enregistrer la demande de suppression pour le moment."
  ],
  "حذف الحساب والبيانات": [
    "حذف الحساب والبيانات",
    "Delete account and data",
    "Supprimer le compte et les données"
  ],
  "طلب حذف حساب UniSpace": [
    "طلب حذف حساب UniSpace",
    "Request deletion of your UniSpace account",
    "Demander la suppression de votre compte UniSpace"
  ],
  "ماذا يحدث بعد الطلب؟": [
    "ماذا يحدث بعد الطلب؟",
    "What happens after the request?",
    "Que se passe-t-il après la demande ?"
  ],
  "يُسجّل الطلب باسم الحساب الذي أنت مسجل الدخول إليه فقط.": [
    "يُسجّل الطلب باسم الحساب الذي أنت مسجل الدخول إليه فقط.",
    "The request is submitted only for the account you are signed in to.",
    "La demande concerne uniquement le compte auquel vous êtes connecté."
  ],
  "تُلغى جلسات الحساب ويُطلب منك تسجيل الخروج من التطبيق.": [
    "تُلغى جلسات الحساب ويُطلب منك تسجيل الخروج من التطبيق.",
    "Account sessions are revoked and you are asked to sign out of the app.",
    "Les sessions du compte sont révoquées et vous êtes invité à vous déconnecter de l’application."
  ],
  "نستهدف إكمال حذف بيانات الحساب التشغيلية خلال مدة لا تتجاوز 30 يومًا.": [
    "نستهدف إكمال حذف بيانات الحساب التشغيلية خلال مدة لا تتجاوز 30 يومًا.",
    "We aim to complete deletion of operational account data within 30 days.",
    "Nous visons à supprimer les données opérationnelles du compte dans un délai maximal de 30 jours."
  ],
  "البيانات المشتركة، مثل المحادثات مع مستخدمين آخرين، تُعالج بطريقة لا تكشف بياناتك ولا تفسد بيانات الطرف الآخر.":
      [
    "البيانات المشتركة، مثل المحادثات مع مستخدمين آخرين، تُعالج بطريقة لا تكشف بياناتك ولا تفسد بيانات الطرف الآخر.",
    "Shared data, such as conversations with other users, is handled without exposing your data or damaging the other person’s data.",
    "Les données partagées, comme les conversations, sont traitées sans exposer vos données ni altérer celles des autres utilisateurs."
  ],
  "الاحتفاظ المحدود": [
    "الاحتفاظ المحدود",
    "Limited retention",
    "Conservation limitée"
  ],
  "طلبات الدعم: حتى 180 يومًا بعد إغلاق الطلب عند الحاجة للمتابعة.": [
    "طلبات الدعم: حتى 180 يومًا بعد إغلاق الطلب عند الحاجة للمتابعة.",
    "Support requests: up to 180 days after closure when follow-up is needed.",
    "Demandes d’assistance : jusqu’à 180 jours après leur clôture si un suivi est nécessaire."
  ],
  "البلاغات وقرارات الإشراف: حتى 180 يومًا بعد الإغلاق أو آخر اعتراض.": [
    "البلاغات وقرارات الإشراف: حتى 180 يومًا بعد الإغلاق أو آخر اعتراض.",
    "Reports and moderation decisions: up to 180 days after closure or the latest appeal.",
    "Signalements et décisions de modération : jusqu’à 180 jours après leur clôture ou le dernier recours."
  ],
  "سجلات الأمان التشغيلية المعتادة: حتى 90 يومًا.": [
    "سجلات الأمان التشغيلية المعتادة: حتى 90 يومًا.",
    "Routine operational security logs: up to 90 days.",
    "Journaux de sécurité opérationnelle courants : jusqu’à 90 jours."
  ],
  "النزاع أو الالتزام القانوني: فقط للمدة اللازمة للسبب القانوني.": [
    "النزاع أو الالتزام القانوني: فقط للمدة اللازمة للسبب القانوني.",
    "Disputes or legal obligations: only as long as required for that legal reason.",
    "Litige ou obligation légale : uniquement pendant la durée nécessaire au motif juridique concerné."
  ],
  "قبل أن تطلب الحذف": [
    "قبل أن تطلب الحذف",
    "Before requesting deletion",
    "Avant de demander la suppression"
  ],
  "إذا أردت نسخة من بياناتك، اطلبها قبل حذف الحساب.": [
    "إذا أردت نسخة من بياناتك، اطلبها قبل حذف الحساب.",
    "If you want a copy of your data, request it before deleting your account.",
    "Si vous souhaitez une copie de vos données, demandez-la avant de supprimer votre compte."
  ],
  "لا ترسل كلمة المرور أو رموز المصادقة أو مفاتيح الاستعادة عبر البريد.": [
    "لا ترسل كلمة المرور أو رموز المصادقة أو مفاتيح الاستعادة عبر البريد.",
    "Do not email passwords, authentication codes or recovery keys.",
    "N’envoyez pas de mot de passe, de code d’authentification ni de clé de récupération par e-mail."
  ],
  "للمساعدة: unispace.0.1.0@gmail.com": [
    "للمساعدة: unispace.0.1.0@gmail.com",
    "For help: unispace.0.1.0@gmail.com",
    "Assistance : unispace.0.1.0@gmail.com"
  ],
  "أفهم أن هذا طلب لحذف الحساب والبيانات وليس مجرد تسجيل خروج.": [
    "أفهم أن هذا طلب لحذف الحساب والبيانات وليس مجرد تسجيل خروج.",
    "I understand this requests deletion of my account and data, not just signing out.",
    "Je comprends qu’il s’agit d’une demande de suppression du compte et des données, et non d’une simple déconnexion."
  ],
  "جارٍ تسجيل الطلب…": [
    "جارٍ تسجيل الطلب…",
    "Submitting request…",
    "Enregistrement de la demande…"
  ],
  "طلب حذف الحساب": [
    "طلب حذف الحساب",
    "Request account deletion",
    "Demander la suppression du compte"
  ],
  "هذه القواعد تكمل شروط الاستخدام وتحدد السلوك المتوقع داخل مساحات المجتمع في UniSpace. قراءة الصفحة وحدها لا تحدد خانة الموافقة في شاشة الدخول.":
      [
    "هذه القواعد تكمل شروط الاستخدام وتحدد السلوك المتوقع داخل مساحات المجتمع في UniSpace. قراءة الصفحة وحدها لا تحدد خانة الموافقة في شاشة الدخول.",
    "These guidelines supplement the terms of use and define the conduct expected in UniSpace community spaces. Reading this page alone does not select the consent checkbox on the sign-in screen.",
    "Ces règles complètent les conditions d’utilisation et définissent le comportement attendu dans les espaces communautaires de UniSpace. La seule lecture de cette page ne coche pas la case d’acceptation sur l’écran de connexion."
  ],
  "توضح هذه السياسة كيف يعالج UniSpace البيانات في النسخة الحالية من الخدمة، وما الخيارات المتاحة للمستخدم بشأنها. قراءة السياسة أو إغلاقها لا تحدد خانة الموافقة على شروط الاستخدام ولا تسجل موافقة مستقلة على معالجة اختيارية.":
      [
    "توضح هذه السياسة كيف يعالج UniSpace البيانات في النسخة الحالية من الخدمة، وما الخيارات المتاحة للمستخدم بشأنها. قراءة السياسة أو إغلاقها لا تحدد خانة الموافقة على شروط الاستخدام ولا تسجل موافقة مستقلة على معالجة اختيارية.",
    "This policy explains how UniSpace processes data in the current service and the choices available to users. Reading or closing the policy does not select the terms-of-use checkbox or record separate consent to optional processing.",
    "Cette politique explique comment UniSpace traite les données dans la version actuelle du service et les choix proposés aux utilisateurs. La lecture ou la fermeture de cette politique ne coche pas la case d’acceptation des conditions d’utilisation et n’enregistre aucun consentement distinct à un traitement facultatif."
  ],
  "سيتم تسجيل طلب الحذف وإلغاء جلسات الحساب. قد تستغرق إزالة البيانات من الأنظمة التشغيلية حتى 30 يومًا. لا يمكن استخدام هذا الطلب لحذف حساب شخص آخر.":
      [
    "سيتم تسجيل طلب الحذف وإلغاء جلسات الحساب. قد تستغرق إزالة البيانات من الأنظمة التشغيلية حتى 30 يومًا. لا يمكن استخدام هذا الطلب لحذف حساب شخص آخر.",
    "Your deletion request will be recorded and account sessions revoked. Removing data from operational systems may take up to 30 days. This request cannot delete someone else’s account.",
    "Votre demande de suppression sera enregistrée et les sessions du compte seront révoquées. La suppression des données des systèmes opérationnels peut prendre jusqu’à 30 jours. Cette demande ne permet pas de supprimer le compte d’une autre personne."
  ],
  "سُجل طلب حذف حسابك. سنعالج البيانات التشغيلية خلال مدة لا تتجاوز 30 يومًا، مع الاحتفاظ المحدود فقط عندما يوجد سبب قانوني أو أمني مشروع.":
      [
    "سُجل طلب حذف حسابك. سنعالج البيانات التشغيلية خلال مدة لا تتجاوز 30 يومًا، مع الاحتفاظ المحدود فقط عندما يوجد سبب قانوني أو أمني مشروع.",
    "Your account deletion request has been recorded. We will process operational data within 30 days, with limited retention only for legitimate legal or security reasons.",
    "Votre demande de suppression du compte a été enregistrée. Nous traiterons les données opérationnelles dans un délai maximal de 30 jours, avec une conservation limitée uniquement pour des motifs juridiques ou de sécurité légitimes."
  ],
  "يمكنك طلب حذف حسابك والبيانات المرتبطة به من الأنظمة التي نديرها. هذا ليس تعطيلًا مؤقتًا للحساب.":
      [
    "يمكنك طلب حذف حسابك والبيانات المرتبطة به من الأنظمة التي نديرها. هذا ليس تعطيلًا مؤقتًا للحساب.",
    "You can request deletion of your account and associated data from the systems we operate. This is not temporary account deactivation.",
    "Vous pouvez demander la suppression de votre compte et des données associées dans les systèmes que nous gérons. Il ne s’agit pas d’une désactivation temporaire du compte."
  ],
  "هذه الواجهة تسجل طلب الحذف على الخادم. إكمال إزالة جميع البيانات المشتركة والنسخ لدى مزودي الخدمة يخضع لعملية الحذف والاحتفاظ المعلنة.":
      [
    "هذه الواجهة تسجل طلب الحذف على الخادم. إكمال إزالة جميع البيانات المشتركة والنسخ لدى مزودي الخدمة يخضع لعملية الحذف والاحتفاظ المعلنة.",
    "This screen records your deletion request on the server. Completing removal of shared data and copies held by service providers follows the published deletion and retention process.",
    "Cet écran enregistre votre demande de suppression sur le serveur. La suppression complète des données partagées et des copies détenues par les prestataires suit la procédure de suppression et de conservation annoncée."
  ],
  "Saved ✅": ["تم الحفظ ✅", "Saved ✅", "Enregistré ✅"],
  "Cleared ✅": ["تم المسح ✅", "Cleared ✅", "Effacé ✅"],
  "Deleted": ["تم الحذف", "Deleted", "Supprimé"],
  "UNDO": ["تراجع", "UNDO", "ANNULER"],
  "Succeeded": ["ناجح", "Succeeded", "Admis"],
  "Failed": ["راسب", "Failed", "Non admis"],
  "Succeed": ["ناجح", "Succeed", "Admis"],
  "Saved": ["تم الحفظ", "Saved", "Enregistré"],
  "COEF": ["المعامل", "COEF", "COEF"],
  "CRED": ["الرصيد", "CRED", "CRÉD"],
  "Coef": ["المعامل", "Coef", "Coef"],
  "Cred": ["الرصيد", "Cred", "Créd"],
  "TD": ["أعمال موجهة", "TD", "TD"],
  "TP": ["أعمال تطبيقية", "TP", "TP"],
  "EXAM": ["امتحان", "EXAM", "EXAMEN"],
  "W.TD": ["وزن الأعمال الموجهة", "W.TD", "Poids TD"],
  "W.TP": ["وزن الأعمال التطبيقية", "W.TP", "Poids TP"],
  "W.EX": ["وزن الامتحان", "W.EX", "Poids examen"],
  "W. TD": ["وزن الأعمال الموجهة", "W. TD", "Poids TD"],
  "W. TP": ["وزن الأعمال التطبيقية", "W. TP", "Poids TP"],
  "W. EXAM": ["وزن الامتحان", "W. EXAM", "Poids examen"],
  "OK": ["حسنًا", "OK", "OK"],
  "Moy:        ": ["المعدل:        ", "Average:        ", "Moy. :        "],
  "S1 Résumé": ["ملخص الفصل 1", "Semester 1 summary", "Résumé S1"],
  "S1 Moyenne": ["معدل الفصل 1", "Semester 1 average", "Moyenne S1"],
  "S1 Credits": ["أرصدة الفصل 1", "Semester 1 credits", "Crédits S1"],
  "S2 Résumé": ["ملخص الفصل 2", "Semester 2 summary", "Résumé S2"],
  "S2 Moyenne": ["معدل الفصل 2", "Semester 2 average", "Moyenne S2"],
  "S2 Credits": ["أرصدة الفصل 2", "Semester 2 credits", "Crédits S2"],
  "Résumé Annual": ["الملخص السنوي", "Annual summary", "Résumé annuel"],
  "Année": ["السنة", "Year", "Année"],
  "Total Credits": ["مجموع الأرصدة", "Total Credits", "Total des crédits"],
  "Résultat:": ["النتيجة:", "Result:", "Résultat :"],
  "✨u Succeeded✨": ["✨ناجح✨", "✨Passed✨", "✨Admis✨"],
  "u Failed ❌": ["راسب ❌", "Failed ❌", "Non admis ❌"],
  "Decision :": ["القرار:", "Decision :", "Décision :"],
  "Résultat": ["النتيجة", "Result", "Résultat"],
  "S1 Modules": ["مواد الفصل 1", "Semester 1 subjects", "Matières S1"],
  "S2 Modules": ["مواد الفصل 2", "Semester 2 subjects", "Matières S2"],
  "SUCCEED": ["ناجح", "SUCCEED", "ADMIS"],
  "FAILED": ["راسب", "FAILED", "NON ADMIS"],
  "majorCount": ["{count} تخصصات", "{count} majors", "{count} spécialités"],
  "trackCount": ["{count} مسارات", "{count} tracks", "{count} parcours"],
  "Average": ["المعدل", "Average", "Moyenne"],
  "Admitted (regular session)": [
    "ناجح (الدورة العادية)",
    "Admitted (regular session)",
    "Admis (session ordinaire)"
  ],
  "Not admitted": ["غير مقبول", "Not admitted", "Non admis"],
  "UniSpace student": [
    "طالب UniSpace",
    "UniSpace student",
    "Étudiant UniSpace"
  ],
  "UniSpace grade report": [
    "كشف نقاط UniSpace",
    "UniSpace grade report",
    "Relevé de notes UniSpace"
  ],
  "Annual grade report": [
    "كشف النقاط السنوي",
    "Annual grade report",
    "Relevé de notes annuel"
  ],
  "GRADE REPORT": ["كشف النقاط", "GRADE REPORT", "RELEVÉ DE NOTES"],
  "Semester 1": ["الفصل 1", "Semester 1", "Semestre 1"],
  "Semester 2": ["الفصل 2", "Semester 2", "Semestre 2"],
  "University platform": [
    "منصة جامعية",
    "University platform",
    "Plateforme universitaire"
  ],
  "Faculty": ["الكلية", "Faculty", "Faculté"],
  "Department": ["القسم", "Department", "Département"],
  "Major": ["التخصص", "Major", "Spécialité"],
  "Not specified": ["غير محدد", "Not specified", "Non renseigné"],
  "Academic year": ["السنة الجامعية", "Academic year", "Année universitaire"],
  "Last name": ["اللقب", "Last name", "Nom"],
  "First name": ["الاسم", "First name", "Prénom"],
  "ID": ["المعرّف", "ID", "Identifiant"],
  "Level": ["المستوى", "Level", "Niveau"],
  "Email": ["البريد الإلكتروني", "Email", "E-mail"],
  "Degree": ["الدرجة", "Degree", "Diplôme"],
  "Teaching unit (UE)": [
    "الوحدة التعليمية",
    "Teaching unit (UE)",
    "Unité d’enseignement (UE)"
  ],
  "Subject(s) of the teaching unit": [
    "مواد الوحدة التعليمية",
    "Subject(s) of the teaching unit",
    "Matières de l’unité d’enseignement"
  ],
  "Type": ["النوع", "Type", "Type"],
  "UE code": ["رمز الوحدة", "UE code", "Code UE"],
  "Credits": ["الأرصدة", "Credits", "Crédits"],
  "Avg": ["المعدل", "Avg", "Moy."],
  "Earned": ["المكتسب", "Earned", "Acquis"],
  "Sess": ["الدورة", "Sess", "Session"],
  "Title": ["العنوان", "Title", "Intitulé"],
  "N = regular session    R = resit": [
    "N = الدورة العادية    R = الاستدراك",
    "N = regular session    R = resit",
    "N = session ordinaire    R = rattrapage"
  ],
  "Annual average": ["المعدل السنوي", "Annual average", "Moyenne annuelle"],
  "Decision": ["القرار", "Decision", "Décision"],
  "Credits earned this year": [
    "الأرصدة المكتسبة هذه السنة",
    "Credits earned this year",
    "Crédits acquis cette année"
  ],
  "Generated on": ["أُنشئ في", "Generated on", "Généré le"],
  "Document ID": ["معرّف الوثيقة", "Document ID", "Identifiant du document"],
  "Page": ["الصفحة", "Page", "Page"],
  "Generated by UniSpace. This document has no official administrative value.":
      [
    "أُنشئ بواسطة UniSpace. هذه الوثيقة لا تحمل أي قيمة إدارية رسمية.",
    "Generated by UniSpace. This document has no official administrative value.",
    "Généré par UniSpace. Ce document n’a aucune valeur administrative officielle."
  ],
  "Exam reminders": [
    "تذكيرات الامتحانات",
    "Exam reminders",
    "Rappels d’examens"
  ],
  "Notifications for upcoming exams": [
    "إشعارات الامتحانات القادمة",
    "Notifications for upcoming exams",
    "Notifications pour les examens à venir"
  ],
  "Saved locally. Sync failed.": [
    "تم الحفظ محليًا. تعذرت المزامنة.",
    "Saved locally. Sync failed.",
    "Enregistré localement. La synchronisation a échoué."
  ],
};

const _legalSections = <String, List<FeatureLegalSection>>{
  'community/en': [
    (
      heading: "1. Purpose and scope",
      body:
          "UniSpace community guidelines aim to keep posts, comments, messages, groups and other interaction spaces useful and safe for students. They apply to content and conduct within the social features actually available.\n\nThese guidelines supplement, rather than replace, the terms of use. They do not make UniSpace a university or an official body. Disagreement or polite criticism is not a violation simply because it is upsetting or disputed."
    ),
    (
      heading: "2. Respect and prevention of harassment",
      body:
          "Threats, bullying, harassment, repeated insults and targeting someone to humiliate or intimidate them or encourage others to attack them are prohibited. Hate speech or discrimination against people or groups based on legally protected characteristics is also prohibited.\n\nIdeas, course materials and university decisions may be debated firmly or critically, without turning the discussion into personal abuse or a harassment campaign."
    ),
    (
      heading: "3. Safety and highly sensitive content",
      body:
          "Content that exploits or endangers minors, sexually explicit content, serious threats, glorification of violence, and encouragement of self-harm or dangerous activities are prohibited. Shocking content intended to harm or intimidate is also prohibited.\n\nSensitive educational or awareness content is assessed according to its context, necessity and presentation. An educational purpose does not automatically exempt it from safety rules."
    ),
    (
      heading: "4. Illegal activity and fraud",
      body:
          "Using UniSpace to facilitate illegal activity, fraud, blackmail, falsified transactions or documents, or deceptive requests for users’ confidential information is prohibited.\n\nOffers or links intended to deceive students or take their accounts, money or personal information are not allowed."
    ),
    (
      heading: "5. Privacy and personal data",
      body:
          "Do not publish someone’s address, phone number, documents, private photos or sensitive information without an appropriate right or permission. Do not use information obtained in a private conversation to embarrass or endanger the other person.\n\nWhen reporting a violation, share only the information needed to understand the report and avoid publishing it publicly."
    ),
    (
      heading: "6. Impersonation and misleading information",
      body:
          "Impersonating a student, teacher, university, administration or another party, or creating an account that falsely implies an official relationship, is prohibited. Forged badges, documents or fundamental claims intended to deceive others are also prohibited.\n\nOpinions or unverified information may be shared when clearly presented as such. Deliberately misleading claims that may cause harm can be restricted or removed."
    ),
    (
      heading: "7. Copyright and academic integrity",
      body:
          "Do not upload a book, lesson, exam or file you have no right to share, or claim another person’s work as your own. Legitimate discussion, summaries and study assistance are allowed while respecting creators’ rights and the educational institution’s rules.\n\nUsing the platform to falsify academic work, sell fake results or documents, or facilitate organized cheating is prohibited."
    ),
    (
      heading: "8. Unwanted messages and contact",
      body:
          "Respect another person’s wish to stop communication. Repeated unwanted messages, pursuing a user through multiple accounts after being asked to stop, and using mentions or groups to bother specific people are prohibited.\n\nDirect communication does not grant a right to publish a private conversation outside its purpose without a legitimate basis."
    ),
    (
      heading: "9. Spam, advertising and commercial exploitation",
      body:
          "Spam, misleading links, disruptive automated accounts and repeated out-of-context promotion are prohibited. Commercial or sponsored content must be clearly identified when permitted.\n\nBuying engagement or exploiting points, rewards or any future feature to encourage prohibited content or disruptive behavior is not allowed."
    ),
    (
      heading: "10. Reporting and blocking",
      body:
          "Tools are available to report certain types of content and accounts, and blocked accounts can be managed in privacy settings. The location of the report or block button may vary by content type and navigation path.\n\nIf the appropriate reporting option is unavailable, safety or violation reports can be sent to unispace.0.1.0@gmail.com with a link or content identifier and only the information needed to understand the report. Do not send passwords or verification codes."
    ),
    (
      heading: "11. Moderation, measures and appeals",
      body:
          "Moderation measures may include hiding or deleting content, restricting a feature or suspending an account, depending on the type, severity and recurrence of a violation. The number of reports alone does not establish wrongdoing; available context is reviewed before action where possible.\n\nA significant decision can be submitted for review through support, identifying the account or content and the decision being appealed. These guidelines do not set a fixed response deadline. Requests are handled according to priority, severity and available resources."
    ),
    (
      heading: "12. Application, changes and contact",
      body:
          "Reading this page does not select the agreement checkbox on the login screen. “I agree to the terms of use” remains the required choice on that screen; there is no separate second checkbox for community guidelines.\n\nThese guidelines may be updated when community features or safety tools change, with the new version’s date clearly displayed. For questions, reports or appeals: unispace.0.1.0@gmail.com."
    ),
  ],
  'community/fr': [
    (
      heading: "1. Objet et portée",
      body:
          "Les règles de la communauté UniSpace visent à rendre les publications, commentaires, messages, groupes et autres espaces d’échange utiles et sûrs pour les étudiants. Elles s’appliquent aux contenus et aux comportements dans les fonctions sociales effectivement disponibles.\n\nCes règles complètent les conditions d’utilisation sans les remplacer et ne confèrent à UniSpace aucun statut d’université ou d’organisme officiel. Un désaccord ou une critique courtoise ne constitue pas une infraction au seul motif qu’il dérange ou fait débat."
    ),
    (
      heading: "2. Respect et prévention du harcèlement",
      body:
          "Les menaces, l’intimidation, le harcèlement, les insultes répétées et le ciblage d’une personne pour l’humilier, l’effrayer ou inciter autrui à l’attaquer sont interdits. Les discours haineux ou discriminatoires visant des personnes ou des groupes sur la base de caractéristiques protégées par la loi sont également interdits.\n\nLes idées, les supports de cours et les décisions universitaires peuvent faire l’objet de débats fermes ou critiques, sans que ceux-ci deviennent des attaques personnelles ou des campagnes de harcèlement."
    ),
    (
      heading: "3. Sécurité et contenus très sensibles",
      body:
          "Les contenus qui exploitent ou mettent en danger des mineurs, les contenus sexuellement explicites, les menaces sérieuses, la glorification de la violence et l’encouragement à l’automutilation ou aux activités dangereuses sont interdits. Les contenus choquants destinés à nuire ou à intimider sont également interdits.\n\nLes contenus sensibles à visée pédagogique ou de sensibilisation sont évalués selon leur contexte, leur nécessité et leur présentation. Leur vocation éducative ne les dispense pas automatiquement des règles de sécurité."
    ),
    (
      heading: "4. Activités illégales et fraude",
      body:
          "Il est interdit d’utiliser UniSpace pour faciliter une activité illégale, une fraude, un chantage, la falsification de transactions ou de documents, ou pour demander de manière trompeuse des informations confidentielles aux utilisateurs.\n\nLes offres ou liens visant à tromper les étudiants ou à s’emparer de leurs comptes, de leur argent ou de leurs données personnelles sont interdits."
    ),
    (
      heading: "5. Vie privée et données personnelles",
      body:
          "Ne publiez pas l’adresse, le numéro de téléphone, les documents, les photos privées ou les données sensibles d’une personne sans droit ou autorisation appropriés. N’utilisez pas des informations issues d’une conversation privée pour embarrasser ou mettre en danger votre interlocuteur.\n\nLors d’un signalement, ne partagez que les données nécessaires à sa compréhension et évitez de les publier publiquement."
    ),
    (
      heading: "6. Usurpation d’identité et informations trompeuses",
      body:
          "Il est interdit d’usurper l’identité d’un étudiant, d’un enseignant, d’une université, d’une administration ou d’un tiers, ou de créer un compte suggérant une affiliation officielle inexistante. La falsification de badges, de documents ou d’affirmations essentielles visant à tromper autrui est également interdite.\n\nLes opinions et les informations non vérifiées peuvent être partagées si elles sont clairement présentées comme telles. Les affirmations volontairement trompeuses susceptibles de causer un préjudice peuvent être restreintes ou supprimées."
    ),
    (
      heading: "7. Droit d’auteur et intégrité universitaire",
      body:
          "Ne téléversez pas un livre, un cours, un examen ou un fichier que vous n’avez pas le droit de partager et ne vous attribuez pas le travail d’autrui. Les échanges, résumés et aides aux études légitimes sont autorisés dans le respect des droits des auteurs et des règles de l’établissement.\n\nIl est interdit d’utiliser la plateforme pour falsifier des travaux universitaires, vendre de faux résultats ou documents, ou faciliter une tricherie organisée."
    ),
    (
      heading: "8. Messages et contacts indésirables",
      body:
          "Respectez la volonté d’autrui de mettre fin aux échanges. Les messages indésirables répétés, le fait de poursuivre un utilisateur au moyen de plusieurs comptes après sa demande d’arrêt, et l’utilisation des mentions ou des groupes pour importuner des personnes précises sont interdits.\n\nUn échange individuel ne donne pas le droit de publier une conversation privée en dehors de sa finalité sans fondement légitime."
    ),
    (
      heading: "9. Spam, publicité et exploitation commerciale",
      body:
          "Le spam, les liens trompeurs, les comptes automatisés perturbateurs et la promotion répétée hors contexte sont interdits. Les contenus commerciaux ou sponsorisés doivent être clairement identifiés lorsqu’ils sont autorisés.\n\nIl est interdit d’acheter des interactions ou d’exploiter les points, récompenses ou toute fonctionnalité future pour encourager des contenus interdits ou des comportements perturbateurs."
    ),
    (
      heading: "10. Signalement et blocage",
      body:
          "Des outils permettent de signaler certains contenus et comptes, et les comptes bloqués peuvent être gérés dans les paramètres de confidentialité. L’emplacement des boutons de signalement et de blocage peut varier selon le contenu et le parcours utilisé.\n\nSi l’option de signalement adaptée n’apparaît pas, vous pouvez écrire à unispace.0.1.0@gmail.com avec un lien ou un identifiant du contenu et les seules informations nécessaires à la compréhension du signalement. N’envoyez ni mot de passe ni code de vérification."
    ),
    (
      heading: "11. Modération, mesures et recours",
      body:
          "Les mesures de modération peuvent comprendre le masquage ou la suppression d’un contenu, la restriction d’une fonction ou la suspension d’un compte, selon la nature, la gravité et la répétition de l’infraction. Le nombre de signalements ne suffit pas à établir une faute ; le contexte disponible est examiné avant toute mesure, dans la mesure du possible.\n\nUne décision importante peut faire l’objet d’une demande de réexamen auprès de l’assistance, en précisant le compte ou le contenu et la décision contestée. Ces règles ne fixent aucun délai de réponse garanti. Les demandes sont traitées selon leur priorité, leur gravité et les ressources disponibles."
    ),
    (
      heading: "12. Application, modifications et contact",
      body:
          "La lecture de cette page ne coche pas la case d’acceptation sur l’écran de connexion. « J’accepte les conditions d’utilisation » reste le choix requis sur cet écran ; il n’existe pas de deuxième case distincte pour les règles de la communauté.\n\nCes règles peuvent évoluer avec les fonctionnalités communautaires ou les outils de sécurité, en affichant clairement la date de la nouvelle version. Questions, signalements et recours : unispace.0.1.0@gmail.com."
    ),
  ],
  'privacy/en': [
    (
      heading: "1. Who we are and how to contact us",
      body:
          "UniSpace is an independent digital project serving the university community in Algeria, not an official university or ministry service. In this policy, the project and its operators are referred to as “UniSpace”. The contact address for privacy, support and rights requests is unispace.0.1.0@gmail.com. If the operator changes or a legal entity is established for the service, this policy and contact information will be updated accordingly."
    ),
    (
      heading: "2. Data UniSpace may process",
      body:
          "Depending on the features used, data may include email, account identifier and sign-in provider; name, username, profile photo and cover; date of birth, gender, faculty, department, major, level and optional profile fields; posts, comments, reactions, follows, blocks and saved items; messages, attachments, read and typing data; notification tokens and session/device data needed for security; and support requests, reports and associated technical data. A field’s presence in the app does not mean every user must complete it."
    ),
    (
      heading: "3. Local academic data",
      body:
          "The grade-calculator flows we reviewed save grades and calculation data locally on the device using local storage. This description does not extend to all UniSpace features: profiles, social content, messaging and notifications rely on cloud services when using the connected version."
    ),
    (
      heading: "4. Why we use data",
      body:
          "We use data to the extent related to the feature requested by the user: creating accounts and signing in, displaying profiles, operating community features and messaging, saving content and attachments, sending notifications, protecting accounts and managing sessions, applying privacy settings, handling reports and providing support. We do not use private messages, grades or support requests to train an AI model. Any future optional processing for a different purpose requires appropriate explanation and choice before activation."
    ),
    (
      heading: "5. Firebase and supporting services",
      body:
          "UniSpace uses Google Firebase services, including Authentication, Firestore, Storage, Cloud Functions and Cloud Messaging, depending on the feature. Some project resources are configured in European regions, but processing locations vary by Firebase service; we therefore do not claim that all data remains in Europe. Messages sent to the support email also pass through the email service used to receive them."
    ),
    (
      heading: "6. Data sharing",
      body:
          "Using technical infrastructure providers does not mean selling users’ data. Data may be processed by service providers needed to operate a feature, according to its settings. We may disclose information where required by a binding legal obligation or to protect service security and rights within appropriate limits. We do not provide advertisers with raw personal student lists or sell personal data as a product."
    ),
    (
      heading: "7. Data security",
      body:
          "We use technical and organizational measures intended to limit unauthorized access or use, including account authentication, access rules and session safeguards. No system can be described as 100% secure, so we do not make an absolute promise that all data is protected from every risk. Do not send passwords or verification codes to support."
    ),
    (
      heading: "8. Retention and deletion",
      body:
          "Users can request deletion of their account and associated data in the app. An external page is also available at https://fachub-c631c.web.app/delete-account, or support can be contacted if the account is inaccessible. Confirming the request in the app stops account access and starts a server process to delete or anonymize associated data. We aim to complete deletion of operational data handled by UniSpace under its current architecture within 30 days of the request. Deletion is not merely account deactivation.\n\nWe may retain the deletion-request record for up to 30 days after completion, necessary security logs for up to 90 days, and support requests, reports and moderation decisions for up to 180 days according to legitimate operational needs. For a specific dispute or legal obligation, additional retention is limited to the data and duration needed for that reason.\n\nFor data shared with other users, such as conversations and replies, account data may be removed or replaced with an unidentified identity while preserving other parties’ content that does not belong to the deleted account. Technical copies held by service providers may take a further limited time to disappear under their systems."
    ),
    (
      heading: "9. Age and eligibility data",
      body:
          "Accounts and community participation are intended for people aged 18 or over. Date of birth may be used to apply eligibility rules or for profile features chosen by the user. The technical ability to create an account does not mean UniSpace independently verifies age in every case. If applicable law requires additional eligibility or consent for a particular action, those requirements must be met before that action."
    ),
    (
      heading: "10. User rights and contact",
      body:
          "Users may contact us to request information about their data, correct what can be corrected, object, request deletion or exercise another right available under applicable law. We may require proportionate verification to protect accounts from requests made by others. Contact unispace.0.1.0@gmail.com. Passwords, login codes and complete sensitive documents should not be emailed without a secure and justified process."
    ),
    (
      heading: "11. Policy changes",
      body:
          "This policy may change when UniSpace features, data processing or applicable requirements change. For a material change, we will clearly display an updated version with the appropriate update or effective date. Acceptance of the terms of use does not constitute advance consent to new optional processing such as marketing or AI training."
    ),
  ],
  'privacy/fr': [
    (
      heading: "1. Qui sommes-nous et comment nous contacter ?",
      body:
          "UniSpace est un projet numérique indépendant au service de la communauté universitaire en Algérie, et non un service officiel d’une université ou d’un ministère. Dans cette politique, le projet et ses exploitants sont désignés par « UniSpace ». L’adresse de contact pour la confidentialité, l’assistance et l’exercice des droits est unispace.0.1.0@gmail.com. Si l’exploitant change ou si une entité juridique est créée pour le service, cette politique et les coordonnées seront mises à jour en conséquence."
    ),
    (
      heading: "2. Données susceptibles d’être traitées",
      body:
          "Selon les fonctionnalités utilisées, les données peuvent inclure l’e-mail, l’identifiant du compte et le fournisseur de connexion ; le nom, le nom d’utilisateur, la photo et la couverture ; la date de naissance, le genre, la faculté, le département, la spécialité, le niveau et les champs facultatifs du profil ; les publications, commentaires, réactions, abonnements, blocages et éléments enregistrés ; les messages, pièces jointes et informations de lecture ou de saisie ; les jetons de notification et les données de session et d’appareil nécessaires à la sécurité ; ainsi que les demandes d’assistance, signalements et données techniques associées. La présence d’un champ ne le rend pas obligatoire pour chaque utilisateur."
    ),
    (
      heading: "3. Données universitaires locales",
      body:
          "Les parcours du calculateur de moyenne que nous avons examinés enregistrent les notes et les données de calcul localement sur l’appareil. Cette description ne s’étend pas à toutes les fonctionnalités d’UniSpace : les profils, contenus sociaux, messages et notifications reposent sur des services cloud dans la version connectée."
    ),
    (
      heading: "4. Pourquoi nous utilisons les données",
      body:
          "Nous utilisons les données dans la mesure nécessaire à la fonctionnalité demandée : création de compte et connexion, affichage du profil, communauté et messagerie, enregistrement des contenus et pièces jointes, notifications, protection des comptes et gestion des sessions, application des paramètres de confidentialité, traitement des signalements et assistance. Nous n’utilisons pas les messages privés, les notes ou les demandes d’assistance pour entraîner un modèle d’intelligence artificielle. Tout traitement facultatif futur poursuivant une autre finalité nécessite une explication et un choix appropriés avant son activation."
    ),
    (
      heading: "5. Firebase et services utilisés",
      body:
          "UniSpace utilise des services Google Firebase, notamment Authentication, Firestore, Storage, Cloud Functions et Cloud Messaging selon les fonctionnalités. Certaines ressources du projet sont configurées dans des régions européennes, mais le lieu de traitement varie selon le service Firebase ; nous n’affirmons donc pas que toutes les données restent en Europe. Les messages adressés à l’assistance passent également par le service de messagerie utilisé pour les recevoir."
    ),
    (
      heading: "6. Partage des données",
      body:
          "Le recours à des prestataires d’infrastructure technique ne signifie pas que les données des utilisateurs sont vendues. Les données peuvent être traitées par les prestataires nécessaires au fonctionnement d’une fonctionnalité, selon ses paramètres. Nous pouvons divulguer des informations lorsqu’une obligation légale contraignante l’exige ou pour protéger la sécurité du service et les droits dans des limites appropriées. Nous ne fournissons pas aux annonceurs de listes brutes de données personnelles d’étudiants et ne vendons pas les données personnelles comme un produit."
    ),
    (
      heading: "7. Sécurité des données",
      body:
          "Nous utilisons des mesures techniques et organisationnelles visant à limiter les accès et usages non autorisés, notamment l’authentification, les règles d’accès et la protection des sessions. Aucun système ne peut être qualifié de sûr à 100 % ; nous ne garantissons donc pas une protection absolue de toutes les données contre tous les risques. N’envoyez ni mot de passe ni code de vérification à l’assistance."
    ),
    (
      heading: "8. Conservation et suppression",
      body:
          "L’utilisateur peut demander la suppression de son compte et des données associées depuis l’application. Une page externe est également disponible à l’adresse https://fachub-c631c.web.app/delete-account ; l’assistance peut être contactée si le compte est inaccessible. La confirmation de la demande dans l’application interrompt l’accès au compte et lance un processus serveur de suppression ou d’anonymisation des données associées. Nous visons à supprimer les données opérationnelles traitées par UniSpace selon son architecture actuelle dans un délai maximal de 30 jours après la demande. La suppression n’est pas une simple désactivation.\n\nNous pouvons conserver le dossier de demande de suppression jusqu’à 30 jours après son achèvement, les journaux de sécurité nécessaires jusqu’à 90 jours, et les demandes d’assistance, signalements et décisions de modération jusqu’à 180 jours selon les besoins opérationnels légitimes. En cas de litige ou d’obligation légale spécifique, toute conservation supplémentaire est limitée aux données et à la durée nécessaires à ce motif.\n\nPour les données partagées, notamment les conversations et réponses, les données du compte peuvent être supprimées ou remplacées par une identité non identifiable, tout en préservant les contenus des autres parties qui n’appartiennent pas au compte supprimé. Les copies techniques chez les prestataires peuvent subsister pendant une durée supplémentaire limitée selon leurs systèmes."
    ),
    (
      heading: "9. Âge et données d’éligibilité",
      body:
          "Les comptes et la participation à la communauté sont destinés aux personnes de 18 ans ou plus. La date de naissance peut servir à appliquer les règles d’éligibilité ou aux fonctions de profil choisies par l’utilisateur. La possibilité technique de créer un compte ne signifie pas qu’UniSpace vérifie indépendamment l’âge dans chaque cas. Si le droit applicable exige une capacité ou un consentement supplémentaire pour une action, ces conditions doivent être remplies avant celle-ci."
    ),
    (
      heading: "10. Droits des utilisateurs et contact",
      body:
          "Les utilisateurs peuvent nous contacter pour obtenir des informations sur leurs données, demander leur rectification lorsque cela est possible, s’opposer à un traitement, demander une suppression ou exercer un autre droit prévu par le droit applicable. Une vérification proportionnée peut être demandée afin de protéger le compte contre les demandes de tiers. Contact : unispace.0.1.0@gmail.com. Les mots de passe, codes de connexion et documents sensibles complets ne doivent pas être envoyés par e-mail sans procédure sécurisée et justifiée."
    ),
    (
      heading: "11. Modifications de la politique",
      body:
          "Cette politique peut évoluer lorsque les fonctionnalités d’UniSpace, les traitements ou les exigences applicables changent. En cas de modification importante, une version actualisée sera clairement affichée avec la date de mise à jour ou d’entrée en vigueur appropriée. L’acceptation des conditions d’utilisation ne vaut pas consentement préalable à de nouveaux traitements facultatifs, comme le marketing ou l’entraînement de modèles d’intelligence artificielle."
    ),
  ],
};
