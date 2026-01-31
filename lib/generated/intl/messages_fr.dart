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

  static String m0(count) => "Commentaires (${count})";

  static String m1(e) => "Échec de l\'envoi : ${e}";

  static String m2(min) => "Veuillez saisir au moins ${min} caractères";

  static String m3(max) => "Veuillez rester sous ${max} caractères";

  static String m4(subject) => "Rappel : ${subject} dans 24 heures";

  static String m5(subject) => "Rappel : ${subject} dans 2 heures";

  static String m6(subject) => "Rappel : ${subject} dans 30 minutes";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "Fail": MessageLookupByLibrary.simpleMessage(" Échoué"),
        "Pass": MessageLookupByLibrary.simpleMessage(" Réussi"),
        "aboutApp":
            MessageLookupByLibrary.simpleMessage("À propos de l\'application"),
        "aboutAppDetails": MessageLookupByLibrary.simpleMessage(
            "UniSpace ne collecte pas de données personnelles en dehors de Firebase. Toutes les données sont sécurisées."),
        "accounting": MessageLookupByLibrary.simpleMessage("Comptabilité"),
        "accountingTaxation":
            MessageLookupByLibrary.simpleMessage("Comptabilité et fiscalité"),
        "add": MessageLookupByLibrary.simpleMessage("Ajouter"),
        "advancedPublicLaw":
            MessageLookupByLibrary.simpleMessage("Droit public approfondi"),
        "arabic": MessageLookupByLibrary.simpleMessage("Arabe"),
        "archive": MessageLookupByLibrary.simpleMessage("Archives"),
        "basicEducation":
            MessageLookupByLibrary.simpleMessage("Enseignement de base"),
        "basicEducationDept": MessageLookupByLibrary.simpleMessage(
            "Département de l\'enseignement de base"),
        "basicUnit": MessageLookupByLibrary.simpleMessage("Unité fondamentale"),
        "blockAccount":
            MessageLookupByLibrary.simpleMessage("Bloquer le compte"),
        "businessAdministration":
            MessageLookupByLibrary.simpleMessage("Administration des affaires"),
        "businessLaw":
            MessageLookupByLibrary.simpleMessage("Droit des affaires"),
        "calculate": MessageLookupByLibrary.simpleMessage("Calculer"),
        "cancel": MessageLookupByLibrary.simpleMessage("Annuler"),
        "changeLanguage":
            MessageLookupByLibrary.simpleMessage("Changer la langue"),
        "changeTheme": MessageLookupByLibrary.simpleMessage("Changer le thème"),
        "chooseLanguage":
            MessageLookupByLibrary.simpleMessage("Choisir la langue"),
        "chooseTheme": MessageLookupByLibrary.simpleMessage("Choisir le thème"),
        "clipboard": MessageLookupByLibrary.simpleMessage("Note-pade"),
        "close": MessageLookupByLibrary.simpleMessage("Fermer"),
        "coefficient": MessageLookupByLibrary.simpleMessage("Coef :"),
        "comment": MessageLookupByLibrary.simpleMessage("Commentaire"),
        "comments": MessageLookupByLibrary.simpleMessage("Commentaires"),
        "commentsCount": m0,
        "commercialSciences":
            MessageLookupByLibrary.simpleMessage("Sciences commerciales"),
        "commercialSciencesDept": MessageLookupByLibrary.simpleMessage(
            "Département des sciences commerciales"),
        "commonCore": MessageLookupByLibrary.simpleMessage("Tronc commun"),
        "community": MessageLookupByLibrary.simpleMessage("Communauté"),
        "contactCategoryFeature": MessageLookupByLibrary.simpleMessage(
            "Suggestion de nouvelle fonctionnalité"),
        "contactCategoryImprovement":
            MessageLookupByLibrary.simpleMessage("Amélioration"),
        "contactCategoryIssue": MessageLookupByLibrary.simpleMessage("Problème"),
        "contactCategoryLabel":
            MessageLookupByLibrary.simpleMessage("Catégorie"),
        "contactCategoryOther": MessageLookupByLibrary.simpleMessage("Autre"),
        "contactCategoryReport":
            MessageLookupByLibrary.simpleMessage("Signalement"),
        "contactCopyAction": MessageLookupByLibrary.simpleMessage("Copier"),
        "contactCopyDialogBody": MessageLookupByLibrary.simpleMessage(
            "Copiez le message et envoyez-le au support via votre messagerie."),
        "contactCopyDialogTitle":
            MessageLookupByLibrary.simpleMessage("Copier le message"),
        "contactCopied": MessageLookupByLibrary.simpleMessage("Message copié"),
        "contactDescriptionHint": MessageLookupByLibrary.simpleMessage(
            "Expliquez les détails pour vous aider rapidement"),
        "contactDescriptionLabel":
            MessageLookupByLibrary.simpleMessage("Description"),
        "contactIncludeUserInfo": MessageLookupByLibrary.simpleMessage(
            "Inclure mes informations de compte"),
        "contactMailOpened": MessageLookupByLibrary.simpleMessage(
            "Application e-mail ouverte pour envoyer votre message"),
        "contactMailUnavailable": MessageLookupByLibrary.simpleMessage(
            "Aucune application e-mail disponible. Vous pouvez copier le message."),
        "contactMetadataAppVersion":
            MessageLookupByLibrary.simpleMessage("Version de l'application"),
        "contactMetadataEmail": MessageLookupByLibrary.simpleMessage("E-mail"),
        "contactMetadataHeader":
            MessageLookupByLibrary.simpleMessage("Métadonnées"),
        "contactMetadataLocale": MessageLookupByLibrary.simpleMessage("Langue"),
        "contactMetadataName": MessageLookupByLibrary.simpleMessage("Nom"),
        "contactMetadataPlatform":
            MessageLookupByLibrary.simpleMessage("Plateforme"),
        "contactMetadataTimestamp":
            MessageLookupByLibrary.simpleMessage("Horodatage"),
        "contactMetadataUserId":
            MessageLookupByLibrary.simpleMessage("ID utilisateur"),
        "contactScreenshotPlaceholder":
            MessageLookupByLibrary.simpleMessage("Joindre une capture d'écran"),
        "contactScreenshotSoon":
            MessageLookupByLibrary.simpleMessage("Bientôt disponible"),
        "contactSend": MessageLookupByLibrary.simpleMessage("Envoyer"),
        "contactSendFailure": MessageLookupByLibrary.simpleMessage(
            "Impossible d'envoyer votre message. Veuillez réessayer."),
        "contactSendSuccess": MessageLookupByLibrary.simpleMessage("Envoyé ✅"),
        "contactSending":
            MessageLookupByLibrary.simpleMessage("Envoi en cours..."),
        "contactSubjectHint": MessageLookupByLibrary.simpleMessage(
            "Bref résumé de votre demande"),
        "contactSubjectLabel": MessageLookupByLibrary.simpleMessage("Sujet"),
        "contactUs": MessageLookupByLibrary.simpleMessage("Contactez-nous"),
        "contactUsSubtitle": MessageLookupByLibrary.simpleMessage(
            "Nous sommes ravis d'avoir votre message. Envoyez-le au support."),
        "contactUserInfoUnavailable": MessageLookupByLibrary.simpleMessage(
            "Aucune information de compte disponible"),
        "contactValidationMaxLength": m3,
        "contactValidationMinLength": m2,
        "contactValidationRequired":
            MessageLookupByLibrary.simpleMessage("Ce champ est obligatoire"),
        "content": MessageLookupByLibrary.simpleMessage("Contenu"),
        "copyText": MessageLookupByLibrary.simpleMessage("Copier le texte"),
        "corporateFinance":
            MessageLookupByLibrary.simpleMessage("Finance d\'entreprise"),
        "corporateFinancialManagement": MessageLookupByLibrary.simpleMessage(
            "Gestion financière des entreprises"),
        "createPost": MessageLookupByLibrary.simpleMessage("Publication"),
        "createPoste":
            MessageLookupByLibrary.simpleMessage("Créer une publication"),
        "credits": MessageLookupByLibrary.simpleMessage("Crédits :"),
        "criminalLaw": MessageLookupByLibrary.simpleMessage(
            "Droit pénal et sciences criminelles"),
        "dark": MessageLookupByLibrary.simpleMessage("Sombre"),
        "darkMode": MessageLookupByLibrary.simpleMessage("Mode sombre"),
        "department": MessageLookupByLibrary.simpleMessage("Department"),
        "deptArabicLangLit": MessageLookupByLibrary.simpleMessage(
            "Département de langue et littérature arabes"),
        "deptEnglishLangLit": MessageLookupByLibrary.simpleMessage(
            "Département de langue et littérature anglaises"),
        "deptFrenchLangLit": MessageLookupByLibrary.simpleMessage(
            "Département de langue et littérature françaises"),
        "economics":
            MessageLookupByLibrary.simpleMessage("Sciences économiques"),
        "economicsDept": MessageLookupByLibrary.simpleMessage(
            "Département des sciences économiques"),
        "email": MessageLookupByLibrary.simpleMessage("E-mail"),
        "energyMiningLaw": MessageLookupByLibrary.simpleMessage(
            "Droit de l’énergie et des mines"),
        "exploratoryUnit":
            MessageLookupByLibrary.simpleMessage("Unité exploratoire"),
        "faculties": MessageLookupByLibrary.simpleMessage("Facultés"),
        "faculty": MessageLookupByLibrary.simpleMessage("Faculty"),
        "facultyArtsLanguages": MessageLookupByLibrary.simpleMessage(
            "Faculté des lettres et des langues étrangères"),
        "facultyEconomics": MessageLookupByLibrary.simpleMessage(
            "Faculté des sciences économiques, commerciales et des sciences de gestion"),
        "facultyLawPolitical": MessageLookupByLibrary.simpleMessage(
            "Faculté de droit et des sciences politiques"),
        "familyLaw":
            MessageLookupByLibrary.simpleMessage("Droit de la famille"),
        "finance": MessageLookupByLibrary.simpleMessage("Finance"),
        "financeInternationalTrade": MessageLookupByLibrary.simpleMessage(
            "Finance et commerce international"),
        "financialAccounting": MessageLookupByLibrary.simpleMessage(
            "Sciences financières et comptables"),
        "financialAccountingDept": MessageLookupByLibrary.simpleMessage(
            "Département des sciences financières et comptables"),
        "financialManagement":
            MessageLookupByLibrary.simpleMessage("Gestion financière"),
        "followComment":
            MessageLookupByLibrary.simpleMessage("Suivre le commentaire"),
        "following": MessageLookupByLibrary.simpleMessage("Following"),
        "hashtag": MessageLookupByLibrary.simpleMessage("#"),
        "hide": MessageLookupByLibrary.simpleMessage("Masquer"),
        "home": MessageLookupByLibrary.simpleMessage("Accueil"),
        "homeSubtitle": MessageLookupByLibrary.simpleMessage(
            "Parcourez les facultés, calculez votre moyenne, partagez vos idées et notez facilement."),
        "horizontalUnit":
            MessageLookupByLibrary.simpleMessage("Unité horizontale"),
        "hotelTourismMarketing": MessageLookupByLibrary.simpleMessage(
            "Marketing hôtelier et touristique"),
        "humanResourcesManagement": MessageLookupByLibrary.simpleMessage(
            "Gestion des ressources humaines"),
        "internationalCooperation":
            MessageLookupByLibrary.simpleMessage("Coopération internationale"),
        "internationalEconomics":
            MessageLookupByLibrary.simpleMessage("Économie internationale"),
        "internationalRelations":
            MessageLookupByLibrary.simpleMessage("Relations internationales"),
        "law": MessageLookupByLibrary.simpleMessage("Droit"),
        "legalProfessionsLaw": MessageLookupByLibrary.simpleMessage(
            "Droit des professions juridiques et judiciaires"),
        "light": MessageLookupByLibrary.simpleMessage("Clair"),
        "lightMode": MessageLookupByLibrary.simpleMessage("Mode clair"),
        "localAdministration":
            MessageLookupByLibrary.simpleMessage("Administration locale"),
        "login": MessageLookupByLibrary.simpleMessage("Se connecter"),
        "logout": MessageLookupByLibrary.simpleMessage("Se déconnecter"),
        "major": MessageLookupByLibrary.simpleMessage("Major"),
        "majors": MessageLookupByLibrary.simpleMessage("Spécialités"),
        "managementSciences":
            MessageLookupByLibrary.simpleMessage("Sciences de gestion"),
        "managementSciencesDept": MessageLookupByLibrary.simpleMessage(
            "Département des sciences de gestion"),
        "maritimePortLaw":
            MessageLookupByLibrary.simpleMessage("Droit maritime et portuaire"),
        "marketing": MessageLookupByLibrary.simpleMessage("Marketing"),
        "mediaUrl": MessageLookupByLibrary.simpleMessage("Lien image/vidéo"),
        "methodologicalUnit":
            MessageLookupByLibrary.simpleMessage("Unité méthodologique"),
        "monetaryFinancialEconomics": MessageLookupByLibrary.simpleMessage(
            "Économie monétaire et financière"),
        "mood": MessageLookupByLibrary.simpleMessage("Humeur"),
        "name": MessageLookupByLibrary.simpleMessage("Nom"),
        "newPost": MessageLookupByLibrary.simpleMessage("Nouvelle publication"),
        "noMajorsYet": MessageLookupByLibrary.simpleMessage(
            "Aucune spécialité enregistrée pour le moment"),
        "noNotesYet":
            MessageLookupByLibrary.simpleMessage("Aucune note pour le moment"),
        "noPostsYet": MessageLookupByLibrary.simpleMessage(
            "Aucune publication pour le moment"),
        "noSubjectsThisSemester": MessageLookupByLibrary.simpleMessage(
            "Aucune matière dans ce semestre."),
        "notRegistered": MessageLookupByLibrary.simpleMessage("Non enregistré"),
        "note": MessageLookupByLibrary.simpleMessage("Note"),
        "notesTdTpExam":
            MessageLookupByLibrary.simpleMessage("Notes (TD/TP/Exam)"),
        "oneMajor": MessageLookupByLibrary.simpleMessage("Une spécialité"),
        "otherNotes": MessageLookupByLibrary.simpleMessage("Autres notes"),
        "password": MessageLookupByLibrary.simpleMessage("Mot de passe"),
        "pinNote": MessageLookupByLibrary.simpleMessage("Épingler la note"),
        "pinned": MessageLookupByLibrary.simpleMessage("Épinglées"),
        "politicalAdministrativeOrgs": MessageLookupByLibrary.simpleMessage(
            "Organisations politiques et administratives"),
        "politicalSciences":
            MessageLookupByLibrary.simpleMessage("Sciences politiques"),
        "post": MessageLookupByLibrary.simpleMessage(
            "Votre publication a été publiée ✅"),
        "posted": MessageLookupByLibrary.simpleMessage("Publication"),
        "posts": MessageLookupByLibrary.simpleMessage("Publications"),
        "privacyPolicy": MessageLookupByLibrary.simpleMessage(
            "Politique de confidentialité"),
        "privateLaw": MessageLookupByLibrary.simpleMessage("Droit privé"),
        "profile": MessageLookupByLibrary.simpleMessage("Profile"),
        "publicLaw": MessageLookupByLibrary.simpleMessage("Droit public"),
        "publish": MessageLookupByLibrary.simpleMessage("Publier"),
        "quickCalc": MessageLookupByLibrary.simpleMessage("Calcul rapide"),
        "quickCalc2": MessageLookupByLibrary.simpleMessage("Calcul rapide"),
        "register": MessageLookupByLibrary.simpleMessage("S\'inscrire"),
        "report": MessageLookupByLibrary.simpleMessage("Signaler"),
        "resetFailed": m1,
        "resetPassword": MessageLookupByLibrary.simpleMessage(
            "Réinitialiser le mot de passe"),
        "resetSent": MessageLookupByLibrary.simpleMessage(
            "Le lien de réinitialisation a été envoyé"),
        "save": MessageLookupByLibrary.simpleMessage("Enregistrer"),
        "saveExam":
            MessageLookupByLibrary.simpleMessage("Enregistrer l'examen"),
        "savePost":
            MessageLookupByLibrary.simpleMessage("Enregistrer la publication"),
        "searchClipboard": MessageLookupByLibrary.simpleMessage(
            "Rechercher dans le Note-pade…"),
        "searchFaculty":
            MessageLookupByLibrary.simpleMessage("Rechercher une faculté..."),
        "searchNoResults":
            MessageLookupByLibrary.simpleMessage("Aucun résultat"),
        "searchStartTyping": MessageLookupByLibrary.simpleMessage(
            "Commencez à taper pour rechercher"),
        "sections": MessageLookupByLibrary.simpleMessage("Sections"),
        "servicesMarketing":
            MessageLookupByLibrary.simpleMessage("Marketing des services"),
        "share": MessageLookupByLibrary.simpleMessage("Partager"),
        "addExam": MessageLookupByLibrary.simpleMessage("Ajouter un examen"),
        "confirmDeleteExam": MessageLookupByLibrary.simpleMessage(
            "Voulez-vous supprimer cet examen ?"),
        "deleteExam": MessageLookupByLibrary.simpleMessage("Supprimer l'examen"),
        "editExam": MessageLookupByLibrary.simpleMessage("Modifier l'examen"),
        "examCalendar":
            MessageLookupByLibrary.simpleMessage("Calendrier des examens"),
        "examNote": MessageLookupByLibrary.simpleMessage("Note"),
        "examReminder24h": m4,
        "examReminder2h": m5,
        "examReminder30m": m6,
        "examRoom": MessageLookupByLibrary.simpleMessage("Salle"),
        "examSubject": MessageLookupByLibrary.simpleMessage("Matière"),
        "examSubjectRequired":
            MessageLookupByLibrary.simpleMessage("Veuillez saisir la matière"),
        "noExamsDay":
            MessageLookupByLibrary.simpleMessage("Aucun examen pour ce jour"),
        "reminder24h":
            MessageLookupByLibrary.simpleMessage("24 heures avant"),
        "reminder2h":
            MessageLookupByLibrary.simpleMessage("2 heures avant"),
        "reminder30m":
            MessageLookupByLibrary.simpleMessage("30 minutes avant"),
        "reminders": MessageLookupByLibrary.simpleMessage("Rappels"),
        "startDiscussion": MessageLookupByLibrary.simpleMessage(
            "Commencez la première discussion dans la communauté et partagez votre expérience avec vos collègues."),
        "studyResults":
            MessageLookupByLibrary.simpleMessage("Résultats d\'étude"),
        "system": MessageLookupByLibrary.simpleMessage("Système"),
        "systemMode": MessageLookupByLibrary.simpleMessage("Mode système"),
        "taxLaw": MessageLookupByLibrary.simpleMessage("Droit fiscal"),
        "title": MessageLookupByLibrary.simpleMessage("Titre"),
        "university": MessageLookupByLibrary.simpleMessage("University"),
        "userInfo": MessageLookupByLibrary.simpleMessage("User Information"),
        "viewAll": MessageLookupByLibrary.simpleMessage("Voir tout"),
        "welcomeEmoji": MessageLookupByLibrary.simpleMessage("Bienvenue 👋"),
        "welcomeUniSpace":
            MessageLookupByLibrary.simpleMessage("Bienvenue sur UniSpace"),
        "writeComment":
            MessageLookupByLibrary.simpleMessage("Écrivez votre commentaire…"),
        "writeYourComment":
            MessageLookupByLibrary.simpleMessage("Écrivez votre commentaire")
      };
}
