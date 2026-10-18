// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a fr locale. All the
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
  String get localeName => 'fr';

  static String m0(specialty, level) =>
      "Spécialité : ${specialty} | Niveau : ${level}";

  static String m1(date) => "Bloqué le ${date}";

  static String m2(count) => "Commentaires (${count})";

  static String m3(max) => "Veuillez rester sous ${max} caractères";

  static String m4(min) => "Veuillez saisir au moins ${min} caractères";

  static String m5(fileName) => "Supprimer ${fileName} de cet appareil ?";

  static String m6(size) => "Cache : ${size}";

  static String m7(size) => "Total utilisé : ${size}";

  static String m8(size) => "Utilisateur : ${size}";

  static String m9(date) => "Mis à jour ${date}";

  static String m10(subject) => "Rappel : ${subject} dans 24 heures";

  static String m11(subject) => "Rappel : ${subject} dans 2 heures";

  static String m12(subject) => "Rappel : ${subject} dans 30 minutes";

  static String m13(type) => "Type : ${type}";

  static String m14(seconds) => "Envoyer l\'OTP dans ${seconds}s";

  static String m15(masked) =>
      "Saisissez votre e-mail actuel pour vérifier. Indice : ${masked}";

  static String m16(masked) => "Vérifiez le nouvel e-mail : ${masked}";

  static String m17(date) => "Dernier changement de mot de passe : ${date}";

  static String m18(days, hours) =>
      "Vous pouvez modifier votre nom après : ${days} jour / ${hours} heure";

  static String m19(hours) =>
      "Vous pouvez modifier votre nom après : ${hours} heure";

  static String m20(maskedEmail) =>
      "Nous enverrons un lien de réinitialisation à votre e-mail enregistré : ${maskedEmail}";

  static String m21(current, total) => "Étape ${current} sur ${total}";

  static String m22(seconds) => "Renvoyer dans ${seconds}s";

  static String m23(e) => "Échec de l\'envoi : ${e}";

  static String m24(days) => "Il y a ${days} j";

  static String m25(hours) => "Il y a ${hours} h";

  static String m26(minutes) => "Il y a ${minutes} min";

  static String m27(start, end) => "${start} → ${end}";

  static String m28(minutes) => "${minutes} min";

  static String m29(subject) => "Session focus : ${subject}";

  static String m30(subject) => "Examen blanc : ${subject}";

  static String m31(subject) => "Quiz d\'entraînement : ${subject}";

  static String m32(subject) => "Révision synthèse : ${subject}";

  static String m33(count) => "Tentatives restantes : ${count}";

  static String m34(email) =>
      "Saisissez le code à 6 chiffres envoyé à ${email}.";

  static String m35(seconds) => "Renvoyer dans ${seconds}s";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "aboutApp": MessageLookupByLibrary.simpleMessage(
      "À propos de l\'application",
    ),
    "aboutAppDescription": MessageLookupByLibrary.simpleMessage(
      "Une plateforme universitaire intelligente qui aide les étudiants à organiser leurs études, calculer les moyennes, suivre les examens et planifier les révisions de manière simple et efficace.",
    ),
    "aboutAppDetails": MessageLookupByLibrary.simpleMessage(
      "UniSpace ne collecte pas de données personnelles en dehors de Firebase. Toutes les données sont sécurisées.",
    ),
    "aboutAppFeatureExams": MessageLookupByLibrary.simpleMessage(
      "Calendrier des examens",
    ),
    "aboutAppFeatureGpa": MessageLookupByLibrary.simpleMessage(
      "Calcul précis de la moyenne universitaire",
    ),
    "aboutAppFeatureNotes": MessageLookupByLibrary.simpleMessage(
      "Prise de notes académiques",
    ),
    "aboutAppFeatureReviewPlan": MessageLookupByLibrary.simpleMessage(
      "Planificateur de révision intelligent",
    ),
    "aboutAppFeatureStudents": MessageLookupByLibrary.simpleMessage(
      "Conçu spécialement pour les étudiants universitaires",
    ),
    "aboutAppFooter": MessageLookupByLibrary.simpleMessage(
      "Développé avec Flutter",
    ),
    "aboutAppSummary": MessageLookupByLibrary.simpleMessage(
      "Plateforme pour calculer la moyenne universitaire, échanger avec les étudiants et prendre des notes.",
    ),
    "aboutAppViewLicenses": MessageLookupByLibrary.simpleMessage(
      "Consulter les licences",
    ),
    "academicCollegeLabel": MessageLookupByLibrary.simpleMessage("Faculté"),
    "academicLevelLabel": MessageLookupByLibrary.simpleMessage("Niveau"),
    "academicMajorLabel": MessageLookupByLibrary.simpleMessage("Spécialité"),
    "academicSettingsDescription": MessageLookupByLibrary.simpleMessage(
      "Mettez à jour votre faculté, spécialité et niveau.",
    ),
    "academicSettingsSaved": MessageLookupByLibrary.simpleMessage(
      "Paramètres académiques enregistrés.",
    ),
    "academicSettingsTitle": MessageLookupByLibrary.simpleMessage(
      "Paramètres académiques",
    ),
    "academicShortcutDeleteCancel": MessageLookupByLibrary.simpleMessage(
      "Annuler",
    ),
    "academicShortcutDeleteConfirm": MessageLookupByLibrary.simpleMessage(
      "Supprimer",
    ),
    "academicShortcutDeleteConfirmBody": MessageLookupByLibrary.simpleMessage(
      "Voulez-vous supprimer le raccourci académique ? Vous pouvez l\'ajouter de nouveau plus tard.",
    ),
    "academicShortcutDeleteConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Confirmer la suppression",
    ),
    "academicShortcutDeleteSuccess": MessageLookupByLibrary.simpleMessage(
      "Raccourci supprimé avec succès.",
    ),
    "academicShortcutDeleteTitle": MessageLookupByLibrary.simpleMessage(
      "Supprimer le raccourci",
    ),
    "academicShortcutDetails": m0,
    "academicShortcutEdit": MessageLookupByLibrary.simpleMessage("Modifier"),
    "academicShortcutEmptyAction": MessageLookupByLibrary.simpleMessage(
      "Ajouter un raccourci",
    ),
    "academicShortcutEmptyTitle": MessageLookupByLibrary.simpleMessage(
      "Aucun raccourci académique n\'a encore été configuré.",
    ),
    "academicShortcutGo": MessageLookupByLibrary.simpleMessage("Aller"),
    "academicShortcutNotFound": MessageLookupByLibrary.simpleMessage(
      "Impossible de trouver cette spécialité. Veuillez mettre à jour vos paramètres académiques.",
    ),
    "academicShortcutTitle": MessageLookupByLibrary.simpleMessage(
      "Votre raccourci académique",
    ),
    "academicclass": MessageLookupByLibrary.simpleMessage("Section"),
    "accounting": MessageLookupByLibrary.simpleMessage("Comptabilité"),
    "accountingTaxation": MessageLookupByLibrary.simpleMessage(
      "Comptabilité et fiscalité",
    ),
    "activeSessionNow": MessageLookupByLibrary.simpleMessage("À l’instant"),
    "activeSessionsEmpty": MessageLookupByLibrary.simpleMessage(
      "Aucune autre session active",
    ),
    "activeSessionsHint": MessageLookupByLibrary.simpleMessage(
      "La gestion des sessions nécessite un backend sécurisé.",
    ),
    "activeSessionsTitle": MessageLookupByLibrary.simpleMessage(
      "Sessions actives",
    ),
    "add": MessageLookupByLibrary.simpleMessage("Ajouter"),
    "addExam": MessageLookupByLibrary.simpleMessage("Ajouter un examen"),
    "advancedPublicLaw": MessageLookupByLibrary.simpleMessage(
      "Droit public approfondi",
    ),
    "algeriaLabel": MessageLookupByLibrary.simpleMessage("Algérie"),
    "arabic": MessageLookupByLibrary.simpleMessage("Arabe"),
    "archive": MessageLookupByLibrary.simpleMessage("Archives"),
    "basicEducation": MessageLookupByLibrary.simpleMessage(
      "Enseignement de base",
    ),
    "basicEducationDept": MessageLookupByLibrary.simpleMessage(
      "Département de l\'enseignement de base",
    ),
    "basicUnit": MessageLookupByLibrary.simpleMessage("Unité fondamentale"),
    "blockAccount": MessageLookupByLibrary.simpleMessage("Bloquer le compte"),
    "blockedUsersAddAction": MessageLookupByLibrary.simpleMessage("Bloquer"),
    "blockedUsersAddHint": MessageLookupByLibrary.simpleMessage(
      "Saisissez l\'identifiant ou l\'e-mail",
    ),
    "blockedUsersAddTitle": MessageLookupByLibrary.simpleMessage(
      "Bloquer un utilisateur",
    ),
    "blockedUsersEmpty": MessageLookupByLibrary.simpleMessage(
      "Aucun utilisateur bloqué",
    ),
    "blockedUsersHint": MessageLookupByLibrary.simpleMessage(
      "Les utilisateurs bloqués apparaîtront ici.",
    ),
    "blockedUsersSince": m1,
    "blockedUsersTitle": MessageLookupByLibrary.simpleMessage(
      "Utilisateurs bloqués",
    ),
    "businessAdministration": MessageLookupByLibrary.simpleMessage(
      "Administration des affaires",
    ),
    "businessLaw": MessageLookupByLibrary.simpleMessage("Droit des affaires"),
    "calculate": MessageLookupByLibrary.simpleMessage("Calculer"),
    "cancel": MessageLookupByLibrary.simpleMessage("Annuler"),
    "changeLanguage": MessageLookupByLibrary.simpleMessage("Changer la langue"),
    "changeTheme": MessageLookupByLibrary.simpleMessage("Changer le thème"),
    "checkNow": MessageLookupByLibrary.simpleMessage("Vérifier maintenant"),
    "chooseLanguage": MessageLookupByLibrary.simpleMessage("Choisir la langue"),
    "chooseTheme": MessageLookupByLibrary.simpleMessage("Choisir le thème"),
    "clipboard": MessageLookupByLibrary.simpleMessage("Bloc-notes"),
    "close": MessageLookupByLibrary.simpleMessage("Fermer"),
    "coefficient": MessageLookupByLibrary.simpleMessage("Coef :"),
    "comment": MessageLookupByLibrary.simpleMessage("Commentaire"),
    "comments": MessageLookupByLibrary.simpleMessage("Commentaires"),
    "commentsCount": m2,
    "commercialSciences": MessageLookupByLibrary.simpleMessage(
      "Sciences commerciales",
    ),
    "commercialSciencesDept": MessageLookupByLibrary.simpleMessage(
      "Département des sciences commerciales",
    ),
    "commonCore": MessageLookupByLibrary.simpleMessage("Tronc commun"),
    "commonCore1": MessageLookupByLibrary.simpleMessage("Tronc commun"),
    "community": MessageLookupByLibrary.simpleMessage("Communauté"),
    "confirmDeleteExam": MessageLookupByLibrary.simpleMessage(
      "Voulez-vous supprimer cet examen ?",
    ),
    "contactCategoryFeature": MessageLookupByLibrary.simpleMessage(
      "Suggestion de nouvelle fonctionnalité",
    ),
    "contactCategoryImprovement": MessageLookupByLibrary.simpleMessage(
      "Amélioration",
    ),
    "contactCategoryIssue": MessageLookupByLibrary.simpleMessage("Problème"),
    "contactCategoryLabel": MessageLookupByLibrary.simpleMessage("Catégorie"),
    "contactCategoryOther": MessageLookupByLibrary.simpleMessage("Autre"),
    "contactCategoryReport": MessageLookupByLibrary.simpleMessage(
      "Signalement",
    ),
    "contactCopied": MessageLookupByLibrary.simpleMessage("Message copié"),
    "contactCopyAction": MessageLookupByLibrary.simpleMessage("Copier"),
    "contactCopyDialogBody": MessageLookupByLibrary.simpleMessage(
      "Copiez le message et envoyez-le au support via votre messagerie.",
    ),
    "contactCopyDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Copier le message",
    ),
    "contactDescriptionHint": MessageLookupByLibrary.simpleMessage(
      "Expliquez les détails pour vous aider rapidement",
    ),
    "contactDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "Description",
    ),
    "contactIncludeUserInfo": MessageLookupByLibrary.simpleMessage(
      "Inclure mes informations de compte",
    ),
    "contactMailOpened": MessageLookupByLibrary.simpleMessage(
      "Application e-mail ouverte pour envoyer votre message",
    ),
    "contactMailUnavailable": MessageLookupByLibrary.simpleMessage(
      "Aucune application e-mail disponible. Vous pouvez copier le message.",
    ),
    "contactMetadataAppVersion": MessageLookupByLibrary.simpleMessage(
      "Version de l\'application",
    ),
    "contactMetadataEmail": MessageLookupByLibrary.simpleMessage("E-mail"),
    "contactMetadataHeader": MessageLookupByLibrary.simpleMessage(
      "Métadonnées",
    ),
    "contactMetadataLocale": MessageLookupByLibrary.simpleMessage("Langue"),
    "contactMetadataName": MessageLookupByLibrary.simpleMessage("Nom"),
    "contactMetadataPlatform": MessageLookupByLibrary.simpleMessage(
      "Plateforme",
    ),
    "contactMetadataTimestamp": MessageLookupByLibrary.simpleMessage(
      "Horodatage",
    ),
    "contactMetadataUserId": MessageLookupByLibrary.simpleMessage(
      "ID utilisateur",
    ),
    "contactScreenshotPlaceholder": MessageLookupByLibrary.simpleMessage(
      "Joindre une capture d\'écran",
    ),
    "contactScreenshotSoon": MessageLookupByLibrary.simpleMessage(
      "Bientôt disponible",
    ),
    "contactSend": MessageLookupByLibrary.simpleMessage("Envoyer"),
    "contactSendFailure": MessageLookupByLibrary.simpleMessage(
      "Impossible d\'envoyer votre message. Veuillez réessayer.",
    ),
    "contactSendSuccess": MessageLookupByLibrary.simpleMessage("Envoyé ✅"),
    "contactSending": MessageLookupByLibrary.simpleMessage("Envoi en cours..."),
    "contactSubjectHint": MessageLookupByLibrary.simpleMessage(
      "Bref résumé de votre demande",
    ),
    "contactSubjectLabel": MessageLookupByLibrary.simpleMessage("Sujet"),
    "contactUs": MessageLookupByLibrary.simpleMessage("Contactez-nous"),
    "contactUsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Nous sommes ravis d\'avoir votre message. Envoyez-le au support.",
    ),
    "contactUserInfoUnavailable": MessageLookupByLibrary.simpleMessage(
      "Aucune information de compte disponible",
    ),
    "contactValidationMaxLength": m3,
    "contactValidationMinLength": m4,
    "contactValidationRequired": MessageLookupByLibrary.simpleMessage(
      "Ce champ est obligatoire",
    ),
    "content": MessageLookupByLibrary.simpleMessage("Contenu"),
    "copyText": MessageLookupByLibrary.simpleMessage("Copier le texte"),
    "corporateFinance": MessageLookupByLibrary.simpleMessage(
      "Finance d\'entreprise",
    ),
    "corporateFinancialManagement": MessageLookupByLibrary.simpleMessage(
      "Gestion financière des entreprises",
    ),
    "createPost": MessageLookupByLibrary.simpleMessage("Publication"),
    "createPoste": MessageLookupByLibrary.simpleMessage(
      "Créer une publication",
    ),
    "credits": MessageLookupByLibrary.simpleMessage("Crédits :"),
    "criminalLaw": MessageLookupByLibrary.simpleMessage(
      "Droit pénal et sciences criminelles",
    ),
    "currentDeviceTitle": MessageLookupByLibrary.simpleMessage(
      "Appareil actuel",
    ),
    "dangerZone": MessageLookupByLibrary.simpleMessage("Zone de danger"),
    "dark": MessageLookupByLibrary.simpleMessage("Sombre"),
    "darkMode": MessageLookupByLibrary.simpleMessage("Mode sombre"),
    "delete": MessageLookupByLibrary.simpleMessage("Supprimer"),
    "deleteExam": MessageLookupByLibrary.simpleMessage("Supprimer l\'examen"),
    "department": MessageLookupByLibrary.simpleMessage("Département"),
    "deptArabicLangLit": MessageLookupByLibrary.simpleMessage(
      "Département de langue et littérature arabes",
    ),
    "deptEnglishLangLit": MessageLookupByLibrary.simpleMessage(
      "Département de langue et littérature anglaises",
    ),
    "deptFrenchLangLit": MessageLookupByLibrary.simpleMessage(
      "Département de langue et littérature françaises",
    ),
    "deviceActiveNow": MessageLookupByLibrary.simpleMessage("Actif maintenant"),
    "devicePrimary": MessageLookupByLibrary.simpleMessage("Appareil principal"),
    "downloadsCacheClearFailed": MessageLookupByLibrary.simpleMessage(
      "Impossible de vider le cache.",
    ),
    "downloadsCacheCleared": MessageLookupByLibrary.simpleMessage(
      "Cache vidé.",
    ),
    "downloadsClearAllAction": MessageLookupByLibrary.simpleMessage(
      "Tout supprimer",
    ),
    "downloadsClearAllDialogBody": MessageLookupByLibrary.simpleMessage(
      "Cela supprimera tous les fichiers téléchargés de cet appareil.",
    ),
    "downloadsClearAllDialogConfirm": MessageLookupByLibrary.simpleMessage(
      "Tout supprimer",
    ),
    "downloadsClearAllDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Supprimer tous les téléchargements ?",
    ),
    "downloadsClearAllFailed": MessageLookupByLibrary.simpleMessage(
      "Impossible de supprimer tous les téléchargements.",
    ),
    "downloadsClearAllSuccess": MessageLookupByLibrary.simpleMessage(
      "Tous les téléchargements ont été supprimés.",
    ),
    "downloadsClearCache": MessageLookupByLibrary.simpleMessage(
      "Vider le cache",
    ),
    "downloadsClearCacheDialogBody": MessageLookupByLibrary.simpleMessage(
      "Cela supprimera les fichiers mis en cache sur cet appareil. Vous pourrez les télécharger de nouveau plus tard.",
    ),
    "downloadsClearCacheDialogConfirm": MessageLookupByLibrary.simpleMessage(
      "Vider le cache",
    ),
    "downloadsClearCacheDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Vider le cache des téléchargements ?",
    ),
    "downloadsDeleteDialogBody": m5,
    "downloadsDeleteDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Supprimer le téléchargement ?",
    ),
    "downloadsDeleteFailed": MessageLookupByLibrary.simpleMessage(
      "Impossible de supprimer le téléchargement.",
    ),
    "downloadsDeleteSuccess": MessageLookupByLibrary.simpleMessage(
      "Téléchargement supprimé.",
    ),
    "downloadsDescription": MessageLookupByLibrary.simpleMessage(
      "Consultez vos fichiers téléchargés et nettoyez le cache.",
    ),
    "downloadsEmptyHint": MessageLookupByLibrary.simpleMessage(
      "Les éléments téléchargés apparaîtront ici.",
    ),
    "downloadsEmptyTitle": MessageLookupByLibrary.simpleMessage(
      "Aucun téléchargement",
    ),
    "downloadsExploreCta": MessageLookupByLibrary.simpleMessage(
      "Explorer le contenu",
    ),
    "downloadsFilterAll": MessageLookupByLibrary.simpleMessage("Tout"),
    "downloadsFilterFiles": MessageLookupByLibrary.simpleMessage("Fichiers"),
    "downloadsFilterImages": MessageLookupByLibrary.simpleMessage("Images"),
    "downloadsLoadFailed": MessageLookupByLibrary.simpleMessage(
      "Impossible de charger les téléchargements.",
    ),
    "downloadsRefreshList": MessageLookupByLibrary.simpleMessage(
      "Rafraîchir la liste",
    ),
    "downloadsSortLabel": MessageLookupByLibrary.simpleMessage("Trier par"),
    "downloadsSortNewest": MessageLookupByLibrary.simpleMessage(
      "Les plus récents",
    ),
    "downloadsSortOldest": MessageLookupByLibrary.simpleMessage(
      "Les plus anciens",
    ),
    "downloadsStorageCacheLabel": MessageLookupByLibrary.simpleMessage(
      "Cache : 0 Mo",
    ),
    "downloadsStorageCacheLabelValue": m6,
    "downloadsStorageInfo": MessageLookupByLibrary.simpleMessage(
      "Les tailles seront calculées automatiquement plus tard.",
    ),
    "downloadsStorageInfoValue": m7,
    "downloadsStorageTitle": MessageLookupByLibrary.simpleMessage(
      "Stockage des téléchargements",
    ),
    "downloadsStorageUserLabel": MessageLookupByLibrary.simpleMessage(
      "Utilisateur : 0 Mo",
    ),
    "downloadsStorageUserLabelValue": m8,
    "downloadsTitle": MessageLookupByLibrary.simpleMessage("Téléchargements"),
    "downloadsUpdatedAt": m9,
    "drawerSectionAccount": MessageLookupByLibrary.simpleMessage("Compte"),
    "drawerSectionApp": MessageLookupByLibrary.simpleMessage("Application"),
    "drawerSectionContent": MessageLookupByLibrary.simpleMessage("Contenu"),
    "drawerSectionStudent": MessageLookupByLibrary.simpleMessage("Étudiant"),
    "economics": MessageLookupByLibrary.simpleMessage("Sciences économiques"),
    "economicsDept": MessageLookupByLibrary.simpleMessage(
      "Département des sciences économiques",
    ),
    "editExam": MessageLookupByLibrary.simpleMessage("Modifier l\'examen"),
    "editProfile": MessageLookupByLibrary.simpleMessage("Modifier le profil"),
    "editWeights": MessageLookupByLibrary.simpleMessage(
      "Modifier les pondérations",
    ),
    "email": MessageLookupByLibrary.simpleMessage("E-mail"),
    "emailAlreadyInUseError": MessageLookupByLibrary.simpleMessage(
      "Cet e-mail est déjà utilisé.",
    ),
    "emailAuthDisabledError": MessageLookupByLibrary.simpleMessage(
      "La connexion par e-mail est désactivée.",
    ),
    "emailHidden": MessageLookupByLibrary.simpleMessage("E-mail masqué"),
    "emailNotVerified": MessageLookupByLibrary.simpleMessage(
      "E-mail non vérifié",
    ),
    "emailNotVerifiedYet": MessageLookupByLibrary.simpleMessage(
      "L\'e-mail n\'est pas encore vérifié. Veuillez ouvrir votre e-mail, cliquer sur le lien de vérification, puis réessayer.",
    ),
    "emailUnavailable": MessageLookupByLibrary.simpleMessage(
      "E-mail indisponible",
    ),
    "emailVerified": MessageLookupByLibrary.simpleMessage("E-mail vérifié"),
    "energyMiningLaw": MessageLookupByLibrary.simpleMessage(
      "Droit de l’énergie et des mines",
    ),
    "examCalendar": MessageLookupByLibrary.simpleMessage(
      "Calendrier des examens",
    ),
    "examNote": MessageLookupByLibrary.simpleMessage("Note"),
    "examReminder24h": m10,
    "examReminder2h": m11,
    "examReminder30m": m12,
    "examRoom": MessageLookupByLibrary.simpleMessage("Salle"),
    "examSubject": MessageLookupByLibrary.simpleMessage("Matière"),
    "examSubjectRequired": MessageLookupByLibrary.simpleMessage(
      "Veuillez saisir la matière",
    ),
    "exploratoryUnit": MessageLookupByLibrary.simpleMessage(
      "Unité exploratoire",
    ),
    "faculties": MessageLookupByLibrary.simpleMessage("Facultés"),
    "faculty": MessageLookupByLibrary.simpleMessage("Faculté"),
    "facultyArtsLanguages": MessageLookupByLibrary.simpleMessage(
      "Faculté des lettres et des langues étrangères",
    ),
    "facultyEconomics": MessageLookupByLibrary.simpleMessage(
      "Faculté des sciences économiques, commerciales et des sciences de gestion",
    ),
    "facultyLawPolitical": MessageLookupByLibrary.simpleMessage(
      "Faculté de droit et des sciences politiques",
    ),
    "fail": MessageLookupByLibrary.simpleMessage(" Échoué"),
    "familyLaw": MessageLookupByLibrary.simpleMessage("Droit de la famille"),
    "favoritesAddAction": MessageLookupByLibrary.simpleMessage("Enregistrer"),
    "favoritesAddHint": MessageLookupByLibrary.simpleMessage(
      "Saisissez l\'ID de l\'élément",
    ),
    "favoritesAddTitle": MessageLookupByLibrary.simpleMessage(
      "Ajouter un favori",
    ),
    "favoritesAddTypeHint": MessageLookupByLibrary.simpleMessage(
      "Type (optionnel)",
    ),
    "favoritesAdded": MessageLookupByLibrary.simpleMessage(
      "Favori enregistré.",
    ),
    "favoritesDescription": MessageLookupByLibrary.simpleMessage(
      "Vos éléments enregistrés apparaissent ici.",
    ),
    "favoritesEmptyHint": MessageLookupByLibrary.simpleMessage(
      "Enregistrez des publications ou fichiers pour les voir ici.",
    ),
    "favoritesEmptyTitle": MessageLookupByLibrary.simpleMessage("Aucun favori"),
    "favoritesRemoved": MessageLookupByLibrary.simpleMessage(
      "Favori supprimé.",
    ),
    "favoritesSignInHint": MessageLookupByLibrary.simpleMessage(
      "Les favoris se synchronisent avec votre compte.",
    ),
    "favoritesSignInTitle": MessageLookupByLibrary.simpleMessage(
      "Connectez-vous pour enregistrer des favoris",
    ),
    "favoritesTitle": MessageLookupByLibrary.simpleMessage("Favoris"),
    "favoritesTypeLabel": m13,
    "finance": MessageLookupByLibrary.simpleMessage("Finance"),
    "financeInternationalTrade": MessageLookupByLibrary.simpleMessage(
      "Finance et commerce international",
    ),
    "financialAccounting": MessageLookupByLibrary.simpleMessage(
      "Sciences financières et comptables",
    ),
    "financialAccountingDept": MessageLookupByLibrary.simpleMessage(
      "Département des sciences financières et comptables",
    ),
    "financialManagement": MessageLookupByLibrary.simpleMessage(
      "Gestion financière",
    ),
    "followComment": MessageLookupByLibrary.simpleMessage(
      "Suivre le commentaire",
    ),
    "following": MessageLookupByLibrary.simpleMessage("Abonnements"),
    "fontSizeDescription": MessageLookupByLibrary.simpleMessage(
      "Choisissez une taille de lecture confortable.",
    ),
    "fontSizeLarge": MessageLookupByLibrary.simpleMessage("Grande"),
    "fontSizeMedium": MessageLookupByLibrary.simpleMessage("Moyenne"),
    "fontSizePreviewLabel": MessageLookupByLibrary.simpleMessage("Aperçu"),
    "fontSizePreviewText": MessageLookupByLibrary.simpleMessage(
      "Le vif renard brun saute par-dessus le chien paresseux.",
    ),
    "fontSizeSmall": MessageLookupByLibrary.simpleMessage("Petite"),
    "fontSizeTitle": MessageLookupByLibrary.simpleMessage("Taille de police"),
    "forgotPassword": MessageLookupByLibrary.simpleMessage(
      "Mot de passe oublié ?",
    ),
    "genericAuthError": MessageLookupByLibrary.simpleMessage(
      "Une erreur est survenue. Veuillez réessayer.",
    ),
    "gpu": MessageLookupByLibrary.simpleMessage(
      "Calcul de la moyenne scolaire",
    ),
    "guestUser": MessageLookupByLibrary.simpleMessage("Invité"),
    "hashtag": MessageLookupByLibrary.simpleMessage("#"),
    "hide": MessageLookupByLibrary.simpleMessage("Masquer"),
    "home": MessageLookupByLibrary.simpleMessage("Accueil"),
    "homeSubtitle": MessageLookupByLibrary.simpleMessage(
      "Parcourez les facultés, calculez votre moyenne, partagez vos idées et notez facilement.",
    ),
    "horizontalUnit": MessageLookupByLibrary.simpleMessage("Unité horizontale"),
    "hotelTourismMarketing": MessageLookupByLibrary.simpleMessage(
      "Marketing hôtelier et touristique",
    ),
    "humanResourcesManagement": MessageLookupByLibrary.simpleMessage(
      "Gestion des ressources humaines",
    ),
    "internationalCooperation": MessageLookupByLibrary.simpleMessage(
      "Coopération internationale",
    ),
    "internationalEconomics": MessageLookupByLibrary.simpleMessage(
      "Économie internationale",
    ),
    "internationalRelations": MessageLookupByLibrary.simpleMessage(
      "Relations internationales",
    ),
    "invalidEmailError": MessageLookupByLibrary.simpleMessage(
      "L’adresse e-mail est invalide.",
    ),
    "invalidEmailValidation": MessageLookupByLibrary.simpleMessage(
      "Veuillez saisir une adresse e-mail valide.",
    ),
    "law": MessageLookupByLibrary.simpleMessage("Droit"),
    "legalProfessionsLaw": MessageLookupByLibrary.simpleMessage(
      "Droit des professions juridiques et judiciaires",
    ),
    "light": MessageLookupByLibrary.simpleMessage("Clair"),
    "lightMode": MessageLookupByLibrary.simpleMessage("Mode clair"),
    "localAdministration": MessageLookupByLibrary.simpleMessage(
      "Administration locale",
    ),
    "login": MessageLookupByLibrary.simpleMessage("Se connecter"),
    "logout": MessageLookupByLibrary.simpleMessage("Se déconnecter"),
    "logoutAllConfirm": MessageLookupByLibrary.simpleMessage("Se déconnecter"),
    "logoutAllDevices": MessageLookupByLibrary.simpleMessage(
      "Déconnecter tous les appareils",
    ),
    "logoutAllDevicesPrompt": MessageLookupByLibrary.simpleMessage(
      "Nous vous déconnecterons sur cet appareil. Activez la révocation backend pour les autres sessions.",
    ),
    "logoutAllFailed": MessageLookupByLibrary.simpleMessage(
      "Impossible de déconnecter tous les appareils.",
    ),
    "logoutAllLocalOnly": MessageLookupByLibrary.simpleMessage(
      "Déconnecté ici. Configurez la révocation backend pour les autres appareils.",
    ),
    "logoutAllOtherDevices": MessageLookupByLibrary.simpleMessage(
      "Déconnecter les autres appareils",
    ),
    "logoutAllSuccess": MessageLookupByLibrary.simpleMessage(
      "Déconnexion de tous les appareils réussie.",
    ),
    "major": MessageLookupByLibrary.simpleMessage("Spécialité"),
    "majors": MessageLookupByLibrary.simpleMessage("Spécialités"),
    "manageDevicesDescription": MessageLookupByLibrary.simpleMessage(
      "Consultez les connexions et retirez l\'accès si nécessaire.",
    ),
    "manageDevicesHint": MessageLookupByLibrary.simpleMessage(
      "Consultez les sessions actives et les appareils.",
    ),
    "manageDevicesTitle": MessageLookupByLibrary.simpleMessage(
      "Gérer les appareils",
    ),
    "managementSciences": MessageLookupByLibrary.simpleMessage(
      "Sciences de gestion",
    ),
    "managementSciencesDept": MessageLookupByLibrary.simpleMessage(
      "Département des sciences de gestion",
    ),
    "maritimePortLaw": MessageLookupByLibrary.simpleMessage(
      "Droit maritime et portuaire",
    ),
    "marketing": MessageLookupByLibrary.simpleMessage("Marketing"),
    "mediaUrl": MessageLookupByLibrary.simpleMessage("Lien image/vidéo"),
    "methodologicalUnit": MessageLookupByLibrary.simpleMessage(
      "Unité méthodologique",
    ),
    "monetaryFinancialEconomics": MessageLookupByLibrary.simpleMessage(
      "Économie monétaire et financière",
    ),
    "mood": MessageLookupByLibrary.simpleMessage("Humeur"),
    "name": MessageLookupByLibrary.simpleMessage("Nom"),
    "networkError": MessageLookupByLibrary.simpleMessage(
      "Erreur réseau. Veuillez réessayer.",
    ),
    "newPost": MessageLookupByLibrary.simpleMessage("Nouvelle publication"),
    "noExamsDay": MessageLookupByLibrary.simpleMessage(
      "Aucun examen pour ce jour",
    ),
    "noMajorsYet": MessageLookupByLibrary.simpleMessage(
      "Aucune spécialité enregistrée pour le moment",
    ),
    "noNotesYet": MessageLookupByLibrary.simpleMessage(
      "Aucune note pour le moment",
    ),
    "noPostsYet": MessageLookupByLibrary.simpleMessage(
      "Aucune publication pour le moment",
    ),
    "noSubjectsThisSemester": MessageLookupByLibrary.simpleMessage(
      "Aucune matière dans ce semestre.",
    ),
    "notRegistered": MessageLookupByLibrary.simpleMessage("Non enregistré"),
    "note": MessageLookupByLibrary.simpleMessage("Note"),
    "notesTdTpExam": MessageLookupByLibrary.simpleMessage("Notes (TD/TP/Exam)"),
    "notificationsAnnouncements": MessageLookupByLibrary.simpleMessage(
      "Annonces",
    ),
    "notificationsAnnouncementsHint": MessageLookupByLibrary.simpleMessage(
      "Restez informé des actualités du campus.",
    ),
    "notificationsCommunity": MessageLookupByLibrary.simpleMessage(
      "Mises à jour de la communauté",
    ),
    "notificationsCommunityHint": MessageLookupByLibrary.simpleMessage(
      "Soyez notifié de l\'activité de la communauté.",
    ),
    "notificationsDisabledHint": MessageLookupByLibrary.simpleMessage(
      "Activez les notifications pour gérer les rappels et alertes.",
    ),
    "notificationsEnabled": MessageLookupByLibrary.simpleMessage(
      "Activer les notifications",
    ),
    "notificationsEnabledHint": MessageLookupByLibrary.simpleMessage(
      "Recevez des alertes sur les mises à jour et rappels.",
    ),
    "notificationsExamReminders": MessageLookupByLibrary.simpleMessage(
      "Rappels d\'examens",
    ),
    "notificationsExamRemindersHint": MessageLookupByLibrary.simpleMessage(
      "Recevez des alertes locales pour les examens planifiés.",
    ),
    "notificationsSettingsDescription": MessageLookupByLibrary.simpleMessage(
      "Gérez les notifications et rappels.",
    ),
    "notificationsSettingsTitle": MessageLookupByLibrary.simpleMessage(
      "Notifications",
    ),
    "oneMajor": MessageLookupByLibrary.simpleMessage("Une spécialité"),
    "otherNotes": MessageLookupByLibrary.simpleMessage("Autres notes"),
    "otherSessionsSignedOutSuccess": MessageLookupByLibrary.simpleMessage(
      "Déconnexion des autres appareils effectuée.",
    ),
    "otpCooldownLabel": m14,
    "otpSentFailed": MessageLookupByLibrary.simpleMessage(
      "Impossible d\'envoyer le lien de vérification pour le moment.",
    ),
    "otpSentSuccess": MessageLookupByLibrary.simpleMessage(
      "Lien de vérification envoyé. Vérifiez votre e-mail.",
    ),
    "pass": MessageLookupByLibrary.simpleMessage(" Réussi"),
    "password": MessageLookupByLibrary.simpleMessage("Mot de passe"),
    "pinNote": MessageLookupByLibrary.simpleMessage("Épingler la note"),
    "pinned": MessageLookupByLibrary.simpleMessage("Épinglées"),
    "politicalAdministrativeOrgs": MessageLookupByLibrary.simpleMessage(
      "Organisations politiques et administratives",
    ),
    "politicalSciences": MessageLookupByLibrary.simpleMessage(
      "Sciences politiques",
    ),
    "post": MessageLookupByLibrary.simpleMessage(
      "Votre publication a été publiée ✅",
    ),
    "posted": MessageLookupByLibrary.simpleMessage("Publication"),
    "posts": MessageLookupByLibrary.simpleMessage("Publications"),
    "privacyAccountOverviewSection": MessageLookupByLibrary.simpleMessage(
      "Aperçu du compte",
    ),
    "privacyAppVersionLabel": MessageLookupByLibrary.simpleMessage(
      "Version de l\'application",
    ),
    "privacyApproxLocationLabel": MessageLookupByLibrary.simpleMessage(
      "Localisation approximative",
    ),
    "privacyChangePasswordNowNote": MessageLookupByLibrary.simpleMessage(
      "Veuillez changer votre mot de passe immédiatement. Vérification en deux étapes : bientôt disponible.",
    ),
    "privacyChangePasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Changer le mot de passe",
    ),
    "privacyConfirmNewPasswordHelper": MessageLookupByLibrary.simpleMessage(
      "Saisissez à nouveau le nouveau mot de passe pour confirmation.",
    ),
    "privacyConfirmNewPasswordLabel": MessageLookupByLibrary.simpleMessage(
      "Confirmer le nouveau mot de passe",
    ),
    "privacyConnectionTypeLabel": MessageLookupByLibrary.simpleMessage(
      "Type de connexion",
    ),
    "privacyContinue": MessageLookupByLibrary.simpleMessage("Continuer"),
    "privacyContinueAction": MessageLookupByLibrary.simpleMessage("Continuer"),
    "privacyCopyFullIp": MessageLookupByLibrary.simpleMessage(
      "Copier l\'IP complète",
    ),
    "privacyCopyIpSuccess": MessageLookupByLibrary.simpleMessage(
      "IP complète copiée en toute sécurité.",
    ),
    "privacyCurrentPasswordHelper": MessageLookupByLibrary.simpleMessage(
      "Saisissez votre mot de passe actuel pour vérifier la propriété du compte.",
    ),
    "privacyCurrentPasswordLabel": MessageLookupByLibrary.simpleMessage(
      "Mot de passe actuel",
    ),
    "privacyDateTimeLabel": MessageLookupByLibrary.simpleMessage(
      "Date et heure",
    ),
    "privacyDeviceLabel": MessageLookupByLibrary.simpleMessage("Appareil"),
    "privacyEditNameTitle": MessageLookupByLibrary.simpleMessage(
      "Modifier le nom",
    ),
    "privacyEmailConfirmLabel": MessageLookupByLibrary.simpleMessage(
      "Confirmer le nouvel e-mail",
    ),
    "privacyEmailConfirmMismatch": MessageLookupByLibrary.simpleMessage(
      "Les e-mails ne correspondent pas.",
    ),
    "privacyEmailCurrentLabel": MessageLookupByLibrary.simpleMessage(
      "E-mail actuel",
    ),
    "privacyEmailCurrentMismatch": MessageLookupByLibrary.simpleMessage(
      "L\'e-mail actuel ne correspond pas.",
    ),
    "privacyEmailFlowSecurityNote": MessageLookupByLibrary.simpleMessage(
      "Note de sécurité : votre mot de passe n\'est jamais stocké dans l\'application.",
    ),
    "privacyEmailFlowSendLink": MessageLookupByLibrary.simpleMessage(
      "Envoyer le lien de changement d\'e-mail",
    ),
    "privacyEmailFlowStep1Help": m15,
    "privacyEmailFlowStep2Help": MessageLookupByLibrary.simpleMessage(
      "Nous enverrons un lien de changement d\'e-mail à votre boîte actuelle pour vérification.",
    ),
    "privacyEmailFlowStep3Help": MessageLookupByLibrary.simpleMessage(
      "Saisissez votre nouvel e-mail et confirmez-le.",
    ),
    "privacyEmailFlowStep4Help": m16,
    "privacyEmailFlowTitle": MessageLookupByLibrary.simpleMessage(
      "Modifier l\'e-mail",
    ),
    "privacyEmailNewLabel": MessageLookupByLibrary.simpleMessage(
      "Nouvel e-mail",
    ),
    "privacyEmailRowTitle": MessageLookupByLibrary.simpleMessage("E-mail"),
    "privacyEmailSaved": MessageLookupByLibrary.simpleMessage(
      "E-mail mis à jour localement.",
    ),
    "privacyEmailValidationRequired": MessageLookupByLibrary.simpleMessage(
      "Saisissez et confirmez le nouvel e-mail.",
    ),
    "privacyEnterConfirmToMatch": MessageLookupByLibrary.simpleMessage(
      "Saisissez la confirmation pour vérifier la correspondance.",
    ),
    "privacyFirstName": MessageLookupByLibrary.simpleMessage("Prénom"),
    "privacyIpAddressLabel": MessageLookupByLibrary.simpleMessage("Adresse IP"),
    "privacyIpUnavailable": MessageLookupByLibrary.simpleMessage(
      "Adresse IP indisponible.",
    ),
    "privacyLastName": MessageLookupByLibrary.simpleMessage("Nom"),
    "privacyLastPasswordChangeAt": m17,
    "privacyLastPasswordChangeTitle": MessageLookupByLibrary.simpleMessage(
      "Dernier changement de mot de passe",
    ),
    "privacyLastPasswordChangeUnavailable":
        MessageLookupByLibrary.simpleMessage(
          "Dernier changement de mot de passe : Non disponible",
        ),
    "privacyLoadFailed": MessageLookupByLibrary.simpleMessage(
      "Impossible de charger les données de confidentialité.",
    ),
    "privacyLoadingLastChange": MessageLookupByLibrary.simpleMessage(
      "Chargement des données du dernier changement...",
    ),
    "privacyManufacturerLabel": MessageLookupByLibrary.simpleMessage(
      "Fabricant",
    ),
    "privacyNameRowTitle": MessageLookupByLibrary.simpleMessage(
      "Prénom et nom",
    ),
    "privacyNameRuleAllowed": MessageLookupByLibrary.simpleMessage(
      "Vous pouvez modifier votre nom une fois par mois.",
    ),
    "privacyNameRuleBlockedDays": m18,
    "privacyNameRuleBlockedHours": m19,
    "privacyNameSaved": MessageLookupByLibrary.simpleMessage(
      "Nom mis à jour avec succès.",
    ),
    "privacyNameValidationLong": MessageLookupByLibrary.simpleMessage(
      "Maximum 40 caractères",
    ),
    "privacyNameValidationRequired": MessageLookupByLibrary.simpleMessage(
      "Ce champ est requis",
    ),
    "privacyNameValidationShort": MessageLookupByLibrary.simpleMessage(
      "Le nom doit contenir au moins 2 caractères",
    ),
    "privacyNetworkCellular": MessageLookupByLibrary.simpleMessage(
      "Données mobiles",
    ),
    "privacyNewPasswordHelper": MessageLookupByLibrary.simpleMessage(
      "Il doit contenir au moins 8 caractères.",
    ),
    "privacyNewPasswordLabel": MessageLookupByLibrary.simpleMessage(
      "Nouveau mot de passe",
    ),
    "privacyNoAuditDataYet": MessageLookupByLibrary.simpleMessage(
      "Aucune donnée disponible pour le moment.",
    ),
    "privacyNoEmailLinked": MessageLookupByLibrary.simpleMessage(
      "Aucun e-mail n\'est lié à ce compte.",
    ),
    "privacyNotAvailable": MessageLookupByLibrary.simpleMessage(
      "Non disponible",
    ),
    "privacyOperatingSystemLabel": MessageLookupByLibrary.simpleMessage(
      "Système d\'exploitation",
    ),
    "privacyOtherSessionsRevokedPrecaution":
        MessageLookupByLibrary.simpleMessage(
          "Les autres sessions ont été déconnectées par précaution.",
        ),
    "privacyPasswordMismatchError": MessageLookupByLibrary.simpleMessage(
      "Les mots de passe ne correspondent pas.",
    ),
    "privacyPasswordMustDifferError": MessageLookupByLibrary.simpleMessage(
      "Le nouveau mot de passe doit être différent de l\'actuel.",
    ),
    "privacyPasswordNewLengthError": MessageLookupByLibrary.simpleMessage(
      "Le nouveau mot de passe doit contenir au moins 8 caractères.",
    ),
    "privacyPasswordReauthFailedGeneric": MessageLookupByLibrary.simpleMessage(
      "Impossible de vérifier votre identité. Réessayez plus tard.",
    ),
    "privacyPasswordStrengthLabel": MessageLookupByLibrary.simpleMessage(
      "Solidité du mot de passe : ",
    ),
    "privacyPasswordStrengthMedium": MessageLookupByLibrary.simpleMessage(
      "Moyenne",
    ),
    "privacyPasswordStrengthStrong": MessageLookupByLibrary.simpleMessage(
      "Forte",
    ),
    "privacyPasswordStrengthWeak": MessageLookupByLibrary.simpleMessage(
      "Faible",
    ),
    "privacyPasswordUpdateAction": MessageLookupByLibrary.simpleMessage(
      "Mettre à jour",
    ),
    "privacyPasswordUpdateConfirmBody": MessageLookupByLibrary.simpleMessage(
      "Voulez-vous mettre à jour le mot de passe ?",
    ),
    "privacyPasswordUpdateConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Confirmer la mise à jour",
    ),
    "privacyPasswordUpdateFailed": MessageLookupByLibrary.simpleMessage(
      "Impossible de mettre à jour le mot de passe. Réessayez plus tard.",
    ),
    "privacyPasswordUpdateRequiresSignin": MessageLookupByLibrary.simpleMessage(
      "Impossible de mettre à jour le mot de passe. Veuillez vous reconnecter.",
    ),
    "privacyPasswordUpdateSuccess": MessageLookupByLibrary.simpleMessage(
      "Mot de passe mis à jour avec succès.",
    ),
    "privacyPasswordsMatch": MessageLookupByLibrary.simpleMessage(
      "Les mots de passe correspondent.",
    ),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage(
      "Politique de confidentialité",
    ),
    "privacyPolicyBody": MessageLookupByLibrary.simpleMessage(
      "Chez UniSpace, nous accordons une grande importance à la confidentialité des utilisateurs et nous nous engageons à protéger leurs données et à respecter leur vie privée. Cette politique explique comment les informations sont traitées lors de l\'utilisation de l\'application.\n\n1) Données que nous collectons\nNous pouvons collecter uniquement le minimum de données nécessaires au bon fonctionnement de l\'application, notamment :\n- E-mail : utilisé pour créer un compte, se connecter et vérifier l\'identité de l\'utilisateur.\n- Nom d\'utilisateur ou nom personnel : choisi par l\'utilisateur dans l\'application.\nNous ne collectons aucune donnée supplémentaire sans l\'accord ou la connaissance de l\'utilisateur.\n\n2) Données locales sur l\'appareil\nL\'application peut permettre à l\'utilisateur de saisir des données d\'étude telles que :\n- Notes\n- Remarques\n- Informations d\'organisation des études ou des examens\nImportant :\n- Ces données sont stockées localement uniquement sur l\'appareil de l\'utilisateur.\n- Elles ne sont pas envoyées à nos serveurs.\n- Nous n\'y accédons pas, ne les collectons pas et ne les partageons pas.\n- Elles restent entièrement sous le contrôle de l\'utilisateur.\n\n3) Utilisation des données\nNous utilisons les données collectées uniquement pour :\n- Permettre à l\'utilisateur de créer un compte et de se connecter.\n- Améliorer l\'expérience d\'utilisation de l\'application.\n- Assurer la sécurité du compte et prévenir l\'utilisation non autorisée.\n\n4) Partage des données\n- Nous ne vendons, ne louons ni ne partageons les données des utilisateurs avec aucun tiers.\n- Aucune information personnelle n\'est partagée sauf si la loi l\'exige.\n\n5) Services tiers\nL\'application utilise des services fiables tels que Firebase de Google pour l\'authentification et la sécurité des comptes.\nCes services sont soumis à leurs propres politiques de confidentialité, et nous les utilisons conformément aux meilleures pratiques de sécurité.\n\n6) Sécurité des données\nNous appliquons des mesures de sécurité appropriées pour protéger les données des utilisateurs contre l\'accès non autorisé, la modification ou la perte.\n\n7) Confidentialité des enfants\nUniSpace est destiné aux étudiants universitaires et ne cible pas les enfants de moins de 13 ans, et nous ne collectons pas sciemment de données à leur sujet.\n\n8) Modifications de la politique de confidentialité\nNous pouvons mettre à jour la politique de confidentialité de temps à autre.\nLes utilisateurs seront informés de tout changement important dans l\'application.\n\n9) Nous contacter\nSi vous avez des questions concernant cette politique de confidentialité, vous pouvez nous contacter via la section \"Contactez-nous\" dans l\'application.\n\nEn utilisant UniSpace, vous acceptez cette politique de confidentialité.",
    ),
    "privacyPolicyTitle": MessageLookupByLibrary.simpleMessage(
      "Politique de confidentialité – UniSpace",
    ),
    "privacyReauthCopyIpReason": MessageLookupByLibrary.simpleMessage(
      "Vérifiez votre identité pour copier l\'IP complète.",
    ),
    "privacyReauthFailed": MessageLookupByLibrary.simpleMessage(
      "Échec de la vérification du mot de passe. Réessayez.",
    ),
    "privacyReauthSubtitle": MessageLookupByLibrary.simpleMessage(
      "Pour votre sécurité, saisissez votre mot de passe actuel avant de continuer.",
    ),
    "privacyReauthTitle": MessageLookupByLibrary.simpleMessage(
      "Confirmer le mot de passe",
    ),
    "privacyResetEmailHint": MessageLookupByLibrary.simpleMessage(
      "L\'e-mail peut arriver dans une minute. Vérifiez aussi le dossier spam.",
    ),
    "privacyResetLinkFailed": MessageLookupByLibrary.simpleMessage(
      "Impossible d\'envoyer le lien. Réessayez plus tard.",
    ),
    "privacyResetLinkSent": MessageLookupByLibrary.simpleMessage(
      "Lien de réinitialisation envoyé à votre e-mail.",
    ),
    "privacyResetPasswordDialogBody": m20,
    "privacyRevokeSessionsFailed": MessageLookupByLibrary.simpleMessage(
      "Impossible de terminer toutes les sessions pour le moment.",
    ),
    "privacySaveNewPassword": MessageLookupByLibrary.simpleMessage(
      "Enregistrer le nouveau mot de passe",
    ),
    "privacySecurityAlertBody": MessageLookupByLibrary.simpleMessage(
      "Si vous n\'avez pas changé le mot de passe, nous déconnecterons immédiatement toutes les autres sessions. Voulez-vous continuer ?",
    ),
    "privacySecurityAlertTitle": MessageLookupByLibrary.simpleMessage(
      "Alerte de sécurité critique",
    ),
    "privacySegmentTitle": MessageLookupByLibrary.simpleMessage(
      "Confidentialité",
    ),
    "privacySendResetLinkAction": MessageLookupByLibrary.simpleMessage(
      "Envoyer le lien",
    ),
    "privacySettingsDescription": MessageLookupByLibrary.simpleMessage(
      "Contrôlez ce que les autres voient sur votre profil.",
    ),
    "privacySettingsTitle": MessageLookupByLibrary.simpleMessage(
      "Confidentialité",
    ),
    "privacyStepOf": m21,
    "privacyTabSubtitle": MessageLookupByLibrary.simpleMessage(
      "Gérez vos données de compte en toute sécurité",
    ),
    "privacyTabTitle": MessageLookupByLibrary.simpleMessage("Confidentialité"),
    "privacyThisWasNotMe": MessageLookupByLibrary.simpleMessage(
      "Ce n\'était pas moi",
    ),
    "privacyUnknown": MessageLookupByLibrary.simpleMessage("Inconnu"),
    "privacyViewDetails": MessageLookupByLibrary.simpleMessage(
      "Voir les détails ⌄",
    ),
    "privateLaw": MessageLookupByLibrary.simpleMessage("Droit privé"),
    "profile": MessageLookupByLibrary.simpleMessage("Profil"),
    "profileVisibilityPrivate": MessageLookupByLibrary.simpleMessage("Privé"),
    "profileVisibilityPublic": MessageLookupByLibrary.simpleMessage("Public"),
    "profileVisibilityTitle": MessageLookupByLibrary.simpleMessage(
      "Visibilité du profil",
    ),
    "publicLaw": MessageLookupByLibrary.simpleMessage("Droit public"),
    "publish": MessageLookupByLibrary.simpleMessage("Publier"),
    "quickCalc": MessageLookupByLibrary.simpleMessage("Calcul rapide"),
    "quickCalc2": MessageLookupByLibrary.simpleMessage("Calcul rapide"),
    "rateApp": MessageLookupByLibrary.simpleMessage("Évaluer l\'application"),
    "rateAppFailed": MessageLookupByLibrary.simpleMessage(
      "Impossible d\'ouvrir la boutique pour le moment.",
    ),
    "register": MessageLookupByLibrary.simpleMessage("S\'inscrire"),
    "reminder24h": MessageLookupByLibrary.simpleMessage("24 heures avant"),
    "reminder2h": MessageLookupByLibrary.simpleMessage("2 heures avant"),
    "reminder30m": MessageLookupByLibrary.simpleMessage("30 minutes avant"),
    "reminders": MessageLookupByLibrary.simpleMessage("Rappels"),
    "report": MessageLookupByLibrary.simpleMessage("Signaler"),
    "resendVerificationCooldown": m22,
    "resendVerificationEmail": MessageLookupByLibrary.simpleMessage(
      "Renvoyer l\'e-mail de vérification",
    ),
    "resetFailed": m23,
    "resetLinkFailed": MessageLookupByLibrary.simpleMessage(
      "Impossible d’envoyer le lien, réessayez.",
    ),
    "resetLinkSentSuccess": MessageLookupByLibrary.simpleMessage(
      "Si cet e-mail correspond à un compte, un lien de réinitialisation arrivera. Vérifiez aussi les indésirables.",
    ),
    "resetPassword": MessageLookupByLibrary.simpleMessage(
      "Réinitialiser le mot de passe",
    ),
    "resetPasswordHelper": MessageLookupByLibrary.simpleMessage(
      "Entrez votre e-mail et nous vous enverrons un lien de réinitialisation.",
    ),
    "resetPasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Réinitialiser le mot de passe",
    ),
    "resetSent": MessageLookupByLibrary.simpleMessage(
      "Le lien de réinitialisation a été envoyé",
    ),
    "save": MessageLookupByLibrary.simpleMessage("Enregistrer"),
    "saveChanges": MessageLookupByLibrary.simpleMessage(
      "Enregistrer les modifications",
    ),
    "saveExam": MessageLookupByLibrary.simpleMessage("Enregistrer l\'examen"),
    "savePost": MessageLookupByLibrary.simpleMessage(
      "Enregistrer la publication",
    ),
    "searchClipboard": MessageLookupByLibrary.simpleMessage(
      "Rechercher dans le bloc-notes…",
    ),
    "searchFaculty": MessageLookupByLibrary.simpleMessage(
      "Rechercher une faculté...",
    ),
    "searchNoResults": MessageLookupByLibrary.simpleMessage("Aucun résultat"),
    "searchStartTyping": MessageLookupByLibrary.simpleMessage(
      "Commencez à taper pour rechercher",
    ),
    "sections": MessageLookupByLibrary.simpleMessage("Sections"),
    "securityCenterTitle": MessageLookupByLibrary.simpleMessage("Sécurité"),
    "securityPrivacyTitle": MessageLookupByLibrary.simpleMessage(
      "Sécurité et confidentialité",
    ),
    "securitySegmentTitle": MessageLookupByLibrary.simpleMessage("Sécurité"),
    "sendOtpNow": MessageLookupByLibrary.simpleMessage(
      "Envoyer l\'OTP maintenant",
    ),
    "sendResetLink": MessageLookupByLibrary.simpleMessage("Envoyer le lien"),
    "sendResetLinkLoading": MessageLookupByLibrary.simpleMessage("Envoi..."),
    "servicesMarketing": MessageLookupByLibrary.simpleMessage(
      "Marketing des services",
    ),
    "sessionAgoDays": m24,
    "sessionAgoHours": m25,
    "sessionAgoMinutes": m26,
    "sessionDeviceNameLabel": MessageLookupByLibrary.simpleMessage(
      "Nom de l\'appareil",
    ),
    "sessionLastActivityLabel": MessageLookupByLibrary.simpleMessage(
      "Dernière activité",
    ),
    "sessionLoginDateLabel": MessageLookupByLibrary.simpleMessage(
      "Date de connexion",
    ),
    "sessionModelLabel": MessageLookupByLibrary.simpleMessage("Modèle"),
    "sessionNetworkLabel": MessageLookupByLibrary.simpleMessage("Réseau"),
    "sessionPlatformLabel": MessageLookupByLibrary.simpleMessage("Plateforme"),
    "sessionSignOutFailed": MessageLookupByLibrary.simpleMessage(
      "Impossible de déconnecter cette session.",
    ),
    "sessionSignedOutSuccess": MessageLookupByLibrary.simpleMessage(
      "Session déconnectée avec succès.",
    ),
    "sessionTrustedDevice": MessageLookupByLibrary.simpleMessage(
      "Appareil de confiance",
    ),
    "sessionUnknownDevice": MessageLookupByLibrary.simpleMessage(
      "Appareil inconnu",
    ),
    "sessionVersionLabel": MessageLookupByLibrary.simpleMessage("Version"),
    "share": MessageLookupByLibrary.simpleMessage("Partager"),
    "shareApp": MessageLookupByLibrary.simpleMessage("Partager l\'application"),
    "shareAppMessage": MessageLookupByLibrary.simpleMessage(
      "Découvrez UniSpace pour des outils d\'étude intelligents et une communauté étudiante !",
    ),
    "showEmailInProfileHint": MessageLookupByLibrary.simpleMessage(
      "Autoriser les autres à voir votre e-mail.",
    ),
    "showEmailInProfileTitle": MessageLookupByLibrary.simpleMessage(
      "Afficher l\'e-mail dans le profil",
    ),
    "signInRequired": MessageLookupByLibrary.simpleMessage(
      "Veuillez vous connecter pour continuer.",
    ),
    "signOut": MessageLookupByLibrary.simpleMessage("Se déconnecter"),
    "smartReviewActionAddExam": MessageLookupByLibrary.simpleMessage(
      "Ajouter un examen",
    ),
    "smartReviewActionAddSubjects": MessageLookupByLibrary.simpleMessage(
      "Ajouter des matières",
    ),
    "smartReviewActionClearPlan": MessageLookupByLibrary.simpleMessage(
      "Supprimer le plan",
    ),
    "smartReviewActionLater": MessageLookupByLibrary.simpleMessage("Plus tard"),
    "smartReviewBottomSheetBody": MessageLookupByLibrary.simpleMessage(
      "Ajoutez vos matières et dates d’examen pour personnaliser le planning.",
    ),
    "smartReviewBottomSheetTitle": MessageLookupByLibrary.simpleMessage(
      "Avant de créer votre plan",
    ),
    "smartReviewChipExams": MessageLookupByLibrary.simpleMessage("Axé examens"),
    "smartReviewChipReminders": MessageLookupByLibrary.simpleMessage("Rappels"),
    "smartReviewChipSimple": MessageLookupByLibrary.simpleMessage(
      "Simple à suivre",
    ),
    "smartReviewChipTime": MessageLookupByLibrary.simpleMessage(
      "Gestion du temps",
    ),
    "smartReviewCtaCreate": MessageLookupByLibrary.simpleMessage(
      "Créer un plan de révision",
    ),
    "smartReviewEmptyNoExamsBody": MessageLookupByLibrary.simpleMessage(
      "Ajoutez au moins un examen pour générer un plan de révision ciblé.",
    ),
    "smartReviewEmptyNoExamsTitle": MessageLookupByLibrary.simpleMessage(
      "Aucun examen à venir",
    ),
    "smartReviewEmptyNoPlanBody": MessageLookupByLibrary.simpleMessage(
      "Nous générerons un planning de 7 jours basé sur votre examen le plus proche et votre temps d’étude.",
    ),
    "smartReviewEmptyNoPlanTitle": MessageLookupByLibrary.simpleMessage(
      "Prêt à créer votre plan",
    ),
    "smartReviewPlanCleared": MessageLookupByLibrary.simpleMessage(
      "Plan supprimé",
    ),
    "smartReviewPlanComingSoon": MessageLookupByLibrary.simpleMessage(
      "Bientôt",
    ),
    "smartReviewPlanCtaCreate": MessageLookupByLibrary.simpleMessage(
      "Créer un plan",
    ),
    "smartReviewPlanDescription": MessageLookupByLibrary.simpleMessage(
      "Générez un plan de révision ciblé selon vos examens à venir et vos objectifs.",
    ),
    "smartReviewPlanRange": m27,
    "smartReviewPlanSectionTitle": MessageLookupByLibrary.simpleMessage(
      "Votre plan",
    ),
    "smartReviewPlanTitle": MessageLookupByLibrary.simpleMessage(
      "Plan de révision intelligent",
    ),
    "smartReviewPreviewItem1": MessageLookupByLibrary.simpleMessage(
      "Aujourd\'hui · 2 sessions focus (45 min)",
    ),
    "smartReviewPreviewItem2": MessageLookupByLibrary.simpleMessage(
      "Demain · 1 quiz blanc + récap",
    ),
    "smartReviewPreviewItem3": MessageLookupByLibrary.simpleMessage(
      "Cette semaine · Priorisez les matières difficiles",
    ),
    "smartReviewPreviewTitle": MessageLookupByLibrary.simpleMessage(
      "Aperçu de la semaine",
    ),
    "smartReviewSubtitle": MessageLookupByLibrary.simpleMessage(
      "Transformez vos examens à venir en un planning quotidien équilibré.",
    ),
    "smartReviewTaskDuration": m28,
    "smartReviewTaskFocusTitle": m29,
    "smartReviewTaskMockTitle": m30,
    "smartReviewTaskPracticeTitle": m31,
    "smartReviewTaskSummaryTitle": m32,
    "smartReviewTipsBody": MessageLookupByLibrary.simpleMessage(
      "Nous analysons vos examens, le temps restant et la difficulté pour créer des sessions quotidiennes réalistes.",
    ),
    "smartReviewTipsTitle": MessageLookupByLibrary.simpleMessage(
      "Comment ça marche",
    ),
    "smartReviewTitle": MessageLookupByLibrary.simpleMessage(
      "Plan de révision intelligent",
    ),
    "soon": MessageLookupByLibrary.simpleMessage("Bientôt"),
    "startDiscussion": MessageLookupByLibrary.simpleMessage(
      "Commencez la première discussion dans la communauté et partagez votre expérience avec vos collègues.",
    ),
    "studyResults": MessageLookupByLibrary.simpleMessage("Résultats d\'étude"),
    "system": MessageLookupByLibrary.simpleMessage("Système"),
    "systemMode": MessageLookupByLibrary.simpleMessage("Mode système"),
    "taxLaw": MessageLookupByLibrary.simpleMessage("Droit fiscal"),
    "title": MessageLookupByLibrary.simpleMessage("Titre"),
    "tooManyRequestsError": MessageLookupByLibrary.simpleMessage(
      "Trop de demandes, réessayez plus tard.",
    ),
    "trustedDevicesTitle": MessageLookupByLibrary.simpleMessage(
      "Appareils de confiance",
    ),
    "twoFactorAttemptsRemaining": m33,
    "twoFactorAuthHint": MessageLookupByLibrary.simpleMessage(
      "Exiger un code OTP lors de la connexion.",
    ),
    "twoFactorAuthTitle": MessageLookupByLibrary.simpleMessage(
      "Authentification à deux facteurs",
    ),
    "twoFactorBackToLogin": MessageLookupByLibrary.simpleMessage(
      "Retour à la connexion",
    ),
    "twoFactorChallengeMissing": MessageLookupByLibrary.simpleMessage(
      "Session de vérification introuvable. Reconnectez-vous.",
    ),
    "twoFactorCodeExpired": MessageLookupByLibrary.simpleMessage(
      "Code expiré. Demandez un nouveau code.",
    ),
    "twoFactorCodeHint": MessageLookupByLibrary.simpleMessage(
      "Code à 6 chiffres",
    ),
    "twoFactorCodeIncorrect": MessageLookupByLibrary.simpleMessage(
      "Code incorrect. Réessayez.",
    ),
    "twoFactorCodeInvalidFormat": MessageLookupByLibrary.simpleMessage(
      "Entrez un code valide à 6 chiffres.",
    ),
    "twoFactorCodeLabel": MessageLookupByLibrary.simpleMessage(
      "Code de vérification",
    ),
    "twoFactorCodeSent": MessageLookupByLibrary.simpleMessage(
      "Code de vérification envoyé par e-mail.",
    ),
    "twoFactorConfirmButton": MessageLookupByLibrary.simpleMessage("Confirmer"),
    "twoFactorDisabledToast": MessageLookupByLibrary.simpleMessage(
      "Authentification à deux facteurs désactivée.",
    ),
    "twoFactorEnableConfirmBody": MessageLookupByLibrary.simpleMessage(
      "Un code à usage unique sera demandé après la connexion par mot de passe.",
    ),
    "twoFactorEnableConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Activer l’authentification à deux facteurs ?",
    ),
    "twoFactorEnabledToast": MessageLookupByLibrary.simpleMessage(
      "Authentification à deux facteurs activée.",
    ),
    "twoFactorGenericError": MessageLookupByLibrary.simpleMessage(
      "Vérification impossible. Réessayez.",
    ),
    "twoFactorOtpDescription": m34,
    "twoFactorOtpTitle": MessageLookupByLibrary.simpleMessage(
      "Code de vérification par e-mail",
    ),
    "twoFactorResendCode": MessageLookupByLibrary.simpleMessage(
      "Renvoyer le code",
    ),
    "twoFactorResendCooldown": MessageLookupByLibrary.simpleMessage(
      "Veuillez patienter avant de renvoyer.",
    ),
    "twoFactorResendIn": m35,
    "twoFactorSendFailed": MessageLookupByLibrary.simpleMessage(
      "Échec de l’envoi du code de vérification.",
    ),
    "twoFactorTooManyAttempts": MessageLookupByLibrary.simpleMessage(
      "Trop de tentatives échouées. Réessayez plus tard.",
    ),
    "twoFactorVerifiedSuccess": MessageLookupByLibrary.simpleMessage(
      "Vérification à deux facteurs terminée.",
    ),
    "unblockUser": MessageLookupByLibrary.simpleMessage("Débloquer"),
    "university": MessageLookupByLibrary.simpleMessage("Université"),
    "userDisabledError": MessageLookupByLibrary.simpleMessage(
      "Ce compte est désactivé.",
    ),
    "userInfo": MessageLookupByLibrary.simpleMessage(
      "Informations utilisateur",
    ),
    "userNotFoundError": MessageLookupByLibrary.simpleMessage(
      "Aucun compte trouvé avec cet e-mail.",
    ),
    "verificationEmailSent": MessageLookupByLibrary.simpleMessage(
      "E-mail de vérification envoyé.",
    ),
    "verifyEmailHelper": MessageLookupByLibrary.simpleMessage(
      "Ouvrez l\'e-mail de vérification et cliquez sur le lien, puis appuyez sur vérifier maintenant.",
    ),
    "verifyEmailTitle": MessageLookupByLibrary.simpleMessage(
      "Vérifier l\'e-mail",
    ),
    "verifyEmailToContinue": MessageLookupByLibrary.simpleMessage(
      "Veuillez vérifier votre e-mail pour continuer.",
    ),
    "viewAll": MessageLookupByLibrary.simpleMessage("Voir tout"),
    "weakPasswordError": MessageLookupByLibrary.simpleMessage(
      "Le mot de passe est trop faible.",
    ),
    "welcomeEmoji": MessageLookupByLibrary.simpleMessage("Bienvenue 👋"),
    "welcomeUniSpace": MessageLookupByLibrary.simpleMessage(
      "Bienvenue sur UniSpace",
    ),
    "writeComment": MessageLookupByLibrary.simpleMessage(
      "Écrivez votre commentaire…",
    ),
    "writeYourComment": MessageLookupByLibrary.simpleMessage(
      "Écrivez votre commentaire",
    ),
    "wrongPasswordError": MessageLookupByLibrary.simpleMessage(
      "Mot de passe incorrect.",
    ),
  };
}
