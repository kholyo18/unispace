import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

// Application-authored UI text only. Stored identifiers and user content stay unchanged.
const mainMessageCatalog = <String, List<String>>{
  "تعذر تحميل بعض نتائج المنشورات. أعد البحث للمحاولة مجددًا.": <String>["Some post results could not load. Search again to retry.", "Certains résultats n’ont pas pu être chargés. Relancez la recherche."],
  "النتائج محدودة؛ قد لا تشمل المنشورات الأقدم.": <String>["Results are limited and may not include older posts.", "Les résultats sont limités et peuvent exclure les anciennes publications."],
  "اسم المستخدم": <String>["Username", "Nom d’utilisateur"],
  "القسم": <String>["Department", "Département"],
  "تخصصات": <String>["Majors", "Spécialités"],
  "حفظ": <String>["Save", "Enregistrer"],
  "اللقب": <String>["Last name", "Nom"],
  "أنشئ منشوراً": <String>["Create a post", "Créer une publication"],
  "فاتح": <String>["Light", "Clair"],
  "المنشورات": <String>["Posts", "Publications"],
  "حول التطبيق": <String>["About the App", "À propos de l'application"],
  "إغلاق": <String>["Close", "Fermer"],
  "حذف": <String>["Delete", "Supprimer"],
  "تعديل": <String>["Edit", "Modifier"],
  "تحديث القائمة": <String>["Refresh list", "Rafraîchir la liste"],
  "لا توجد منشورات بعد": <String>[
    "No posts yet",
    "Aucune publication pour le moment"
  ],
  "سياسة الخصوصية": <String>["Privacy Policy", "Politique de confidentialité"],
  "إخفاء": <String>["Hide", "Masquer"],
  "أخرى": <String>["Other", "Autre"],
  "مسح الكل": <String>["Clear all", "Tout effacer"],
  "حظر الحساب": <String>["Block Account", "Bloquer le compte"],
  "الأمان والخصوصية": <String>[
    "Security and privacy",
    "Sécurité et confidentialité"
  ],
  "الإشعارات": <String>["Notifications", "Notifications"],
  "إلغاء الحظر": <String>["Unblock", "Débloquer"],
  "مرحبًا بك في UniSpace": <String>[
    "Welcome to UniSpace",
    "Bienvenue sur UniSpace"
  ],
  "قريباً": <String>["Coming soon", "Bientôt"],
  "التخصص": <String>["Major", "Spécialité"],
  "اللغة": <String>["Locale", "Langue"],
  "الكلية": <String>["College", "Faculté"],
  "لا توجد نتائج": <String>["No results found", "Aucun résultat"],
  "الحساب": <String>["Account", "Compte"],
  "العربية": <String>["Arabic", "Arabe"],
  "إلغاء": <String>["Cancel", "Annuler"],
  "كلمة المرور": <String>["Password", "Mot de passe"],
  "متابعة": <String>["Continue", "Continuer"],
  "تحديث": <String>["Refresh", "Actualiser"],
  "تسجيل الخروج": <String>["Sign out", "Se déconnecter"],
  "الجامعة": <String>["University", "University"],
  "التعليقات": <String>["Comments", "Commentaires"],
  "الملف الشخصي": <String>["Profile", "Profile"],
  "تسجيل الدخول": <String>["Login", "Se connecter"],
  "مشاركة": <String>["Share", "Partager"],
  "داكن": <String>["Dark", "Sombre"],
  "الكل": <String>["All", "Tout"],
  "عام": <String>["Public", "Public"],
  "نسخ النص": <String>["Copy Text", "Copier le texte"],
  "الاسم": <String>["Name", "Nom"],
  "حفظ المنشور": <String>["Save Post", "Enregistrer la publication"],
  "حظر": <String>["Block", "Bloquer"],
  "تأكيد": <String>["Confirm", "Confirmer"],
  "تعليق": <String>["Comment", "Commentaire"],
  "يتابع": <String>["Following", "Following"],
  "الآن": <String>["Now", "Maintenant"],
  "المنشورات المحفوظة": <String>["Saved posts", "Publications enregistrées"],
  "المظهر والألوان": <String>["Appearance and colors", "Apparence et couleurs"],
  "خصص شكل التطبيق بما يناسبك": <String>[
    "Customize the look of your app",
    "Personnalisez l’apparence de votre application"
  ],
  "السمة": <String>["Theme", "Thème"],
  "استخدام المظهر الفاتح دائمًا": <String>[
    "Always use light mode",
    "Toujours utiliser le mode clair"
  ],
  "استخدام المظهر الداكن دائمًا": <String>[
    "Always use dark mode",
    "Toujours utiliser le mode sombre"
  ],
  "اتباع إعدادات الجهاز تلقائيًا": <String>[
    "Follow device settings automatically",
    "Suivre automatiquement les réglages de l’appareil"
  ],
  "ألوان التطبيق": <String>["App colors", "Couleurs de l’application"],
  "العودة للألوان الأصلية": <String>[
    "Restore default colors",
    "Rétablir les couleurs par défaut"
  ],
  "اختر اللون": <String>["Choose a color", "Choisir une couleur"],
  "السطوع": <String>["Brightness", "Luminosité"],
  "المعاينة": <String>["Preview", "Aperçu"],
  "جارٍ الحفظ...": <String>["Saving…", "Enregistrement…"],
  "اعتماد اللون": <String>["Apply color", "Appliquer la couleur"],
  "اختر اللغة المناسبة لتجربتك": <String>[
    "Choose your preferred language",
    "Choisissez votre langue préférée"
  ],
  "أعد تسجيل الدخول لإكمال التأكيد بخطوتين عبر تطبيق المصادقة.": <String>[
    "Sign in again to complete two-step verification with your authenticator app.",
    "Reconnectez-vous pour terminer la validation en deux étapes avec votre application d’authentification."
  ],
  "متابعة إلى تسجيل الدخول": <String>[
    "Continue to sign in",
    "Continuer vers la connexion"
  ],
  "تعذر تشغيل Firebase. أعد فتح التطبيق.": <String>[
    "Could not start Firebase. Reopen the app.",
    "Impossible de démarrer Firebase. Rouvrez l’application."
  ],
  "الحساب محذوف": <String>["Account deleted", "Compte supprimé"],
  "تحقق من اتصال الإنترنت ثم أعد المحاولة.": <String>[
    "Check your internet connection and try again.",
    "Vérifiez votre connexion Internet, puis réessayez."
  ],
  "بيانات الاعتماد غير صالحة. تحقق من إعدادات تسجيل الدخول.": <String>[
    "Invalid credentials. Check your sign-in settings.",
    "Identifiants non valides. Vérifiez les paramètres de connexion."
  ],
  "تم تعطيل الحساب.": <String>[
    "This account has been disabled.",
    "Ce compte a été désactivé."
  ],
  "حدث خطأ أثناء تسجيل الدخول عبر Google. حاول مرة أخرى.": <String>[
    "Google sign-in failed. Please try again.",
    "La connexion avec Google a échoué. Réessayez."
  ],
  "تم إلغاء تسجيل الدخول عبر Google.": <String>[
    "Google sign-in was canceled.",
    "La connexion avec Google a été annulée."
  ],
  "تعذر إكمال تسجيل الدخول. تأكد من إعدادات Firebase/Google (SHA-1، الحزمة، OAuth) ثم أعد المحاولة.":
      <String>[
    "Could not complete sign-in. Check the Firebase/Google configuration (SHA-1, package, OAuth) and try again.",
    "Connexion impossible. Vérifiez la configuration Firebase/Google (SHA-1, package, OAuth), puis réessayez."
  ],
  "الرجاء إدخال البريد الإلكتروني وكلمة المرور.": <String>[
    "Enter your email and password.",
    "Saisissez votre adresse e-mail et votre mot de passe."
  ],
  "حدث خطأ أثناء تسجيل الدخول.": <String>[
    "An error occurred while signing in.",
    "Une erreur s’est produite lors de la connexion."
  ],
  "مساحتك الجامعية": <String>[
    "Your university space",
    "Votre espace universitaire"
  ],
  "أوافق على شروط الاستخدام": <String>[
    "I agree to the Terms of Use",
    "J’accepte les conditions d’utilisation"
  ],
  "اطّلع على": <String>["Read the", "Consultez les"],
  "شروط الاستخدام": <String>["Terms of Use", "Conditions d’utilisation"],
  "قواعد المجتمع": <String>["Community Guidelines", "Règles de la communauté"],
  "ليس لديك حساب؟  ": <String>[
    "Don’t have an account?  ",
    "Vous n’avez pas de compte ?  "
  ],
  "متابعة عبر Google": <String>[
    "Continue with Google",
    "Continuer avec Google"
  ],
  "تم إعادة تفعيل الحساب": <String>["Account reactivated", "Compte réactivé"],
  "الحساب معطّل": <String>["Account disabled", "Compte désactivé"],
  "حسابك متوقف مؤقتاً. يمكنك إعادة تفعيله الآن للعودة إلى UniSpace.": <String>[
    "Your account is temporarily disabled. Reactivate it to return to UniSpace.",
    "Votre compte est temporairement désactivé. Réactivez-le pour revenir sur UniSpace."
  ],
  "إعادة تفعيل الحساب": <String>["Reactivate account", "Réactiver le compte"],
  "خطة مذاكرة S1": <String>["Semester 1 study plan", "Plan de révision S1"],
  "رياضيات، فيزياء، برمجة...": <String>[
    "Mathematics, physics, programming…",
    "Mathématiques, physique, programmation…"
  ],
  "تعذر تحميل الإشعارات — إعادة المحاولة": <String>[
    "Could not load notifications — retry",
    "Impossible de charger les notifications — réessayer"
  ],
  "نشر منشوراً جديداً": <String>[
    "published a new post",
    " a publié une nouvelle publication"
  ],
  "علّق على منشورك": <String>[
    "commented on your post",
    " a commenté votre publication"
  ],
  "رد على تعليقك": <String>[
    "replied to your comment",
    " a répondu à votre commentaire"
  ],
  "أعاد نشر محتوى": <String>["reposted content", " a repartagé du contenu"],
  "وآخرون أعجبوا بمنشورك": <String>[
    "and others liked your post",
    "et d’autres ont aimé votre publication"
  ],
  "أعجب بمنشورك": <String>["liked your post", " a aimé votre publication"],
  "وآخرون أعجبوا بتعليقك": <String>[
    "and others liked your comment",
    "et d’autres ont aimé votre commentaire"
  ],
  "أعجب بتعليقك": <String>["liked your comment", " a aimé votre commentaire"],
  "لديك تحديث على محتوى تتابعه": <String>[
    "There is an update to content you follow",
    "Du contenu que vous suivez a été mis à jour"
  ],
  "سابقاً": <String>["Earlier", "Plus tôt"],
  "سابقًا": <String>["Earlier", "Plus tôt"],
  "اليوم": <String>["Today", "Aujourd’hui"],
  "أمس": <String>["Yesterday", "Hier"],
  "هذا الأسبوع": <String>["This week", "Cette semaine"],
  "مستخدم": <String>["User", "Utilisateur"],
  "طالب": <String>["Student", "Étudiant"],
  "وآخر أعجبا بتعليقك": <String>[
    "and one other liked your comment",
    "et une autre personne ont aimé votre commentaire"
  ],
  "وآخر أعجبا بمنشورك": <String>[
    "and one other liked your post",
    "et une autre personne ont aimé votre publication"
  ],
  "طالب UniSpace": <String>["UniSpace student", "Étudiant UniSpace"],
  "هذا التعليق غير متاح حاليًا": <String>[
    "This comment is currently unavailable",
    "Ce commentaire est actuellement indisponible"
  ],
  "تعذر فتح المحتوى. قد يكون غير متاح أو تعذر الاتصال.": <String>[
    "Could not open the content. It may be unavailable or there may be a connection issue.",
    "Impossible d’ouvrir le contenu. Il est peut-être indisponible ou la connexion a échoué."
  ],
  "لا يمكن مراسلة هذا الحساب": <String>[
    "You cannot message this account",
    "Vous ne pouvez pas envoyer de message à ce compte"
  ],
  "توسيع": <String>["Expand", "Développer"],
  "تعذر التحقق من الإشعارات. إعادة المحاولة": <String>[
    "Could not verify notifications. Retry",
    "Impossible de vérifier les notifications. Réessayer"
  ],
  "تغيّر الحساب. أغلق هذه النافذة وافتح الإشعارات مجددًا": <String>[
    "The account changed. Close this window and reopen notifications",
    "Le compte a changé. Fermez cette fenêtre et rouvrez les notifications"
  ],
  "لا توجد إشعارات": <String>["No notifications", "Aucune notification"],
  "تعذر تحميل الإشعارات بأمان": <String>[
    "Could not securely load notifications",
    "Impossible de charger les notifications de manière sécurisée"
  ],
  "إعادة المحاولة": <String>["Retry", "Réessayer"],
  "سجّل الدخول أولاً": <String>["Sign in first", "Connectez-vous d’abord"],
  "تحميل إشعارات أقدم": <String>[
    "Load older notifications",
    "Charger les notifications plus anciennes"
  ],
  "تعرض هذه الصفحة أحدث 400 إشعار": <String>[
    "This page shows the latest 400 notifications",
    "Cette page affiche les 400 dernières notifications"
  ],
  "لا توجد إشعارات في القائمة المحمّلة": <String>[
    "No notifications in the loaded list",
    "Aucune notification dans la liste chargée"
  ],
  "لا توجد إشعارات محمّلة في هذا التصنيف": <String>[
    "No loaded notifications in this category",
    "Aucune notification chargée dans cette catégorie"
  ],
  "المتابعة": <String>["Following", "Abonnements"],
  "التفاعل": <String>["Activity", "Interactions"],
  "كن أول من يبدأ نقاشاً جامعياً مع زملائك.": <String>[
    "Be the first to start a university discussion with your classmates.",
    "Lancez la première discussion universitaire avec vos camarades."
  ],
  "تعذر التحقق من صلاحية عرض المنشورات": <String>[
    "Could not verify permission to view posts",
    "Impossible de vérifier l’autorisation de consulter les publications"
  ],
  "تعذر تأكيد صفحة الخلاصة": <String>[
    "Could not verify the feed page",
    "Impossible de vérifier la page du fil"
  ],
  "بيانات منشور غير صالحة": <String>[
    "Invalid post data",
    "Données de publication non valides"
  ],
  "تعذر تحديث المنشورات بأمان": <String>[
    "Could not securely refresh posts",
    "Impossible d’actualiser les publications de manière sécurisée"
  ],
  "يجب تسجيل الدخول أولاً": <String>[
    "You must sign in first",
    "Vous devez d’abord vous connecter"
  ],
  "المنشور فارغ": <String>["The post is empty", "La publication est vide"],
  "تعذر تأكيد بدء النشر": <String>[
    "Could not confirm the start of publishing",
    "Impossible de confirmer le début de la publication"
  ],
  "تغير الحساب أثناء النشر": <String>[
    "The account changed while publishing",
    "Le compte a changé pendant la publication"
  ],
  "تعذر تأكيد نشر المنشور": <String>[
    "Could not confirm publication",
    "Impossible de confirmer la publication"
  ],
  "تم نشر المنشور، لكن تعذر تحديث القائمة. حدّث الصفحة.": <String>[
    "Your post was published, but the list could not refresh. Refresh the page.",
    "Votre publication a été publiée, mais la liste n’a pas pu être actualisée. Actualisez la page."
  ],
  "تعذر تأكيد النشر. حدّث الصفحة قبل إعادة المحاولة.": <String>[
    "Could not confirm publication. Refresh the page before retrying.",
    "Impossible de confirmer la publication. Actualisez la page avant de réessayer."
  ],
  "تعذر تحديد المنشور": <String>[
    "Could not identify the post",
    "Impossible d’identifier la publication"
  ],
  "إنشاء منشور": <String>["Create post", "Créer une publication"],
  "تعذر تحميل المنشورات بأمان": <String>[
    "Could not securely load posts",
    "Impossible de charger les publications de manière sécurisée"
  ],
  "جارٍ التحميل...": <String>["Loading…", "Chargement…"],
  "جارٍ التحميل…": <String>["Loading…", "Chargement…"],
  "عرض منشورات أقدم": <String>[
    "Show older posts",
    "Afficher les publications plus anciennes"
  ],
  "لا مزيد من المنشورات": <String>["No more posts", "Aucune autre publication"],
  "تعذر التحقق من قائمة الحظر": <String>[
    "Could not verify the block list",
    "Impossible de vérifier la liste des comptes bloqués"
  ],
  "تعذر تحديث التصويت. حاول مرة أخرى.": <String>[
    "Could not update your vote. Try again.",
    "Impossible de mettre à jour votre vote. Réessayez."
  ],
  " • إعادة نشر": <String>[" • Repost", " • Republication"],
  "محفوظ": <String>["Saved", "Enregistré"],
  "إلغاء الحفظ": <String>["Unsave", "Retirer des éléments enregistrés"],
  "رد على تعليق": <String>["Reply to a comment", "Répondre à un commentaire"],
  "دراسة": <String>["Study", "Études"],
  "امتحانات": <String>["Exams", "Examens"],
  "٢٤٠+ منشور": <String>["240+ posts", "240+ publications"],
  "فرص": <String>["Opportunities", "Opportunités"],
  "منح دراسية": <String>["Scholarships", "Bourses d’études"],
  "١٨٠+ منشور": <String>["180+ posts", "180+ publications"],
  "مذاكرة": <String>["Revision", "Révision"],
  "٣١٠+ منشور": <String>["310+ posts", "310+ publications"],
  "حياة جامعية": <String>["Campus life", "Vie universitaire"],
  "سكن جامعي": <String>["Student housing", "Résidence universitaire"],
  "١٤٠+ منشور": <String>["140+ posts", "140+ publications"],
  "٧٥+ منشور": <String>["75+ posts", "75+ publications"],
  "٩٠+ منشور": <String>["90+ posts", "90+ publications"],
  "أنشطة طلابية": <String>["Student activities", "Activités étudiantes"],
  "عمل": <String>["Work", "Travail"],
  "نصائح": <String>["Tips", "Conseils"],
  "نقاش جامعي": <String>["University discussion", "Discussion universitaire"],
  "لا توجد نتائج مطابقة": <String>[
    "No matching results",
    "Aucun résultat correspondant"
  ],
  "لا نتائج مطابقة": <String>[
    "No matching results",
    "Aucun résultat correspondant"
  ],
  "جاري البحث...": <String>["Searching…", "Recherche…"],
  "ابحث": <String>["Search", "Rechercher"],
  "إغلاق البحث": <String>["Close search", "Fermer la recherche"],
  "ابحث في المنشورات والتعليقات": <String>[
    "Search posts and comments",
    "Rechercher dans les publications et commentaires"
  ],
  "لا يوجد محتوى نصي": <String>["No text content", "Aucun contenu textuel"],
  "تعليق أصلي": <String>["Original comment", "Commentaire d’origine"],
  "تعليق منقول": <String>["Reposted comment", "Commentaire repartagé"],
  "منشور أصلي · UniSpace": <String>[
    "Original post · UniSpace",
    "Publication d’origine · UniSpace"
  ],
  "استطلاع أصلي · UniSpace": <String>[
    "Original poll · UniSpace",
    "Sondage d’origine · UniSpace"
  ],
  "منشور UniSpace": <String>["UniSpace post", "Publication UniSpace"],
  "نسخ الرابط": <String>["Copy link", "Copier le lien"],
  "تم نسخ الرابط": <String>["Link copied", "Lien copié"],
  "تم نسخ النص": <String>["Text copied", "Texte copié"],
  "مشاركة المنشور": <String>["Share post", "Partager la publication"],
  "مشاركة عبر التطبيقات": <String>[
    "Share via apps",
    "Partager via les applications"
  ],
  "إعادة نشر": <String>["Repost", "Repartager"],
  "تمت إعادة النشر": <String>["Reposted", "Contenu repartagé"],
  "تعذر إعادة النشر، حاول مجددًا": <String>[
    "Could not repost. Try again",
    "Impossible de repartager. Réessayez"
  ],
  "تعذر تحديد مصدر إعادة النشر": <String>[
    "Could not identify the repost source",
    "Impossible d’identifier la source de la republication"
  ],
  "المحتوى الأصلي غير متاح": <String>[
    "Original content unavailable",
    "Contenu d’origine indisponible"
  ],
  "المحتوى الأصلي غير متاح حاليًا. قد يكون محذوفًا أو خاصًا.": <String>[
    "The original content is currently unavailable. It may have been deleted or made private.",
    "Le contenu d’origine est actuellement indisponible. Il a peut-être été supprimé ou rendu privé."
  ],
  "المنشور الأصلي غير موجود": <String>[
    "Original post not found",
    "Publication d’origine introuvable"
  ],
  "المنشور الأصلي لم يعد متاحاً": <String>[
    "The original post is no longer available",
    "La publication d’origine n’est plus disponible"
  ],
  "المنشور غير متاح": <String>["Post unavailable", "Publication indisponible"],
  "المنشور لم يعد متاحاً": <String>[
    "The post is no longer available",
    "La publication n’est plus disponible"
  ],
  "تعذر فتح المنشور الأصلي، حاول مجدداً": <String>[
    "Could not open the original post. Try again",
    "Impossible d’ouvrir la publication d’origine. Réessayez"
  ],
  "تعذر تأكيد إعادة النشر": <String>[
    "Could not confirm the repost",
    "Impossible de confirmer la republication"
  ],
  "تغير الحساب أثناء إعادة النشر": <String>[
    "The account changed while reposting",
    "Le compte a changé pendant la republication"
  ],
  "إعادة النشر غير مسموحة لهذا الحساب": <String>[
    "Reposting is not allowed for this account",
    "La republication n’est pas autorisée pour ce compte"
  ],
  "تعذر إعادة نشر هذا المنشور": <String>[
    "Could not repost this post",
    "Impossible de repartager cette publication"
  ],
  "تعذر الوصول إلى المنشور الأصلي لإعادة نشره": <String>[
    "Could not access the original post to repost it",
    "Impossible d’accéder à la publication d’origine pour la repartager"
  ],
  "تعذر تجهيز المشاركة، ربما تغيّر المنشور أو الوصول إليه": <String>[
    "Could not prepare sharing. The post or your access may have changed",
    "Impossible de préparer le partage. La publication ou vos droits d’accès ont peut-être changé"
  ],
  "تعذر نسخ النص، ربما لم يعد المنشور متاحًا": <String>[
    "Could not copy the text. The post may no longer be available",
    "Impossible de copier le texte. La publication n’est peut-être plus disponible"
  ],
  "تعذر فتح الوسائط، حاول مجدداً": <String>[
    "Could not open media. Try again",
    "Impossible d’ouvrir les médias. Réessayez"
  ],
  "عرض المزيد": <String>["Show more", "Afficher plus"],
  "عرض أقل": <String>["Show less", "Afficher moins"],
  "إعجابات": <String>["Likes", "J’aime"],
  "لا توجد إعجابات": <String>["No likes", "Aucun J’aime"],
  "لا توجد إعادة نشر": <String>["No reposts", "Aucune republication"],
  "تعذر تحميل التفاعلات": <String>[
    "Could not load reactions",
    "Impossible de charger les réactions"
  ],
  "تعليقات": <String>["Comments", "Commentaires"],
  "لا توجد تعليقات": <String>["No comments", "Aucun commentaire"],
  "لا توجد تعليقات بعد": <String>[
    "No comments yet",
    "Aucun commentaire pour le moment"
  ],
  "كن أول من يعلّق على هذا المنشور": <String>[
    "Be the first to comment on this post",
    "Soyez la première personne à commenter cette publication"
  ],
  "أضف تعليقاً...": <String>["Add a comment…", "Ajouter un commentaire…"],
  "أضف رداً...": <String>["Add a reply…", "Ajouter une réponse…"],
  "تعديل التعليق": <String>["Edit comment", "Modifier le commentaire"],
  "عدّل التعليق...": <String>[
    "Edit your comment…",
    "Modifiez votre commentaire…"
  ],
  "حذف التعليق؟": <String>["Delete comment?", "Supprimer le commentaire ?"],
  "سيتم حذف التعليق وكل الردود عليه نهائيًا.": <String>[
    "This comment and all its replies will be permanently deleted.",
    "Ce commentaire et toutes ses réponses seront définitivement supprimés."
  ],
  "تعذر حذف التعليق، حاول مجددًا": <String>[
    "Could not delete the comment. Try again",
    "Impossible de supprimer le commentaire. Réessayez"
  ],
  "تعذر تعديل التعليق، حاول مجددًا": <String>[
    "Could not edit the comment. Try again",
    "Impossible de modifier le commentaire. Réessayez"
  ],
  "تعذر تأكيد تحديث التعليق": <String>[
    "Could not confirm the comment update",
    "Impossible de confirmer la mise à jour du commentaire"
  ],
  "التعليق لم يعد متاحاً": <String>[
    "The comment is no longer available",
    "Le commentaire n’est plus disponible"
  ],
  "التعليق غير مسموح على هذا المنشور": <String>[
    "Comments are not allowed on this post",
    "Les commentaires ne sont pas autorisés sur cette publication"
  ],
  "التعليق غير مسموح وفق إعدادات الخصوصية الحالية.": <String>[
    "Comments are not allowed under the current privacy settings.",
    "Les paramètres de confidentialité actuels n’autorisent pas les commentaires."
  ],
  "التعليق على منشورات هذا الحساب مقيّد.": <String>[
    "Commenting on this account’s posts is restricted.",
    "Les commentaires sur les publications de ce compte sont restreints."
  ],
  "تعذر تحميل التعليقات": <String>[
    "Could not load comments",
    "Impossible de charger les commentaires"
  ],
  "بيانات تعليقات غير صالحة": <String>[
    "Invalid comment data",
    "Données de commentaire non valides"
  ],
  "تعذر تأكيد صلاحية عرض التعليقات": <String>[
    "Could not verify permission to view comments",
    "Impossible de vérifier l’autorisation de consulter les commentaires"
  ],
  "تعذر فتح التعليق": <String>[
    "Could not open the comment",
    "Impossible d’ouvrir le commentaire"
  ],
  "إعادة نشر تعليق": <String>["Repost comment", "Repartager le commentaire"],
  "تمت إعادة نشر التعليق": <String>[
    "Comment reposted",
    "Commentaire repartagé"
  ],
  "تعذر إعادة نشر هذا التعليق": <String>[
    "Could not repost this comment",
    "Impossible de repartager ce commentaire"
  ],
  "تعذر تحديث التصويت على التعليق. حاول مرة أخرى.": <String>[
    "Could not update your vote on the comment. Try again.",
    "Impossible de mettre à jour votre vote sur le commentaire. Réessayez."
  ],
  "تم حفظ التعليق": <String>["Comment saved", "Commentaire enregistré"],
  "تعذر حفظ التعليق": <String>[
    "Could not save the comment",
    "Impossible d’enregistrer le commentaire"
  ],
  "تم إلغاء حفظ التعليق": <String>[
    "Comment unsaved",
    "Commentaire retiré des éléments enregistrés"
  ],
  "تعذر إلغاء حفظ التعليق": <String>[
    "Could not unsave the comment",
    "Impossible de retirer le commentaire des éléments enregistrés"
  ],
  "تعذر تأكيد حفظ التعليق. حدّث القائمة قبل إعادة الإرسال.": <String>[
    "Could not confirm saving the comment. Refresh the list before retrying.",
    "Impossible de confirmer l’enregistrement du commentaire. Actualisez la liste avant de réessayer."
  ],
  "أخفينا هذا التعليق عنك.": <String>[
    "This comment has been hidden from you.",
    "Ce commentaire a été masqué pour vous."
  ],
  "أخفينا هذا المنشور عنك.": <String>[
    "This post has been hidden from you.",
    "Cette publication a été masquée pour vous."
  ],
  "تم حفظ المنشور": <String>["Post saved", "Publication enregistrée"],
  "تعذر حفظ المنشور": <String>[
    "Could not save the post",
    "Impossible d’enregistrer la publication"
  ],
  "تم إلغاء حفظ المنشور": <String>[
    "Post unsaved",
    "Publication retirée des éléments enregistrés"
  ],
  "تعذر إلغاء حفظ المنشور": <String>[
    "Could not unsave the post",
    "Impossible de retirer la publication des éléments enregistrés"
  ],
  "تم إلغاء الحفظ": <String>[
    "Removed from saved items",
    "Retiré des éléments enregistrés"
  ],
  "تعذر التراجع عن إلغاء الحفظ": <String>[
    "Could not undo removing the saved item",
    "Impossible d’annuler le retrait des éléments enregistrés"
  ],
  "تراجع": <String>["Undo", "Annuler"],
  "احفظ المنشورات أو التعليقات المهمة لتجدها هنا لاحقًا": <String>[
    "Save important posts or comments to find them here later",
    "Enregistrez les publications ou commentaires importants pour les retrouver ici"
  ],
  "لا توجد محفوظات": <String>["No saved items", "Aucun élément enregistré"],
  "لا توجد منشورات محفوظة": <String>[
    "No saved posts",
    "Aucune publication enregistrée"
  ],
  "لا توجد تعليقات محفوظة": <String>[
    "No saved comments",
    "Aucun commentaire enregistré"
  ],
  "تعذر تحميل المحفوظات": <String>[
    "Could not load saved items",
    "Impossible de charger les éléments enregistrés"
  ],
  "البحث في المحفوظات": <String>[
    "Search saved items",
    "Rechercher dans les éléments enregistrés"
  ],
  "المحفوظات": <String>["Saved items", "Éléments enregistrés"],
  "تعديل المنشور": <String>["Edit post", "Modifier la publication"],
  "تعديل منشور": <String>["Edit post", "Modifier une publication"],
  "حذف المنشور": <String>["Delete post", "Supprimer la publication"],
  "حذف المنشور؟": <String>["Delete post?", "Supprimer la publication ?"],
  "سيتم حذف هذا المنشور نهائيًا ولا يمكن التراجع عن العملية.": <String>[
    "This post will be permanently deleted. This cannot be undone.",
    "Cette publication sera définitivement supprimée. Cette action est irréversible."
  ],
  "تم حذف المنشور": <String>["Post deleted", "Publication supprimée"],
  "تعذر حذف المنشور، حاول مجددًا": <String>[
    "Could not delete the post. Try again",
    "Impossible de supprimer la publication. Réessayez"
  ],
  "تعذر تأكيد حذف المنشور": <String>[
    "Could not confirm deleting the post",
    "Impossible de confirmer la suppression de la publication"
  ],
  "تم تعديل المنشور": <String>["Post updated", "Publication modifiée"],
  "تعذر تعديل المنشور": <String>[
    "Could not edit the post",
    "Impossible de modifier la publication"
  ],
  "تعذر تأكيد تعديل المنشور": <String>[
    "Could not confirm the post update",
    "Impossible de confirmer la modification de la publication"
  ],
  "تغير الحساب أثناء التعديل": <String>[
    "The account changed while editing",
    "Le compte a changé pendant la modification"
  ],
  "تثبيت المنشور": <String>["Pin post", "Épingler la publication"],
  "إلغاء التثبيت": <String>["Unpin", "Désépingler"],
  "تم تثبيت المنشور": <String>["Post pinned", "Publication épinglée"],
  "تم إلغاء التثبيت": <String>["Post unpinned", "Publication désépinglée"],
  "خيارات المنشور": <String>["Post options", "Options de publication"],
  "الشعور": <String>["Feeling", "Humeur"],
  "أضف شعوراً...": <String>["Add a feeling…", "Ajouter une humeur…"],
  "اكتب شعورك...": <String>["Describe how you feel…", "Décrivez votre humeur…"],
  "☕ استراحة": <String>["☕ Taking a break", "☕ En pause"],
  "📚 أذاكر": <String>["📚 Studying", "📚 En révision"],
  "😴 متعب": <String>["😴 Tired", "😴 Fatigué"],
  "🚀 متحمس": <String>["🚀 Excited", "🚀 Enthousiaste"],
  "أضف وسمًا...": <String>["Add a tag…", "Ajouter un mot-clé…"],
  "الوسوم على هذا المنشور": <String>[
    "Tags on this post",
    "Mots-clés de cette publication"
  ],
  "لا توجد وسوم على هذا المنشور": <String>[
    "No tags on this post",
    "Aucun mot-clé sur cette publication"
  ],
  "صورة": <String>["Image", "Image"],
  "فيديو": <String>["Video", "Vidéo"],
  "وسائط": <String>["Media", "Médias"],
  "صورة مرفقة": <String>["Attached image", "Image jointe"],
  "فيديو مرفق": <String>["Attached video", "Vidéo jointe"],
  "GIF مرفق": <String>["Attached GIF", "GIF joint"],
  "لا توجد وسائط": <String>["No media", "Aucun média"],
  "لا توجد وسائط متاحة للتنزيل": <String>[
    "No media available to download",
    "Aucun média disponible au téléchargement"
  ],
  "لم تعد هناك وسائط في هذا المنشور": <String>[
    "This post no longer contains media",
    "Cette publication ne contient plus de médias"
  ],
  "هذا الملف لم يعد متاحاً في المنشور": <String>[
    "This file is no longer available in the post",
    "Ce fichier n’est plus disponible dans la publication"
  ],
  "تحميل الوسائط": <String>["Download media", "Télécharger les médias"],
  "اختر ما تريد تحميله": <String>[
    "Choose what to download",
    "Choisissez les éléments à télécharger"
  ],
  "تحميل ": <String>["Download ", "Télécharger "],
  "تم حفظ الوسائط": <String>["Media saved", "Médias enregistrés"],
  "تم الحفظ للمعرض": <String>["Saved to gallery", "Enregistré dans la galerie"],
  "تم الحفظ": <String>["Saved", "Enregistré"],
  "تعذر حفظ الصورة": <String>[
    "Could not save the image",
    "Impossible d’enregistrer l’image"
  ],
  "تعذر حفظ الفيديو": <String>[
    "Could not save the video",
    "Impossible d’enregistrer la vidéo"
  ],
  "تعذر تنزيل الوسائط أو لم تعد متاحة": <String>[
    "Could not download media, or it is no longer available",
    "Impossible de télécharger les médias, ou ils ne sont plus disponibles"
  ],
  "تعذر تحميل الصورة": <String>[
    "Could not load the image",
    "Impossible de charger l’image"
  ],
  "تعذر تحميل الفيديو": <String>[
    "Could not load the video",
    "Impossible de charger la vidéo"
  ],
  "رابط الصورة فارغ": <String>[
    "The image URL is empty",
    "Le lien de l’image est vide"
  ],
  "رابط الفيديو فارغ": <String>[
    "The video URL is empty",
    "Le lien de la vidéo est vide"
  ],
  "تعذر فتح الصورة، ربما تغيّر الوصول إلى المنشور": <String>[
    "Could not open the image. Your access to the post may have changed",
    "Impossible d’ouvrir l’image. Vos droits d’accès à la publication ont peut-être changé"
  ],
  "تعذر فتح الصورة، ربما لم يعد التعليق متاحًا": <String>[
    "Could not open the image. The comment may no longer be available",
    "Impossible d’ouvrir l’image. Le commentaire n’est peut-être plus disponible"
  ],
  "تغيّر الحساب، أعد فتح العارض": <String>[
    "The account changed. Reopen the viewer",
    "Le compte a changé. Rouvrez la visionneuse"
  ],
  "تغيّر الحساب، أغلق العارض وأعد فتحه": <String>[
    "The account changed. Close and reopen the viewer",
    "Le compte a changé. Fermez et rouvrez la visionneuse"
  ],
  "تغيّر الوصول، أعد التحقق لتشغيل الفيديو": <String>[
    "Access changed. Verify access again to play the video",
    "Les droits d’accès ont changé. Vérifiez-les à nouveau pour lire la vidéo"
  ],
  "أعد التحقق لتشغيل الفيديو": <String>[
    "Verify access again to play the video",
    "Vérifiez à nouveau l’accès pour lire la vidéo"
  ],
  "يجب السماح بالوصول لألبوم الصور": <String>[
    "Allow access to your photo library",
    "Autorisez l’accès à votre photothèque"
  ],
  "يجب أن تكون الصورة غير فارغة وألا تتجاوز 20 ميغابايت": <String>[
    "The image must not be empty or exceed 20 MB",
    "L’image ne doit pas être vide ni dépasser 20 Mo"
  ],
  "يجب أن يكون المرفق غير فارغ وألا يتجاوز 40 ميغابايت": <String>[
    "The attachment must not be empty or exceed 40 MB",
    "La pièce jointe ne doit pas être vide ni dépasser 40 Mo"
  ],
  "صيغة المرفق غير مدعومة؛ اختر صورة أو فيديو آخر": <String>[
    "Unsupported attachment format. Choose another image or video",
    "Format non pris en charge. Choisissez une autre image ou vidéo"
  ],
  "تعذر رفع الصورة، حاول مجددًا": <String>[
    "Could not upload the image. Try again",
    "Impossible d’envoyer l’image. Réessayez"
  ],
  "اسحب للانتقال إلى منشور آخر": <String>[
    "Swipe to another post",
    "Balayez pour passer à une autre publication"
  ],
  "التفاصيل الكاملة": <String>["Full details", "Détails complets"],
  "حدد النص ثم انسخه": <String>[
    "Select the text, then copy it",
    "Sélectionnez le texte, puis copiez-le"
  ],
  "إجراءات الحساب": <String>["Account actions", "Actions du compte"],
  "إدارة إعدادات الحساب والخصوصية": <String>[
    "Manage account and privacy settings",
    "Gérer les paramètres du compte et de confidentialité"
  ],
  "إدارة طلبات المتابعة الجديدة": <String>[
    "Manage new follow requests",
    "Gérer les nouvelles demandes d’abonnement"
  ],
  "الخروج من حسابك الحالي": <String>[
    "Sign out of your current account",
    "Se déconnecter du compte actuel"
  ],
  "الخصوصية والأمان": <String>[
    "Privacy and security",
    "Confidentialité et sécurité"
  ],
  "الحساب والمجتمع": <String>["Account and community", "Compte et communauté"],
  "المظهر واللغة": <String>["Appearance and language", "Apparence et langue"],
  "تغيير لغة التطبيق": <String>[
    "Change app language",
    "Changer la langue de l’application"
  ],
  "معلومات عن UniSpace وإصدار التطبيق": <String>[
    "About UniSpace and the app version",
    "À propos d’UniSpace et de la version de l’application"
  ],
  "عن التطبيق": <String>["About", "À propos"],
  "مشاركة التطبيق": <String>["Share app", "Partager l’application"],
  "دع أصدقاءك يعرفون عن UniSpace": <String>[
    "Tell your friends about UniSpace",
    "Faites découvrir UniSpace à vos amis"
  ],
  "تقييم التطبيق": <String>["Rate the app", "Évaluer l’application"],
  "شاركنا رأيك حول UniSpace": <String>[
    "Share your feedback about UniSpace",
    "Donnez votre avis sur UniSpace"
  ],
  "خصص تجربتك داخل UniSpace": <String>[
    "Customize your UniSpace experience",
    "Personnalisez votre expérience UniSpace"
  ],
  "اختيار الإشعارات التي تريد استقبالها": <String>[
    "Choose which notifications to receive",
    "Choisir les notifications à recevoir"
  ],
  "هل تريد تسجيل الخروج من الحساب؟": <String>[
    "Sign out of your account?",
    "Voulez-vous vous déconnecter de votre compte ?"
  ],
  "خروج": <String>["Sign out", "Se déconnecter"],
  "حسب إعدادات النظام": <String>[
    "Follow system settings",
    "Selon les réglages du système"
  ],
  "تعديل الحساب": <String>["Edit account", "Modifier le compte"],
  "معلومات الحساب": <String>["Account information", "Informations du compte"],
  "معلومات إضافية": <String>[
    "Additional information",
    "Informations complémentaires"
  ],
  "مكان الإقامة": <String>["Location", "Lieu de résidence"],
  "العمل / الوظيفة": <String>["Work / occupation", "Travail / profession"],
  "عمل وروابط": <String>["Work and links", "Travail et liens"],
  "روابط": <String>["Links", "Liens"],
  "الجنس": <String>["Gender", "Genre"],
  "ذكر": <String>["Male", "Homme"],
  "أنثى": <String>["Female", "Femme"],
  "أفضل عدم القول": <String>["Prefer not to say", "Je préfère ne pas répondre"],
  "تاريخ الميلاد": <String>["Date of birth", "Date de naissance"],
  "المستوى / السنة": <String>["Level / year", "Niveau / année"],
  "السيرة": <String>["Bio", "Biographie"],
  "(CV) السيرة": <String>["Résumé (CV)", "Curriculum vitæ (CV)"],
  "واجهة السيرة قريباً": <String>[
    "Résumé page coming soon",
    "La page CV sera bientôt disponible"
  ],
  "لا توجد سيرة بعد": <String>[
    "No bio yet",
    "Aucune biographie pour le moment"
  ],
  "لا توجد معلومات": <String>["No information", "Aucune information"],
  "ضبط صورة الحساب": <String>[
    "Adjust profile photo",
    "Ajuster la photo de profil"
  ],
  "ضبط صورة الغلاف": <String>[
    "Adjust cover photo",
    "Ajuster la photo de couverture"
  ],
  "حساب": <String>["Account", "Compte"],
  "حسابات": <String>["Accounts", "Comptes"],
  "الأشخاص": <String>["People", "Personnes"],
  "متابعون": <String>["Followers", "Abonnés"],
  "متابَع": <String>["Following", "Abonné"],
  "ردّ المتابعة": <String>["Follow back", "S’abonner en retour"],
  "طلبات المتابعة": <String>["Follow requests", "Demandes d’abonnement"],
  "قبول": <String>["Accept", "Accepter"],
  "رفض": <String>["Reject", "Refuser"],
  "لا توجد طلبات": <String>["No requests", "Aucune demande"],
  "لا يوجد متابعون بعد": <String>[
    "No followers yet",
    "Aucun abonné pour le moment"
  ],
  "لا تتابع أحدًا بعد": <String>[
    "You are not following anyone yet",
    "Vous ne suivez encore personne"
  ],
  "عندما يتابعك أحد، سيظهر هنا": <String>[
    "People who follow you will appear here",
    "Les personnes qui vous suivent apparaîtront ici"
  ],
  "ابحث عن أشخاص وابدأ بمتابعتهم": <String>[
    "Find people and start following them",
    "Trouvez des personnes et commencez à les suivre"
  ],
  "إلغاء الطلب": <String>["Cancel request", "Annuler la demande"],
  "إلغاء المتابعة": <String>["Unfollow", "Se désabonner"],
  "إلغاء المتابعة؟": <String>["Unfollow?", "Se désabonner ?"],
  "تعذر تحديث المتابعة": <String>[
    "Could not update following",
    "Impossible de mettre à jour l’abonnement"
  ],
  "تعذر تحديث المتابعة. حاول مرة أخرى.": <String>[
    "Could not update following. Try again.",
    "Impossible de mettre à jour l’abonnement. Réessayez."
  ],
  "تعذر إلغاء المتابعة": <String>[
    "Could not unfollow",
    "Impossible de se désabonner"
  ],
  "تعذر تحميل طلبات المتابعة. إعادة المحاولة": <String>[
    "Could not load follow requests. Retry",
    "Impossible de charger les demandes d’abonnement. Réessayer"
  ],
  "تعذر تحميل منشورات الملف": <String>[
    "Could not load profile posts",
    "Impossible de charger les publications du profil"
  ],
  "هذا الحساب خاص": <String>["This account is private", "Ce compte est privé"],
  "تابع هذا الحساب لرؤية منشوراته.": <String>[
    "Follow this account to see its posts.",
    "Abonnez-vous à ce compte pour voir ses publications."
  ],
  "هذا الحساب غير متاح": <String>[
    "This account is unavailable",
    "Ce compte est indisponible"
  ],
  "هذه القائمة خاصة وفق إعدادات صاحب الحساب.": <String>[
    "This list is private under the account owner’s settings.",
    "Cette liste est privée selon les paramètres du propriétaire du compte."
  ],
  "تعذر التحقق من خصوصية الملف. حاول مجددًا.": <String>[
    "Could not verify profile privacy. Try again.",
    "Impossible de vérifier la confidentialité du profil. Réessayez."
  ],
  "تعذر عرض القائمة. قد تكون غير متاحة؛ حاول مجددًا.": <String>[
    "Could not display the list. It may be unavailable; try again.",
    "Impossible d’afficher la liste. Elle est peut-être indisponible ; réessayez."
  ],
  "وصلت إلى حد العرض الحالي لهذه القائمة.": <String>[
    "You have reached the current display limit for this list.",
    "Vous avez atteint la limite d’affichage actuelle de cette liste."
  ],
  "البحث يشمل الحسابات المحمّلة فقط.": <String>[
    "Search includes only loaded accounts.",
    "La recherche porte uniquement sur les comptes chargés."
  ],
  "لا توجد نتائج ضمن الحسابات المحمّلة": <String>[
    "No results among loaded accounts",
    "Aucun résultat parmi les comptes chargés"
  ],
  "نتائج الحسابات محدودة حاليًا؛ قد لا تشمل كل الحسابات المطابقة.": <String>[
    "Account results are currently limited and may not include all matches.",
    "Les résultats sont actuellement limités et peuvent ne pas inclure tous les comptes correspondants."
  ],
  "بحثت مرات كثيرة. انتظر دقيقة ثم أعد البحث عن الحسابات.": <String>[
    "Too many searches. Wait a minute before searching accounts again.",
    "Trop de recherches. Attendez une minute avant de rechercher à nouveau des comptes."
  ],
  "تعذر البحث عن الحسابات. حاول مرة أخرى.": <String>[
    "Could not search accounts. Try again.",
    "Impossible de rechercher des comptes. Réessayez."
  ],
  "تعذر إتمام البحث، حاول مجدداً": <String>[
    "Could not complete the search. Try again",
    "Impossible de terminer la recherche. Réessayez"
  ],
  "جرّب استخدام كلمات بحث مختلفة": <String>[
    "Try different search terms",
    "Essayez d’autres mots-clés"
  ],
  "ابحث بالاسم...": <String>["Search by name…", "Rechercher par nom…"],
  "الحسابات المحظورة": <String>["Blocked accounts", "Comptes bloqués"],
  "لا توجد حسابات محظورة": <String>[
    "No blocked accounts",
    "Aucun compte bloqué"
  ],
  "تعذر تحميل الحسابات المحظورة": <String>[
    "Could not load blocked accounts",
    "Impossible de charger les comptes bloqués"
  ],
  "ابحث في المحظورين": <String>[
    "Search blocked accounts",
    "Rechercher dans les comptes bloqués"
  ],
  "حساب محظور": <String>["Blocked account", "Compte bloqué"],
  "حظر الحساب؟": <String>["Block account?", "Bloquer le compte ?"],
  "لقد حظرت هذا الحساب": <String>[
    "You blocked this account",
    "Vous avez bloqué ce compte"
  ],
  "لقد حظرك هذا الحساب": <String>[
    "This account blocked you",
    "Ce compte vous a bloqué"
  ],
  "لا يمكن المراسلة بسبب الحظر": <String>[
    "Messaging is unavailable because of a block",
    "La messagerie est indisponible en raison d’un blocage"
  ],
  "لن تظهر منشوراته في فيدك. يمكنك إلغاء الحظر في أي وقت.": <String>[
    "Their posts will no longer appear in your feed. You can unblock them at any time.",
    "Ses publications n’apparaîtront plus dans votre fil. Vous pouvez le débloquer à tout moment."
  ],
  "لن تتمكن من مشاهدة منشوراته أو التفاعل معه.": <String>[
    "You will not be able to view their posts or interact with them.",
    "Vous ne pourrez plus voir ses publications ni interagir avec ce compte."
  ],
  "يمكنك حظر الحساب حتى لا يظهر لك.": <String>[
    "You can block the account to hide it from you.",
    "Vous pouvez bloquer le compte pour ne plus le voir."
  ],
  "تعذر حظر الحساب": <String>[
    "Could not block the account",
    "Impossible de bloquer le compte"
  ],
  "تعذر حظر الحساب، حاول مجددًا": <String>[
    "Could not block the account. Try again",
    "Impossible de bloquer le compte. Réessayez"
  ],
  "إلغاء الحظر؟": <String>["Unblock?", "Débloquer ?"],
  "تم إلغاء الحظر": <String>["Account unblocked", "Compte débloqué"],
  "تعذر إلغاء الحظر": <String>[
    "Could not unblock the account",
    "Impossible de débloquer le compte"
  ],
  "تعذر إلغاء الحظر، حاول مجددًا": <String>[
    "Could not unblock the account. Try again",
    "Impossible de débloquer le compte. Réessayez"
  ],
  "العناصر المخفية": <String>["Hidden items", "Éléments masqués"],
  "لا يوجد محتوى مخفي": <String>["No hidden content", "Aucun contenu masqué"],
  "لا توجد منشورات مخفية": <String>[
    "No hidden posts",
    "Aucune publication masquée"
  ],
  "لا توجد تعليقات مخفية": <String>[
    "No hidden comments",
    "Aucun commentaire masqué"
  ],
  "تعذر تحميل التعليقات المخفية": <String>[
    "Could not load hidden comments",
    "Impossible de charger les commentaires masqués"
  ],
  "تعذر تحميل المنشورات المخفية": <String>[
    "Could not load hidden posts",
    "Impossible de charger les publications masquées"
  ],
  "لا توجد منشورات غير معجب بها": <String>[
    "No disliked posts",
    "Aucune publication marquée Je n’aime pas"
  ],
  "لم يعجبني": <String>["Dislike", "Je n’aime pas"],
  "مخفي": <String>["Hidden", "Masqué"],
  "حذف الحساب": <String>["Delete account", "Supprimer le compte"],
  "حذف الحساب نهائياً": <String>[
    "Permanently delete account",
    "Supprimer définitivement le compte"
  ],
  "حذف نهائي للبيانات ولا يمكن التراجع عنه": <String>[
    "Permanently delete data. This cannot be undone",
    "Supprimer définitivement les données. Cette action est irréversible"
  ],
  "أكد هويتك قبل الحذف": <String>[
    "Confirm your identity before deletion",
    "Confirmez votre identité avant la suppression"
  ],
  "تأكيد والحذف": <String>["Confirm and delete", "Confirmer et supprimer"],
  "لا يمكن التراجع عن هذا الإجراء.": <String>[
    "This action cannot be undone.",
    "Cette action est irréversible."
  ],
  "تم حذف الحساب. يمكنك إنشاء حساب جديد بنفس البريد.": <String>[
    "Account deleted. You can create a new account with the same email.",
    "Compte supprimé. Vous pouvez créer un nouveau compte avec la même adresse e-mail."
  ],
  "انتهت الجلسة. سجّل الدخول ثم أعد محاولة الحذف.": <String>[
    "Your session expired. Sign in and try deleting again.",
    "Votre session a expiré. Connectez-vous et réessayez la suppression."
  ],
  "انتهت صلاحية الجلسة. سجّل الدخول من جديد ثم احذف الحساب مباشرة.": <String>[
    "Your session expired. Sign in again, then delete your account immediately.",
    "Votre session a expiré. Reconnectez-vous, puis supprimez immédiatement votre compte."
  ],
  "لا يمكن حذف هذا النوع من الحساب من التطبيق حالياً": <String>[
    "This type of account cannot currently be deleted from the app",
    "Ce type de compte ne peut pas être supprimé depuis l’application pour le moment"
  ],
  "كلمة المرور غير صحيحة": <String>[
    "Incorrect password",
    "Mot de passe incorrect"
  ],
  "فشلت إعادة المصادقة": <String>[
    "Reauthentication failed",
    "La réauthentification a échoué"
  ],
  "تم تعطيل هذا الحساب أو لم يعد موجودًا.": <String>[
    "This account has been disabled or no longer exists.",
    "Ce compte a été désactivé ou n’existe plus."
  ],
  "تعطيل الحساب": <String>["Disable account", "Désactiver le compte"],
  "تعطيل": <String>["Disable", "Désactiver"],
  "إخفاء حسابك مؤقتًا مع إمكانية العودة لاحقًا": <String>[
    "Temporarily hide your account and return later",
    "Masquer temporairement votre compte et revenir plus tard"
  ],
  "إعادة إظهار حسابك والعودة للاستخدام": <String>[
    "Make your account visible again and return",
    "Rendre votre compte visible à nouveau et revenir"
  ],
  "إلغاء التعطيل": <String>["Reactivate", "Réactiver"],
  "سيتم إخفاء حسابك مؤقتاً. يمكنك طلب إعادة التفعيل لاحقاً عبر الدعم أو بتسجيل الدخول إن سمحت بذلك لاحقاً.":
      <String>[
    "Your account will be temporarily hidden. You can request reactivation later through support or by signing in if that option is available.",
    "Votre compte sera temporairement masqué. Vous pourrez demander sa réactivation via l’assistance ou en vous connectant si cette option est disponible."
  ],
  "تبليغ": <String>["Report", "Signaler"],
  "تبليغ عن التعليق": <String>["Report comment", "Signaler le commentaire"],
  "تبليغ عن الحساب": <String>["Report account", "Signaler le compte"],
  "تبليغ عن حساب": <String>["Report an account", "Signaler un compte"],
  "تبليغ عن المنشور": <String>["Report post", "Signaler la publication"],
  "إرسال التبليغ": <String>["Send report", "Envoyer le signalement"],
  "تم إرسال التبليغ": <String>["Report sent", "Signalement envoyé"],
  "تعذر إرسال التبليغ": <String>[
    "Could not send the report",
    "Impossible d’envoyer le signalement"
  ],
  "سبق أن بلّغت": <String>[
    "You have already reported this",
    "Vous avez déjà signalé ce contenu"
  ],
  "تعذر التحقق من البلاغ السابق؛ أعد المحاولة": <String>[
    "Could not check the previous report. Try again",
    "Impossible de vérifier le signalement précédent. Réessayez"
  ],
  "لا يمكنك تبليغ محتواك": <String>[
    "You cannot report your own content",
    "Vous ne pouvez pas signaler votre propre contenu"
  ],
  "لن يعرف صاحب التعليق أنك بلّغت": <String>[
    "The comment author will not know you reported it",
    "L’auteur du commentaire ne saura pas que vous l’avez signalé"
  ],
  "لن يعرف صاحب الحساب أنك بلّغت": <String>[
    "The account owner will not know you reported them",
    "Le propriétaire du compte ne saura pas que vous l’avez signalé"
  ],
  "لن يعرف صاحب المنشور أنك بلّغت": <String>[
    "The post author will not know you reported it",
    "L’auteur de la publication ne saura pas que vous l’avez signalée"
  ],
  "تفاصيل إضافية (اختياري)": <String>[
    "Additional details (optional)",
    "Détails supplémentaires (facultatif)"
  ],
  "اكتب سبب التبليغ...": <String>[
    "Describe the reason for your report…",
    "Décrivez le motif du signalement…"
  ],
  "مضايقة": <String>["Harassment", "Harcèlement"],
  "مضايقة أو تنمّر": <String>[
    "Harassment or bullying",
    "Harcèlement ou intimidation"
  ],
  "إساءة أو تنمّر": <String>["Abuse or bullying", "Abus ou intimidation"],
  "خطاب كراهية": <String>["Hate speech", "Discours haineux"],
  "حساب وهمي": <String>["Fake account", "Faux compte"],
  "حساب وهمي أو مزيف": <String>[
    "Fake or fraudulent account",
    "Compte faux ou frauduleux"
  ],
  "انتحال شخصية": <String>["Impersonation", "Usurpation d’identité"],
  "محتوى غير لائق": <String>["Inappropriate content", "Contenu inapproprié"],
  "صورة أو معلومات غير لائقة": <String>[
    "Inappropriate image or information",
    "Image ou informations inappropriées"
  ],
  "معلومات غير لائقة": <String>[
    "Inappropriate information",
    "Informations inappropriées"
  ],
  "إعلان أو سبام": <String>["Advertising or spam", "Publicité ou spam"],
  "إعلانات أو سبام": <String>["Advertising or spam", "Publicité ou spam"],
  "مخالفة أكاديمية": <String>[
    "Academic misconduct",
    "Manquement à l’intégrité académique"
  ],
  "غش أو بيع حلول": <String>[
    "Cheating or selling answers",
    "Triche ou vente de corrigés"
  ],
  "تسريب امتحان أو فرض": <String>[
    "Leaked exam or test",
    "Fuite d’examen ou de devoir"
  ],
  "معلومات دراسية مضللة": <String>[
    "Misleading academic information",
    "Informations académiques trompeuses"
  ],
  "مراجعة التبليغات": <String>["Review reports", "Examiner les signalements"],
  "إدارة البلاغات الواردة من المجتمع": <String>[
    "Manage community reports",
    "Gérer les signalements de la communauté"
  ],
  "ابحث في البلاغات المحمّلة باسم صاحب المحتوى...": <String>[
    "Search loaded reports by content owner…",
    "Rechercher dans les signalements chargés par propriétaire du contenu…"
  ],
  "البحث وترتيب الأولوية ضمن البلاغات المحمّلة": <String>[
    "Search and prioritize loaded reports",
    "Rechercher et hiérarchiser les signalements chargés"
  ],
  "معلّق": <String>["Pending", "En attente"],
  "مرفوض": <String>["Dismissed", "Rejeté"],
  "مستعاد": <String>["Restored", "Restauré"],
  "لا توجد تبليغات معلّقة حاليًا 🎉": <String>[
    "No pending reports right now 🎉",
    "Aucun signalement en attente pour le moment 🎉"
  ],
  "لا توجد تبليغات مرفوضة": <String>[
    "No dismissed reports",
    "Aucun signalement rejeté"
  ],
  "لا توجد محتويات مستعادة": <String>[
    "No restored content",
    "Aucun contenu restauré"
  ],
  "تعذر تحميل البلاغات أو لم تعد لديك صلاحية الوصول": <String>[
    "Could not load reports, or you no longer have access",
    "Impossible de charger les signalements, ou vous n’y avez plus accès"
  ],
  "تعذر تحديد المحتوى المبلَّغ عنه": <String>[
    "Could not identify the reported content",
    "Impossible d’identifier le contenu signalé"
  ],
  "تعذر عرض النتائج أو ليست لديك صلاحية الوصول": <String>[
    "Could not show results, or you do not have access",
    "Impossible d’afficher les résultats, ou vous n’y avez pas accès"
  ],
  "تعذر تنفيذ إجراء الإشراف": <String>[
    "Could not perform the moderation action",
    "Impossible d’effectuer l’action de modération"
  ],
  "تغيّرت حالة البلاغ أو تعذر تنفيذ الإجراء؛ افتح البلاغ مجدداً": <String>[
    "The report status changed or the action failed. Reopen the report",
    "L’état du signalement a changé ou l’action a échoué. Rouvrez le signalement"
  ],
  "إخفاء للجميع": <String>["Hide for everyone", "Masquer pour tout le monde"],
  "إخفاء للجميع؟": <String>[
    "Hide for everyone?",
    "Masquer pour tout le monde ?"
  ],
  "سيتم إخفاء هذا التعليق عن كل المستخدمين.": <String>[
    "This comment will be hidden from all users.",
    "Ce commentaire sera masqué pour tous les utilisateurs."
  ],
  "سيتم إخفاء هذا المنشور عن كل المستخدمين.": <String>[
    "This post will be hidden from all users.",
    "Cette publication sera masquée pour tous les utilisateurs."
  ],
  "تم إخفاء التعليق للجميع": <String>[
    "Comment hidden for everyone",
    "Commentaire masqué pour tout le monde"
  ],
  "تم إخفاء المنشور للجميع": <String>[
    "Post hidden for everyone",
    "Publication masquée pour tout le monde"
  ],
  "رفض التبليغ": <String>["Dismiss report", "Rejeter le signalement"],
  "تم رفض التبليغ": <String>["Report dismissed", "Signalement rejeté"],
  "استعادة المحتوى": <String>["Restore content", "Restaurer le contenu"],
  "تمت استعادة المحتوى": <String>["Content restored", "Contenu restauré"],
  "تراجع: إعادة فتح التبليغ": <String>[
    "Undo: reopen report",
    "Annuler : rouvrir le signalement"
  ],
  "أُعيد فتح التبليغ": <String>["Report reopened", "Signalement rouvert"],
  "تعذر فتح المناقشة؛ استخدم معاينة البلاغ للمراجعة": <String>[
    "Could not open the discussion. Use the report preview to review it",
    "Impossible d’ouvrir la discussion. Utilisez l’aperçu du signalement pour l’examiner"
  ],
  "استطلاع": <String>["Poll", "Sondage"],
  "أسئلة": <String>["Questions", "Questions"],
  "ردود الاستطلاع": <String>["Poll responses", "Réponses au sondage"],
  "اكتب إجابتك هنا...": <String>[
    "Write your answer here…",
    "Écrivez votre réponse ici…"
  ],
  "اختر خياراً...": <String>["Choose an option…", "Choisissez une option…"],
  "يجب الإجابة على جميع الأسئلة الإلزامية أولاً": <String>[
    "Answer all required questions first",
    "Répondez d’abord à toutes les questions obligatoires"
  ],
  "لا يمكن الحفظ بدون وجود سؤال بول": <String>[
    "Cannot save without a poll question",
    "Impossible d’enregistrer sans question de sondage"
  ],
  "لا يمكن الحفظ، أضف سؤالاً واحداً على الأقل": <String>[
    "Add at least one question before saving",
    "Ajoutez au moins une question avant d’enregistrer"
  ],
  "راجع الإجابات والأسئلة الإلزامية، ثم أعد المحاولة": <String>[
    "Check your answers and the required questions, then try again",
    "Vérifiez vos réponses et les questions obligatoires, puis réessayez"
  ],
  "تم إرسال الإجابات": <String>["Answers submitted", "Réponses envoyées"],
  "تعذر إرسال الإجابات": <String>[
    "Could not submit answers",
    "Impossible d’envoyer les réponses"
  ],
  " إجابة محمّلة": <String>[" loaded responses", " réponses chargées"],
  " إجابة محمّلة — الملخص جزئي": <String>[
    " loaded responses — partial summary",
    " réponses chargées — résumé partiel"
  ],
  "الأيام المسموحة": <String>["Allowed days", "Jours autorisés"],
  "اضغط يوماً لإضافته أو إزالته": <String>[
    "Tap a day to add or remove it",
    "Touchez un jour pour l’ajouter ou le retirer"
  ],
  "تحديد الأيام": <String>["Select days", "Choisir les jours"],
  "السنة": <String>["Year", "Année"],
  "اختيار وقت": <String>["Choose time", "Choisir l’heure"],
  "تغيير الوقت": <String>["Change time", "Modifier l’heure"],
  "لم يُحدَّد تاريخ": <String>["No date selected", "Aucune date sélectionnée"],
  "مثال: [1/2-1/20] = من 2 يناير إلى 20 يناير": <String>[
    "Example: [1/2-1/20] = January 2 to January 20",
    "Exemple : [1/2-1/20] = du 2 janvier au 20 janvier"
  ],
  "يناير": <String>["January", "Janvier"],
  "فبراير": <String>["February", "Février"],
  "مارس": <String>["March", "Mars"],
  "أبريل": <String>["April", "Avril"],
  "مايو": <String>["May", "Mai"],
  "يونيو": <String>["June", "Juin"],
  "يوليو": <String>["July", "Juillet"],
  "أغسطس": <String>["August", "Août"],
  "سبتمبر": <String>["September", "Septembre"],
  "أكتوبر": <String>["October", "Octobre"],
  "نوفمبر": <String>["November", "Novembre"],
  "ديسمبر": <String>["December", "Décembre"],
  "متصل": <String>["Online", "En ligne"],
  "آخر ظهور الآن": <String>["Last seen just now", "Vu à l’instant"],
  "آخر ظهور أمس": <String>["Last seen yesterday", "Vu hier"],
  "اسأل الذكاء الاصطناعي...": <String>["Ask AI…", "Demandez à l’IA…"],
  "الذكاء الاصطناعي يفكر...": <String>["AI is thinking…", "L’IA réfléchit…"],
  "مشاركة رأي من المجتمع": <String>[
    "Share a community opinion",
    "Partager un avis de la communauté"
  ],
  "ما رأيك؟": <String>["What do you think?", "Qu’en pensez-vous ?"],
  "محتوى موثّق": <String>["Verified content", "Contenu vérifié"],
  "لا توجد بيانات للشبكة": <String>["No network data", "Aucune donnée réseau"],
  "تواصل": <String>["Contact", "Contact"],
  "توجيه": <String>["Guidance", "Orientation"],
  "شخصية": <String>["Personal", "Personnel"],
  "الأخيرة": <String>["Recent", "Récent"],
  "منشور": <String>["Post", "Publication"],
  "منشورات": <String>["Posts", "Publications"],
  "مواد": <String>["Subjects", "Matières"],
  "المزيد": <String>["More", "Plus"],
  "المعرّف": <String>["Username", "Nom d’utilisateur"],
  "البريد": <String>["Email", "E-mail"],
  "رقم الهاتف": <String>["Phone number", "Numéro de téléphone"],
  "الإعدادات": <String>["Settings", "Paramètres"],
  "بحث": <String>["Search", "Rechercher"],
  "فتح": <String>["Open", "Ouvrir"],
  "تحميل المزيد": <String>["Load more", "Charger plus"],
  "أنشئ أول منشور": <String>[
    "Create your first post",
    "Créez votre première publication"
  ],
  "استكشف": <String>["Explore", "Explorer"],
  "تم": <String>["Done", "Terminé"],
  "رجوع": <String>["Back", "Retour"],
  "رد": <String>["Reply", "Répondre"],
  "خطأ": <String>["Error", "Erreur"],
  "غير مصرّح": <String>["Unauthorized", "Non autorisé"],
  "حدث خطأ غير متوقع": <String>[
    "An unexpected error occurred",
    "Une erreur inattendue s’est produite"
  ],
  "تعذر تحميل القائمة": <String>[
    "Could not load the list",
    "Impossible de charger la liste"
  ],
  "تعذر تحميل المحتوى": <String>[
    "Could not load content",
    "Impossible de charger le contenu"
  ],
  "تعذر فتح المتجر": <String>[
    "Could not open the store",
    "Impossible d’ouvrir la boutique"
  ],
  "تعذر التحقق من عرض المنشور": <String>[
    "Could not verify access to the post",
    "Impossible de vérifier l’accès à la publication"
  ],
  "تعذر تأكيد صلاحية عرض المنشور": <String>[
    "Could not verify permission to view the post",
    "Impossible de vérifier l’autorisation de consulter la publication"
  ],
  "تعذر عرض المنشور. قد يكون محذوفًا أو غير متاح لك.": <String>[
    "Could not show the post. It may have been deleted or be unavailable to you.",
    "Impossible d’afficher la publication. Elle a peut-être été supprimée ou ne vous est pas accessible."
  ],
  "انتهت الجلسة. سجّل الدخول ثم أعد المحاولة.": <String>[
    "Your session expired. Sign in and try again.",
    "Votre session a expiré. Connectez-vous et réessayez."
  ],
  "تغيّر الحساب": <String>["Account changed", "Le compte a changé"],
  "أعد فتح القائمة بعد تسجيل الدخول.": <String>[
    "Reopen the list after signing in.",
    "Rouvrez la liste après vous être connecté."
  ],
  "سجّل الدخول للوصول إلى حسابك": <String>[
    "Sign in to access your account",
    "Connectez-vous pour accéder à votre compte"
  ],
  "مستخدم UniSpace": <String>["UniSpace user", "Utilisateur UniSpace"],
  "هذا الحساب": <String>["This account", "Ce compte"],
  "محظور": <String>["Blocked", "Bloqué"],
  "إشعارات UniSpace": <String>[
    "UniSpace notifications",
    "Notifications UniSpace"
  ],
  "متابعة، تعليقات، إعجابات": <String>[
    "Follows, comments, likes",
    "Abonnements, commentaires, J’aime"
  ],
  "اChoose from the list": <String>[
    "Choose from the list",
    "Choisir dans la liste"
  ],
  " — إعادة المحاولة": <String>[" — Retry", " — Réessayer"],
  "مجتمع": <String>["Community", "Communauté"],
  "، ": <String>[", ", ", "],
  " المنشور: {0}": <String>[" Post: {0}", " Publication : {0}"],
  "— {0} على UniSpace": <String>["— {0} on UniSpace", "— {0} sur UniSpace"],
  "{0}ي": <String>["{0}d", "{0}j"],
  "{0}س": <String>["{0}h", "{0}h"],
  "{0}د": <String>["{0}m", "{0}min"],
  "{0} ي": <String>["{0} d", "{0} j"],
  "{0} س": <String>["{0} h", "{0} h"],
  "{0} د": <String>["{0} min", "{0} min"],
  "{0} حرف": <String>["{0} characters", "{0} caractères"],
  "{0} يوم ضمن المجال": <String>[
    "{0} days in range",
    "{0} jours dans la plage"
  ],
  "{0} يوم محدد": <String>["{0} days selected", "{0} jours sélectionnés"],
  "{0}، اسم المستخدم {1}": <String>[
    "{0}, username {1}",
    "{0}, nom d’utilisateur {1}"
  ],
  "آخر ظهور منذ {0}ي": <String>["Last seen {0}d ago", "Vu il y a {0} j"],
  "آخر ظهور منذ {0}س": <String>["Last seen {0}h ago", "Vu il y a {0} h"],
  "آخر ظهور منذ {0}د": <String>["Last seen {0}min ago", "Vu il y a {0} min"],
  "أدخل كلمة مرور {0}": <String>[
    "Enter the password for {0}",
    "Saisissez le mot de passe de {0}"
  ],
  "بحث في منشورات وتعليقات {0}...": <String>[
    "Search posts and comments by {0}…",
    "Rechercher dans les publications et commentaires de {0}…"
  ],
  "تحميل ({0})": <String>["Download ({0})", "Télécharger ({0})"],
  "تعذر إرسال التبليغ ({0})": <String>[
    "Could not send report ({0})",
    "Impossible d’envoyer le signalement ({0})"
  ],
  "تعذر إعادة التفعيل: {0}": <String>[
    "Could not reactivate: {0}",
    "Réactivation impossible : {0}"
  ],
  "تعذر إعادة تفعيل الحساب: {0}": <String>[
    "Could not reactivate account: {0}",
    "Impossible de réactiver le compte : {0}"
  ],
  "تعذر التعطيل: {0}": <String>[
    "Could not disable account: {0}",
    "Impossible de désactiver le compte : {0}"
  ],
  "تعذر الحظر: {0}": <String>[
    "Could not block account: {0}",
    "Impossible de bloquer le compte : {0}"
  ],
  "تعذر الحفظ: {0}": <String>[
    "Could not save: {0}",
    "Enregistrement impossible : {0}"
  ],
  "تعذر تأكيد Google: {0}": <String>[
    "Could not verify Google sign-in: {0}",
    "Impossible de vérifier la connexion Google : {0}"
  ],
  "تعذر حذف الحساب ({0})": <String>[
    "Could not delete account ({0})",
    "Impossible de supprimer le compte ({0})"
  ],
  "تعذر حذف الحساب: {0}": <String>[
    "Could not delete account: {0}",
    "Impossible de supprimer le compte : {0}"
  ],
  "تعليق على: {0}": <String>["Comment on: {0}", "Commentaire sur : {0}"],
  "تعليق لـ {0}": <String>["Comment by {0}", "Commentaire de {0}"],
  "تفاصيل المُبلِّغ: {0}": <String>[
    "Reporter’s details: {0}",
    "Détails du signalement : {0}"
  ],
  "تلقائي: {0} مبلّغ · نقاط {1} · {2}٪ من المشاهدين": <String>[
    "Automatic: {0} reporters · score {1} · {2}% of viewers",
    "Automatique : {0} signalements · score {1} · {2} % des vues"
  ],
  "تلقائي: {0} مبلّغ · نقاط {1}": <String>[
    "Automatic: {0} reporters · score {1}",
    "Automatique : {0} signalements · score {1}"
  ],
  "تم إلغاء حظر {0}": <String>["{0} unblocked", "{0} a été débloqué"],
  "تم حظر {0}": <String>["{0} blocked", "{0} a été bloqué"],
  "تم حفظ {0} ملفات، وتعذر إكمال الباقي": <String>[
    "Saved {0} files; the remaining files could not be saved",
    "{0} fichiers enregistrés ; les autres n’ont pas pu être enregistrés"
  ],
  "تم حفظ {0} ملفات": <String>["Saved {0} files", "{0} fichiers enregistrés"],
  "حدث خطأ أثناء البحث\n{0}": <String>[
    "An error occurred while searching\n{0}",
    "Une erreur s’est produite pendant la recherche\n{0}"
  ],
  "حظر {0}": <String>["Block {0}", "Bloquer {0}"],
  "رد على {0}": <String>["Reply to {0}", "Répondre à {0}"],
  "ستظهر منشورات {0} في الفيد مجددًا.": <String>[
    "Posts from {0} will appear in your feed again.",
    "Les publications de {0} réapparaîtront dans votre fil."
  ],
  "ستظهر منشورات {0} في الفيد، ويمكنكما المتابعة مجدداً.": <String>[
    "Posts from {0} will appear in your feed, and you can follow each other again.",
    "Les publications de {0} apparaîtront dans votre fil et vous pourrez à nouveau vous suivre."
  ],
  "صاحب المحتوى: {0}": <String>[
    "Content owner: {0}",
    "Propriétaire du contenu : {0}"
  ],
  "على: {0}": <String>["On: {0}", "Sur : {0}"],
  "قراءة أحدث {0}": <String>["Read the latest {0}", "Lire les {0} dernières"],
  "لا توجد نتائج لـ \"{0}\"": <String>[
    "No results for “{0}”",
    "Aucun résultat pour « {0} »"
  ],
  "لم أجد منشورات في المجتمع حول \"{0}\".": <String>[
    "No community posts found about “{0}”.",
    "Aucune publication de la communauté trouvée sur « {0} »."
  ],
  "لن تظهر منشورات {0} في فيدك بعد الآن. يمكنك إلغاء الحظر لاحقًا من الإعدادات.":
      <String>[
    "Posts from {0} will no longer appear in your feed. You can unblock them later in settings.",
    "Les publications de {0} n’apparaîtront plus dans votre fil. Vous pourrez débloquer ce compte dans les paramètres."
  ],
  "لن تظهر منشورات وتعليقات {0} بعد الآن.": <String>[
    "Posts and comments from {0} will no longer appear.",
    "Les publications et commentaires de {0} n’apparaîtront plus."
  ],
  "لن يظهر {0} في قائمة المتابَعين.": <String>[
    "{0} will no longer appear in your following list.",
    "{0} n’apparaîtra plus dans votre liste d’abonnements."
  ],
  "لن يعرف {0} أنك بلّغت. {1}": <String>[
    "{0} will not know you reported them. {1}",
    "{0} ne saura pas que vous avez effectué un signalement. {1}"
  ],
  "ملخص من منشورات المجتمع حول \"{0}\":\n": <String>[
    "Summary of community posts about “{0}”:\n",
    "Résumé des publications de la communauté sur « {0} » :\n"
  ],
  "منذ {0}ش": <String>["{0}mo ago", "il y a {0} mois"],
  "منذ {0}سنة": <String>["{0}y ago", "il y a {0} ans"],
  "منذ {0}أ": <String>["{0}w ago", "il y a {0} sem."],
  "منذ {0}ي": <String>["{0}d ago", "il y a {0} j"],
  "منذ {0}س": <String>["{0}h ago", "il y a {0} h"],
  "منذ {0}د": <String>["{0}min ago", "il y a {0} min"],
  "منذ {0}ث": <String>["{0}s ago", "il y a {0} s"],
  "و{0} آخرين أعجبوا بتعليقك": <String>[
    "and {0} others liked your comment",
    "et {0} autres ont aimé votre commentaire"
  ],
  "و{0} آخرين أعجبوا بمنشورك": <String>[
    "and {0} others liked your post",
    "et {0} autres ont aimé votre publication"
  ],
  "و{0} أعجبا بتعليقك": <String>[
    "and {0} liked your comment",
    "et {0} ont aimé votre commentaire"
  ],
  "و{0} أعجبا بمنشورك": <String>[
    "and {0} liked your post",
    "et {0} ont aimé votre publication"
  ],
  "سيتم حذف حسابك من التطبيق. المنشورات القديمة قد تبقى إلى أن تُنظَّف لاحقاً من الخادم.\n\n":
      <String>[
    "Your account will be deleted from the app. Older posts may remain until they are cleaned up on the server.\n\n",
    "Votre compte sera supprimé de l’application. Les anciennes publications peuvent rester jusqu’à leur suppression ultérieure sur le serveur.\n\n"
  ],
  "الفرنسية": <String>["French", "Français"],
  "الإنجليزية": <String>["English", "Anglais"],
  "Profile": <String>["Profile", "Profil", "الملف الشخصي"],
  "Chat": <String>["Chat", "Discussion", "المحادثة"],
  "Settings": <String>["Settings", "Paramètres", "الإعدادات"],
  "Main color": <String>["Main color", "Couleur principale", "اللون الرئيسي"],
  "The app main color": <String>[
    "The app main color",
    "Couleur principale de l’application",
    "اللون الرئيسي للتطبيق"
  ],
  "Chose the app main color as you like": <String>[
    "Chose the app main color as you like",
    "Choisissez la couleur principale de l’application",
    "اختر اللون الرئيسي للتطبيق"
  ],
  "Sub color": <String>["Sub color", "Couleur secondaire", "اللون الثانوي"],
  "the app sub color": <String>[
    "the app sub color",
    "Couleur secondaire de l’application",
    "اللون الثانوي للتطبيق"
  ],
  "Chose the app sub color as you like": <String>[
    "Chose the app sub color as you like",
    "Choisissez la couleur secondaire de l’application",
    "اختر اللون الثانوي للتطبيق"
  ],
  "Welcome to UniSpace where we all meet": <String>[
    "Welcome to UniSpace where we all meet",
    "Bienvenue sur UniSpace, notre espace de rencontre",
    "مرحبًا بك في UniSpace حيث نلتقي جميعًا"
  ],
  "Noting to show.": <String>[
    "Noting to show.",
    "Rien à afficher.",
    "لا يوجد شيء لعرضه."
  ],
  "Add choice": <String>["Add choice", "Ajouter un choix", "إضافة خيار"],
  "Add column": <String>["Add column", "Ajouter une colonne", "إضافة عمود"],
  "Add row": <String>["Add row", "Ajouter une ligne", "إضافة صف"],
  "Add image": <String>["Add image", "Ajouter une image", "إضافة صورة"],
  "Allow multiple days": <String>[
    "Allow multiple days",
    "Autoriser plusieurs jours",
    "السماح بعدة أيام"
  ],
  "Assessement on a graded scale": <String>[
    "Assessement on a graded scale",
    "Évaluation sur une échelle graduée",
    "تقييم على مقياس متدرج"
  ],
  "Can choose many answers": <String>[
    "Can choose many answers",
    "Plusieurs réponses possibles",
    "يمكن اختيار عدة إجابات"
  ],
  "Can choose only one answer": <String>[
    "Can choose only one answer",
    "Une seule réponse possible",
    "يمكن اختيار إجابة واحدة"
  ],
  "Checkbox": <String>["Checkbox", "Cases à cocher", "مربعات اختيار"],
  "Checkboxes": <String>["Checkboxes", "Cases à cocher", "مربعات اختيار"],
  "Checkbox grid": <String>[
    "Checkbox grid",
    "Grille de cases à cocher",
    "شبكة مربعات اختيار"
  ],
  "Choose": <String>["Choose", "Choisir", "اختر"],
  "choose a poll": <String>[
    "choose a poll",
    "Choisissez un sondage",
    "اختر استطلاعًا"
  ],
  "Choose a day a month or a year": <String>[
    "Choose a day a month or a year",
    "Choisissez un jour, un mois ou une année",
    "اختر يومًا أو شهرًا أو سنة"
  ],
  "choose a specific time": <String>[
    "choose a specific time",
    "Choisissez une heure précise",
    "اختر وقتًا محددًا"
  ],
  "Column option": <String>[
    "Column option",
    "Option de colonne",
    "خيار العمود"
  ],
  "Columns": <String>["Columns", "Colonnes", "الأعمدة"],
  "Create a Poll": <String>[
    "Create a Poll",
    "Créer un sondage",
    "إنشاء استطلاع"
  ],
  "Date": <String>["Date", "Date", "التاريخ"],
  "Dropdowen": <String>["Dropdowen", "Liste déroulante", "قائمة منسدلة"],
  "Dropdown": <String>["Dropdown", "Liste déroulante", "قائمة منسدلة"],
  "Duplicate": <String>["Duplicate", "Dupliquer", "تكرار"],
  "Emoji": <String>["Emoji", "Émoji", "رمز تعبيري"],
  "Grid": <String>["Grid", "Grille", "شبكة"],
  "High": <String>["High", "Élevé", "مرتفع"],
  "Include time": <String>["Include time", "Inclure l’heure", "تضمين الوقت"],
  "Individual": <String>["Individual", "Individuel", "فردي"],
  "Labels": <String>["Labels", "Libellés", "التسميات"],
  "Levels": <String>["Levels", "Niveaux", "المستويات"],
  "lienear scale": <String>["lienear scale", "Échelle linéaire", "مقياس خطي"],
  "Line": <String>["Line", "Ligne", "خط"],
  "Linear scale": <String>["Linear scale", "Échelle linéaire", "مقياس خطي"],
  "Long answer text": <String>[
    "Long answer text",
    "Réponse longue",
    "نص إجابة طويلة"
  ],
  "Long text": <String>["Long text", "Texte long", "نص طويل"],
  "Max label": <String>["Max label", "Libellé du maximum", "تسمية الحد الأقصى"],
  "Min label": <String>["Min label", "Libellé du minimum", "تسمية الحد الأدنى"],
  "Months": <String>["Months", "Mois", "الأشهر"],
  "Multi lines answer": <String>[
    "Multi lines answer",
    "Réponse sur plusieurs lignes",
    "إجابة متعددة الأسطر"
  ],
  "Neutral": <String>["Neutral", "Neutre", "محايد"],
  "No answer": <String>["No answer", "Aucune réponse", "لا توجد إجابة"],
  "No answers yet": <String>[
    "No answers yet",
    "Aucune réponse pour le moment",
    "لا توجد إجابات بعد"
  ],
  "No grid data": <String>[
    "No grid data",
    "Aucune donnée de grille",
    "لا توجد بيانات للشبكة"
  ],
  "No numeric answers": <String>[
    "No numeric answers",
    "Aucune réponse numérique",
    "لا توجد إجابات رقمية"
  ],
  "No options": <String>["No options", "Aucune option", "لا توجد خيارات"],
  "No responses yet": <String>[
    "No responses yet",
    "Aucune réponse pour le moment",
    "لا توجد ردود بعد"
  ],
  "No text answers yet": <String>[
    "No text answers yet",
    "Aucune réponse textuelle pour le moment",
    "لا توجد إجابات نصية بعد"
  ],
  "Numbers": <String>["Numbers", "Nombres", "أرقام"],
  "One line answer": <String>[
    "One line answer",
    "Réponse sur une ligne",
    "إجابة من سطر واحد"
  ],
  "Option": <String>["Option", "Option", "خيار"],
  "Options": <String>["Options", "Options", "الخيارات"],
  "Paragraph": <String>["Paragraph", "Paragraphe", "فقرة"],
  "Pictures": <String>["Pictures", "Images", "صور"],
  "Picturs": <String>["Picturs", "Images", "صور"],
  "Poll": <String>["Poll", "Sondage", "استطلاع"],
  "Poll responses": <String>[
    "Poll responses",
    "Réponses au sondage",
    "إجابات الاستطلاع"
  ],
  "Preview": <String>["Preview", "Aperçu", "معاينة"],
  "Question": <String>["Question", "Question", "سؤال"],
  "Ranges": <String>["Ranges", "Plages", "نطاقات"],
  "Required": <String>["Required", "Obligatoire", "مطلوب"],
  "Restrict by": <String>["Restrict by", "Limiter par", "تقييد حسب"],
  "Restricted": <String>["Restricted", "Limité", "مقيّد"],
  "Row option": <String>["Row option", "Option de ligne", "خيار الصف"],
  "Rows": <String>["Rows", "Lignes", "الصفوف"],
  "Select days": <String>[
    "Select days",
    "Sélectionner les jours",
    "اختر الأيام"
  ],
  "Short answer": <String>["Short answer", "Réponse courte", "إجابة قصيرة"],
  "Short answer text": <String>[
    "Short answer text",
    "Réponse courte",
    "نص إجابة قصيرة"
  ],
  "Short text": <String>["Short text", "Texte court", "نص قصير"],
  "Singel optin": <String>["Singel optin", "Choix unique", "خيار واحد"],
  "Singel optin grid": <String>[
    "Singel optin grid",
    "Grille à choix unique",
    "شبكة اختيار واحد"
  ],
  "Singel option": <String>["Singel option", "Choix unique", "خيار واحد"],
  "Slider": <String>["Slider", "Curseur", "شريط تمرير"],
  "Specific days": <String>["Specific days", "Jours précis", "أيام محددة"],
  "Stars": <String>["Stars", "Étoiles", "نجوم"],
  "Style": <String>["Style", "Style", "النمط"],
  "Submit answers": <String>[
    "Submit answers",
    "Envoyer les réponses",
    "إرسال الإجابات"
  ],
  "Summary": <String>["Summary", "Résumé", "الملخص"],
  "Tags": <String>["Tags", "Étiquettes", "الوسوم"],
  "Text": <String>["Text", "Texte", "نص"],
  "Time": <String>["Time", "Heure", "الوقت"],
  "Title": <String>["Title", "Titre", "العنوان"],
  "Vedios": <String>["Vedios", "Vidéos", "فيديوهات"],
  "Video": <String>["Video", "Vidéo", "فيديو"],
  "Videos": <String>["Videos", "Vidéos", "فيديوهات"],
  "Write your text...": <String>[
    "Write your text...",
    "Écrivez votre texte…",
    "اكتب نصك..."
  ],
  "Year": <String>["Year", "Année", "السنة"],
  "Your answer": <String>["Your answer", "Votre réponse", "إجابتك"],
  "Add Comment": <String>[
    "Add Comment",
    "Ajouter un commentaire",
    "إضافة تعليق"
  ],
  "Comments": <String>["Comments", "Commentaires", "التعليقات"],
  "Deep Replies": <String>[
    "Deep Replies",
    "Réponses imbriquées",
    "الردود المتفرعة"
  ],
  "Enter your comment": <String>[
    "Enter your comment",
    "Saisissez votre commentaire",
    "أدخل تعليقك"
  ],
  "edited": <String>["edited", "modifié", "معدّل"],
  "Replying to ": <String>["Replying to ", "Réponse à ", "الرد على "],
  "Search comments...": <String>[
    "Search comments...",
    "Rechercher des commentaires…",
    "البحث في التعليقات..."
  ],
  "Copy link": <String>["Copy link", "Copier le lien", "نسخ الرابط"],
  "Edit profile": <String>[
    "Edit profile",
    "Modifier le profil",
    "تعديل الملف الشخصي"
  ],
  "Following": <String>["Following", "Abonnements", "يتابع"],
  "Free date": <String>["Free date", "Date libre", "تاريخ حر"],
  "Profile info": <String>[
    "Profile info",
    "Informations du profil",
    "معلومات الملف الشخصي"
  ],
  "Posts": <String>["Posts", "Publications", "المنشورات"],
  "Share to": <String>["Share to", "Partager vers", "مشاركة عبر"],
  "Repost": <String>["Repost", "Republier", "إعادة نشر"],
  "Reposted": <String>["Reposted", "Republié", "أُعيد نشره"],
  "noResultsFound": <String>[
    "noResultsFound",
    "Aucun résultat",
    "لا توجد نتائج"
  ],
  "Portfolio": <String>["Portfolio", "Portfolio", "معرض الأعمال"],
  "Image": <String>["Image", "Image", "صورة"],
  "Low": <String>["Low", "Faible", "منخفض"],
  "Post": <String>["Post", "Publier", "نشر"],
  "Edited": <String>["Edited", "Modifié", "معدّل"],
  "AI": <String>["AI", "IA", "ذكاء اصطناعي"],
  "Cancel": <String>["Cancel", "Annuler", "إلغاء"],
  "Save": <String>["Save", "Enregistrer", "حفظ"],
  "cancel": <String>["cancel", "Annuler", "إلغاء"],
  "save": <String>["save", "Enregistrer", "حفظ"],
  "edit": <String>["edit", "Modifier", "تعديل"],
  "Confirm & Submit": <String>[
    "Confirm & Submit",
    "Confirmer et envoyer",
    "تأكيد وإرسال"
  ],
  "Body ...what you think about this comment?": <String>[
    "Body ...what you think about this comment?",
    "Que pensez-vous de ce commentaire ?",
    "ما رأيك في هذا التعليق؟"
  ],
  "Body ...what you think of about this post?": <String>[
    "Body ...what you think of about this post?",
    "Que pensez-vous de cette publication ?",
    "ما رأيك في هذا المنشور؟"
  ],
  "Body ...What you think of?)": <String>[
    "Body ...What you think of?)",
    "Qu’en pensez-vous ?",
    "ما رأيك؟"
  ],
  "Select time": <String>["Select time", "Choisir l’heure", "اختر الوقت"],
  "Open calender": <String>[
    "Open calender",
    "Ouvrir le calendrier",
    "فتح التقويم"
  ],
  "response": <String>["response", "réponse", "إجابة"],
  "responses": <String>["responses", "réponses", "إجابات"],
  "{0} / {1} answered": <String>[
    "{0} / {1} answered",
    "{0} / {1} réponses",
    "أُجيب عن {0} / {1}"
  ],
  "{0} / {1} required": <String>[
    "{0} / {1} required",
    "{0} / {1} obligatoires",
    "{0} / {1} من الإجابات المطلوبة"
  ],
  "Allowed days: {0}": <String>[
    "Allowed days: {0}",
    "Jours autorisés : {0}",
    "الأيام المسموحة: {0}"
  ],
  "Year {0}": <String>["Year {0}", "Année {0}", "السنة {0}"],
  "Response {0}": <String>["Response {0}", "Réponse {0}", "الإجابة {0}"],
  "Average {0}": <String>["Average {0}", "Moyenne {0}", "المتوسط {0}"],
  "Average: {0} / {1}": <String>[
    "Average: {0} / {1}",
    "Moyenne : {0} / {1}",
    "المتوسط: {0} / {1}"
  ],
  "{0} response{1}  ·  avg": <String>[
    "{0} response{1}  ·  avg",
    "{0} réponses · moyenne",
    "{0} إجابات · المتوسط"
  ],
  "Average step {0} / {1}": <String>[
    "Average step {0} / {1}",
    "Niveau moyen {0} / {1}",
    "متوسط الدرجة {0} / {1}"
  ],
  "Question {0}": <String>["Question {0}", "Question {0}", "السؤال {0}"],
  "{0} answer{1}": <String>["{0} answer{1}", "{0} réponses", "{0} إجابات"],
  "OK ({0})": <String>["OK ({0})", "Valider ({0})", "تأكيد ({0})"],
  "{0} Days selected": <String>[
    "{0} Days selected",
    "{0} jours sélectionnés",
    "{0} أيام محددة"
  ],
  "{0} more reply": <String>[
    "{0} more reply",
    "{0} réponse supplémentaire",
    "{0} رد إضافي"
  ],
  "{0} more replies": <String>[
    "{0} more replies",
    "{0} réponses supplémentaires",
    "{0} ردود إضافية"
  ],
  "replide to: @ {0}": <String>[
    "replide to: @ {0}",
    "En réponse à : @ {0}",
    "ردًا على: @ {0}"
  ],
  "Row/Colams...can choose only one answer in a row": <String>[
    "Row/Colams...can choose only one answer in a row",
    "Une réponse par ligne dans la grille",
    "إجابة واحدة لكل صف في الشبكة"
  ],
  "Row/Colams...can choose many answers in a row": <String>[
    "Row/Colams...can choose many answers in a row",
    "Plusieurs réponses par ligne dans la grille",
    "عدة إجابات لكل صف في الشبكة"
  ],
  "Month, day, year": <String>[
    "Month, day, year",
    "Mois, jour, année",
    "الشهر، اليوم، السنة"
  ],
  "NotePade": <String>["Notepad", "Bloc-notes", "المفكرة"],
};
Locale supportedAppLocale(String languageCode) {
  final language = languageCode.toLowerCase().split(RegExp('[-_]')).first;
  return Locale(const ['ar', 'en', 'fr'].contains(language) ? language : 'en');
}

String mainTextForLocale(String languageCode, String source,
    [List<Object?> arguments = const []]) {
  final language = languageCode.split(RegExp('[-_]')).first;
  final translations = mainMessageCatalog[source];
  final text = translations == null
      ? source
      : language == 'ar'
          ? (translations.length > 2 ? translations[2] : source)
          : translations[language == 'fr' ? 1 : 0];
  return text.replaceAllMapped(RegExp(r'\{(\d+)\}'), (match) {
    final index = int.parse(match.group(1)!);
    return index < arguments.length
        ? '${arguments[index] ?? ''}'
        : match.group(0)!;
  });
}

String mainText(BuildContext context, String source,
        [List<Object?> arguments = const []]) =>
    mainTextForLocale(
        Localizations.localeOf(context).languageCode, source, arguments);

// Used for messages produced outside a widget; S.load keeps this locale current.
String mainTextCurrent(String source, [List<Object?> arguments = const []]) =>
    mainTextForLocale(Intl.defaultLocale ?? 'en', source, arguments);

String mainTagText(BuildContext context, String tag) => const [
      'أسئلة',
      'مواد',
      'امتحانات',
      'نصائح',
      'تخصصات',
      'نقاش جامعي'
    ].contains(tag)
        ? mainText(context, tag)
        : tag;
