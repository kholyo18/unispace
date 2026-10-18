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

  static String m0(specialty, level) =>
      "Specialty: ${specialty} | Level: ${level}";

  static String m1(date) => "Blocked on ${date}";

  static String m2(count) => "Comments (${count})";

  static String m3(max) => "Please keep this under ${max} characters";

  static String m4(min) => "Please enter at least ${min} characters";

  static String m5(fileName) => "Delete ${fileName} from this device?";

  static String m6(size) => "Cache: ${size}";

  static String m7(size) => "Total used: ${size}";

  static String m8(size) => "User: ${size}";

  static String m9(date) => "Updated ${date}";

  static String m10(subject) => "Reminder: ${subject} in 24 hours";

  static String m11(subject) => "Reminder: ${subject} in 2 hours";

  static String m12(subject) => "Reminder: ${subject} in 30 minutes";

  static String m13(type) => "Type: ${type}";

  static String m14(seconds) => "Send OTP in ${seconds}s";

  static String m15(masked) =>
      "Enter your current email to verify. Hint: ${masked}";

  static String m16(masked) => "Review new email: ${masked}";

  static String m17(date) => "Last password change: ${date}";

  static String m18(days, hours) =>
      "You can change your name after: ${days} day / ${hours} hour";

  static String m19(hours) => "You can change your name after: ${hours} hour";

  static String m20(maskedEmail) =>
      "We will send a password reset link to your registered email: ${maskedEmail}";

  static String m21(current, total) => "Step ${current} of ${total}";

  static String m22(seconds) => "Resend in ${seconds}s";

  static String m23(e) => "Failed to send: ${e}";

  static String m24(days) => "${days} d ago";

  static String m25(hours) => "${hours} h ago";

  static String m26(minutes) => "${minutes} min ago";

  static String m27(start, end) => "${start} → ${end}";

  static String m28(minutes) => "${minutes} min";

  static String m29(subject) => "Focus session: ${subject}";

  static String m30(subject) => "Mock test: ${subject}";

  static String m31(subject) => "Practice quiz: ${subject}";

  static String m32(subject) => "Summary review: ${subject}";

  static String m33(count) => "Attempts remaining: ${count}";

  static String m34(email) => "Enter the 6-digit code sent to ${email}.";

  static String m35(seconds) => "Resend in ${seconds}s";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "aboutApp": MessageLookupByLibrary.simpleMessage("About the App"),
    "aboutAppDescription": MessageLookupByLibrary.simpleMessage(
      "A smart university platform that helps students organize their studies, calculate averages, track exams, and plan revision in an easy and effective way.",
    ),
    "aboutAppDetails": MessageLookupByLibrary.simpleMessage(
      "UniSpace does not collect personal data outside Firebase. All data is secure.",
    ),
    "aboutAppFeatureExams": MessageLookupByLibrary.simpleMessage(
      "Exam calendar",
    ),
    "aboutAppFeatureGpa": MessageLookupByLibrary.simpleMessage(
      "Accurate university GPA calculation",
    ),
    "aboutAppFeatureNotes": MessageLookupByLibrary.simpleMessage(
      "Academic note taking",
    ),
    "aboutAppFeatureReviewPlan": MessageLookupByLibrary.simpleMessage(
      "Smart revision planner",
    ),
    "aboutAppFeatureStudents": MessageLookupByLibrary.simpleMessage(
      "Tailored specifically for university students",
    ),
    "aboutAppFooter": MessageLookupByLibrary.simpleMessage(
      "Developed with Flutter",
    ),
    "aboutAppSummary": MessageLookupByLibrary.simpleMessage(
      "A platform to calculate GPA, connect with students, and take notes.",
    ),
    "aboutAppViewLicenses": MessageLookupByLibrary.simpleMessage(
      "View licenses",
    ),
    "academicCollegeLabel": MessageLookupByLibrary.simpleMessage("College"),
    "academicLevelLabel": MessageLookupByLibrary.simpleMessage("Level"),
    "academicMajorLabel": MessageLookupByLibrary.simpleMessage("Major"),
    "academicSettingsDescription": MessageLookupByLibrary.simpleMessage(
      "Update your college, major, and level.",
    ),
    "academicSettingsSaved": MessageLookupByLibrary.simpleMessage(
      "Academic settings saved.",
    ),
    "academicSettingsTitle": MessageLookupByLibrary.simpleMessage(
      "Academic settings",
    ),
    "academicShortcutDeleteCancel": MessageLookupByLibrary.simpleMessage(
      "Cancel",
    ),
    "academicShortcutDeleteConfirm": MessageLookupByLibrary.simpleMessage(
      "Delete",
    ),
    "academicShortcutDeleteConfirmBody": MessageLookupByLibrary.simpleMessage(
      "Do you want to delete the academic shortcut? You can add it again later.",
    ),
    "academicShortcutDeleteConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Confirm deletion",
    ),
    "academicShortcutDeleteSuccess": MessageLookupByLibrary.simpleMessage(
      "Shortcut deleted successfully.",
    ),
    "academicShortcutDeleteTitle": MessageLookupByLibrary.simpleMessage(
      "Delete shortcut",
    ),
    "academicShortcutDetails": m0,
    "academicShortcutEdit": MessageLookupByLibrary.simpleMessage("Edit"),
    "academicShortcutEmptyAction": MessageLookupByLibrary.simpleMessage(
      "Add shortcut",
    ),
    "academicShortcutEmptyTitle": MessageLookupByLibrary.simpleMessage(
      "No academic shortcut set yet.",
    ),
    "academicShortcutGo": MessageLookupByLibrary.simpleMessage("Go"),
    "academicShortcutNotFound": MessageLookupByLibrary.simpleMessage(
      "We couldn\'t find that specialty. Please update your academic settings.",
    ),
    "academicShortcutTitle": MessageLookupByLibrary.simpleMessage(
      "Your academic shortcut",
    ),
    "academicclass": MessageLookupByLibrary.simpleMessage("class"),
    "accounting": MessageLookupByLibrary.simpleMessage("Accounting"),
    "accountingTaxation": MessageLookupByLibrary.simpleMessage(
      "Accounting and Taxation",
    ),
    "activeSessionNow": MessageLookupByLibrary.simpleMessage("Just now"),
    "activeSessionsEmpty": MessageLookupByLibrary.simpleMessage(
      "No other active sessions",
    ),
    "activeSessionsHint": MessageLookupByLibrary.simpleMessage(
      "Session management requires a secure backend.",
    ),
    "activeSessionsTitle": MessageLookupByLibrary.simpleMessage(
      "Active sessions",
    ),
    "add": MessageLookupByLibrary.simpleMessage("Add"),
    "addExam": MessageLookupByLibrary.simpleMessage("Add Exam"),
    "advancedPublicLaw": MessageLookupByLibrary.simpleMessage(
      "Advanced Public Law",
    ),
    "algeriaLabel": MessageLookupByLibrary.simpleMessage("Algeria"),
    "arabic": MessageLookupByLibrary.simpleMessage("Arabic"),
    "archive": MessageLookupByLibrary.simpleMessage("Archive"),
    "basicEducation": MessageLookupByLibrary.simpleMessage("Basic Education"),
    "basicEducationDept": MessageLookupByLibrary.simpleMessage(
      "Basic Education Department",
    ),
    "basicUnit": MessageLookupByLibrary.simpleMessage("Basic Unit"),
    "blockAccount": MessageLookupByLibrary.simpleMessage("Block Account"),
    "blockedUsersAddAction": MessageLookupByLibrary.simpleMessage("Block"),
    "blockedUsersAddHint": MessageLookupByLibrary.simpleMessage(
      "Enter user ID or email",
    ),
    "blockedUsersAddTitle": MessageLookupByLibrary.simpleMessage(
      "Block a user",
    ),
    "blockedUsersEmpty": MessageLookupByLibrary.simpleMessage(
      "No blocked users",
    ),
    "blockedUsersHint": MessageLookupByLibrary.simpleMessage(
      "Blocked users will appear here.",
    ),
    "blockedUsersSince": m1,
    "blockedUsersTitle": MessageLookupByLibrary.simpleMessage("Blocked users"),
    "businessAdministration": MessageLookupByLibrary.simpleMessage(
      "Business Administration",
    ),
    "businessLaw": MessageLookupByLibrary.simpleMessage("Business Law"),
    "calculate": MessageLookupByLibrary.simpleMessage("Calculate"),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "changeLanguage": MessageLookupByLibrary.simpleMessage("Change Language"),
    "changeTheme": MessageLookupByLibrary.simpleMessage("Change Theme"),
    "checkNow": MessageLookupByLibrary.simpleMessage("Check now"),
    "chooseLanguage": MessageLookupByLibrary.simpleMessage("Choose Language"),
    "chooseTheme": MessageLookupByLibrary.simpleMessage("Choose Theme"),
    "clipboard": MessageLookupByLibrary.simpleMessage("Notepad"),
    "close": MessageLookupByLibrary.simpleMessage("Close"),
    "coefficient": MessageLookupByLibrary.simpleMessage("Coef:"),
    "comment": MessageLookupByLibrary.simpleMessage("Comment"),
    "comments": MessageLookupByLibrary.simpleMessage("Comments"),
    "commentsCount": m2,
    "commercialSciences": MessageLookupByLibrary.simpleMessage(
      "Commercial Sciences",
    ),
    "commercialSciencesDept": MessageLookupByLibrary.simpleMessage(
      "Department of Commercial Sciences",
    ),
    "commonCore": MessageLookupByLibrary.simpleMessage("Common Core"),
    "commonCore1": MessageLookupByLibrary.simpleMessage("Common Core"),
    "community": MessageLookupByLibrary.simpleMessage("Community"),
    "confirmDeleteExam": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to delete this exam?",
    ),
    "contactCategoryFeature": MessageLookupByLibrary.simpleMessage(
      "New feature suggestion",
    ),
    "contactCategoryImprovement": MessageLookupByLibrary.simpleMessage(
      "Improvement",
    ),
    "contactCategoryIssue": MessageLookupByLibrary.simpleMessage("Issue"),
    "contactCategoryLabel": MessageLookupByLibrary.simpleMessage("Category"),
    "contactCategoryOther": MessageLookupByLibrary.simpleMessage("Other"),
    "contactCategoryReport": MessageLookupByLibrary.simpleMessage("Report"),
    "contactCopied": MessageLookupByLibrary.simpleMessage("Message copied"),
    "contactCopyAction": MessageLookupByLibrary.simpleMessage("Copy"),
    "contactCopyDialogBody": MessageLookupByLibrary.simpleMessage(
      "Copy the message and send it to support via your email app.",
    ),
    "contactCopyDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Copy message",
    ),
    "contactDescriptionHint": MessageLookupByLibrary.simpleMessage(
      "Explain the details so we can help quickly",
    ),
    "contactDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "Description",
    ),
    "contactIncludeUserInfo": MessageLookupByLibrary.simpleMessage(
      "Include my account information",
    ),
    "contactMailOpened": MessageLookupByLibrary.simpleMessage(
      "Email app opened to send your message",
    ),
    "contactMailUnavailable": MessageLookupByLibrary.simpleMessage(
      "Email app not available. You can copy the message instead.",
    ),
    "contactMetadataAppVersion": MessageLookupByLibrary.simpleMessage(
      "App version",
    ),
    "contactMetadataEmail": MessageLookupByLibrary.simpleMessage("Email"),
    "contactMetadataHeader": MessageLookupByLibrary.simpleMessage("Metadata"),
    "contactMetadataLocale": MessageLookupByLibrary.simpleMessage("Locale"),
    "contactMetadataName": MessageLookupByLibrary.simpleMessage("Name"),
    "contactMetadataPlatform": MessageLookupByLibrary.simpleMessage("Platform"),
    "contactMetadataTimestamp": MessageLookupByLibrary.simpleMessage(
      "Timestamp",
    ),
    "contactMetadataUserId": MessageLookupByLibrary.simpleMessage("User ID"),
    "contactScreenshotPlaceholder": MessageLookupByLibrary.simpleMessage(
      "Attach a screenshot",
    ),
    "contactScreenshotSoon": MessageLookupByLibrary.simpleMessage(
      "Coming soon",
    ),
    "contactSend": MessageLookupByLibrary.simpleMessage("Send"),
    "contactSendFailure": MessageLookupByLibrary.simpleMessage(
      "We couldn\'t send your message. Please try again.",
    ),
    "contactSendSuccess": MessageLookupByLibrary.simpleMessage("Sent ✅"),
    "contactSending": MessageLookupByLibrary.simpleMessage("Sending..."),
    "contactSubjectHint": MessageLookupByLibrary.simpleMessage(
      "Short summary of your request",
    ),
    "contactSubjectLabel": MessageLookupByLibrary.simpleMessage("Subject"),
    "contactUs": MessageLookupByLibrary.simpleMessage("Contact Us"),
    "contactUsSubtitle": MessageLookupByLibrary.simpleMessage(
      "We are happy to hear from you. Send your message to support.",
    ),
    "contactUserInfoUnavailable": MessageLookupByLibrary.simpleMessage(
      "No signed-in user information available",
    ),
    "contactValidationMaxLength": m3,
    "contactValidationMinLength": m4,
    "contactValidationRequired": MessageLookupByLibrary.simpleMessage(
      "This field is required",
    ),
    "content": MessageLookupByLibrary.simpleMessage("Content"),
    "copyText": MessageLookupByLibrary.simpleMessage("Copy Text"),
    "corporateFinance": MessageLookupByLibrary.simpleMessage(
      "Corporate Finance",
    ),
    "corporateFinancialManagement": MessageLookupByLibrary.simpleMessage(
      "Corporate Financial Management",
    ),
    "createPost": MessageLookupByLibrary.simpleMessage("Post"),
    "createPoste": MessageLookupByLibrary.simpleMessage("Create a post"),
    "credits": MessageLookupByLibrary.simpleMessage("Credits:"),
    "criminalLaw": MessageLookupByLibrary.simpleMessage(
      "Criminal Law and Criminal Sciences",
    ),
    "currentDeviceTitle": MessageLookupByLibrary.simpleMessage(
      "Current device",
    ),
    "dangerZone": MessageLookupByLibrary.simpleMessage("Danger zone"),
    "dark": MessageLookupByLibrary.simpleMessage("Dark"),
    "darkMode": MessageLookupByLibrary.simpleMessage("Dark Mode"),
    "delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "deleteExam": MessageLookupByLibrary.simpleMessage("Delete Exam"),
    "department": MessageLookupByLibrary.simpleMessage("Department"),
    "deptArabicLangLit": MessageLookupByLibrary.simpleMessage(
      "Department of Arabic Language and Literature",
    ),
    "deptEnglishLangLit": MessageLookupByLibrary.simpleMessage(
      "Department of English Language and Literature",
    ),
    "deptFrenchLangLit": MessageLookupByLibrary.simpleMessage(
      "Department of French Language and Literature",
    ),
    "deviceActiveNow": MessageLookupByLibrary.simpleMessage("Active now"),
    "devicePrimary": MessageLookupByLibrary.simpleMessage("Primary device"),
    "downloadsCacheClearFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to clear the cache.",
    ),
    "downloadsCacheCleared": MessageLookupByLibrary.simpleMessage(
      "Cache cleared.",
    ),
    "downloadsClearAllAction": MessageLookupByLibrary.simpleMessage(
      "Clear all downloads",
    ),
    "downloadsClearAllDialogBody": MessageLookupByLibrary.simpleMessage(
      "This will remove all downloaded files from this device.",
    ),
    "downloadsClearAllDialogConfirm": MessageLookupByLibrary.simpleMessage(
      "Clear all",
    ),
    "downloadsClearAllDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Clear all downloads?",
    ),
    "downloadsClearAllFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to clear all downloads.",
    ),
    "downloadsClearAllSuccess": MessageLookupByLibrary.simpleMessage(
      "All downloads cleared.",
    ),
    "downloadsClearCache": MessageLookupByLibrary.simpleMessage("Clear cache"),
    "downloadsClearCacheDialogBody": MessageLookupByLibrary.simpleMessage(
      "This will remove cached files from this device. You can download them again later.",
    ),
    "downloadsClearCacheDialogConfirm": MessageLookupByLibrary.simpleMessage(
      "Clear cache",
    ),
    "downloadsClearCacheDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Clear cached downloads?",
    ),
    "downloadsDeleteDialogBody": m5,
    "downloadsDeleteDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Delete download?",
    ),
    "downloadsDeleteFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to delete the download.",
    ),
    "downloadsDeleteSuccess": MessageLookupByLibrary.simpleMessage(
      "Download deleted.",
    ),
    "downloadsDescription": MessageLookupByLibrary.simpleMessage(
      "Browse your downloaded files and clean the cache.",
    ),
    "downloadsEmptyHint": MessageLookupByLibrary.simpleMessage(
      "Downloaded items will appear here.",
    ),
    "downloadsEmptyTitle": MessageLookupByLibrary.simpleMessage(
      "No downloads yet",
    ),
    "downloadsExploreCta": MessageLookupByLibrary.simpleMessage(
      "Explore content",
    ),
    "downloadsFilterAll": MessageLookupByLibrary.simpleMessage("All"),
    "downloadsFilterFiles": MessageLookupByLibrary.simpleMessage("Files"),
    "downloadsFilterImages": MessageLookupByLibrary.simpleMessage("Images"),
    "downloadsLoadFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to load downloads.",
    ),
    "downloadsRefreshList": MessageLookupByLibrary.simpleMessage(
      "Refresh list",
    ),
    "downloadsSortLabel": MessageLookupByLibrary.simpleMessage("Sort by"),
    "downloadsSortNewest": MessageLookupByLibrary.simpleMessage("Newest"),
    "downloadsSortOldest": MessageLookupByLibrary.simpleMessage("Oldest"),
    "downloadsStorageCacheLabel": MessageLookupByLibrary.simpleMessage(
      "Cache: 0 MB",
    ),
    "downloadsStorageCacheLabelValue": m6,
    "downloadsStorageInfo": MessageLookupByLibrary.simpleMessage(
      "Sizes will be calculated automatically later.",
    ),
    "downloadsStorageInfoValue": m7,
    "downloadsStorageTitle": MessageLookupByLibrary.simpleMessage(
      "Downloads storage",
    ),
    "downloadsStorageUserLabel": MessageLookupByLibrary.simpleMessage(
      "User: 0 MB",
    ),
    "downloadsStorageUserLabelValue": m8,
    "downloadsTitle": MessageLookupByLibrary.simpleMessage("Downloads"),
    "downloadsUpdatedAt": m9,
    "drawerSectionAccount": MessageLookupByLibrary.simpleMessage("Account"),
    "drawerSectionApp": MessageLookupByLibrary.simpleMessage("App"),
    "drawerSectionContent": MessageLookupByLibrary.simpleMessage("Content"),
    "drawerSectionStudent": MessageLookupByLibrary.simpleMessage("Student"),
    "economics": MessageLookupByLibrary.simpleMessage("Economics"),
    "economicsDept": MessageLookupByLibrary.simpleMessage(
      "Department of Economics",
    ),
    "editExam": MessageLookupByLibrary.simpleMessage("Edit Exam"),
    "editProfile": MessageLookupByLibrary.simpleMessage("Edit Profile"),
    "editWeights": MessageLookupByLibrary.simpleMessage("Edit Weights"),
    "email": MessageLookupByLibrary.simpleMessage("Email"),
    "emailAlreadyInUseError": MessageLookupByLibrary.simpleMessage(
      "Email is already in use.",
    ),
    "emailAuthDisabledError": MessageLookupByLibrary.simpleMessage(
      "Email/password sign-in is disabled.",
    ),
    "emailHidden": MessageLookupByLibrary.simpleMessage("Email hidden"),
    "emailNotVerified": MessageLookupByLibrary.simpleMessage(
      "Email not verified",
    ),
    "emailNotVerifiedYet": MessageLookupByLibrary.simpleMessage(
      "Email is not verified yet. Please open your email, click the verification link, then try again.",
    ),
    "emailUnavailable": MessageLookupByLibrary.simpleMessage(
      "Email unavailable",
    ),
    "emailVerified": MessageLookupByLibrary.simpleMessage("Email verified"),
    "energyMiningLaw": MessageLookupByLibrary.simpleMessage(
      "Energy and Mining Law",
    ),
    "examCalendar": MessageLookupByLibrary.simpleMessage("Exam Calendar"),
    "examNote": MessageLookupByLibrary.simpleMessage("Note"),
    "examReminder24h": m10,
    "examReminder2h": m11,
    "examReminder30m": m12,
    "examRoom": MessageLookupByLibrary.simpleMessage("Room"),
    "examSubject": MessageLookupByLibrary.simpleMessage("Subject"),
    "examSubjectRequired": MessageLookupByLibrary.simpleMessage(
      "Please enter the subject",
    ),
    "exploratoryUnit": MessageLookupByLibrary.simpleMessage("Exploratory Unit"),
    "faculties": MessageLookupByLibrary.simpleMessage("Faculties"),
    "faculty": MessageLookupByLibrary.simpleMessage("Faculty"),
    "facultyArtsLanguages": MessageLookupByLibrary.simpleMessage(
      "Faculty of Arts and Foreign Languages",
    ),
    "facultyEconomics": MessageLookupByLibrary.simpleMessage(
      "Faculty of Economics, Commerce, and Management Sciences",
    ),
    "facultyLawPolitical": MessageLookupByLibrary.simpleMessage(
      "Faculty of Law and Political Sciences",
    ),
    "fail": MessageLookupByLibrary.simpleMessage(" Failed"),
    "familyLaw": MessageLookupByLibrary.simpleMessage("Family Law"),
    "favoritesAddAction": MessageLookupByLibrary.simpleMessage("Save"),
    "favoritesAddHint": MessageLookupByLibrary.simpleMessage("Enter item ID"),
    "favoritesAddTitle": MessageLookupByLibrary.simpleMessage("Add favorite"),
    "favoritesAddTypeHint": MessageLookupByLibrary.simpleMessage(
      "Type (optional)",
    ),
    "favoritesAdded": MessageLookupByLibrary.simpleMessage("Favorite saved."),
    "favoritesDescription": MessageLookupByLibrary.simpleMessage(
      "Your saved items appear here.",
    ),
    "favoritesEmptyHint": MessageLookupByLibrary.simpleMessage(
      "Save posts or files to see them here.",
    ),
    "favoritesEmptyTitle": MessageLookupByLibrary.simpleMessage(
      "No favorites yet",
    ),
    "favoritesRemoved": MessageLookupByLibrary.simpleMessage(
      "Favorite removed.",
    ),
    "favoritesSignInHint": MessageLookupByLibrary.simpleMessage(
      "Favorites sync to your account when signed in.",
    ),
    "favoritesSignInTitle": MessageLookupByLibrary.simpleMessage(
      "Sign in to save favorites",
    ),
    "favoritesTitle": MessageLookupByLibrary.simpleMessage("Favorites"),
    "favoritesTypeLabel": m13,
    "finance": MessageLookupByLibrary.simpleMessage("Finance"),
    "financeInternationalTrade": MessageLookupByLibrary.simpleMessage(
      "Finance and International Trade",
    ),
    "financialAccounting": MessageLookupByLibrary.simpleMessage(
      "Financial and Accounting Sciences",
    ),
    "financialAccountingDept": MessageLookupByLibrary.simpleMessage(
      "Department of Financial and Accounting Sciences",
    ),
    "financialManagement": MessageLookupByLibrary.simpleMessage(
      "Financial Management",
    ),
    "followComment": MessageLookupByLibrary.simpleMessage("Follow Comment"),
    "following": MessageLookupByLibrary.simpleMessage("Following"),
    "fontSizeDescription": MessageLookupByLibrary.simpleMessage(
      "Choose a comfortable reading size.",
    ),
    "fontSizeLarge": MessageLookupByLibrary.simpleMessage("Large"),
    "fontSizeMedium": MessageLookupByLibrary.simpleMessage("Medium"),
    "fontSizePreviewLabel": MessageLookupByLibrary.simpleMessage("Preview"),
    "fontSizePreviewText": MessageLookupByLibrary.simpleMessage(
      "The quick brown fox jumps over the lazy dog.",
    ),
    "fontSizeSmall": MessageLookupByLibrary.simpleMessage("Small"),
    "fontSizeTitle": MessageLookupByLibrary.simpleMessage("Font size"),
    "forgotPassword": MessageLookupByLibrary.simpleMessage("Forgot password?"),
    "genericAuthError": MessageLookupByLibrary.simpleMessage(
      "Something went wrong. Please try again.",
    ),
    "gpu": MessageLookupByLibrary.simpleMessage(
      "Calculating the academic average",
    ),
    "guestUser": MessageLookupByLibrary.simpleMessage("Guest"),
    "hashtag": MessageLookupByLibrary.simpleMessage("#"),
    "hide": MessageLookupByLibrary.simpleMessage("Hide"),
    "home": MessageLookupByLibrary.simpleMessage("Home"),
    "homeSubtitle": MessageLookupByLibrary.simpleMessage(
      "Browse faculties, calculate your GPA, share your ideas, and write notes easily.",
    ),
    "horizontalUnit": MessageLookupByLibrary.simpleMessage("Horizontal Unit"),
    "hotelTourismMarketing": MessageLookupByLibrary.simpleMessage(
      "Hotel and Tourism Marketing",
    ),
    "humanResourcesManagement": MessageLookupByLibrary.simpleMessage(
      "Human Resources Management",
    ),
    "internationalCooperation": MessageLookupByLibrary.simpleMessage(
      "International Cooperation",
    ),
    "internationalEconomics": MessageLookupByLibrary.simpleMessage(
      "International Economics",
    ),
    "internationalRelations": MessageLookupByLibrary.simpleMessage(
      "International Relations",
    ),
    "invalidEmailError": MessageLookupByLibrary.simpleMessage(
      "The email address is invalid.",
    ),
    "invalidEmailValidation": MessageLookupByLibrary.simpleMessage(
      "Please enter a valid email address.",
    ),
    "law": MessageLookupByLibrary.simpleMessage("Law"),
    "legalProfessionsLaw": MessageLookupByLibrary.simpleMessage(
      "Legal and Judicial Professions Law",
    ),
    "light": MessageLookupByLibrary.simpleMessage("Light"),
    "lightMode": MessageLookupByLibrary.simpleMessage("Light Mode"),
    "localAdministration": MessageLookupByLibrary.simpleMessage(
      "Local Administration",
    ),
    "login": MessageLookupByLibrary.simpleMessage("Login"),
    "logout": MessageLookupByLibrary.simpleMessage("Logout"),
    "logoutAllConfirm": MessageLookupByLibrary.simpleMessage("Log out"),
    "logoutAllDevices": MessageLookupByLibrary.simpleMessage(
      "Log out of all devices",
    ),
    "logoutAllDevicesPrompt": MessageLookupByLibrary.simpleMessage(
      "We\'ll sign you out on this device. For other sessions, enable backend revocation.",
    ),
    "logoutAllFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to sign out from all devices.",
    ),
    "logoutAllLocalOnly": MessageLookupByLibrary.simpleMessage(
      "Signed out here. Configure backend revocation for other devices.",
    ),
    "logoutAllOtherDevices": MessageLookupByLibrary.simpleMessage(
      "Log out other devices",
    ),
    "logoutAllSuccess": MessageLookupByLibrary.simpleMessage(
      "Signed out from all devices.",
    ),
    "major": MessageLookupByLibrary.simpleMessage("Major"),
    "majors": MessageLookupByLibrary.simpleMessage("Majors"),
    "manageDevicesDescription": MessageLookupByLibrary.simpleMessage(
      "See where your account is signed in and remove access if needed.",
    ),
    "manageDevicesHint": MessageLookupByLibrary.simpleMessage(
      "Review active sessions and devices.",
    ),
    "manageDevicesTitle": MessageLookupByLibrary.simpleMessage(
      "Manage devices",
    ),
    "managementSciences": MessageLookupByLibrary.simpleMessage(
      "Management Sciences",
    ),
    "managementSciencesDept": MessageLookupByLibrary.simpleMessage(
      "Department of Management Sciences",
    ),
    "maritimePortLaw": MessageLookupByLibrary.simpleMessage(
      "Maritime and Port Law",
    ),
    "marketing": MessageLookupByLibrary.simpleMessage("Marketing"),
    "mediaUrl": MessageLookupByLibrary.simpleMessage("Image/Video URL"),
    "methodologicalUnit": MessageLookupByLibrary.simpleMessage(
      "Methodological Unit",
    ),
    "monetaryFinancialEconomics": MessageLookupByLibrary.simpleMessage(
      "Monetary and Financial Economics",
    ),
    "mood": MessageLookupByLibrary.simpleMessage("Mood"),
    "name": MessageLookupByLibrary.simpleMessage("Name"),
    "networkError": MessageLookupByLibrary.simpleMessage(
      "Network error. Please try again.",
    ),
    "newPost": MessageLookupByLibrary.simpleMessage("New Post"),
    "noExamsDay": MessageLookupByLibrary.simpleMessage("No exams for this day"),
    "noMajorsYet": MessageLookupByLibrary.simpleMessage("No majors yet"),
    "noNotesYet": MessageLookupByLibrary.simpleMessage("No notes yet"),
    "noPostsYet": MessageLookupByLibrary.simpleMessage("No posts yet"),
    "noSubjectsThisSemester": MessageLookupByLibrary.simpleMessage(
      "No subjects in this semester.",
    ),
    "notRegistered": MessageLookupByLibrary.simpleMessage("Not registered"),
    "note": MessageLookupByLibrary.simpleMessage("Note"),
    "notesTdTpExam": MessageLookupByLibrary.simpleMessage(
      "Grades (TD/TP/Exam)",
    ),
    "notificationsAnnouncements": MessageLookupByLibrary.simpleMessage(
      "Announcements",
    ),
    "notificationsAnnouncementsHint": MessageLookupByLibrary.simpleMessage(
      "Stay up to date on campus news.",
    ),
    "notificationsCommunity": MessageLookupByLibrary.simpleMessage(
      "Community updates",
    ),
    "notificationsCommunityHint": MessageLookupByLibrary.simpleMessage(
      "Get notified about community activity.",
    ),
    "notificationsDisabledHint": MessageLookupByLibrary.simpleMessage(
      "Enable notifications to manage reminders and alerts.",
    ),
    "notificationsEnabled": MessageLookupByLibrary.simpleMessage(
      "Enable notifications",
    ),
    "notificationsEnabledHint": MessageLookupByLibrary.simpleMessage(
      "Get alerts about updates and reminders.",
    ),
    "notificationsExamReminders": MessageLookupByLibrary.simpleMessage(
      "Exam reminders",
    ),
    "notificationsExamRemindersHint": MessageLookupByLibrary.simpleMessage(
      "Receive local alerts for scheduled exams.",
    ),
    "notificationsSettingsDescription": MessageLookupByLibrary.simpleMessage(
      "Manage push notifications and reminders.",
    ),
    "notificationsSettingsTitle": MessageLookupByLibrary.simpleMessage(
      "Notifications",
    ),
    "oneMajor": MessageLookupByLibrary.simpleMessage("One major"),
    "otherNotes": MessageLookupByLibrary.simpleMessage("Other Notes"),
    "otherSessionsSignedOutSuccess": MessageLookupByLibrary.simpleMessage(
      "Signed out from other devices.",
    ),
    "otpCooldownLabel": m14,
    "otpSentFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to send the verification link right now.",
    ),
    "otpSentSuccess": MessageLookupByLibrary.simpleMessage(
      "Verification link sent. Check your email.",
    ),
    "pass": MessageLookupByLibrary.simpleMessage(" Passed"),
    "password": MessageLookupByLibrary.simpleMessage("Password"),
    "pinNote": MessageLookupByLibrary.simpleMessage("Pin Note"),
    "pinned": MessageLookupByLibrary.simpleMessage("Pinned"),
    "politicalAdministrativeOrgs": MessageLookupByLibrary.simpleMessage(
      "Political and Administrative Organizations",
    ),
    "politicalSciences": MessageLookupByLibrary.simpleMessage(
      "Political Sciences",
    ),
    "post": MessageLookupByLibrary.simpleMessage(
      "Your post has been published ✅",
    ),
    "posted": MessageLookupByLibrary.simpleMessage("Post"),
    "posts": MessageLookupByLibrary.simpleMessage("Posts"),
    "privacyAccountOverviewSection": MessageLookupByLibrary.simpleMessage(
      "Account overview",
    ),
    "privacyAppVersionLabel": MessageLookupByLibrary.simpleMessage(
      "App version",
    ),
    "privacyApproxLocationLabel": MessageLookupByLibrary.simpleMessage(
      "Approximate location",
    ),
    "privacyChangePasswordNowNote": MessageLookupByLibrary.simpleMessage(
      "Please change your password immediately. Two-step verification: coming soon.",
    ),
    "privacyChangePasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Change password",
    ),
    "privacyConfirmNewPasswordHelper": MessageLookupByLibrary.simpleMessage(
      "Re-enter your new password for confirmation.",
    ),
    "privacyConfirmNewPasswordLabel": MessageLookupByLibrary.simpleMessage(
      "Confirm new password",
    ),
    "privacyConnectionTypeLabel": MessageLookupByLibrary.simpleMessage(
      "Connection type",
    ),
    "privacyContinue": MessageLookupByLibrary.simpleMessage("Continue"),
    "privacyContinueAction": MessageLookupByLibrary.simpleMessage("Continue"),
    "privacyCopyFullIp": MessageLookupByLibrary.simpleMessage("Copy full IP"),
    "privacyCopyIpSuccess": MessageLookupByLibrary.simpleMessage(
      "Full IP copied securely.",
    ),
    "privacyCurrentPasswordHelper": MessageLookupByLibrary.simpleMessage(
      "Enter your current password to verify account ownership.",
    ),
    "privacyCurrentPasswordLabel": MessageLookupByLibrary.simpleMessage(
      "Current password",
    ),
    "privacyDateTimeLabel": MessageLookupByLibrary.simpleMessage(
      "Date and time",
    ),
    "privacyDeviceLabel": MessageLookupByLibrary.simpleMessage("Device"),
    "privacyEditNameTitle": MessageLookupByLibrary.simpleMessage("Edit name"),
    "privacyEmailConfirmLabel": MessageLookupByLibrary.simpleMessage(
      "Confirm new email",
    ),
    "privacyEmailConfirmMismatch": MessageLookupByLibrary.simpleMessage(
      "Emails do not match.",
    ),
    "privacyEmailCurrentLabel": MessageLookupByLibrary.simpleMessage(
      "Current email",
    ),
    "privacyEmailCurrentMismatch": MessageLookupByLibrary.simpleMessage(
      "Current email does not match.",
    ),
    "privacyEmailFlowSecurityNote": MessageLookupByLibrary.simpleMessage(
      "Security note: your password is never stored in the app.",
    ),
    "privacyEmailFlowSendLink": MessageLookupByLibrary.simpleMessage(
      "Send change email link",
    ),
    "privacyEmailFlowStep1Help": m15,
    "privacyEmailFlowStep2Help": MessageLookupByLibrary.simpleMessage(
      "We\'ll send an email change link to your current inbox for verification.",
    ),
    "privacyEmailFlowStep3Help": MessageLookupByLibrary.simpleMessage(
      "Enter your new email and confirm it.",
    ),
    "privacyEmailFlowStep4Help": m16,
    "privacyEmailFlowTitle": MessageLookupByLibrary.simpleMessage(
      "Change email",
    ),
    "privacyEmailNewLabel": MessageLookupByLibrary.simpleMessage("New email"),
    "privacyEmailRowTitle": MessageLookupByLibrary.simpleMessage("Email"),
    "privacyEmailSaved": MessageLookupByLibrary.simpleMessage(
      "Email updated locally.",
    ),
    "privacyEmailValidationRequired": MessageLookupByLibrary.simpleMessage(
      "Enter and confirm your new email.",
    ),
    "privacyEnterConfirmToMatch": MessageLookupByLibrary.simpleMessage(
      "Enter confirmation to verify the match.",
    ),
    "privacyFirstName": MessageLookupByLibrary.simpleMessage("First name"),
    "privacyIpAddressLabel": MessageLookupByLibrary.simpleMessage("IP address"),
    "privacyIpUnavailable": MessageLookupByLibrary.simpleMessage(
      "IP address is unavailable.",
    ),
    "privacyLastName": MessageLookupByLibrary.simpleMessage("Last name"),
    "privacyLastPasswordChangeAt": m17,
    "privacyLastPasswordChangeTitle": MessageLookupByLibrary.simpleMessage(
      "Last password change",
    ),
    "privacyLastPasswordChangeUnavailable":
        MessageLookupByLibrary.simpleMessage(
          "Last password change: Not available",
        ),
    "privacyLoadFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to load privacy data.",
    ),
    "privacyLoadingLastChange": MessageLookupByLibrary.simpleMessage(
      "Loading last change data...",
    ),
    "privacyManufacturerLabel": MessageLookupByLibrary.simpleMessage(
      "Manufacturer",
    ),
    "privacyNameRowTitle": MessageLookupByLibrary.simpleMessage(
      "First and last name",
    ),
    "privacyNameRuleAllowed": MessageLookupByLibrary.simpleMessage(
      "You can change your name once per month.",
    ),
    "privacyNameRuleBlockedDays": m18,
    "privacyNameRuleBlockedHours": m19,
    "privacyNameSaved": MessageLookupByLibrary.simpleMessage(
      "Name updated successfully.",
    ),
    "privacyNameValidationLong": MessageLookupByLibrary.simpleMessage(
      "Maximum 40 characters",
    ),
    "privacyNameValidationRequired": MessageLookupByLibrary.simpleMessage(
      "This field is required",
    ),
    "privacyNameValidationShort": MessageLookupByLibrary.simpleMessage(
      "Name must be at least 2 characters",
    ),
    "privacyNetworkCellular": MessageLookupByLibrary.simpleMessage(
      "Mobile data",
    ),
    "privacyNewPasswordHelper": MessageLookupByLibrary.simpleMessage(
      "It must contain at least 8 characters.",
    ),
    "privacyNewPasswordLabel": MessageLookupByLibrary.simpleMessage(
      "New password",
    ),
    "privacyNoAuditDataYet": MessageLookupByLibrary.simpleMessage(
      "No data available yet.",
    ),
    "privacyNoEmailLinked": MessageLookupByLibrary.simpleMessage(
      "No email is linked to this account.",
    ),
    "privacyNotAvailable": MessageLookupByLibrary.simpleMessage(
      "Not available",
    ),
    "privacyOperatingSystemLabel": MessageLookupByLibrary.simpleMessage(
      "Operating system",
    ),
    "privacyOtherSessionsRevokedPrecaution":
        MessageLookupByLibrary.simpleMessage(
          "Other sessions were signed out as a precaution.",
        ),
    "privacyPasswordMismatchError": MessageLookupByLibrary.simpleMessage(
      "Passwords do not match.",
    ),
    "privacyPasswordMustDifferError": MessageLookupByLibrary.simpleMessage(
      "The new password must be different from the current password.",
    ),
    "privacyPasswordNewLengthError": MessageLookupByLibrary.simpleMessage(
      "The new password must be at least 8 characters long.",
    ),
    "privacyPasswordReauthFailedGeneric": MessageLookupByLibrary.simpleMessage(
      "Unable to verify your identity. Please try again later.",
    ),
    "privacyPasswordStrengthLabel": MessageLookupByLibrary.simpleMessage(
      "Password strength: ",
    ),
    "privacyPasswordStrengthMedium": MessageLookupByLibrary.simpleMessage(
      "Medium",
    ),
    "privacyPasswordStrengthStrong": MessageLookupByLibrary.simpleMessage(
      "Strong",
    ),
    "privacyPasswordStrengthWeak": MessageLookupByLibrary.simpleMessage("Weak"),
    "privacyPasswordUpdateAction": MessageLookupByLibrary.simpleMessage(
      "Update",
    ),
    "privacyPasswordUpdateConfirmBody": MessageLookupByLibrary.simpleMessage(
      "Do you want to update the password?",
    ),
    "privacyPasswordUpdateConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Confirm update",
    ),
    "privacyPasswordUpdateFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to update password. Please try again later.",
    ),
    "privacyPasswordUpdateRequiresSignin": MessageLookupByLibrary.simpleMessage(
      "Unable to update password. Please sign in again.",
    ),
    "privacyPasswordUpdateSuccess": MessageLookupByLibrary.simpleMessage(
      "Password updated successfully.",
    ),
    "privacyPasswordsMatch": MessageLookupByLibrary.simpleMessage(
      "Passwords match.",
    ),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage("Privacy Policy"),
    "privacyPolicyBody": MessageLookupByLibrary.simpleMessage(
      "Please review our privacy policy.",
    ),
    "privacyPolicyTitle": MessageLookupByLibrary.simpleMessage(
      "Privacy Policy",
    ),
    "privacyReauthCopyIpReason": MessageLookupByLibrary.simpleMessage(
      "Verify your identity to copy the full IP.",
    ),
    "privacyReauthFailed": MessageLookupByLibrary.simpleMessage(
      "Password verification failed. Please try again.",
    ),
    "privacyReauthSubtitle": MessageLookupByLibrary.simpleMessage(
      "For your security, enter your current password before continuing.",
    ),
    "privacyReauthTitle": MessageLookupByLibrary.simpleMessage(
      "Confirm password",
    ),
    "privacyResetEmailHint": MessageLookupByLibrary.simpleMessage(
      "The email may arrive within a minute. Check your spam folder too.",
    ),
    "privacyResetLinkFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to send reset link. Please try again later.",
    ),
    "privacyResetLinkSent": MessageLookupByLibrary.simpleMessage(
      "Password reset link sent to your email.",
    ),
    "privacyResetPasswordDialogBody": m20,
    "privacyRevokeSessionsFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to end all sessions right now.",
    ),
    "privacySaveNewPassword": MessageLookupByLibrary.simpleMessage(
      "Save new password",
    ),
    "privacySecurityAlertBody": MessageLookupByLibrary.simpleMessage(
      "If you did not change the password, we will immediately sign out all other sessions. Do you want to continue?",
    ),
    "privacySecurityAlertTitle": MessageLookupByLibrary.simpleMessage(
      "Critical security alert",
    ),
    "privacySegmentTitle": MessageLookupByLibrary.simpleMessage("Privacy"),
    "privacySendResetLinkAction": MessageLookupByLibrary.simpleMessage(
      "Send link",
    ),
    "privacySettingsDescription": MessageLookupByLibrary.simpleMessage(
      "Control what others can see on your profile.",
    ),
    "privacySettingsTitle": MessageLookupByLibrary.simpleMessage("Privacy"),
    "privacyStepOf": m21,
    "privacyTabSubtitle": MessageLookupByLibrary.simpleMessage(
      "Manage your account data securely",
    ),
    "privacyTabTitle": MessageLookupByLibrary.simpleMessage("Privacy"),
    "privacyThisWasNotMe": MessageLookupByLibrary.simpleMessage(
      "This wasn\'t me",
    ),
    "privacyUnknown": MessageLookupByLibrary.simpleMessage("Unknown"),
    "privacyViewDetails": MessageLookupByLibrary.simpleMessage(
      "View details ⌄",
    ),
    "privateLaw": MessageLookupByLibrary.simpleMessage("Private Law"),
    "profile": MessageLookupByLibrary.simpleMessage("Profile"),
    "profileVisibilityPrivate": MessageLookupByLibrary.simpleMessage("Private"),
    "profileVisibilityPublic": MessageLookupByLibrary.simpleMessage("Public"),
    "profileVisibilityTitle": MessageLookupByLibrary.simpleMessage(
      "Profile visibility",
    ),
    "publicLaw": MessageLookupByLibrary.simpleMessage("Public Law"),
    "publish": MessageLookupByLibrary.simpleMessage("Publish"),
    "quickCalc": MessageLookupByLibrary.simpleMessage("Quick Calculation"),
    "quickCalc2": MessageLookupByLibrary.simpleMessage("Quick Calc"),
    "rateApp": MessageLookupByLibrary.simpleMessage("Rate app"),
    "rateAppFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to open the store right now.",
    ),
    "register": MessageLookupByLibrary.simpleMessage("Register"),
    "reminder24h": MessageLookupByLibrary.simpleMessage("24 hours before"),
    "reminder2h": MessageLookupByLibrary.simpleMessage("2 hours before"),
    "reminder30m": MessageLookupByLibrary.simpleMessage("30 minutes before"),
    "reminders": MessageLookupByLibrary.simpleMessage("Reminders"),
    "report": MessageLookupByLibrary.simpleMessage("Report"),
    "resendVerificationCooldown": m22,
    "resendVerificationEmail": MessageLookupByLibrary.simpleMessage(
      "Resend verification email",
    ),
    "resetFailed": m23,
    "resetLinkFailed": MessageLookupByLibrary.simpleMessage(
      "Could not send the link, please try again.",
    ),
    "resetLinkSentSuccess": MessageLookupByLibrary.simpleMessage(
      "If the email belongs to an account, a reset link will arrive. Check your spam folder too.",
    ),
    "resetPassword": MessageLookupByLibrary.simpleMessage("Reset Password"),
    "resetPasswordHelper": MessageLookupByLibrary.simpleMessage(
      "Enter your email and we’ll send you a reset link.",
    ),
    "resetPasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Reset your password",
    ),
    "resetSent": MessageLookupByLibrary.simpleMessage(
      "Reset link has been sent",
    ),
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("Save changes"),
    "saveExam": MessageLookupByLibrary.simpleMessage("Save Exam"),
    "savePost": MessageLookupByLibrary.simpleMessage("Save Post"),
    "searchClipboard": MessageLookupByLibrary.simpleMessage(
      "Search inside Notepad…",
    ),
    "searchFaculty": MessageLookupByLibrary.simpleMessage(
      "Search for a faculty...",
    ),
    "searchNoResults": MessageLookupByLibrary.simpleMessage("No results found"),
    "searchStartTyping": MessageLookupByLibrary.simpleMessage(
      "Start typing to search",
    ),
    "sections": MessageLookupByLibrary.simpleMessage("Sections"),
    "securityCenterTitle": MessageLookupByLibrary.simpleMessage("Security"),
    "securityPrivacyTitle": MessageLookupByLibrary.simpleMessage(
      "Security & Privacy",
    ),
    "securitySegmentTitle": MessageLookupByLibrary.simpleMessage("Security"),
    "sendOtpNow": MessageLookupByLibrary.simpleMessage("Send OTP now"),
    "sendResetLink": MessageLookupByLibrary.simpleMessage("Send link"),
    "sendResetLinkLoading": MessageLookupByLibrary.simpleMessage("Sending..."),
    "servicesMarketing": MessageLookupByLibrary.simpleMessage(
      "Services Marketing",
    ),
    "sessionAgoDays": m24,
    "sessionAgoHours": m25,
    "sessionAgoMinutes": m26,
    "sessionDeviceNameLabel": MessageLookupByLibrary.simpleMessage(
      "Device name",
    ),
    "sessionLastActivityLabel": MessageLookupByLibrary.simpleMessage(
      "Last activity",
    ),
    "sessionLoginDateLabel": MessageLookupByLibrary.simpleMessage("Login date"),
    "sessionModelLabel": MessageLookupByLibrary.simpleMessage("Model"),
    "sessionNetworkLabel": MessageLookupByLibrary.simpleMessage("Network"),
    "sessionPlatformLabel": MessageLookupByLibrary.simpleMessage("Platform"),
    "sessionSignOutFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to sign out this session.",
    ),
    "sessionSignedOutSuccess": MessageLookupByLibrary.simpleMessage(
      "Session signed out successfully.",
    ),
    "sessionTrustedDevice": MessageLookupByLibrary.simpleMessage(
      "Trusted device",
    ),
    "sessionUnknownDevice": MessageLookupByLibrary.simpleMessage(
      "Unknown device",
    ),
    "sessionVersionLabel": MessageLookupByLibrary.simpleMessage("Version"),
    "share": MessageLookupByLibrary.simpleMessage("Share"),
    "shareApp": MessageLookupByLibrary.simpleMessage("Share app"),
    "shareAppMessage": MessageLookupByLibrary.simpleMessage(
      "Check out UniSpace for smart study tools and student community!",
    ),
    "showEmailInProfileHint": MessageLookupByLibrary.simpleMessage(
      "Allow others to see your email.",
    ),
    "showEmailInProfileTitle": MessageLookupByLibrary.simpleMessage(
      "Show email on profile",
    ),
    "signInRequired": MessageLookupByLibrary.simpleMessage(
      "Please sign in to continue.",
    ),
    "signOut": MessageLookupByLibrary.simpleMessage("Sign out"),
    "smartReviewActionAddExam": MessageLookupByLibrary.simpleMessage(
      "Add exam",
    ),
    "smartReviewActionAddSubjects": MessageLookupByLibrary.simpleMessage(
      "Add subjects",
    ),
    "smartReviewActionClearPlan": MessageLookupByLibrary.simpleMessage(
      "Clear plan",
    ),
    "smartReviewActionLater": MessageLookupByLibrary.simpleMessage(
      "Maybe later",
    ),
    "smartReviewBottomSheetBody": MessageLookupByLibrary.simpleMessage(
      "Add your subjects and exam dates so we can personalize your schedule.",
    ),
    "smartReviewBottomSheetTitle": MessageLookupByLibrary.simpleMessage(
      "Before we build your plan",
    ),
    "smartReviewChipExams": MessageLookupByLibrary.simpleMessage("Exam-aware"),
    "smartReviewChipReminders": MessageLookupByLibrary.simpleMessage(
      "Reminders",
    ),
    "smartReviewChipSimple": MessageLookupByLibrary.simpleMessage(
      "Easy to follow",
    ),
    "smartReviewChipTime": MessageLookupByLibrary.simpleMessage("Time-smart"),
    "smartReviewCtaCreate": MessageLookupByLibrary.simpleMessage(
      "Create review plan",
    ),
    "smartReviewEmptyNoExamsBody": MessageLookupByLibrary.simpleMessage(
      "Add at least one exam so we can build a focused review plan.",
    ),
    "smartReviewEmptyNoExamsTitle": MessageLookupByLibrary.simpleMessage(
      "No upcoming exams yet",
    ),
    "smartReviewEmptyNoPlanBody": MessageLookupByLibrary.simpleMessage(
      "We will generate a 7-day schedule based on your nearest exam and study time.",
    ),
    "smartReviewEmptyNoPlanTitle": MessageLookupByLibrary.simpleMessage(
      "Ready to build your plan",
    ),
    "smartReviewPlanCleared": MessageLookupByLibrary.simpleMessage(
      "Plan cleared",
    ),
    "smartReviewPlanComingSoon": MessageLookupByLibrary.simpleMessage(
      "Coming soon",
    ),
    "smartReviewPlanCtaCreate": MessageLookupByLibrary.simpleMessage(
      "Create a plan",
    ),
    "smartReviewPlanDescription": MessageLookupByLibrary.simpleMessage(
      "Generate a focused review plan based on your upcoming exams and study goals.",
    ),
    "smartReviewPlanRange": m27,
    "smartReviewPlanSectionTitle": MessageLookupByLibrary.simpleMessage(
      "Your plan",
    ),
    "smartReviewPlanTitle": MessageLookupByLibrary.simpleMessage(
      "Smart review plan",
    ),
    "smartReviewPreviewItem1": MessageLookupByLibrary.simpleMessage(
      "Today · 2 focus sessions (45 min)",
    ),
    "smartReviewPreviewItem2": MessageLookupByLibrary.simpleMessage(
      "Tomorrow · 1 mock quiz + recap",
    ),
    "smartReviewPreviewItem3": MessageLookupByLibrary.simpleMessage(
      "This week · Prioritize hardest subjects",
    ),
    "smartReviewPreviewTitle": MessageLookupByLibrary.simpleMessage(
      "Preview your week",
    ),
    "smartReviewSubtitle": MessageLookupByLibrary.simpleMessage(
      "Turn upcoming exams into a balanced, achievable daily plan.",
    ),
    "smartReviewTaskDuration": m28,
    "smartReviewTaskFocusTitle": m29,
    "smartReviewTaskMockTitle": m30,
    "smartReviewTaskPracticeTitle": m31,
    "smartReviewTaskSummaryTitle": m32,
    "smartReviewTipsBody": MessageLookupByLibrary.simpleMessage(
      "We analyze your exams, time left, and difficulty to build daily sessions you can actually follow.",
    ),
    "smartReviewTipsTitle": MessageLookupByLibrary.simpleMessage(
      "How it works",
    ),
    "smartReviewTitle": MessageLookupByLibrary.simpleMessage(
      "Smart Review Plan",
    ),
    "soon": MessageLookupByLibrary.simpleMessage("Coming soon"),
    "startDiscussion": MessageLookupByLibrary.simpleMessage(
      "Start the first discussion in the community and share your experience with colleagues.",
    ),
    "studyResults": MessageLookupByLibrary.simpleMessage("Study Results"),
    "system": MessageLookupByLibrary.simpleMessage("System"),
    "systemMode": MessageLookupByLibrary.simpleMessage("System Mode"),
    "taxLaw": MessageLookupByLibrary.simpleMessage("Tax Law"),
    "title": MessageLookupByLibrary.simpleMessage("Title"),
    "tooManyRequestsError": MessageLookupByLibrary.simpleMessage(
      "Too many requests, try again later.",
    ),
    "trustedDevicesTitle": MessageLookupByLibrary.simpleMessage(
      "Trusted devices",
    ),
    "twoFactorAttemptsRemaining": m33,
    "twoFactorAuthHint": MessageLookupByLibrary.simpleMessage(
      "Require OTP verification on sign-in.",
    ),
    "twoFactorAuthTitle": MessageLookupByLibrary.simpleMessage(
      "Two-factor authentication",
    ),
    "twoFactorBackToLogin": MessageLookupByLibrary.simpleMessage(
      "Back to login",
    ),
    "twoFactorChallengeMissing": MessageLookupByLibrary.simpleMessage(
      "Verification session not found. Sign in again.",
    ),
    "twoFactorCodeExpired": MessageLookupByLibrary.simpleMessage(
      "Code expired. Request a new code.",
    ),
    "twoFactorCodeHint": MessageLookupByLibrary.simpleMessage("6-digit code"),
    "twoFactorCodeIncorrect": MessageLookupByLibrary.simpleMessage(
      "Incorrect code. Try again.",
    ),
    "twoFactorCodeInvalidFormat": MessageLookupByLibrary.simpleMessage(
      "Enter a valid 6-digit code.",
    ),
    "twoFactorCodeLabel": MessageLookupByLibrary.simpleMessage(
      "Verification code",
    ),
    "twoFactorCodeSent": MessageLookupByLibrary.simpleMessage(
      "Verification code sent to your email.",
    ),
    "twoFactorConfirmButton": MessageLookupByLibrary.simpleMessage("Confirm"),
    "twoFactorDisabledToast": MessageLookupByLibrary.simpleMessage(
      "Two-factor authentication disabled.",
    ),
    "twoFactorEnableConfirmBody": MessageLookupByLibrary.simpleMessage(
      "You will be asked for a one-time code sent to your email after password login.",
    ),
    "twoFactorEnableConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Enable two-factor authentication?",
    ),
    "twoFactorEnabledToast": MessageLookupByLibrary.simpleMessage(
      "Two-factor authentication enabled.",
    ),
    "twoFactorGenericError": MessageLookupByLibrary.simpleMessage(
      "Unable to complete verification. Try again.",
    ),
    "twoFactorOtpDescription": m34,
    "twoFactorOtpTitle": MessageLookupByLibrary.simpleMessage(
      "Email verification code",
    ),
    "twoFactorResendCode": MessageLookupByLibrary.simpleMessage("Resend code"),
    "twoFactorResendCooldown": MessageLookupByLibrary.simpleMessage(
      "Please wait before resending.",
    ),
    "twoFactorResendIn": m35,
    "twoFactorSendFailed": MessageLookupByLibrary.simpleMessage(
      "Failed to send verification code.",
    ),
    "twoFactorTooManyAttempts": MessageLookupByLibrary.simpleMessage(
      "Too many failed attempts. Try again later.",
    ),
    "twoFactorVerifiedSuccess": MessageLookupByLibrary.simpleMessage(
      "Two-factor verification completed.",
    ),
    "unblockUser": MessageLookupByLibrary.simpleMessage("Unblock"),
    "university": MessageLookupByLibrary.simpleMessage("University"),
    "userDisabledError": MessageLookupByLibrary.simpleMessage(
      "This account is disabled.",
    ),
    "userInfo": MessageLookupByLibrary.simpleMessage("User Information"),
    "userNotFoundError": MessageLookupByLibrary.simpleMessage(
      "No account found with that email.",
    ),
    "verificationEmailSent": MessageLookupByLibrary.simpleMessage(
      "Verification email sent.",
    ),
    "verifyEmailHelper": MessageLookupByLibrary.simpleMessage(
      "Open the verification email and click the link, then tap check now.",
    ),
    "verifyEmailTitle": MessageLookupByLibrary.simpleMessage("Verify email"),
    "verifyEmailToContinue": MessageLookupByLibrary.simpleMessage(
      "Please verify your email to continue.",
    ),
    "viewAll": MessageLookupByLibrary.simpleMessage("View All"),
    "weakPasswordError": MessageLookupByLibrary.simpleMessage(
      "Password is too weak.",
    ),
    "welcomeEmoji": MessageLookupByLibrary.simpleMessage("Welcome 👋"),
    "welcomeUniSpace": MessageLookupByLibrary.simpleMessage(
      "Welcome to UniSpace",
    ),
    "writeComment": MessageLookupByLibrary.simpleMessage("Write your comment…"),
    "writeYourComment": MessageLookupByLibrary.simpleMessage(
      "Write your comment",
    ),
    "wrongPasswordError": MessageLookupByLibrary.simpleMessage(
      "Wrong password.",
    ),
  };
}
