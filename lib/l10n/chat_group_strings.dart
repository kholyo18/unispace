import 'package:flutter/widgets.dart';
import 'package:cloud_functions/cloud_functions.dart';

String chatGroupText(BuildContext context, String key) =>
    ChatGroupStrings.text(Localizations.localeOf(context).languageCode, key);
String chatGroupError(BuildContext context, Object error) {
  final code = error is FirebaseFunctionsException ? error.code : '';
  return chatGroupText(
      context,
      switch (code) {
        'unauthenticated' => 'Sign in again',
        'permission-denied' => 'Action not permitted',
        'resource-exhausted' => 'Limit reached',
        'failed-precondition' => 'Group changed',
        'invalid-argument' => 'Check group details',
        _ => 'Could not complete request',
      });
}

abstract final class ChatGroupStrings {
  static String text(String languageCode, String key) {
    final row = values[key];
    if (row == null) return key;
    return languageCode == 'ar'
        ? row[0]
        : languageCode == 'fr'
            ? row[1]
            : key;
  }

  static const values = <String, List<String>>{
    'Members added': ['الأعضاء المضافون', 'Membres ajoutés'],
    'Group created; additions pending': ['تم إنشاء المجموعة، ولم تكتمل إضافة الجميع. أعد المحاولة أو أضف الباقين لاحقًا.', 'Le groupe est créé. Réessayez pour ajouter les personnes restantes, ou ajoutez-les plus tard.'],
    'Conversation started': ['بداية المحادثة', 'Début de la conversation'],
    'Member added': ['تمت إضافة العضو', 'Membre ajouté'],
    'Add member': ['إضافة عضو', 'Ajouter un membre'],
    'Change group photo': ['تغيير صورة المجموعة', 'Modifier la photo du groupe'],
    'Conversation settings and media': ['إعدادات المحادثة والوسائط', 'Réglages et médias de la conversation'],
    'People are added directly when their privacy settings allow it. They can leave the group.': ['يُضاف الأشخاص مباشرة إذا سمحت إعدادات الخصوصية، ويمكنهم مغادرة المجموعة.', 'Les personnes sont ajoutées directement si leurs réglages de confidentialité le permettent. Elles peuvent quitter le groupe.'],
    'Reject': ['رفض', 'Refuser'],
    'Refresh': ["تحديث","Actualiser"],
    'Approve': ["موافقة","Approuver"],
    'More requests after reviewing this page': ["راجع هذه الطلبات لعرض الطلبات التالية.","Traitez ces demandes pour afficher les suivantes."],
    'No pending join requests': ["لا توجد طلبات انضمام معلّقة.","Aucune demande en attente."],
    'Join requests': ["طلبات الانضمام","Demandes d’adhésion"],
    'Copy link': ["نسخ الرابط","Copier le lien"],
    'Link expires in seven days': ["ينتهي الرابط بعد سبعة أيام. يُلصق في صفحة الانضمام عبر رابط داخل التطبيق.","Ce lien expire dans sept jours. Collez-le dans la page de participation par lien de l’application."],
    'Link change confirmation': ["سيتوقف الرابط السابق عن العمل، ولن تُقبل طلبات الانضمام المعلّقة التي أُرسلت به. هل تريد المتابعة؟","L’ancien lien et les demandes en attente associées ne pourront plus être utilisés. Continuer ?"],
    'Invitation link revoked': ["تم إلغاء رابط الدعوة.","Lien d’invitation révoqué."],
    'Revoke invitation link': ["إلغاء رابط الدعوة","Révoquer le lien"],
    'Create new invitation link': ["إنشاء رابط دعوة جديد","Créer un nouveau lien"],
    'Only admins can send messages': ["المشرفون فقط يمكنهم إرسال الرسائل","Seuls les administrateurs peuvent envoyer des messages"],
    'Request to join': ["طلب الانضمام","Demander à rejoindre"],
    'Join request sent': ["أُرسل طلب الانضمام وبانتظار موافقة المشرف.","Demande envoyée, en attente de validation."],
    'Invitation link': ["رابط الدعوة","Lien d’invitation"],
    'Join request explanation': ["الرابط يتيح طلب الانضمام فقط. يراجع المشرف الطلب قبل إتاحة رسائل المجموعة، بما فيها الرسائل السابقة.","Le lien permet de demander à rejoindre le groupe. Un administrateur doit approuver avant tout accès aux messages, y compris les anciens."],
    'Join by invitation link': ["الانضمام عبر رابط دعوة","Rejoindre via un lien"],
    'Group access': ["إدارة الوصول للمجموعة","Accès au groupe"],
    'Starred messages': ['الرسائل المميزة بنجمة', 'Messages importants'],
    'Invitations sent': ['الدعوات المرسلة', 'Invitations envoyées'],
    'Group created; invitations pending': [
      'تم إنشاء المجموعة، ولم تُرسل كل الدعوات بعد. أعد المحاولة لإكمالها، أو افتح المجموعة وأضف الباقين لاحقًا.',
      'Le groupe est créé, mais certaines invitations restent à envoyer. Réessayez ou ouvrez le groupe pour les ajouter plus tard.'
    ],
    'Open group': ['فتح المجموعة', 'Ouvrir le groupe'],
    'Pending invitations': ['الدعوات المعلّقة', 'Invitations en attente'],
    'Invitation pending': ['بانتظار قبول الدعوة', 'Invitation en attente'],
    'Cancel invitation': ['إلغاء الدعوة', 'Annuler l’invitation'],
    'Already a member or invited': [
      'هذا الشخص عضو أو لديه دعوة معلّقة بالفعل',
      'Cette personne est déjà membre ou invitée'
    ],
    'Find people': ['البحث عن أشخاص آخرين', 'Rechercher d’autres personnes'],
    'Already a member': [
      'هذا الشخص عضو بالفعل',
      'Cette personne est déjà membre'
    ],
    'Joining gives access to existing group messages.': [
      'قبول الدعوة يتيح لك قراءة رسائل المجموعة السابقة.',
      'Accepter l’invitation donne accès aux messages déjà présents dans le groupe.'
    ],
    'Promote another admin before leaving.': [
      'عيّن مشرفًا آخر قبل مغادرة المجموعة.',
      'Nommez un autre admin avant de quitter le groupe.'
    ],
    'New group': ['مجموعة جديدة', 'Nouveau groupe'],
    'Group name too long': ['اسم المجموعة طويل جدًا. اختصره قليلًا.', 'Le nom du groupe est trop long. Raccourcissez-le.'],
    'Group name (optional)': ['اسم المجموعة (اختياري)', 'Nom du groupe (facultatif)'],
    'Remove selection': ['إلغاء الاختيار', 'Retirer de la sélection'],
    'Group name': ['اسم المجموعة', 'Nom du groupe'],
    'Group details': ['معلومات المجموعة', 'Détails du groupe'],
    'Group invitations': ['دعوات المجموعات', 'Invitations aux groupes'],
    'Members': ['الأعضاء', 'Membres'],
    'Admin': ['مشرف', 'Admin'],
    'You': ['أنت', 'Vous'],
    'Member': ['عضو', 'Membre'],
    'Create group': ['إنشاء المجموعة', 'Créer le groupe'],
    'Invite member': ['دعوة عضو', 'Inviter un membre'],
    'Invite': ['دعوة', 'Inviter'],
    'Accept': ['قبول', 'Accepter'],
    'Decline': ['رفض', 'Refuser'],
    'Cancel': ['إلغاء', 'Annuler'],
    'Save': ['حفظ', 'Enregistrer'],
    'Retry': ['إعادة المحاولة', 'Réessayer'],
    'Search people': ['البحث عن أشخاص', 'Rechercher des personnes'],
    'Choose existing contacts': [
      'اختر من محادثاتك الحالية',
      'Choisissez parmi vos conversations'
    ],
    'No contacts found': ['لم يتم العثور على أشخاص', 'Aucun contact trouvé'],
    'Loading failed': ['تعذر تحميل البيانات', 'Chargement impossible'],
    'Invitations explanation': [
      'سيتلقى الأشخاص دعوة، ولن ينضموا إلا بعد قبولها. الحد الأقصى 32 عضوًا معك.',
      'Les personnes recevront une invitation et rejoindront le groupe après acceptation. Maximum : 32 membres, vous compris.'
    ],
    'Submission locked': [
      'سنُعيد محاولة نفس الطلب لتجنب إنشاء مجموعات مكررة.',
      'La même demande sera réessayée pour éviter les doublons.'
    ],
    'Name required': [
      'أدخل اسم المجموعة (حتى 80 حرفًا)',
      'Saisissez un nom (80 caractères maximum)'
    ],
    'Rename group': ['تغيير اسم المجموعة', 'Renommer le groupe'],
    'Make admin': ['تعيين مشرف', 'Nommer admin'],
    'Remove admin': ['إلغاء الإشراف', 'Retirer le rôle admin'],
    'Remove member': ['إزالة العضو', 'Retirer le membre'],
    'Remove confirmation': [
      'هل تريد إزالة هذا العضو من المجموعة؟',
      'Retirer ce membre du groupe ?'
    ],
    'Leave group': ['مغادرة المجموعة', 'Quitter le groupe'],
    'Leave confirmation': [
      'هل تريد مغادرة المجموعة؟ إذا كنت المشرف الوحيد ويوجد أعضاء آخرون، عيّن مشرفًا آخر أولًا.',
      'Quitter le groupe ? Si vous êtes le seul admin et que d’autres membres restent, nommez d’abord un autre admin.'
    ],
    'Confirm': ['تأكيد', 'Confirmer'],
    'Invitation sent': ['تم إرسال الدعوة', 'Invitation envoyée'],
    'No longer a member': [
      'لم تعد عضوًا في هذه المجموعة',
      'Vous ne faites plus partie de ce groupe'
    ],
    'Sign in again': [
      'انتهت الجلسة. سجّل الدخول مجددًا.',
      'Session expirée. Reconnectez-vous.'
    ],
    'Action not permitted': [
      'لا تملك صلاحية هذا الإجراء أو تمنعه إعدادات الخصوصية.',
      'Cette action est interdite par vos droits ou les paramètres de confidentialité.'
    ],
    'Limit reached': [
      'أُرسلت دعوات كثيرة مؤخرًا. انتظر قليلًا ثم أعد المحاولة لإكمال الدعوات.',
      'Trop d’invitations récentes. Patientez puis réessayez pour continuer.'
    ],
    'Group changed': [
      'تعذر تنفيذ الإجراء بالحالة الحالية. تحقّق من الأعضاء والمشرفين.',
      'Action impossible dans cet état. Vérifiez les membres et les admins.'
    ],
    'Check group details': [
      'تحقّق من الاسم والأعضاء المدخلين.',
      'Vérifiez le nom et les membres sélectionnés.'
    ],
    'Could not complete request': [
      'تعذر إكمال الطلب. يمكنك إعادة المحاولة.',
      'Impossible de terminer la demande. Réessayez.'
    ],
  };
}
