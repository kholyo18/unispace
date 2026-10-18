import 'package:flutter/widgets.dart';

// Static UI text only. Stored messages and action identifiers are not translated.
String shellText(BuildContext context, String key) =>
    ShellStrings.text(Localizations.localeOf(context).languageCode, key);

String shellFormat(BuildContext context, String key, List<Object?> values) =>
    ShellStrings.format(
        Localizations.localeOf(context).languageCode, key, values);

/// Localize known service failures only at a visible UI boundary.
String serviceErrorText(BuildContext context, Object error) =>
    ShellStrings.error(Localizations.localeOf(context).languageCode, error);

abstract final class ShellStrings {
  static String error(String languageCode, Object error) {
    final raw = error is StateError
        ? error.message
        : error is ArgumentError
            ? error.message?.toString() ?? error.toString()
            : error.toString();
    final size = RegExp(r'^الملف فارغ أو يتجاوز الحد المسموح: (\d+) ميغابايت$')
        .firstMatch(raw);
    if (size != null) {
      return format(languageCode,
          'الملف فارغ أو يتجاوز الحد المسموح: {0} ميغابايت', [size[1]]);
    }
    return _messages.containsKey(raw)
        ? text(languageCode, raw)
        : error.toString();
  }

  static String text(String languageCode, String key) {
    final entry = _messages[key];
    if (entry == null) return key;
    return entry[languageCode == 'ar'
        ? 0
        : languageCode == 'fr'
            ? 2
            : 1];
  }

  static String format(String languageCode, String key, List<Object?> values) {
    final template = text(languageCode, key);
    return template.replaceAllMapped(RegExp(r'\{(\d+)\}'), (match) {
      final index = int.parse(match[1]!);
      return index < values.length ? values[index].toString() : match[0]!;
    });
  }

  static const _messages = <String, List<String>>{
"سماع التسجيل": ["سماع التسجيل","Listen to recording","Écouter l’enregistrement"],
"استمع للتسجيل أو اضغط المايك لمتابعته": ["استمع للتسجيل أو اضغط المايك لمتابعته","Listen, or tap the microphone to continue recording","Écoutez ou touchez le micro pour continuer"],
"أفلت للمراجعة · يسار للإلغاء · أعلى للقفل": ["أفلت للمراجعة · يسار للإلغاء · أعلى للقفل","Release to review · left to cancel · up to lock","Relâchez pour écouter · gauche pour annuler · haut pour verrouiller"],
"التسجيل قصير جدًا. تابع التسجيل قبل الإرسال.": ["التسجيل قصير جدًا. تابع التسجيل قبل الإرسال.","Recording too short. Continue before sending.","Enregistrement trop court. Continuez avant l’envoi."],
"تعذر تنفيذ العملية الصوتية. حاول مجددًا.": ["تعذر تنفيذ العملية الصوتية. حاول مجددًا.","Audio operation failed. Please try again.","L’opération audio a échoué. Réessayez."],
"تعذر بدء التسجيل. حاول مجددًا.": ["تعذر بدء التسجيل. حاول مجددًا.","Could not start recording. Please try again.","Impossible de démarrer l’enregistrement. Réessayez."],
"وصل التسجيل للحد الأقصى. استمع إليه أو أرسله.": ["وصل التسجيل للحد الأقصى. استمع إليه أو أرسله.","Recording limit reached. Listen or send.","Durée maximale atteinte. Écoutez ou envoyez."],
    "انتهت الجلسة. سجّل الدخول ثم أعد المحاولة.": ["انتهت الجلسة. سجّل الدخول ثم أعد المحاولة.", "Session expired. Sign in and try again.", "Session expirée. Reconnectez-vous et réessayez."],
    "تعذر رفع المرفق": ["تعذر رفع المرفق", "Attachment upload failed", "Échec de l’envoi du fichier"],
    'رسائل جديدة': ['رسائل جديدة', 'New messages', 'Nouveaux messages'],
    "تم إرسال طلب المراسلة": ["تم إرسال طلب المراسلة", "Message request sent", "Demande de message envoyée"],
    "تعذر تحديث طلب المراسلة": ["تعذر تحديث طلب المراسلة", "Could not update the message request", "Impossible de mettre à jour la demande"],
    "تعذر إرسال الرسالة": ["تعذر إرسال الرسالة", "Message not sent", "Message non envoyé"],
    "جارٍ الإرسال": ["جارٍ الإرسال", "Sending", "Envoi en cours"],
    "تحميل رسائل أقدم": ["تحميل رسائل أقدم", "Load older messages", "Charger les anciens messages"],
    "تعذر تحميل الرسائل": ["تعذر تحميل الرسائل", "Could not load messages", "Impossible de charger les messages"],
    "أحدث الرسائل": ["أحدث الرسائل", "Latest messages", "Derniers messages"],
    "مرفق": ["مرفق", "Attachment", "Pièce jointe"],
    "الكل": ["الكل", "All", "Tout"],
    "غير المقروءة": ["غير المقروءة", "Unread", "Non lus"],
    "الأرشيف": ["الأرشيف", "Archived", "Archives"],
    "تحميل المزيد": ["تحميل المزيد", "Load more", "Charger plus"],
    "إلغاء الأرشفة": ["إلغاء الأرشفة", "Unarchive", "Désarchiver"],
    "أرشفة المحادثة": ["أرشفة المحادثة", "Archive conversation", "Archiver la conversation"],
    "حذف لدي": ["حذف لدي", "Delete for me", "Supprimer pour moi"],
    "حذف للجميع": ["حذف للجميع", "Delete for everyone", "Supprimer pour tout le monde"],
    "البحث ضمن الرسائل المحملة؛ حمّل الأقدم للمزيد": ["البحث ضمن الرسائل المحملة؛ حمّل الأقدم للمزيد", "Searching loaded messages; load older messages for more", "Recherche dans les messages chargés ; chargez les anciens pour continuer"],

    'تعذر تحميل الصورة': [
      'تعذر تحميل الصورة',
      'Could not load the image',
      'Impossible de charger l’image'
    ],
    'صيغة الفيديو غير مدعومة': [
      'صيغة الفيديو غير مدعومة',
      'Unsupported video format',
      'Format vidéo non pris en charge'
    ],
    'الملف فارغ أو يتجاوز الحد المسموح: {0} ميغابايت': [
      'الملف فارغ أو يتجاوز الحد المسموح: {0} ميغابايت',
      'The file is empty or exceeds the {0} MB limit',
      'Le fichier est vide ou dépasse la limite de {0} Mo'
    ],
    'تغيّر الحساب. سجّل الدخول مجددًا.': [
      'تغيّر الحساب. سجّل الدخول مجددًا.',
      'Account changed. Sign in again.',
      'Le compte a changé. Reconnectez-vous.'
    ],
    'ملف الرفع غير صالح أو يتجاوز الحجم المسموح.': [
      'ملف الرفع غير صالح أو يتجاوز الحجم المسموح.',
      'The upload is invalid or exceeds the size limit.',
      'Le fichier à envoyer est invalide ou dépasse la taille autorisée.'
    ],
    'تغيّر الحساب أثناء رفع الملف.': [
      'تغيّر الحساب أثناء رفع الملف.',
      'Account changed during upload.',
      'Le compte a changé pendant l’envoi.'
    ],
    'تعذر التحقق من إذن رفع الملف.': [
      'تعذر التحقق من إذن رفع الملف.',
      'Could not verify upload permission.',
      'Impossible de vérifier l’autorisation d’envoi.'
    ],
    'تغيّر الحساب أثناء قراءة الملف.': [
      'تغيّر الحساب أثناء قراءة الملف.',
      'Account changed while reading the file.',
      'Le compte a changé pendant la lecture du fichier.'
    ],
    'Account changed': [
      'تغيّر الحساب',
      'Account changed',
      'Le compte a changé'
    ],
    'Authentication required': [
      'يلزم تسجيل الدخول',
      'Authentication required',
      'Connexion requise'
    ],
    'No conversations': [
      'لا توجد محادثات',
      'No conversations',
      'Aucune conversation'
    ],
    'Start a new conversation.': [
      'ابدأ محادثة جديدة.',
      'Start a new conversation.',
      'Commencez une nouvelle conversation.'
    ],
    'User': ['مستخدم', 'User', 'Utilisateur'],
    "الآن": ["الآن", "Now", "Maintenant"],
    "الاسم البديل": ["الاسم البديل", "Nickname", "Surnom"],
    "يغيّر الاسم المعروض عندك، ولا يغيّر اسم الحساب.": [
      "يغيّر الاسم المعروض عندك، ولا يغيّر اسم الحساب.",
      "Changes the name shown to you, not the account name.",
      "Modifie le nom affiché pour vous, sans changer le nom du compte."
    ],
    "حفظ": ["حفظ", "Save", "Enregistrer"],
    "إزالة الاسم البديل": [
      "إزالة الاسم البديل",
      "Remove nickname",
      "Supprimer le surnom"
    ],
    "حظر هذا الحساب؟": [
      "حظر هذا الحساب؟",
      "Block this account?",
      "Bloquer ce compte ?"
    ],
    "لن يتمكن من مراسلتك وستُخفى المحادثة.": [
      "لن يتمكن من مراسلتك وستُخفى المحادثة.",
      "They will not be able to message you, and the conversation will be hidden.",
      "Cette personne ne pourra plus vous écrire et la conversation sera masquée."
    ],
    "إلغاء": ["إلغاء", "Cancel", "Annuler"],
    "حظر": ["حظر", "Block", "Bloquer"],
    "تم إرسال التبليغ": [
      "تم إرسال التبليغ",
      "Report sent",
      "Signalement envoyé"
    ],
    "تعذر حفظ إعداد المحادثة. حاول مجددًا.": [
      "تعذر حفظ إعداد المحادثة. حاول مجددًا.",
      "Could not save the chat setting. Try again.",
      "Impossible d’enregistrer le réglage. Réessayez."
    ],
    "تعذر حفظ إعدادات المحادثة. حاول مجدداً.": [
      "تعذر حفظ إعدادات المحادثة. حاول مجدداً.",
      "Could not save chat settings. Try again.",
      "Impossible d’enregistrer les réglages. Réessayez."
    ],
    "نعناع": ["نعناع", "Mint", "Menthe"],
    "بنفسجي": ["بنفسجي", "Purple", "Violet"],
    "ورق": ["ورق", "Paper", "Papier"],
    "ليلي": ["ليلي", "Night", "Nuit"],
    "افتراضي": ["افتراضي", "Default", "Par défaut"],
    "محيط": ["محيط", "Ocean", "Océan"],
    "لافندر": ["لافندر", "Lavender", "Lavande"],
    "غروب": ["غروب", "Sunset", "Coucher de soleil"],
    "مرجاني": ["مرجاني", "Coral", "Corail"],
    "سماء": ["سماء", "Sky", "Ciel"],
    "غابة": ["غابة", "Forest", "Forêt"],
    "وردي": ["وردي", "Pink", "Rose"],
    "رملي": ["رملي", "Sand", "Sable"],
    "منتصف الليل": ["منتصف الليل", "Midnight", "Minuit"],
    "جرافيت": ["جرافيت", "Graphite", "Graphite"],
    "فيروزي": ["فيروزي", "Turquoise", "Turquoise"],
    "أزرق": ["أزرق", "Blue", "Bleu"],
    "أخضر": ["أخضر", "Green", "Vert"],
    "برتقالي": ["برتقالي", "Orange", "Orange"],
    "ذهبي": ["ذهبي", "Gold", "Doré"],
    "سماوي": ["سماوي", "Cyan", "Cyan"],
    "نيلي": ["نيلي", "Indigo", "Indigo"],
    "أحمر": ["أحمر", "Red", "Rouge"],
    "ليموني": ["ليموني", "Lime", "Citron vert"],
    "داكن": ["داكن", "Dark", "Sombre"],
    "توت": ["توت", "Berry", "Baie"],
    "موج": ["موج", "Wave", "Vague"],
    "ناري": ["ناري", "Fire", "Feu"],
    "مظهر المحادثة": [
      "مظهر المحادثة",
      "Chat appearance",
      "Apparence de la conversation"
    ],
    "اختر ألوانًا وخلفيات تناسبك": [
      "اختر ألوانًا وخلفيات تناسبك",
      "Choose your colors and backgrounds",
      "Choisissez vos couleurs et arrière-plans"
    ],
    "لون الفقاعات": ["لون الفقاعات", "Bubble color", "Couleur des bulles"],
    "خلفية المحادثة": [
      "خلفية المحادثة",
      "Chat background",
      "Arrière-plan de la conversation"
    ],
    "صورة مخصصة": ["صورة مخصصة", "Custom image", "Image personnalisée"],
    "تفاصيل المحادثة": [
      "تفاصيل المحادثة",
      "Chat details",
      "Détails de la conversation"
    ],
    "الإشعارات والترجمة": [
      "الإشعارات والترجمة",
      "Notifications and translation",
      "Notifications et traduction"
    ],
    "كتم الإشعارات": [
      "كتم الإشعارات",
      "Mute notifications",
      "Désactiver les notifications"
    ],
    "الإشعارات مكتومة": [
      "الإشعارات مكتومة",
      "Notifications muted",
      "Notifications désactivées"
    ],
    "الإشعارات مفعّلة": [
      "الإشعارات مفعّلة",
      "Notifications enabled",
      "Notifications activées"
    ],
    "ترجمة تلقائية": [
      "ترجمة تلقائية",
      "Auto-translate",
      "Traduction automatique"
    ],
    "تتم ترجمة الرسائل تلقائياً": [
      "تتم ترجمة الرسائل تلقائياً",
      "Messages are translated automatically",
      "Les messages sont traduits automatiquement"
    ],
    "الترجمة التلقائية متوقفة": [
      "الترجمة التلقائية متوقفة",
      "Auto-translation is off",
      "La traduction automatique est désactivée"
    ],
    "التخصيص": ["التخصيص", "Personalization", "Personnalisation"],
    "اسم للعرض في هذه المحادثة": [
      "اسم للعرض في هذه المحادثة",
      "A display name for this chat",
      "Un nom à afficher dans cette conversation"
    ],
    "المحتوى المشترك": ["المحتوى المشترك", "Shared content", "Contenu partagé"],
    "لا توجد وسائط": ["لا توجد وسائط", "No media", "Aucun média"],
    "لا توجد منشورات": ["لا توجد منشورات", "No posts", "Aucune publication"],
    "لا توجد روابط": ["لا توجد روابط", "No links", "Aucun lien"],
    "إجراءات الحساب": [
      "إجراءات الحساب",
      "Account actions",
      "Actions du compte"
    ],
    "إبلاغ": ["إبلاغ", "Report", "Signaler"],
    "الإبلاغ عن هذا الحساب": [
      "الإبلاغ عن هذا الحساب",
      "Report this account",
      "Signaler ce compte"
    ],
    "منع الحساب من مراسلتك": [
      "منع الحساب من مراسلتك",
      "Prevent this account from messaging you",
      "Empêcher ce compte de vous écrire"
    ],
    "الصورة الخاصة": ["الصورة الخاصة", "Custom photo", "Photo personnalisée"],
    "من المعرض": ["من المعرض", "From gallery", "Depuis la galerie"],
    "إغلاق": ["إغلاق", "Close", "Fermer"],
    "إعدادات المحادثة": [
      "إعدادات المحادثة",
      "Chat settings",
      "Réglages de la conversation"
    ],
    "منشور": ["منشور", "Post", "Publication"],
    "سجّل الدخول أولاً": [
      "سجّل الدخول أولاً",
      "Sign in first",
      "Connectez-vous d’abord"
    ],
    "Chat": ["الدردشة", "Chat", "Discussion"],
    "Conversation": ["المحادثات", "Conversations", "Conversations"],
    "Request": ["الطلبات", "Requests", "Demandes"],
    "Search": ["بحث", "Search", "Rechercher"],
    "No requests": ["لا توجد طلبات", "No requests", "Aucune demande"],
    "Unpin conversation": [
      "إلغاء تثبيت المحادثة",
      "Unpin conversation",
      "Détacher la conversation"
    ],
    "Pin conversation": [
      "تثبيت المحادثة",
      "Pin conversation",
      "Épingler la conversation"
    ],
    "Unmute conversation": [
      "تفعيل إشعارات المحادثة",
      "Unmute conversation",
      "Réactiver les notifications"
    ],
    "Mute conversation": [
      "كتم المحادثة",
      "Mute conversation",
      "Désactiver les notifications"
    ],
    "Delete conversation": [
      "حذف المحادثة",
      "Delete conversation",
      "Supprimer la conversation"
    ],
    "تعذر تحميل الطلبات": [
      "تعذر تحميل الطلبات",
      "Could not load requests",
      "Impossible de charger les demandes"
    ],
    "تعذر تحميل المحادثات": [
      "تعذر تحميل المحادثات",
      "Could not load conversations",
      "Impossible de charger les conversations"
    ],
    "لا يمكن مراسلة هذا الحساب": [
      "لا يمكن مراسلة هذا الحساب",
      "You cannot message this account",
      "Vous ne pouvez pas écrire à ce compte"
    ],
    "تعذر فتح المحادثة.": [
      "تعذر فتح المحادثة.",
      "Could not open the conversation.",
      "Impossible d’ouvrir la conversation."
    ],
    "غير مسموح": ["غير مسموح", "Not allowed", "Non autorisé"],
    "لا يمكن الإرسال بسبب الحظر": [
      "لا يمكن الإرسال بسبب الحظر",
      "Cannot send messages because of a block",
      "Envoi impossible en raison d’un blocage"
    ],
    "انتهت الجلسة": ["انتهت الجلسة", "Session expired", "Session expirée"],
    "هذا الحساب لا يستقبل رسائل": [
      "هذا الحساب لا يستقبل رسائل",
      "This account does not accept messages",
      "Ce compte n’accepte pas les messages"
    ],
    "المراسلة للمتابعين بالتبادل فقط": [
      "المراسلة للمتابعين بالتبادل فقط",
      "Messaging is limited to mutual followers",
      "La messagerie est réservée aux abonnements réciproques"
    ],
    "تعذر التحقق من إمكانية المراسلة. أعد المحاولة": [
      "تعذر التحقق من إمكانية المراسلة. أعد المحاولة",
      "Could not check messaging availability. Try again.",
      "Impossible de vérifier la disponibilité de la messagerie. Réessayez."
    ],
    "التسجيل قصير أو غير صالح": [
      "التسجيل قصير أو غير صالح",
      "Recording is too short or invalid",
      "L’enregistrement est trop court ou non valide"
    ],
    "مسح المحادثة؟": [
      "مسح المحادثة؟",
      "Clear conversation?",
      "Effacer la conversation ?"
    ],
    "تُمسح عندك فقط. الطرف الآخر يبقي الرسائل.": [
      "تُمسح عندك فقط. الطرف الآخر يبقي الرسائل.",
      "Clears it for you only. The other person keeps the messages.",
      "Efface uniquement votre copie. L’autre personne conserve les messages."
    ],
    "مسح": ["مسح", "Clear", "Effacer"],
    "تعذر مسح المحادثة عندك. حاول مجددًا.": [
      "تعذر مسح المحادثة عندك. حاول مجددًا.",
      "Could not clear your conversation. Try again.",
      "Impossible d’effacer votre conversation. Réessayez."
    ],
    "طالب": ["طالب", "Student", "Étudiant"],
    "أنت": ["أنت", "You", "Vous"],
    "تم التحميل": ["تم التحميل", "Downloaded", "Téléchargement terminé"],
    "📷 صورة": ["📷 صورة", "📷 Photo", "📷 Photo"],
    "🎬 فيديو": ["🎬 فيديو", "🎬 Video", "🎬 Vidéo"],
    "🎤 رسالة صوتية": [
      "🎤 رسالة صوتية",
      "🎤 Voice message",
      "🎤 Message vocal"
    ],
    "🎤 صوت": ["🎤 صوت", "🎤 Audio", "🎤 Audio"],
    "رسالة": ["رسالة", "Message", "Message"],
    "تم النسخ": ["تم النسخ", "Copied", "Copié"],
    "تعذر تعديل الرسالة": [
      "تعذر تعديل الرسالة",
      "Could not edit the message",
      "Impossible de modifier le message"
    ],
    "معلومات الرسالة": [
      "معلومات الرسالة",
      "Message info",
      "Informations du message"
    ],
    "تم التعديل": ["تم التعديل", "Edited", "Modifié"],
    "تعذر قراءة الملف": [
      "تعذر قراءة الملف",
      "Could not read the file",
      "Impossible de lire le fichier"
    ],
    "حجم الملف كبير جداً (الحد 20MB)": [
      "حجم الملف كبير جداً (الحد 20MB)",
      "File is too large (20 MB maximum)",
      "Le fichier est trop volumineux (20 Mo maximum)"
    ],
    "تعذر فتح أداة اختيار الصور والفيديو": [
      "تعذر فتح أداة اختيار الصور والفيديو",
      "Could not open the photo and video picker",
      "Impossible d’ouvrir le sélecteur de photos et vidéos"
    ],
    "إدراج رابط": ["إدراج رابط", "Insert link", "Insérer un lien"],
    "إرسال": ["إرسال", "Send", "Envoyer"],
    "محادثة": ["محادثة", "Conversation", "Conversation"],
    "يكتب الآن…": ["يكتب الآن…", "Typing…", "Écrit…"],
    "متصل الآن": ["متصل الآن", "Online now", "En ligne"],
    "بحث": ["بحث", "Search", "Rechercher"],
    "المزيد": ["المزيد", "More", "Plus"],
    "لا توجد رسائل بعد": [
      "لا توجد رسائل بعد",
      "No messages yet",
      "Aucun message pour le moment"
    ],
    "يلزم السماح بالميكروفون": [
      "يلزم السماح بالميكروفون",
      "Microphone permission is required",
      "L’accès au microphone est nécessaire"
    ],
    "لا توجد رموز مستخدمة مؤخرًا": [
      "لا توجد رموز مستخدمة مؤخرًا",
      "No recently used emoji",
      "Aucun emoji utilisé récemment"
    ],
    "ابحث عن إيموجي": ["ابحث عن إيموجي", "Search emoji", "Rechercher un emoji"],
    "ابحث في المحادثة": [
      "ابحث في المحادثة",
      "Search this conversation",
      "Rechercher dans la conversation"
    ],
    "مسح البحث": ["مسح البحث", "Clear search", "Effacer la recherche"],
    "م": ["م", "PM", "PM"],
    "ص": ["ص", "AM", "AM"],
    "شوهدت": ["شوهدت", "Seen", "Vu"],
    "تم الإرسال": ["تم الإرسال", "Sent", "Envoyé"],
    "معدل": ["معدل", "Edited", "Modifié"],
    "الموقع قريبًا": [
      "الموقع قريبًا",
      "Location sharing is coming soon",
      "Le partage de position sera bientôt disponible"
    ],
    "جهات الاتصال قريبًا": [
      "جهات الاتصال قريبًا",
      "Contacts are coming soon",
      "Les contacts seront bientôt disponibles"
    ],
    "الاستطلاع قريبًا": [
      "الاستطلاع قريبًا",
      "Polls are coming soon",
      "Les sondages seront bientôt disponibles"
    ],
    "الحدث قريبًا": [
      "الحدث قريبًا",
      "Events are coming soon",
      "Les événements seront bientôt disponibles"
    ],
    "Message...": ["رسالة…", "Message...", "Message…"],
    "تعذر بدء التسجيل": [
      "تعذر بدء التسجيل",
      "Could not start recording",
      "Impossible de démarrer l’enregistrement"
    ],
    "تعذر الإيقاف المؤقت": [
      "تعذر الإيقاف المؤقت",
      "Could not pause recording",
      "Impossible de mettre l’enregistrement en pause"
    ],
    "تعذر متابعة التسجيل": [
      "تعذر متابعة التسجيل",
      "Could not resume recording",
      "Impossible de reprendre l’enregistrement"
    ],
    "تعذر إرسال التسجيل": [
      "تعذر إرسال التسجيل",
      "Could not send recording",
      "Impossible d’envoyer l’enregistrement"
    ],
    "أفلت للقفل": [
      "أفلت للقفل",
      "Release to lock",
      "Relâchez pour verrouiller"
    ],
    "لأعلى للقفل": [
      "لأعلى للقفل",
      "Slide up to lock",
      "Glissez vers le haut pour verrouiller"
    ],
    "متابعة التسجيل": [
      "متابعة التسجيل",
      "Resume recording",
      "Reprendre l’enregistrement"
    ],
    "إيقاف مؤقت": ["إيقاف مؤقت", "Pause", "Pause"],
    "حذف التسجيل": [
      "حذف التسجيل",
      "Delete recording",
      "Supprimer l’enregistrement"
    ],
    "أفلت للإرسال · يسار للإلغاء · أعلى للقفل": [
      "أفلت للإرسال · يسار للإلغاء · أعلى للقفل",
      "Release to send · left to cancel · up to lock",
      "Relâchez pour envoyer · gauche pour annuler · haut pour verrouiller"
    ],
    "متوقف — اضغط المايك لمتابعة نفس التسجيل": [
      "متوقف — اضغط المايك لمتابعة نفس التسجيل",
      "Paused — tap the mic to resume this recording",
      "En pause — touchez le micro pour reprendre cet enregistrement"
    ],
    "مقفل — يمكنك رفع إصبعك": [
      "مقفل — يمكنك رفع إصبعك",
      "Locked — you can lift your finger",
      "Verrouillé — vous pouvez lever le doigt"
    ],
    "استئناف التسجيل": [
      "استئناف التسجيل",
      "Resume recording",
      "Reprendre l’enregistrement"
    ],
    "جاري التشغيل": ["جاري التشغيل", "Playing", "Lecture en cours"],
    "تشغيل التسجيل": [
      "تشغيل التسجيل",
      "Play recording",
      "Lire l’enregistrement"
    ],
    "وسائط": ["وسائط", "Media", "Médias"],
    "Media": ["وسائط", "Media", "Médias"],
    "Your reactions": ["تفاعلاتك", "Your reactions", "Vos réactions"],
    "Customize": ["تخصيص", "Customize", "Personnaliser"],
    "Recent": ["الأخيرة", "Recent", "Récents"],
    "Swipe up for filters": [
      "اسحب لأعلى لعرض الفلاتر",
      "Swipe up for filters",
      "Glissez vers le haut pour les filtres"
    ],
    "Camera": ["الكاميرا", "Camera", "Appareil photo"],
    "Gallery": ["المعرض", "Gallery", "Galerie"],
    "Document": ["مستند", "Document", "Document"],
    "Location": ["الموقع", "Location", "Position"],
    "Contact": ["جهة اتصال", "Contact", "Contact"],
    "Poll": ["استطلاع", "Poll", "Sondage"],
    "Event": ["حدث", "Event", "Événement"],
    "Add a caption...": [
      "أضف وصفًا…",
      "Add a caption...",
      "Ajouter une légende…"
    ],
    "إرفاق": ["إرفاق", "Attach", "Joindre"],
    "اختيار الصور والفيديو يتم عبر أداة النظام لحماية خصوصيتك.": [
      "اختيار الصور والفيديو يتم عبر أداة النظام لحماية خصوصيتك.",
      "Photos and videos are selected using the system picker to protect your privacy.",
      "Les photos et vidéos sont sélectionnées avec l’outil du système pour protéger votre vie privée."
    ],
    "نص": ["نص", "Text", "Texte"],
    "اكتب هنا": ["اكتب هنا", "Type here", "Écrivez ici"],
    "إضافة": ["إضافة", "Add", "Ajouter"],
    "تم حفظ النسخة المعدّلة": [
      "تم حفظ النسخة المعدّلة",
      "Edited copy saved",
      "Copie modifiée enregistrée"
    ],
    "You": ["أنت", "You", "Vous"],
    "رد": ["رد", "Reply", "Répondre"],
    "نسخ": ["نسخ", "Copy", "Copier"],
    "ترجمة": ["ترجمة", "Translate", "Traduire"],
    "إلغاء التمييز": ["إلغاء التمييز", "Unstar", "Retirer des favoris"],
    "تمييز": ["تمييز", "Star", "Ajouter aux favoris"],
    "معلومات": ["معلومات", "Info", "Informations"],
    "تحميل": ["تحميل", "Download", "Télécharger"],
    "تعديل": ["تعديل", "Edit", "Modifier"],
    "حذف": ["حذف", "Delete", "Supprimer"],
    "لا توجد رسائل مميزة": [
      "لا توجد رسائل مميزة",
      "No starred messages",
      "Aucun message favori"
    ],
    "تعديل الرسالة": ["تعديل الرسالة", "Edit message", "Modifier le message"],
    "كشف تلقائي": [
      "كشف تلقائي",
      "Detect automatically",
      "Détecter automatiquement"
    ],
    "تعذر الترجمة": [
      "تعذر الترجمة",
      "Translation failed",
      "Échec de la traduction"
    ],
    "نسخ الترجمة": ["نسخ الترجمة", "Copy translation", "Copier la traduction"],
    "المجتمع": ["المجتمع", "Community", "Communauté"],
    "الدردشة": ["الدردشة", "Chat", "Discussion"],
    "الرئيسية": ["الرئيسية", "Home", "Accueil"],
    "إعادة المحاولة": ["إعادة المحاولة", "Retry", "Réessayer"],
    "اختيار {0}": ["اختيار {0}", "Select {0}", "Choisir {0}"],
    "وسائط {0}": ["وسائط {0}", "Media {0}", "Médias {0}"],
    "منشورات {0}": ["منشورات {0}", "Posts {0}", "Publications {0}"],
    "روابط {0}": ["روابط {0}", "Links {0}", "Liens {0}"],
    "تعذر إرسال الصورة: {0}": [
      "تعذر إرسال الصورة: {0}",
      "Could not send the photo: {0}",
      "Impossible d’envoyer la photo : {0}"
    ],
    "تعذر إرسال التسجيل: {0}": [
      "تعذر إرسال التسجيل: {0}",
      "Could not send the recording: {0}",
      "Impossible d’envoyer l’enregistrement : {0}"
    ],
    "تعذر التحميل: {0}": [
      "تعذر التحميل: {0}",
      "Download failed: {0}",
      "Échec du téléchargement : {0}"
    ],
    "تعذر حفظ التفاعل: {0}": [
      "تعذر حفظ التفاعل: {0}",
      "Could not save the reaction: {0}",
      "Impossible d’enregistrer la réaction : {0}"
    ],
    "أُرسلت: {0}": ["أُرسلت: {0}", "Sent: {0}", "Envoyé : {0}"],
    "تعذر إرسال الفيديو: {0}": [
      "تعذر إرسال الفيديو: {0}",
      "Could not send the video: {0}",
      "Impossible d’envoyer la vidéo : {0}"
    ],
    "تعذر إرسال الملف: {0}": [
      "تعذر إرسال الملف: {0}",
      "Could not send the file: {0}",
      "Impossible d’envoyer le fichier : {0}"
    ],
    "آخر ظهور {0}": ["آخر ظهور {0}", "Last seen {0}", "Dernière connexion {0}"],
    "Replying to {0}": ["رد على {0}", "Replying to {0}", "Réponse à {0}"],
    "مميز — {0}": ["مميز — {0}", "Starred — {0}", "Favoris — {0}"],
    "{0}د": ["{0}د", "{0}m", "{0} min"],
    "{0}س": ["{0}س", "{0}h", "{0} h"],
    "{0}ي": ["{0}ي", "{0}d", "{0} j"],
  };
}
