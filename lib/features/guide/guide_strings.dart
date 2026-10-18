import 'package:flutter/widgets.dart';

class GuideCopy {
  const GuideCopy(this.title, this.body);
  final String title;
  final String body;
}

// Arabic, English, French. Tutorial text follows the active application locale.
const guideMessages = <String, List<GuideCopy>>{
  'feed.menu': [
    GuideCopy('صفحات التطبيق',
        'افتح هذه القائمة للوصول إلى ملفك الشخصي والدردشة وحساب المعدل. ستجد دليلًا قصيرًا عند فتح كل صفحة لأول مرة.'),
    GuideCopy('Explore the app',
        'Open this menu to reach your profile, chats and grade calculator. Each page has a short guide on your first visit.'),
    GuideCopy('Découvrir l’application',
        'Ouvrez ce menu pour accéder au profil, aux discussions et au calcul de moyenne. Un guide vous accompagne lors de votre première visite.'),
  ],
  'feed.create': [
    GuideCopy('إنشاء منشور',
        'ابدأ من هنا لكتابة منشور وإضافة صور أو فيديو أو استطلاع. يمكنك مراجعة المحتوى قبل نشره.'),
    GuideCopy('Create a post',
        'Start here to write a post and add images, a video or a poll. Review your content before publishing.'),
    GuideCopy('Créer une publication',
        'Commencez ici pour écrire et ajouter des images, une vidéo ou un sondage. Vérifiez le contenu avant de le publier.'),
  ],
  'nav.profile': [
    GuideCopy('ملفك الشخصي',
        'اعرض معلومات حسابك وصورتك ومنشوراتك وقوائم المتابعين من هذه الصفحة.'),
    GuideCopy('Your profile',
        'Open your account information, profile photo, posts and follower lists here.'),
    GuideCopy('Votre profil',
        'Retrouvez ici vos informations, votre photo, vos publications et vos listes d’abonnés.'),
  ],
  'nav.chat': [
    GuideCopy(
        'الدردشة', 'انتقل إلى محادثاتك وابحث فيها، أو راجع طلبات المراسلة.'),
    GuideCopy('Chats',
        'Open your conversations, search them and review message requests.'),
    GuideCopy('Discussions',
        'Accédez à vos conversations, recherchez-les et consultez les demandes de messages.'),
  ],
  'nav.gpa': [
    GuideCopy('حساب المعدل',
        'اختر حاسبة مواد تخصصك، أو الحساب السريع لإدخال مواد وعلامات من اختيارك.'),
    GuideCopy('Grade calculator',
        'Use your program’s subjects, or the quick calculator for subjects and grades you enter yourself.'),
    GuideCopy('Calcul de moyenne',
        'Utilisez les matières de votre cursus ou le calcul rapide avec vos propres matières et notes.'),
  ],
  'gpa.normal': [
    GuideCopy('الحساب حسب التخصص',
        'اختر الكلية والتخصص للوصول إلى المواد المقررة ونتائج الفصول. الاختصار الأكاديمي المحفوظ يعيدك إلى برنامجك الدراسي.'),
    GuideCopy('Your program calculator',
        'Choose your faculty and specialty to open your curriculum and semester results. A saved academic shortcut takes you back to your program.'),
    GuideCopy('Calcul selon votre cursus',
        'Choisissez votre faculté et votre spécialité pour accéder aux matières et aux résultats semestriels. Le raccourci enregistré vous ramène à votre cursus.'),
  ],
  'gpa.quick': [
    GuideCopy('ما الفرق في الحساب السريع؟',
        'تضيف المواد والعلامات والمعاملات وأوزان التقييم يدويًا، دون اختيار تخصص. استخدم زري الحساب والحفظ داخل الحاسبة؛ البيانات المحفوظة تبقى على هذا الجهاز.'),
    GuideCopy('How is quick calculation different?',
        'Enter your own subjects, grades, coefficients and assessment weights without selecting a program. Use Calculate and Save in the calculator; saved data stays on this device.'),
    GuideCopy('Pourquoi le calcul rapide ?',
        'Saisissez vos matières, notes, coefficients et pondérations sans choisir de cursus. Utilisez Calculer et Enregistrer ; les données sont sauvegardées sur cet appareil.'),
  ],
  'gpa.search': [
    GuideCopy('ابحث عن تخصصك',
        'ابحث عن الكلية أو التخصص، ثم اختر مسارك الدراسي للوصول إلى مواده.'),
    GuideCopy('Find your program',
        'Search for a faculty or specialty, then select your study track to open its subjects.'),
    GuideCopy('Trouver votre cursus',
        'Recherchez une faculté ou une spécialité, puis choisissez votre parcours pour accéder à ses matières.'),
  ],
  'chat.search': [
    GuideCopy('البحث في المحادثات',
        'ابحث عن محادثة موجودة بالاسم أو بمحتوى آخر رسالة.'),
    GuideCopy('Search conversations',
        'Find an existing conversation by name or by its latest message.'),
    GuideCopy('Rechercher une discussion',
        'Retrouvez une conversation existante par nom ou par le contenu du dernier message.'),
  ],
  'chat.requests': [
    GuideCopy(
        'طلبات المراسلة', 'افتح الطلبات لمراجعة طلبات الرسائل التي تنتظر ردك.'),
    GuideCopy('Message requests',
        'Open Requests to review pending message requests.'),
    GuideCopy('Demandes de messages',
        'Ouvrez les demandes pour consulter les messages en attente.'),
  ],
  'chat.conversations': [
    GuideCopy('محادثاتك',
        'اضغط على محادثة لفتحها ومتابعة الدردشة. إن كانت القائمة فارغة، ستظهر محادثاتك هنا عندما تبدأ المراسلة.'),
    GuideCopy('Your conversations',
        'Tap a conversation to open it and continue chatting. If the list is empty, your conversations will appear here when you start messaging.'),
    GuideCopy('Vos conversations',
        'Touchez une conversation pour poursuivre la discussion. Si la liste est vide, vos échanges apparaîtront ici lorsque vous commencerez à discuter.'),
  ],
  'profile.header': [
    GuideCopy('صورتك الشخصية', 'اضغط على صورتك لاختيار صورة شخصية جديدة.'),
    GuideCopy(
        'Your profile photo', 'Tap your photo to choose a new profile image.'),
    GuideCopy('Votre photo de profil',
        'Touchez votre photo pour choisir une nouvelle image.'),
  ],
  'profile.info': [
    GuideCopy('معلومات الملف الشخصي',
        'افتح معلومات الملف للاطلاع على بيانات حسابك وتعديلها.'),
    GuideCopy('Profile information',
        'Open Profile info to view and edit your account details.'),
    GuideCopy('Informations du profil',
        'Ouvrez les informations du profil pour consulter et modifier les données du compte.'),
  ],
  'profile.statistics': [
    GuideCopy('نشاط حسابك',
        'شاهد أعداد المتابعين والحسابات التي تتابعها والمنشورات. اضغط على المتابعين أو المتابَعين لفتح القائمة.'),
    GuideCopy('Your activity',
        'View your follower, following and post counts. Tap Followers or Following to open the list.'),
    GuideCopy('Votre activité',
        'Consultez les nombres d’abonnés, d’abonnements et de publications. Touchez Abonnés ou Abonnements pour ouvrir la liste.'),
  ],
  'post.title': [
    GuideCopy('عنوان المنشور', 'أضف عنوانًا يوضح موضوع منشورك.'),
    GuideCopy(
        'Post title', 'Add a title that explains what your post is about.'),
    GuideCopy('Titre de la publication',
        'Ajoutez un titre qui présente le sujet de votre publication.'),
  ],
  'post.body': [
    GuideCopy('محتوى المنشور',
        'اكتب النص هنا. يمكنك أيضًا إضافة وسائط واستطلاع من الأدوات الموجودة أسفل الصفحة.'),
    GuideCopy('Post content',
        'Write your text here. You can also add media and a poll using the tools at the bottom.'),
    GuideCopy('Contenu de la publication',
        'Écrivez votre texte ici. Les outils du bas permettent aussi d’ajouter des médias et un sondage.'),
  ],
  'post.images': [
    GuideCopy('إضافة صور',
        'اختر صورًا من جهازك. تظهر في المعاينة ويمكنك إزالة ما لا تريد إرفاقه قبل النشر.'),
    GuideCopy('Add images',
        'Choose images from your device. Review the previews and remove unwanted attachments before publishing.'),
    GuideCopy('Ajouter des images',
        'Choisissez des images sur votre appareil. Vérifiez les aperçus et retirez les pièces jointes inutiles avant de publier.'),
  ],
  'post.video': [
    GuideCopy('إضافة فيديو',
        'اختر فيديو لإرفاقه بالمنشور، ثم راجع المعاينة قبل النشر.'),
    GuideCopy('Add a video',
        'Choose a video to attach to the post, then review its preview before publishing.'),
    GuideCopy('Ajouter une vidéo',
        'Choisissez une vidéo à joindre, puis vérifiez son aperçu avant de publier.'),
  ],
  'post.poll': [
    GuideCopy('إضافة استطلاع «Poll»',
        'افتح محرر الاستطلاع لإضافة الأسئلة والخيارات. بعد الحفظ يعود الاستطلاع إلى المنشور؛ لا يُنشر إلا عندما تنشر المنشور نفسه.'),
    GuideCopy('Add a poll',
        'Open the poll editor to add questions and choices. Saving returns the poll to your post; it is published only when you publish the post.'),
    GuideCopy('Ajouter un sondage',
        'Ouvrez l’éditeur pour ajouter des questions et des choix. Enregistrer ajoute le sondage au brouillon ; il sera publié avec la publication.'),
  ],
  'post.tags': [
    GuideCopy(
        'وسوم المنشور', 'أضف الوسوم المناسبة لموضوع منشورك لتوضيح محتواه.'),
    GuideCopy('Post tags', 'Add tags that describe your post’s topic.'),
    GuideCopy('Étiquettes',
        'Ajoutez des étiquettes qui décrivent le sujet de votre publication.'),
  ],
  'post.publish': [
    GuideCopy('المراجعة ثم النشر',
        'راجع النص والصور والفيديو والأسئلة أولًا، ثم استخدم هذا الزر للمتابعة. الدليل لا ينشر أي محتوى نيابة عنك.'),
    GuideCopy('Review, then publish',
        'Review your text, images, video and questions before continuing with this button. This guide never publishes anything for you.'),
    GuideCopy('Vérifier puis publier',
        'Vérifiez le texte, les images, la vidéo et les questions avant de continuer avec ce bouton. Le guide ne publie rien à votre place.'),
  ],
  'poll.add': [
    GuideCopy('أضف سؤال الاستطلاع',
        'اختر نوع السؤال: خيارات، نص، مقياس، تاريخ، وقت أو جدول. بعد إضافته اكتب السؤال واضبط الخيارات وما إذا كانت الإجابة إلزامية.'),
    GuideCopy('Add a poll question',
        'Choose a question type: choices, text, scale, date, time or grid. Then write the question, configure its choices and decide whether an answer is required.'),
    GuideCopy('Ajouter une question',
        'Choisissez le type : choix, texte, échelle, date, heure ou grille. Rédigez la question, réglez les choix et indiquez si la réponse est obligatoire.'),
  ],
  'poll.elements': [
    GuideCopy('عناصر الاستطلاع',
        'يمكنك إضافة نصوص وصور وفيديو بين الأسئلة. استخدم أدوات العناصر لترتيبها أو حذفها قبل الحفظ.'),
    GuideCopy('Poll elements',
        'Add text, images and videos between questions. Use each element’s controls to reorder or remove it before saving.'),
    GuideCopy('Éléments du sondage',
        'Ajoutez du texte, des images et des vidéos entre les questions. Les commandes des éléments permettent de les déplacer ou de les supprimer.'),
  ],
  'poll.save': [
    GuideCopy('حفظ الاستطلاع',
        'أضف سؤالًا واحدًا على الأقل، ثم احفظ للعودة إلى محرر المنشور. راجع المعاينة هناك قبل النشر.'),
    GuideCopy('Save the poll',
        'Add at least one question, then save to return to the post editor. Review the preview there before publishing.'),
    GuideCopy('Enregistrer le sondage',
        'Ajoutez au moins une question, puis enregistrez pour revenir à l’éditeur de publication. Vérifiez l’aperçu avant de publier.'),
  ],
};

int _language(BuildContext context) =>
    switch (Localizations.localeOf(context).languageCode) {
      'ar' => 0,
      'fr' => 2,
      _ => 1,
    };
GuideCopy guideCopy(BuildContext context, String key) =>
    guideMessages[key]![_language(context)];
String guideLabel(BuildContext context, String key) =>
    const <String, List<String>>{
      'help': ['دليل هذه الصفحة', 'Page guide', 'Guide de cette page'],
      'next': ['التالي', 'Next', 'Suivant'],
      'back': ['السابق', 'Back', 'Précédent'],
      'skip': ['تخطي', 'Skip', 'Passer'],
      'done': ['إنهاء', 'Done', 'Terminer'],
    }[key]![_language(context)];
