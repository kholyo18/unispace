// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
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
  String get localeName => 'en';

  static String m0(count) => "تعليقات (${count})";

  static String m1(e) => "Failed to send: ${e}";

  static String m2(min) => "Please enter at least ${min} characters";

  static String m3(max) => "Please keep this under ${max} characters";

  static String m4(subject) => "Reminder: ${subject} in 24 hours";

  static String m5(subject) => "Reminder: ${subject} in 2 hours";

  static String m6(subject) => "Reminder: ${subject} in 30 minutes";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "Fail": MessageLookupByLibrary.simpleMessage(" Failed"),
        "Pass": MessageLookupByLibrary.simpleMessage(" Passed"),
        "aboutApp": MessageLookupByLibrary.simpleMessage("About the App"),
        "aboutAppDetails": MessageLookupByLibrary.simpleMessage(
            "UniSpace does not collect personal data outside Firebase. All data is secure."),
        "accounting": MessageLookupByLibrary.simpleMessage("Accounting"),
        "accountingTaxation":
            MessageLookupByLibrary.simpleMessage("Accounting and Taxation"),
        "add": MessageLookupByLibrary.simpleMessage("Add"),
        "advancedPublicLaw":
            MessageLookupByLibrary.simpleMessage("Advanced Public Law"),
        "arabic": MessageLookupByLibrary.simpleMessage("Arabic"),
        "archive": MessageLookupByLibrary.simpleMessage("Archive"),
        "basicEducation":
            MessageLookupByLibrary.simpleMessage("Basic Education"),
        "basicEducationDept":
            MessageLookupByLibrary.simpleMessage("Basic Education Department"),
        "basicUnit": MessageLookupByLibrary.simpleMessage("Basic Unit"),
        "blockAccount": MessageLookupByLibrary.simpleMessage("Block Account"),
        "businessAdministration":
            MessageLookupByLibrary.simpleMessage("Business Administration"),
        "businessLaw": MessageLookupByLibrary.simpleMessage("Business Law"),
        "calculate": MessageLookupByLibrary.simpleMessage("Calculate"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
        "changeLanguage":
            MessageLookupByLibrary.simpleMessage("Change Language"),
        "changeTheme": MessageLookupByLibrary.simpleMessage("Change Theme"),
        "chooseLanguage":
            MessageLookupByLibrary.simpleMessage("Choose Language"),
        "chooseTheme": MessageLookupByLibrary.simpleMessage("Choose Theme"),
        "clipboard": MessageLookupByLibrary.simpleMessage("Note-pade"),
        "close": MessageLookupByLibrary.simpleMessage("Close"),
        "coefficient": MessageLookupByLibrary.simpleMessage("Coef:"),
        "comment": MessageLookupByLibrary.simpleMessage("Comment"),
        "comments": MessageLookupByLibrary.simpleMessage("Comments"),
        "commentsCount": m0,
        "commercialSciences":
            MessageLookupByLibrary.simpleMessage("Commercial Sciences"),
        "commercialSciencesDept": MessageLookupByLibrary.simpleMessage(
            "Department of Commercial Sciences"),
        "commonCore": MessageLookupByLibrary.simpleMessage("Common Core"),
        "community": MessageLookupByLibrary.simpleMessage("Community"),
        "contactCategoryFeature": MessageLookupByLibrary.simpleMessage(
            "New feature suggestion"),
        "contactCategoryImprovement":
            MessageLookupByLibrary.simpleMessage("Improvement"),
        "contactCategoryIssue":
            MessageLookupByLibrary.simpleMessage("Issue"),
        "contactCategoryLabel":
            MessageLookupByLibrary.simpleMessage("Category"),
        "contactCategoryOther":
            MessageLookupByLibrary.simpleMessage("Other"),
        "contactCategoryReport":
            MessageLookupByLibrary.simpleMessage("Report"),
        "contactCopyAction": MessageLookupByLibrary.simpleMessage("Copy"),
        "contactCopyDialogBody": MessageLookupByLibrary.simpleMessage(
            "Copy the message and send it to support via your email app."),
        "contactCopyDialogTitle":
            MessageLookupByLibrary.simpleMessage("Copy message"),
        "contactCopied": MessageLookupByLibrary.simpleMessage("Message copied"),
        "contactDescriptionHint": MessageLookupByLibrary.simpleMessage(
            "Explain the details so we can help quickly"),
        "contactDescriptionLabel":
            MessageLookupByLibrary.simpleMessage("Description"),
        "contactIncludeUserInfo":
            MessageLookupByLibrary.simpleMessage("Include my account information"),
        "contactMailOpened": MessageLookupByLibrary.simpleMessage(
            "Email app opened to send your message"),
        "contactMailUnavailable": MessageLookupByLibrary.simpleMessage(
            "Email app not available. You can copy the message instead."),
        "contactMetadataAppVersion":
            MessageLookupByLibrary.simpleMessage("App version"),
        "contactMetadataEmail": MessageLookupByLibrary.simpleMessage("Email"),
        "contactMetadataHeader":
            MessageLookupByLibrary.simpleMessage("Metadata"),
        "contactMetadataLocale": MessageLookupByLibrary.simpleMessage("Locale"),
        "contactMetadataName": MessageLookupByLibrary.simpleMessage("Name"),
        "contactMetadataPlatform":
            MessageLookupByLibrary.simpleMessage("Platform"),
        "contactMetadataTimestamp":
            MessageLookupByLibrary.simpleMessage("Timestamp"),
        "contactMetadataUserId": MessageLookupByLibrary.simpleMessage("User ID"),
        "contactScreenshotPlaceholder":
            MessageLookupByLibrary.simpleMessage("Attach a screenshot"),
        "contactScreenshotSoon":
            MessageLookupByLibrary.simpleMessage("Coming soon"),
        "contactSend": MessageLookupByLibrary.simpleMessage("Send"),
        "contactSendFailure": MessageLookupByLibrary.simpleMessage(
            "We couldn't send your message. Please try again."),
        "contactSendSuccess": MessageLookupByLibrary.simpleMessage("Sent ✅"),
        "contactSending": MessageLookupByLibrary.simpleMessage("Sending..."),
        "contactSubjectHint": MessageLookupByLibrary.simpleMessage(
            "Short summary of your request"),
        "contactSubjectLabel": MessageLookupByLibrary.simpleMessage("Subject"),
        "contactUs": MessageLookupByLibrary.simpleMessage("Contact Us"),
        "contactUsSubtitle": MessageLookupByLibrary.simpleMessage(
            "We are happy to hear from you. Send your message to support."),
        "contactUserInfoUnavailable": MessageLookupByLibrary.simpleMessage(
            "No signed-in user information available"),
        "contactValidationMaxLength": m3,
        "contactValidationMinLength": m2,
        "contactValidationRequired":
            MessageLookupByLibrary.simpleMessage("This field is required"),
        "content": MessageLookupByLibrary.simpleMessage("Content"),
        "copyText": MessageLookupByLibrary.simpleMessage("Copy Text"),
        "corporateFinance":
            MessageLookupByLibrary.simpleMessage("Corporate Finance"),
        "corporateFinancialManagement": MessageLookupByLibrary.simpleMessage(
            "Corporate Financial Management"),
        "createPost": MessageLookupByLibrary.simpleMessage("Post"),
        "createPoste": MessageLookupByLibrary.simpleMessage("Create a post"),
        "credits": MessageLookupByLibrary.simpleMessage("Credits:"),
        "criminalLaw": MessageLookupByLibrary.simpleMessage(
            "Criminal Law and Criminal Sciences"),
        "dark": MessageLookupByLibrary.simpleMessage("Dark"),
        "darkMode": MessageLookupByLibrary.simpleMessage("Dark Mode"),
        "department": MessageLookupByLibrary.simpleMessage("Department"),
        "deptArabicLangLit": MessageLookupByLibrary.simpleMessage(
            "Department of Arabic Language and Literature"),
        "deptEnglishLangLit": MessageLookupByLibrary.simpleMessage(
            "Department of English Language and Literature"),
        "deptFrenchLangLit": MessageLookupByLibrary.simpleMessage(
            "Department of French Language and Literature"),
        "economics": MessageLookupByLibrary.simpleMessage("Economics"),
        "economicsDept":
            MessageLookupByLibrary.simpleMessage("Department of Economics"),
        "editWeights": MessageLookupByLibrary.simpleMessage("Edit Weights"),
        "email": MessageLookupByLibrary.simpleMessage("Email"),
        "energyMiningLaw":
            MessageLookupByLibrary.simpleMessage("Energy and Mining Law"),
        "exploratoryUnit":
            MessageLookupByLibrary.simpleMessage("Exploratory Unit"),
        "faculties": MessageLookupByLibrary.simpleMessage("Faculties"),
        "faculty": MessageLookupByLibrary.simpleMessage("Faculty"),
        "facultyArtsLanguages": MessageLookupByLibrary.simpleMessage(
            "Faculty of Arts and Foreign Languages"),
        "facultyEconomics": MessageLookupByLibrary.simpleMessage(
            "Faculty of Economics, Commerce, and Management Sciences"),
        "facultyLawPolitical": MessageLookupByLibrary.simpleMessage(
            "Faculty of Law and Political Sciences"),
        "familyLaw": MessageLookupByLibrary.simpleMessage("Family Law"),
        "finance": MessageLookupByLibrary.simpleMessage("Finance"),
        "financeInternationalTrade": MessageLookupByLibrary.simpleMessage(
            "Finance and International Trade"),
        "financialAccounting": MessageLookupByLibrary.simpleMessage(
            "Financial and Accounting Sciences"),
        "financialAccountingDept": MessageLookupByLibrary.simpleMessage(
            "Department of Financial and Accounting Sciences"),
        "financialManagement":
            MessageLookupByLibrary.simpleMessage("Financial Management"),
        "followComment": MessageLookupByLibrary.simpleMessage("Follow Comment"),
        "following": MessageLookupByLibrary.simpleMessage("Following"),
        "hashtag": MessageLookupByLibrary.simpleMessage("#"),
        "hide": MessageLookupByLibrary.simpleMessage("Hide"),
        "home": MessageLookupByLibrary.simpleMessage("Home"),
        "homeSubtitle": MessageLookupByLibrary.simpleMessage(
            "Browse faculties, calculate your GPA, share your ideas, and write notes easily."),
        "horizontalUnit":
            MessageLookupByLibrary.simpleMessage("Horizontal Unit"),
        "hotelTourismMarketing":
            MessageLookupByLibrary.simpleMessage("Hotel and Tourism Marketing"),
        "humanResourcesManagement":
            MessageLookupByLibrary.simpleMessage("Human Resources Management"),
        "internationalCooperation":
            MessageLookupByLibrary.simpleMessage("International Cooperation"),
        "internationalEconomics":
            MessageLookupByLibrary.simpleMessage("International Economics"),
        "internationalRelations":
            MessageLookupByLibrary.simpleMessage("International Relations"),
        "law": MessageLookupByLibrary.simpleMessage("Law"),
        "legalProfessionsLaw": MessageLookupByLibrary.simpleMessage(
            "Legal and Judicial Professions Law"),
        "light": MessageLookupByLibrary.simpleMessage("Light"),
        "lightMode": MessageLookupByLibrary.simpleMessage("Light Mode"),
        "localAdministration":
            MessageLookupByLibrary.simpleMessage("Local Administration"),
        "login": MessageLookupByLibrary.simpleMessage("Login"),
        "logout": MessageLookupByLibrary.simpleMessage("Logout"),
        "major": MessageLookupByLibrary.simpleMessage("Major"),
        "majors": MessageLookupByLibrary.simpleMessage("Majors"),
        "managementSciences":
            MessageLookupByLibrary.simpleMessage("Management Sciences"),
        "managementSciencesDept": MessageLookupByLibrary.simpleMessage(
            "Department of Management Sciences"),
        "maritimePortLaw":
            MessageLookupByLibrary.simpleMessage("Maritime and Port Law"),
        "marketing": MessageLookupByLibrary.simpleMessage("Marketing"),
        "mediaUrl": MessageLookupByLibrary.simpleMessage("Image/Video URL"),
        "methodologicalUnit":
            MessageLookupByLibrary.simpleMessage("Methodological Unit"),
        "monetaryFinancialEconomics": MessageLookupByLibrary.simpleMessage(
            "Monetary and Financial Economics"),
        "mood": MessageLookupByLibrary.simpleMessage("Mood"),
        "name": MessageLookupByLibrary.simpleMessage("Name"),
        "newPost": MessageLookupByLibrary.simpleMessage("New Post"),
        "noMajorsYet": MessageLookupByLibrary.simpleMessage("No majors yet"),
        "noNotesYet": MessageLookupByLibrary.simpleMessage("No notes yet"),
        "noPostsYet": MessageLookupByLibrary.simpleMessage("No posts yet"),
        "noSubjectsThisSemester": MessageLookupByLibrary.simpleMessage(
            "No subjects in this semester."),
        "notRegistered": MessageLookupByLibrary.simpleMessage("Not registered"),
        "note": MessageLookupByLibrary.simpleMessage("Note"),
        "notesTdTpExam":
            MessageLookupByLibrary.simpleMessage("Grades (TD/TP/Exam)"),
        "oneMajor": MessageLookupByLibrary.simpleMessage("One major"),
        "otherNotes": MessageLookupByLibrary.simpleMessage("Other Notes"),
        "password": MessageLookupByLibrary.simpleMessage("Password"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Forgot password?"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Reset your password"),
        "resetPasswordHelper": MessageLookupByLibrary.simpleMessage(
            "Enter your email and we’ll send you a reset link."),
        "sendResetLink": MessageLookupByLibrary.simpleMessage("Send link"),
        "sendResetLinkLoading":
            MessageLookupByLibrary.simpleMessage("Sending..."),
        "invalidEmailValidation": MessageLookupByLibrary.simpleMessage(
            "Please enter a valid email address."),
        "resetLinkSentSuccess": MessageLookupByLibrary.simpleMessage(
            "The reset link was sent to your email."),
        "invalidEmailError": MessageLookupByLibrary.simpleMessage(
            "The email address is invalid."),
        "userNotFoundError": MessageLookupByLibrary.simpleMessage(
            "No account found with that email."),
        "tooManyRequestsError": MessageLookupByLibrary.simpleMessage(
            "Too many requests, try again later."),
        "resetLinkFailed": MessageLookupByLibrary.simpleMessage(
            "Could not send the link, please try again."),
        "pinNote": MessageLookupByLibrary.simpleMessage("Pin Note"),
        "pinned": MessageLookupByLibrary.simpleMessage("Pinned"),
        "politicalAdministrativeOrgs": MessageLookupByLibrary.simpleMessage(
            "Political and Administrative Organizations"),
        "politicalSciences":
            MessageLookupByLibrary.simpleMessage("Political Sciences"),
        "post": MessageLookupByLibrary.simpleMessage(
            "Your post has been published ✅"),
        "posted": MessageLookupByLibrary.simpleMessage("Post"),
        "posts": MessageLookupByLibrary.simpleMessage("Posts"),
        "privacyPolicy": MessageLookupByLibrary.simpleMessage("Privacy Policy"),
        "privateLaw": MessageLookupByLibrary.simpleMessage("Private Law"),
        "profile": MessageLookupByLibrary.simpleMessage("Profile"),
        "publicLaw": MessageLookupByLibrary.simpleMessage("Public Law"),
        "publish": MessageLookupByLibrary.simpleMessage("Publish"),
        "quickCalc": MessageLookupByLibrary.simpleMessage("Quick Calculation"),
        "quickCalc2": MessageLookupByLibrary.simpleMessage("Quick Calc"),
        "register": MessageLookupByLibrary.simpleMessage("Register"),
        "report": MessageLookupByLibrary.simpleMessage("Report"),
        "resetFailed": m1,
        "resetPassword": MessageLookupByLibrary.simpleMessage("Reset Password"),
        "resetSent":
            MessageLookupByLibrary.simpleMessage("Reset link has been sent"),
        "save": MessageLookupByLibrary.simpleMessage("Save"),
        "saveExam": MessageLookupByLibrary.simpleMessage("Save Exam"),
        "savePost": MessageLookupByLibrary.simpleMessage("Save Post"),
        "searchClipboard":
            MessageLookupByLibrary.simpleMessage("Search inside Note-pade…"),
        "searchFaculty":
            MessageLookupByLibrary.simpleMessage("Search for a faculty..."),
        "searchNoResults":
            MessageLookupByLibrary.simpleMessage("No results found"),
        "searchStartTyping":
            MessageLookupByLibrary.simpleMessage("Start typing to search"),
        "sections": MessageLookupByLibrary.simpleMessage("Sections"),
        "servicesMarketing":
            MessageLookupByLibrary.simpleMessage("Services Marketing"),
        "share": MessageLookupByLibrary.simpleMessage("Share"),
        "addExam": MessageLookupByLibrary.simpleMessage("Add Exam"),
        "confirmDeleteExam": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to delete this exam?"),
        "deleteExam": MessageLookupByLibrary.simpleMessage("Delete Exam"),
        "editExam": MessageLookupByLibrary.simpleMessage("Edit Exam"),
        "examCalendar": MessageLookupByLibrary.simpleMessage("Exam Calendar"),
        "examNote": MessageLookupByLibrary.simpleMessage("Note"),
        "examReminder24h": m4,
        "examReminder2h": m5,
        "examReminder30m": m6,
        "examRoom": MessageLookupByLibrary.simpleMessage("Room"),
        "examSubject": MessageLookupByLibrary.simpleMessage("Subject"),
        "examSubjectRequired":
            MessageLookupByLibrary.simpleMessage("Please enter the subject"),
        "noExamsDay":
            MessageLookupByLibrary.simpleMessage("No exams for this day"),
        "reminder24h":
            MessageLookupByLibrary.simpleMessage("24 hours before"),
        "reminder2h": MessageLookupByLibrary.simpleMessage("2 hours before"),
        "reminder30m":
            MessageLookupByLibrary.simpleMessage("30 minutes before"),
        "reminders": MessageLookupByLibrary.simpleMessage("Reminders"),
        "startDiscussion": MessageLookupByLibrary.simpleMessage(
            "Start the first discussion in the community and share your experience with colleagues."),
        "studyResults": MessageLookupByLibrary.simpleMessage("Study Results"),
        "system": MessageLookupByLibrary.simpleMessage("System"),
        "systemMode": MessageLookupByLibrary.simpleMessage("System Mode"),
        "taxLaw": MessageLookupByLibrary.simpleMessage("Tax Law"),
        "title": MessageLookupByLibrary.simpleMessage("Title"),
        "university": MessageLookupByLibrary.simpleMessage("University"),
        "userInfo": MessageLookupByLibrary.simpleMessage("User Information"),
        "viewAll": MessageLookupByLibrary.simpleMessage("View All"),
        "welcomeEmoji": MessageLookupByLibrary.simpleMessage("Welcome 👋"),
        "welcomeUniSpace":
            MessageLookupByLibrary.simpleMessage("Welcome to UniSpace"),
        "writeComment":
            MessageLookupByLibrary.simpleMessage("Write your comment…"),
        "writeYourComment":
            MessageLookupByLibrary.simpleMessage("Write your comment")
      };
}
