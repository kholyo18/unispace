// GENERATED FILE. Regenerated from lib/l10n/intl_*.arb to restore the project's intl_utils S API.
// ignore_for_file: type=lint
import 'package:flutter/widgets.dart';

class S {
  S(this.localeName);

  final String localeName;

  static S? _current;

  static S get current => _current ?? S('en');

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S) ?? current;
  }

  static Future<S> load(Locale locale) async {
    final localeName = _canonicalLocaleName(locale);
    final localizations = S(localeName);
    _current = localizations;
    return localizations;
  }

  static String _canonicalLocaleName(Locale locale) {
    if (_localizedValues.containsKey(locale.languageCode)) {
      return locale.languageCode;
    }
    return 'en';
  }

  String _message(String key) {
    final values = _localizedValues[localeName] ?? _localizedValues['en']!;
    return values[key] ?? _localizedValues['en']![key] ?? key;
  }

  String _format(String key, Map<String, Object?> args) {
    var value = _message(key);
    args.forEach((name, arg) {
      value = value.replaceAll('{$name}', arg?.toString() ?? '');
    });
    return value;
  }

  String get sections => _message("sections");

  String get majors => _message("majors");

  String get comments => _message("comments");

  String get comment => _message("comment");

  String get writeYourComment => _message("writeYourComment");

  String get publish => _message("publish");

  String get cancel => _message("cancel");

  String get delete => _message("delete");

  String get posted => _message("posted");

  String get searchClipboard => _message("searchClipboard");

  String get note => _message("note");

  String get title => _message("title");

  String get content => _message("content");

  String get save => _message("save");

  String get pinNote => _message("pinNote");

  String get noNotesYet => _message("noNotesYet");

  String get archive => _message("archive");

  String get home => _message("home");

  String get community => _message("community");

  String get viewAll => _message("viewAll");

  String get faculties => _message("faculties");

  String get clipboard => _message("clipboard");

  String get changeTheme => _message("changeTheme");

  String get changeLanguage => _message("changeLanguage");

  String get resetPassword => _message("resetPassword");

  String get logout => _message("logout");

  String get login => _message("login");

  String get aboutApp => _message("aboutApp");

  String get privacyPolicy => _message("privacyPolicy");

  String get privacyPolicyTitle => _message("privacyPolicyTitle");

  String get privacyPolicyBody => _message("privacyPolicyBody");

  String get welcomeEmoji => _message("welcomeEmoji");

  String get homeSubtitle => _message("homeSubtitle");

  String get searchFaculty => _message("searchFaculty");

  String get searchStartTyping => _message("searchStartTyping");

  String get searchNoResults => _message("searchNoResults");

  String get quickCalc => _message("quickCalc");

  String get welcomeUniSpace => _message("welcomeUniSpace");

  String get email => _message("email");

  String get password => _message("password");

  String get forgotPassword => _message("forgotPassword");

  String get resetPasswordTitle => _message("resetPasswordTitle");

  String get resetPasswordHelper => _message("resetPasswordHelper");

  String get sendResetLink => _message("sendResetLink");

  String get sendResetLinkLoading => _message("sendResetLinkLoading");

  String get invalidEmailValidation => _message("invalidEmailValidation");

  String get resetLinkSentSuccess => _message("resetLinkSentSuccess");

  String get invalidEmailError => _message("invalidEmailError");

  String get userNotFoundError => _message("userNotFoundError");

  String get tooManyRequestsError => _message("tooManyRequestsError");

  String get resetLinkFailed => _message("resetLinkFailed");

  String get resetSent => _message("resetSent");

  String get resetFailed => _message("resetFailed");

  String get notRegistered => _message("notRegistered");

  String get pinned => _message("pinned");

  String get otherNotes => _message("otherNotes");

  String get noPostsYet => _message("noPostsYet");

  String get startDiscussion => _message("startDiscussion");

  String get createPost => _message("createPost");

  String get newPost => _message("newPost");

  String get mediaUrl => _message("mediaUrl");

  String get hashtag => _message("hashtag");

  String get share => _message("share");

  String get report => _message("report");

  String get commentsCount => _message("commentsCount");

  String get writeComment => _message("writeComment");

  String get quickCalc2 => _message("quickCalc2");

  String get add => _message("add");

  String get calculate => _message("calculate");

  String get pass => _message("pass");

  String get fail => _message("fail");

  String get credits => _message("credits");

  String get lightMode => _message("lightMode");

  String get darkMode => _message("darkMode");

  String get systemMode => _message("systemMode");

  String get aboutAppDetails => _message("aboutAppDetails");

  String get chooseTheme => _message("chooseTheme");

  String get light => _message("light");

  String get dark => _message("dark");

  String get system => _message("system");

  String get chooseLanguage => _message("chooseLanguage");

  String get arabic => _message("arabic");

  String get register => _message("register");

  String get post => _message("post");

  String get createPoste => _message("createPoste");

  String get oneMajor => _message("oneMajor");

  String get noMajorsYet => _message("noMajorsYet");

  String get editWeights => _message("editWeights");

  String get facultyEconomics => _message("facultyEconomics");

  String get basicEducationDept => _message("basicEducationDept");

  String get basicEducation => _message("basicEducation");

  String get managementSciencesDept => _message("managementSciencesDept");

  String get managementSciences => _message("managementSciences");

  String get businessAdministration => _message("businessAdministration");

  String get financialManagement => _message("financialManagement");

  String get humanResourcesManagement => _message("humanResourcesManagement");

  String get corporateFinancialManagement => _message("corporateFinancialManagement");

  String get commercialSciencesDept => _message("commercialSciencesDept");

  String get commercialSciences => _message("commercialSciences");

  String get financeInternationalTrade => _message("financeInternationalTrade");

  String get marketing => _message("marketing");

  String get servicesMarketing => _message("servicesMarketing");

  String get hotelTourismMarketing => _message("hotelTourismMarketing");

  String get financialAccountingDept => _message("financialAccountingDept");

  String get financialAccounting => _message("financialAccounting");

  String get finance => _message("finance");

  String get accounting => _message("accounting");

  String get accountingTaxation => _message("accountingTaxation");

  String get corporateFinance => _message("corporateFinance");

  String get economicsDept => _message("economicsDept");

  String get economics => _message("economics");

  String get monetaryFinancialEconomics => _message("monetaryFinancialEconomics");

  String get internationalEconomics => _message("internationalEconomics");

  String get noSubjectsThisSemester => _message("noSubjectsThisSemester");

  String get coefficient => _message("coefficient");

  String get close => _message("close");

  String get studyResults => _message("studyResults");

  String get notesTdTpExam => _message("notesTdTpExam");

  String get facultyLawPolitical => _message("facultyLawPolitical");

  String get politicalSciences => _message("politicalSciences");

  String get commonCore => _message("commonCore");

  String get basicUnit => _message("basicUnit");

  String get methodologicalUnit => _message("methodologicalUnit");

  String get exploratoryUnit => _message("exploratoryUnit");

  String get horizontalUnit => _message("horizontalUnit");

  String get politicalAdministrativeOrgs => _message("politicalAdministrativeOrgs");

  String get law => _message("law");

  String get publicLaw => _message("publicLaw");

  String get privateLaw => _message("privateLaw");

  String get advancedPublicLaw => _message("advancedPublicLaw");

  String get familyLaw => _message("familyLaw");

  String get criminalLaw => _message("criminalLaw");

  String get businessLaw => _message("businessLaw");

  String get legalProfessionsLaw => _message("legalProfessionsLaw");

  String get maritimePortLaw => _message("maritimePortLaw");

  String get energyMiningLaw => _message("energyMiningLaw");

  String get taxLaw => _message("taxLaw");

  String get internationalRelations => _message("internationalRelations");

  String get internationalCooperation => _message("internationalCooperation");

  String get localAdministration => _message("localAdministration");

  String get contactUs => _message("contactUs");

  String get blockAccount => _message("blockAccount");

  String get followComment => _message("followComment");

  String get copyText => _message("copyText");

  String get hide => _message("hide");

  String get savePost => _message("savePost");

  String get university => _message("university");

  String get faculty => _message("faculty");

  String get department => _message("department");

  String get major => _message("major");

  String get mood => _message("mood");

  String get name => _message("name");

  String get posts => _message("posts");

  String get profile => _message("profile");

  String get following => _message("following");

  String get userInfo => _message("userInfo");

  String get facultyArtsLanguages => _message("facultyArtsLanguages");

  String get deptArabicLangLit => _message("deptArabicLangLit");

  String get deptFrenchLangLit => _message("deptFrenchLangLit");

  String get deptEnglishLangLit => _message("deptEnglishLangLit");

  String get contactUsSubtitle => _message("contactUsSubtitle");

  String get contactCategoryLabel => _message("contactCategoryLabel");

  String get contactCategoryIssue => _message("contactCategoryIssue");

  String get contactCategoryFeature => _message("contactCategoryFeature");

  String get contactCategoryImprovement => _message("contactCategoryImprovement");

  String get contactCategoryReport => _message("contactCategoryReport");

  String get contactCategoryOther => _message("contactCategoryOther");

  String get contactSubjectLabel => _message("contactSubjectLabel");

  String get contactSubjectHint => _message("contactSubjectHint");

  String get contactDescriptionLabel => _message("contactDescriptionLabel");

  String get contactDescriptionHint => _message("contactDescriptionHint");

  String get contactScreenshotPlaceholder => _message("contactScreenshotPlaceholder");

  String get contactScreenshotSoon => _message("contactScreenshotSoon");

  String get contactIncludeUserInfo => _message("contactIncludeUserInfo");

  String get contactUserInfoUnavailable => _message("contactUserInfoUnavailable");

  String get contactSend => _message("contactSend");

  String get contactValidationRequired => _message("contactValidationRequired");

  String contactValidationMinLength(Object? min) => _format("contactValidationMinLength", <String, Object?>{'min': min});

  String contactValidationMaxLength(Object? max) => _format("contactValidationMaxLength", <String, Object?>{'max': max});

  String get contactSending => _message("contactSending");

  String get contactSendSuccess => _message("contactSendSuccess");

  String get contactSendFailure => _message("contactSendFailure");

  String get contactMailOpened => _message("contactMailOpened");

  String get contactMailUnavailable => _message("contactMailUnavailable");

  String get contactCopyDialogTitle => _message("contactCopyDialogTitle");

  String get contactCopyDialogBody => _message("contactCopyDialogBody");

  String get contactCopyAction => _message("contactCopyAction");

  String get contactCopied => _message("contactCopied");

  String get contactMetadataHeader => _message("contactMetadataHeader");

  String get contactMetadataUserId => _message("contactMetadataUserId");

  String get contactMetadataEmail => _message("contactMetadataEmail");

  String get contactMetadataName => _message("contactMetadataName");

  String get contactMetadataPlatform => _message("contactMetadataPlatform");

  String get contactMetadataLocale => _message("contactMetadataLocale");

  String get contactMetadataTimestamp => _message("contactMetadataTimestamp");

  String get contactMetadataAppVersion => _message("contactMetadataAppVersion");

  String get examCalendar => _message("examCalendar");

  String get smartReviewPlanTitle => _message("smartReviewPlanTitle");

  String get smartReviewPlanDescription => _message("smartReviewPlanDescription");

  String get smartReviewPlanCtaCreate => _message("smartReviewPlanCtaCreate");

  String get smartReviewPlanComingSoon => _message("smartReviewPlanComingSoon");

  String get smartReviewTitle => _message("smartReviewTitle");

  String get smartReviewSubtitle => _message("smartReviewSubtitle");

  String get smartReviewCtaCreate => _message("smartReviewCtaCreate");

  String get smartReviewChipExams => _message("smartReviewChipExams");

  String get smartReviewChipTime => _message("smartReviewChipTime");

  String get smartReviewChipReminders => _message("smartReviewChipReminders");

  String get smartReviewChipSimple => _message("smartReviewChipSimple");

  String get smartReviewPreviewTitle => _message("smartReviewPreviewTitle");

  String get smartReviewPreviewItem1 => _message("smartReviewPreviewItem1");

  String get smartReviewPreviewItem2 => _message("smartReviewPreviewItem2");

  String get smartReviewPreviewItem3 => _message("smartReviewPreviewItem3");

  String get smartReviewBottomSheetTitle => _message("smartReviewBottomSheetTitle");

  String get smartReviewBottomSheetBody => _message("smartReviewBottomSheetBody");

  String get smartReviewActionAddSubjects => _message("smartReviewActionAddSubjects");

  String get smartReviewActionAddExam => _message("smartReviewActionAddExam");

  String get smartReviewActionLater => _message("smartReviewActionLater");

  String get smartReviewTipsTitle => _message("smartReviewTipsTitle");

  String get smartReviewTipsBody => _message("smartReviewTipsBody");

  String get smartReviewEmptyNoExamsTitle => _message("smartReviewEmptyNoExamsTitle");

  String get smartReviewEmptyNoExamsBody => _message("smartReviewEmptyNoExamsBody");

  String get smartReviewEmptyNoPlanTitle => _message("smartReviewEmptyNoPlanTitle");

  String get smartReviewEmptyNoPlanBody => _message("smartReviewEmptyNoPlanBody");

  String get smartReviewPlanSectionTitle => _message("smartReviewPlanSectionTitle");

  String smartReviewPlanRange(Object? start, Object? end) => _format("smartReviewPlanRange", <String, Object?>{'start': start, 'end': end});

  String get smartReviewPlanCleared => _message("smartReviewPlanCleared");

  String get smartReviewActionClearPlan => _message("smartReviewActionClearPlan");

  String smartReviewTaskDuration(Object? minutes) => _format("smartReviewTaskDuration", <String, Object?>{'minutes': minutes});

  String smartReviewTaskFocusTitle(Object? subject) => _format("smartReviewTaskFocusTitle", <String, Object?>{'subject': subject});

  String smartReviewTaskPracticeTitle(Object? subject) => _format("smartReviewTaskPracticeTitle", <String, Object?>{'subject': subject});

  String smartReviewTaskSummaryTitle(Object? subject) => _format("smartReviewTaskSummaryTitle", <String, Object?>{'subject': subject});

  String smartReviewTaskMockTitle(Object? subject) => _format("smartReviewTaskMockTitle", <String, Object?>{'subject': subject});

  String get soon => _message("soon");

  String get addExam => _message("addExam");

  String get editExam => _message("editExam");

  String get deleteExam => _message("deleteExam");

  String get confirmDeleteExam => _message("confirmDeleteExam");

  String get examSubject => _message("examSubject");

  String get examSubjectRequired => _message("examSubjectRequired");

  String get examRoom => _message("examRoom");

  String get examNote => _message("examNote");

  String get reminders => _message("reminders");

  String get reminder24h => _message("reminder24h");

  String get reminder2h => _message("reminder2h");

  String get reminder30m => _message("reminder30m");

  String get saveExam => _message("saveExam");

  String get noExamsDay => _message("noExamsDay");

  String examReminder24h(Object? subject) => _format("examReminder24h", <String, Object?>{'subject': subject});

  String examReminder2h(Object? subject) => _format("examReminder2h", <String, Object?>{'subject': subject});

  String examReminder30m(Object? subject) => _format("examReminder30m", <String, Object?>{'subject': subject});

  String get drawerSectionAccount => _message("drawerSectionAccount");

  String get drawerSectionStudent => _message("drawerSectionStudent");

  String get drawerSectionContent => _message("drawerSectionContent");

  String get drawerSectionApp => _message("drawerSectionApp");

  String get editProfile => _message("editProfile");

  String get notificationsSettingsTitle => _message("notificationsSettingsTitle");

  String get notificationsSettingsDescription => _message("notificationsSettingsDescription");

  String get notificationsEnabled => _message("notificationsEnabled");

  String get notificationsEnabledHint => _message("notificationsEnabledHint");

  String get notificationsExamReminders => _message("notificationsExamReminders");

  String get notificationsExamRemindersHint => _message("notificationsExamRemindersHint");

  String get notificationsAnnouncements => _message("notificationsAnnouncements");

  String get notificationsAnnouncementsHint => _message("notificationsAnnouncementsHint");

  String get notificationsCommunity => _message("notificationsCommunity");

  String get notificationsCommunityHint => _message("notificationsCommunityHint");

  String get notificationsDisabledHint => _message("notificationsDisabledHint");

  String get securityCenterTitle => _message("securityCenterTitle");

  String get twoFactorAuthTitle => _message("twoFactorAuthTitle");

  String get twoFactorAuthHint => _message("twoFactorAuthHint");

  String get twoFactorEnabledToast => _message("twoFactorEnabledToast");

  String get twoFactorDisabledToast => _message("twoFactorDisabledToast");

  String get twoFactorEnableConfirmTitle => _message("twoFactorEnableConfirmTitle");

  String get twoFactorEnableConfirmBody => _message("twoFactorEnableConfirmBody");

  String get twoFactorOtpTitle => _message("twoFactorOtpTitle");

  String twoFactorOtpDescription(Object? email) => _format("twoFactorOtpDescription", <String, Object?>{'email': email});

  String get twoFactorCodeLabel => _message("twoFactorCodeLabel");

  String get twoFactorCodeHint => _message("twoFactorCodeHint");

  String get twoFactorConfirmButton => _message("twoFactorConfirmButton");

  String get twoFactorResendCode => _message("twoFactorResendCode");

  String twoFactorResendIn(Object? seconds) => _format("twoFactorResendIn", <String, Object?>{'seconds': seconds});

  String get twoFactorBackToLogin => _message("twoFactorBackToLogin");

  String get twoFactorCodeSent => _message("twoFactorCodeSent");

  String get twoFactorCodeExpired => _message("twoFactorCodeExpired");

  String get twoFactorCodeIncorrect => _message("twoFactorCodeIncorrect");

  String get twoFactorTooManyAttempts => _message("twoFactorTooManyAttempts");

  String get twoFactorResendCooldown => _message("twoFactorResendCooldown");

  String get twoFactorVerifiedSuccess => _message("twoFactorVerifiedSuccess");

  String get twoFactorCodeInvalidFormat => _message("twoFactorCodeInvalidFormat");

  String get twoFactorChallengeMissing => _message("twoFactorChallengeMissing");

  String get twoFactorSendFailed => _message("twoFactorSendFailed");

  String get twoFactorGenericError => _message("twoFactorGenericError");

  String twoFactorAttemptsRemaining(Object? count) => _format("twoFactorAttemptsRemaining", <String, Object?>{'count': count});

  String get manageDevicesTitle => _message("manageDevicesTitle");

  String get manageDevicesHint => _message("manageDevicesHint");

  String get manageDevicesDescription => _message("manageDevicesDescription");

  String get currentDeviceTitle => _message("currentDeviceTitle");

  String get activeSessionsTitle => _message("activeSessionsTitle");

  String get activeSessionsEmpty => _message("activeSessionsEmpty");

  String get activeSessionsHint => _message("activeSessionsHint");

  String get trustedDevicesTitle => _message("trustedDevicesTitle");

  String get devicePrimary => _message("devicePrimary");

  String get deviceActiveNow => _message("deviceActiveNow");

  String get signOut => _message("signOut");

  String get logoutAllDevices => _message("logoutAllDevices");

  String get logoutAllSuccess => _message("logoutAllSuccess");

  String get logoutAllDevicesPrompt => _message("logoutAllDevicesPrompt");

  String get logoutAllConfirm => _message("logoutAllConfirm");

  String get logoutAllLocalOnly => _message("logoutAllLocalOnly");

  String get logoutAllFailed => _message("logoutAllFailed");

  String get privacySettingsTitle => _message("privacySettingsTitle");

  String get privacySettingsDescription => _message("privacySettingsDescription");

  String get profileVisibilityTitle => _message("profileVisibilityTitle");

  String get profileVisibilityPublic => _message("profileVisibilityPublic");

  String get profileVisibilityPrivate => _message("profileVisibilityPrivate");

  String get showEmailInProfileTitle => _message("showEmailInProfileTitle");

  String get showEmailInProfileHint => _message("showEmailInProfileHint");

  String get blockedUsersTitle => _message("blockedUsersTitle");

  String get blockedUsersEmpty => _message("blockedUsersEmpty");

  String get blockedUsersHint => _message("blockedUsersHint");

  String get blockedUsersAddTitle => _message("blockedUsersAddTitle");

  String get blockedUsersAddHint => _message("blockedUsersAddHint");

  String get blockedUsersAddAction => _message("blockedUsersAddAction");

  String blockedUsersSince(Object? date) => _format("blockedUsersSince", <String, Object?>{'date': date});

  String get unblockUser => _message("unblockUser");

  String get academicSettingsTitle => _message("academicSettingsTitle");

  String get academicSettingsDescription => _message("academicSettingsDescription");

  String get academicCollegeLabel => _message("academicCollegeLabel");

  String get academicMajorLabel => _message("academicMajorLabel");

  String get academicLevelLabel => _message("academicLevelLabel");

  String get academicSettingsSaved => _message("academicSettingsSaved");

  String get academicShortcutTitle => _message("academicShortcutTitle");

  String academicShortcutDetails(Object? specialty, Object? level) => _format("academicShortcutDetails", <String, Object?>{'specialty': specialty, 'level': level});

  String get academicShortcutGo => _message("academicShortcutGo");

  String get academicShortcutEdit => _message("academicShortcutEdit");

  String get academicShortcutDeleteTitle => _message("academicShortcutDeleteTitle");

  String get academicShortcutDeleteConfirmTitle => _message("academicShortcutDeleteConfirmTitle");

  String get academicShortcutDeleteConfirmBody => _message("academicShortcutDeleteConfirmBody");

  String get academicShortcutDeleteCancel => _message("academicShortcutDeleteCancel");

  String get academicShortcutDeleteConfirm => _message("academicShortcutDeleteConfirm");

  String get academicShortcutDeleteSuccess => _message("academicShortcutDeleteSuccess");

  String get academicShortcutEmptyTitle => _message("academicShortcutEmptyTitle");

  String get academicShortcutEmptyAction => _message("academicShortcutEmptyAction");

  String get academicShortcutNotFound => _message("academicShortcutNotFound");

  String get saveChanges => _message("saveChanges");

  String get downloadsTitle => _message("downloadsTitle");

  String get downloadsDescription => _message("downloadsDescription");

  String get downloadsEmptyTitle => _message("downloadsEmptyTitle");

  String get downloadsEmptyHint => _message("downloadsEmptyHint");

  String get downloadsClearCache => _message("downloadsClearCache");

  String get downloadsCacheCleared => _message("downloadsCacheCleared");

  String get downloadsCacheClearFailed => _message("downloadsCacheClearFailed");

  String get downloadsRefreshList => _message("downloadsRefreshList");

  String get downloadsStorageTitle => _message("downloadsStorageTitle");

  String get downloadsStorageUserLabel => _message("downloadsStorageUserLabel");

  String get downloadsStorageCacheLabel => _message("downloadsStorageCacheLabel");

  String get downloadsStorageInfo => _message("downloadsStorageInfo");

  String downloadsStorageUserLabelValue(Object? size) => _format("downloadsStorageUserLabelValue", <String, Object?>{'size': size});

  String downloadsStorageCacheLabelValue(Object? size) => _format("downloadsStorageCacheLabelValue", <String, Object?>{'size': size});

  String downloadsStorageInfoValue(Object? size) => _format("downloadsStorageInfoValue", <String, Object?>{'size': size});

  String get downloadsClearCacheDialogTitle => _message("downloadsClearCacheDialogTitle");

  String get downloadsClearCacheDialogBody => _message("downloadsClearCacheDialogBody");

  String get downloadsClearCacheDialogConfirm => _message("downloadsClearCacheDialogConfirm");

  String get downloadsExploreCta => _message("downloadsExploreCta");

  String get downloadsFilterAll => _message("downloadsFilterAll");

  String get downloadsFilterFiles => _message("downloadsFilterFiles");

  String get downloadsFilterImages => _message("downloadsFilterImages");

  String get downloadsSortLabel => _message("downloadsSortLabel");

  String get downloadsSortNewest => _message("downloadsSortNewest");

  String get downloadsSortOldest => _message("downloadsSortOldest");

  String get downloadsClearAllAction => _message("downloadsClearAllAction");

  String get downloadsClearAllDialogTitle => _message("downloadsClearAllDialogTitle");

  String get downloadsClearAllDialogBody => _message("downloadsClearAllDialogBody");

  String get downloadsClearAllDialogConfirm => _message("downloadsClearAllDialogConfirm");

  String get downloadsClearAllSuccess => _message("downloadsClearAllSuccess");

  String get downloadsClearAllFailed => _message("downloadsClearAllFailed");

  String get downloadsDeleteDialogTitle => _message("downloadsDeleteDialogTitle");

  String downloadsDeleteDialogBody(Object? fileName) => _format("downloadsDeleteDialogBody", <String, Object?>{'fileName': fileName});

  String get downloadsDeleteSuccess => _message("downloadsDeleteSuccess");

  String get downloadsDeleteFailed => _message("downloadsDeleteFailed");

  String get downloadsLoadFailed => _message("downloadsLoadFailed");

  String downloadsUpdatedAt(Object? date) => _format("downloadsUpdatedAt", <String, Object?>{'date': date});

  String get favoritesTitle => _message("favoritesTitle");

  String get favoritesDescription => _message("favoritesDescription");

  String get favoritesEmptyTitle => _message("favoritesEmptyTitle");

  String get favoritesEmptyHint => _message("favoritesEmptyHint");

  String get favoritesAddTitle => _message("favoritesAddTitle");

  String get favoritesAddHint => _message("favoritesAddHint");

  String get favoritesAddTypeHint => _message("favoritesAddTypeHint");

  String get favoritesAddAction => _message("favoritesAddAction");

  String get favoritesAdded => _message("favoritesAdded");

  String get favoritesRemoved => _message("favoritesRemoved");

  String get favoritesSignInTitle => _message("favoritesSignInTitle");

  String get favoritesSignInHint => _message("favoritesSignInHint");

  String favoritesTypeLabel(Object? type) => _format("favoritesTypeLabel", <String, Object?>{'type': type});

  String get fontSizeTitle => _message("fontSizeTitle");

  String get fontSizeDescription => _message("fontSizeDescription");

  String get fontSizeSmall => _message("fontSizeSmall");

  String get fontSizeMedium => _message("fontSizeMedium");

  String get fontSizeLarge => _message("fontSizeLarge");

  String get fontSizePreviewLabel => _message("fontSizePreviewLabel");

  String get fontSizePreviewText => _message("fontSizePreviewText");

  String get rateApp => _message("rateApp");

  String get rateAppFailed => _message("rateAppFailed");

  String get shareApp => _message("shareApp");

  String get shareAppMessage => _message("shareAppMessage");

  String get emailVerified => _message("emailVerified");

  String get emailNotVerified => _message("emailNotVerified");

  String get sendOtpNow => _message("sendOtpNow");

  String otpCooldownLabel(Object? seconds) => _format("otpCooldownLabel", <String, Object?>{'seconds': seconds});

  String get otpSentSuccess => _message("otpSentSuccess");

  String get otpSentFailed => _message("otpSentFailed");

  String get signInRequired => _message("signInRequired");

  String get guestUser => _message("guestUser");

  String get emailUnavailable => _message("emailUnavailable");

  String get emailHidden => _message("emailHidden");

  String get aboutAppSummary => _message("aboutAppSummary");

  String get aboutAppDescription => _message("aboutAppDescription");

  String get aboutAppFeatureGpa => _message("aboutAppFeatureGpa");

  String get aboutAppFeatureReviewPlan => _message("aboutAppFeatureReviewPlan");

  String get aboutAppFeatureExams => _message("aboutAppFeatureExams");

  String get aboutAppFeatureNotes => _message("aboutAppFeatureNotes");

  String get aboutAppFeatureStudents => _message("aboutAppFeatureStudents");

  String get aboutAppViewLicenses => _message("aboutAppViewLicenses");

  String get aboutAppFooter => _message("aboutAppFooter");

  String get commonCore1 => _message("commonCore1");

  String get academicclass => _message("academicclass");

  String get verificationEmailSent => _message("verificationEmailSent");

  String get emailNotVerifiedYet => _message("emailNotVerifiedYet");

  String get verifyEmailToContinue => _message("verifyEmailToContinue");

  String get verifyEmailHelper => _message("verifyEmailHelper");

  String get verifyEmailTitle => _message("verifyEmailTitle");

  String get checkNow => _message("checkNow");

  String get resendVerificationEmail => _message("resendVerificationEmail");

  String resendVerificationCooldown(Object? seconds) => _format("resendVerificationCooldown", <String, Object?>{'seconds': seconds});

  String get wrongPasswordError => _message("wrongPasswordError");

  String get emailAlreadyInUseError => _message("emailAlreadyInUseError");

  String get networkError => _message("networkError");

  String get weakPasswordError => _message("weakPasswordError");

  String get emailAuthDisabledError => _message("emailAuthDisabledError");

  String get userDisabledError => _message("userDisabledError");

  String get genericAuthError => _message("genericAuthError");

  String get activeSessionNow => _message("activeSessionNow");

  String get sessionSignedOutSuccess => _message("sessionSignedOutSuccess");

  String get sessionSignOutFailed => _message("sessionSignOutFailed");

  String get otherSessionsSignedOutSuccess => _message("otherSessionsSignedOutSuccess");

  String get logoutAllOtherDevices => _message("logoutAllOtherDevices");

  String get sessionUnknownDevice => _message("sessionUnknownDevice");

  String get privacyTabTitle => _message("privacyTabTitle");

  String get privacyTabSubtitle => _message("privacyTabSubtitle");

  String get privacyAccountOverviewSection => _message("privacyAccountOverviewSection");

  String get privacyNameRowTitle => _message("privacyNameRowTitle");

  String get privacyEmailRowTitle => _message("privacyEmailRowTitle");

  String get privacyNameRuleAllowed => _message("privacyNameRuleAllowed");

  String privacyNameRuleBlockedDays(Object? days, Object? hours) => _format("privacyNameRuleBlockedDays", <String, Object?>{'days': days, 'hours': hours});

  String privacyNameRuleBlockedHours(Object? hours) => _format("privacyNameRuleBlockedHours", <String, Object?>{'hours': hours});

  String get privacyReauthTitle => _message("privacyReauthTitle");

  String get privacyReauthSubtitle => _message("privacyReauthSubtitle");

  String get privacyContinue => _message("privacyContinue");

  String get privacyReauthFailed => _message("privacyReauthFailed");

  String get privacyEditNameTitle => _message("privacyEditNameTitle");

  String get privacyFirstName => _message("privacyFirstName");

  String get privacyLastName => _message("privacyLastName");

  String get privacyNameValidationRequired => _message("privacyNameValidationRequired");

  String get privacyNameValidationShort => _message("privacyNameValidationShort");

  String get privacyNameValidationLong => _message("privacyNameValidationLong");

  String get privacyNameSaved => _message("privacyNameSaved");

  String get privacyEmailSaved => _message("privacyEmailSaved");

  String get privacyEmailFlowTitle => _message("privacyEmailFlowTitle");

  String privacyStepOf(Object? current, Object? total) => _format("privacyStepOf", <String, Object?>{'current': current, 'total': total});

  String get privacyEmailFlowSecurityNote => _message("privacyEmailFlowSecurityNote");

  String privacyEmailFlowStep1Help(Object? masked) => _format("privacyEmailFlowStep1Help", <String, Object?>{'masked': masked});

  String get privacyEmailCurrentLabel => _message("privacyEmailCurrentLabel");

  String get privacyEmailFlowStep2Help => _message("privacyEmailFlowStep2Help");

  String get privacyEmailFlowSendLink => _message("privacyEmailFlowSendLink");

  String get privacyEmailFlowStep3Help => _message("privacyEmailFlowStep3Help");

  String get privacyEmailNewLabel => _message("privacyEmailNewLabel");

  String get privacyEmailConfirmLabel => _message("privacyEmailConfirmLabel");

  String privacyEmailFlowStep4Help(Object? masked) => _format("privacyEmailFlowStep4Help", <String, Object?>{'masked': masked});

  String get privacyEmailCurrentMismatch => _message("privacyEmailCurrentMismatch");

  String get privacyEmailValidationRequired => _message("privacyEmailValidationRequired");

  String get privacyEmailConfirmMismatch => _message("privacyEmailConfirmMismatch");

  String get privacyLoadFailed => _message("privacyLoadFailed");

  String get securityPrivacyTitle => _message("securityPrivacyTitle");

  String get securitySegmentTitle => _message("securitySegmentTitle");

  String get privacySegmentTitle => _message("privacySegmentTitle");

  String get privacyPasswordNewLengthError => _message("privacyPasswordNewLengthError");

  String get privacyPasswordMustDifferError => _message("privacyPasswordMustDifferError");

  String get privacyPasswordMismatchError => _message("privacyPasswordMismatchError");

  String get privacyPasswordStrengthWeak => _message("privacyPasswordStrengthWeak");

  String get privacyPasswordStrengthMedium => _message("privacyPasswordStrengthMedium");

  String get privacyPasswordStrengthStrong => _message("privacyPasswordStrengthStrong");

  String get privacyPasswordUpdateConfirmTitle => _message("privacyPasswordUpdateConfirmTitle");

  String get privacyPasswordUpdateConfirmBody => _message("privacyPasswordUpdateConfirmBody");

  String get privacyPasswordUpdateAction => _message("privacyPasswordUpdateAction");

  String get privacyPasswordUpdateRequiresSignin => _message("privacyPasswordUpdateRequiresSignin");

  String get privacyPasswordReauthFailedGeneric => _message("privacyPasswordReauthFailedGeneric");

  String get privacyPasswordUpdateSuccess => _message("privacyPasswordUpdateSuccess");

  String get privacyPasswordUpdateFailed => _message("privacyPasswordUpdateFailed");

  String get privacyNotAvailable => _message("privacyNotAvailable");

  String privacyResetPasswordDialogBody(Object? maskedEmail) => _format("privacyResetPasswordDialogBody", <String, Object?>{'maskedEmail': maskedEmail});

  String get privacySendResetLinkAction => _message("privacySendResetLinkAction");

  String get privacyNoEmailLinked => _message("privacyNoEmailLinked");

  String get privacyResetLinkSent => _message("privacyResetLinkSent");

  String get privacyResetLinkFailed => _message("privacyResetLinkFailed");

  String get privacyNetworkCellular => _message("privacyNetworkCellular");

  String get privacyUnknown => _message("privacyUnknown");

  String get algeriaLabel => _message("algeriaLabel");

  String get privacyNoAuditDataYet => _message("privacyNoAuditDataYet");

  String get privacyLastPasswordChangeTitle => _message("privacyLastPasswordChangeTitle");

  String get privacyDateTimeLabel => _message("privacyDateTimeLabel");

  String get privacyDeviceLabel => _message("privacyDeviceLabel");

  String get privacyManufacturerLabel => _message("privacyManufacturerLabel");

  String get privacyOperatingSystemLabel => _message("privacyOperatingSystemLabel");

  String get privacyAppVersionLabel => _message("privacyAppVersionLabel");

  String get privacyConnectionTypeLabel => _message("privacyConnectionTypeLabel");

  String get privacyApproxLocationLabel => _message("privacyApproxLocationLabel");

  String get privacyIpAddressLabel => _message("privacyIpAddressLabel");

  String get privacyCopyFullIp => _message("privacyCopyFullIp");

  String get privacyThisWasNotMe => _message("privacyThisWasNotMe");

  String get privacyIpUnavailable => _message("privacyIpUnavailable");

  String get privacyCopyIpSuccess => _message("privacyCopyIpSuccess");

  String get privacyReauthCopyIpReason => _message("privacyReauthCopyIpReason");

  String get privacySecurityAlertTitle => _message("privacySecurityAlertTitle");

  String get privacySecurityAlertBody => _message("privacySecurityAlertBody");

  String get privacyContinueAction => _message("privacyContinueAction");

  String get privacyOtherSessionsRevokedPrecaution => _message("privacyOtherSessionsRevokedPrecaution");

  String get privacyRevokeSessionsFailed => _message("privacyRevokeSessionsFailed");

  String get privacyChangePasswordNowNote => _message("privacyChangePasswordNowNote");

  String get privacyChangePasswordTitle => _message("privacyChangePasswordTitle");

  String get privacyCurrentPasswordLabel => _message("privacyCurrentPasswordLabel");

  String get privacyCurrentPasswordHelper => _message("privacyCurrentPasswordHelper");

  String get privacyResetEmailHint => _message("privacyResetEmailHint");

  String get privacyNewPasswordLabel => _message("privacyNewPasswordLabel");

  String get privacyNewPasswordHelper => _message("privacyNewPasswordHelper");

  String get privacyPasswordStrengthLabel => _message("privacyPasswordStrengthLabel");

  String get privacyConfirmNewPasswordLabel => _message("privacyConfirmNewPasswordLabel");

  String get privacyConfirmNewPasswordHelper => _message("privacyConfirmNewPasswordHelper");

  String get privacyEnterConfirmToMatch => _message("privacyEnterConfirmToMatch");

  String get privacyPasswordsMatch => _message("privacyPasswordsMatch");

  String get privacyLoadingLastChange => _message("privacyLoadingLastChange");

  String get privacyLastPasswordChangeUnavailable => _message("privacyLastPasswordChangeUnavailable");

  String privacyLastPasswordChangeAt(Object? date) => _format("privacyLastPasswordChangeAt", <String, Object?>{'date': date});

  String get privacyViewDetails => _message("privacyViewDetails");

  String get privacySaveNewPassword => _message("privacySaveNewPassword");

  String sessionAgoMinutes(Object? minutes) => _format("sessionAgoMinutes", <String, Object?>{'minutes': minutes});

  String sessionAgoHours(Object? hours) => _format("sessionAgoHours", <String, Object?>{'hours': hours});

  String sessionAgoDays(Object? days) => _format("sessionAgoDays", <String, Object?>{'days': days});

  String get sessionDeviceNameLabel => _message("sessionDeviceNameLabel");

  String get sessionTrustedDevice => _message("sessionTrustedDevice");

  String get sessionModelLabel => _message("sessionModelLabel");

  String get sessionPlatformLabel => _message("sessionPlatformLabel");

  String get sessionVersionLabel => _message("sessionVersionLabel");

  String get sessionLoginDateLabel => _message("sessionLoginDateLabel");

  String get sessionLastActivityLabel => _message("sessionLastActivityLabel");

  String get sessionNetworkLabel => _message("sessionNetworkLabel");

  String get dangerZone => _message("dangerZone");

  String get gpu => _message("gpu");

  static const Map<String, Map<String, String>> _localizedValues = <String, Map<String, String>>{
    "ar":   <String, String>{
    "sections": "الأقسام",
    "majors": "تخصصات",
    "comments": "التعليقات",
    "comment": "تعليق",
    "writeYourComment": "اكتب تعليقك",
    "publish": "نشر",
    "cancel": "إلغاء",
    "delete": "حذف",
    "posted": "نشر",
    "searchClipboard": "ابحث داخل الحافظة…",
    "note": "ملاحظة",
    "title": "العنوان",
    "content": "المحتوى",
    "save": "حفظ",
    "pinNote": "تثبيت الملاحظة",
    "noNotesYet": "لا توجد ملاحظات بعد",
    "archive": "الأرشيف",
    "home": "الرئيسية",
    "community": "المجتمع",
    "viewAll": "عرض الكل",
    "faculties": "الكليات",
    "clipboard": "الحافظة",
    "changeTheme": "تغيير المظهر",
    "changeLanguage": "تغيير اللغة",
    "resetPassword": "إعادة تعيين كلمة المرور",
    "logout": "تسجيل الخروج",
    "login": "تسجيل الدخول",
    "aboutApp": "حول التطبيق",
    "privacyPolicy": "سياسة الخصوصية",
    "privacyPolicyTitle": "سياسة الخصوصية – UniSpace",
    "privacyPolicyBody": "نحن في UniSpace نولي أهمية كبيرة لخصوصية المستخدمين، ونلتزم بحماية بياناتهم واحترام خصوصيتهم. توضح هذه السياسة كيفية التعامل مع المعلومات عند استخدام التطبيق.\n\n1) البيانات التي نقوم بجمعها\nقد نقوم بجمع الحد الأدنى من البيانات الضرورية فقط لتشغيل التطبيق بشكل صحيح، وتشمل:\n- البريد الإلكتروني: يُستخدم لإنشاء الحساب وتسجيل الدخول والتحقق من هوية المستخدم.\n- اسم المستخدم أو الاسم الشخصي: الذي يختاره المستخدم داخل التطبيق.\nلا نقوم بجمع أي بيانات إضافية دون علم المستخدم أو موافقته.\n\n2) البيانات المحلية داخل الجهاز\nقد يتيح التطبيق للمستخدم إدخال بيانات دراسية مثل:\n- المعدلات\n- الملاحظات\n- معلومات تنظيم الدراسة أو الامتحانات\nمهم جدًا:\n- هذه البيانات يتم حفظها محليًا على جهاز المستخدم فقط.\n- لا يتم إرسالها إلى خوادمنا.\n- لا نقوم بالوصول إليها أو جمعها أو مشاركتها.\n- تبقى تحت تحكم المستخدم الكامل.\n\n3) استخدام البيانات\nنستخدم البيانات التي يتم جمعها فقط من أجل:\n- تمكين المستخدم من إنشاء حساب وتسجيل الدخول.\n- تحسين تجربة استخدام التطبيق.\n- ضمان أمان الحساب ومنع الاستخدام غير المصرح به.\n\n4) مشاركة البيانات\n- لا نقوم ببيع أو تأجير أو مشاركة بيانات المستخدمين مع أي طرف ثالث.\n- لا يتم مشاركة أي معلومات شخصية إلا إذا كان ذلك مطلوبًا قانونيًا.\n\n5) خدمات الطرف الثالث\nيستخدم التطبيق خدمات موثوقة مثل Firebase من Google لأغراض المصادقة وتأمين الحسابات.\nتخضع هذه الخدمات لسياسات الخصوصية الخاصة بها، ونلتزم باستخدامها وفق أفضل ممارسات الأمان.\n\n6) أمان البيانات\nنطبق إجراءات أمان مناسبة لحماية بيانات المستخدم من الوصول غير المصرح به أو التعديل أو الفقدان.\n\n7) خصوصية الأطفال\nتطبيق UniSpace موجه للطلبة الجامعيين ولا يستهدف الأطفال دون سن 13 عامًا، ولا نقوم بجمع أي بيانات عنهم عن قصد.\n\n8) التعديلات على سياسة الخصوصية\nقد نقوم بتحديث سياسة الخصوصية من وقت لآخر.\nسيتم إعلام المستخدم بأي تغييرات جوهرية داخل التطبيق.\n\n9) التواصل معنا\nإذا كان لديك أي استفسار بخصوص سياسة الخصوصية، يمكنك التواصل معنا من خلال قسم \"تواصل معنا\" داخل التطبيق.\n\nباستخدامك لتطبيق UniSpace، فإنك توافق على سياسة الخصوصية هذه.",
    "welcomeEmoji": "مرحباً بك 👋",
    "homeSubtitle": "تصفح الكليات، احسب معدلك، شارك أفكارك، ودوّن ملاحظاتك بسهولة.",
    "searchFaculty": "ابحث عن كلية...",
    "searchStartTyping": "ابدأ بالكتابة للبحث",
    "searchNoResults": "لا توجد نتائج",
    "quickCalc": "الحساب السريع",
    "welcomeUniSpace": "مرحبًا بك في UniSpace",
    "email": "البريد الإلكتروني",
    "password": "كلمة المرور",
    "forgotPassword": "هل نسيت كلمة السر؟",
    "resetPasswordTitle": "إعادة تعيين كلمة السر",
    "resetPasswordHelper": "أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة التعيين.",
    "sendResetLink": "إرسال الرابط",
    "sendResetLinkLoading": "جارٍ الإرسال...",
    "invalidEmailValidation": "يرجى إدخال بريد إلكتروني صالح.",
    "resetLinkSentSuccess": "تم إرسال رابط إعادة التعيين إلى بريدك.",
    "invalidEmailError": "البريد الإلكتروني غير صالح",
    "userNotFoundError": "لا يوجد حساب بهذا البريد",
    "tooManyRequestsError": "طلبات كثيرة، حاول لاحقًا",
    "resetLinkFailed": "تعذر إرسال الرابط، أعد المحاولة",
    "resetSent": "تم إرسال رابط إعادة التعيين",
    "resetFailed": "تعذر الإرسال: {e}",
    "notRegistered": "غير مسجّل",
    "pinned": "مثبّتة",
    "otherNotes": "باقي الملاحظات",
    "noPostsYet": "لا توجد منشورات بعد",
    "startDiscussion": "ابدأ النقاش الأول في المجتمع وشارك تجربتك مع زملائك.",
    "createPost": "نشر",
    "newPost": "منشور جديد",
    "mediaUrl": "رابط صورة/فيديو",
    "hashtag": "#",
    "share": "مشاركة",
    "report": "إبلاغ",
    "commentsCount": "Comments ({count})",
    "writeComment": "اكتب تعليقك…",
    "quickCalc2": "حساب سريع",
    "add": "إضافة",
    "calculate": "احسب",
    "pass": " ناجح",
    "fail": " راسب",
    "credits": "رصيد:",
    "lightMode": "الوضع الفاتح",
    "darkMode": "الوضع الداكن",
    "systemMode": "حسب النظام",
    "aboutAppDetails": "UniSpace لا يجمع بيانات شخصية خارج Firebase. جميع البيانات آمنة.",
    "chooseTheme": "اختر المظهر",
    "light": "فاتح",
    "dark": "داكن",
    "system": "حسب النظام",
    "chooseLanguage": "اختر اللغة",
    "arabic": "العربية",
    "register": "تسجيل",
    "post": "تم نشر منشورك ✅",
    "createPoste": "أنشئ منشوراً",
    "oneMajor": "تخصص واحد",
    "noMajorsYet": "لا تخصصات مسجّلة بعد",
    "editWeights": "تعديل الأوزان",
    "facultyEconomics": "كلية العلوم الاقتصادية والتجارية وعلوم التسيير",
    "basicEducationDept": "قسم التعليم الأساسي",
    "basicEducation": "التعليم الأساسي",
    "managementSciencesDept": "قسم علوم التسيير",
    "managementSciences": "علوم التسيير",
    "businessAdministration": "إدارة أعمال",
    "financialManagement": "الإدارة المالية",
    "humanResourcesManagement": "إدارة موارد بشرية",
    "corporateFinancialManagement": "التسيير المالي للمؤسسات",
    "commercialSciencesDept": "قسم علوم تجارية",
    "commercialSciences": "علوم تجارية",
    "financeInternationalTrade": "مالية وتجارة دولية",
    "marketing": "تسويق",
    "servicesMarketing": "تسويق الخدمات",
    "hotelTourismMarketing": "تسويق فندقي وسياحي",
    "financialAccountingDept": "قسم علوم مالية ومحاسبة",
    "financialAccounting": "علوم مالية ومحاسبة",
    "finance": "مالية",
    "accounting": "محاسبة",
    "accountingTaxation": "محاسبة وجباية",
    "corporateFinance": "مالية المؤسسة",
    "economicsDept": "قسم علوم اقتصادية",
    "economics": "علوم اقتصادية",
    "monetaryFinancialEconomics": "اقتصاد نقدي ومالي",
    "internationalEconomics": "اقتصاد دولي",
    "noSubjectsThisSemester": "لا توجد مواد في هذا الفصل.",
    "coefficient": "معامل:",
    "close": "إغلاق",
    "studyResults": "نتائج الدراسة",
    "notesTdTpExam": "العلامات (TD/TP/EXAM)",
    "facultyLawPolitical": "كلية الحقوق والعلوم السياسية",
    "politicalSciences": "علوم سياسية",
    "commonCore": "جذع مشترك",
    "basicUnit": "الوحدة الأساسية",
    "methodologicalUnit": "الوحدة المنهجية",
    "exploratoryUnit": "الوحدة الاستكشافية",
    "horizontalUnit": "الوحدة الأفقية",
    "politicalAdministrativeOrgs": "تنظيمات سياسية وإدارية",
    "law": "حقوق",
    "publicLaw": "قانون عام",
    "privateLaw": "قانون خاص",
    "advancedPublicLaw": "قانون عام معمق",
    "familyLaw": "قانون الأسرة",
    "criminalLaw": "القانون الجنائي والعلوم الجنائية",
    "businessLaw": "قانون الأعمال",
    "legalProfessionsLaw": "قانون المهن القانونية والقضائية",
    "maritimePortLaw": "القانون البحري والمينائي",
    "energyMiningLaw": "قانون الطاقة والمناجم",
    "taxLaw": "قانون جبائي",
    "internationalRelations": "علاقات دولية",
    "internationalCooperation": "التعاون الدولي",
    "localAdministration": "الإدارة المحلية",
    "contactUs": "تواصل معنا",
    "blockAccount": "حظر الحساب",
    "followComment": "متابعة التعليق",
    "copyText": "نسخ النص",
    "hide": "إخفاء",
    "savePost": "حفظ المنشور",
    "university": "الجامعة",
    "faculty": "الكلية",
    "department": "القسم",
    "major": "التخصص",
    "mood": "Mood",
    "name": "الاسم",
    "posts": "المنشورات",
    "profile": "الملف الشخصي",
    "following": "يتابع",
    "userInfo": "معلومات المستخدم",
    "facultyArtsLanguages": "كلية الآداب واللغات الأجنبية",
    "deptArabicLangLit": "قسم اللغة والأدب العربي",
    "deptFrenchLangLit": "قسم اللغة والأدب الفرنسي",
    "deptEnglishLangLit": "قسم اللغة والأدب الإنجليزي",
    "contactUsSubtitle": "يسعدنا سماع رسالتك. أرسل رسالتك إلى الدعم.",
    "contactCategoryLabel": "الفئة",
    "contactCategoryIssue": "مشكلة",
    "contactCategoryFeature": "اقتراح ميزة جديدة",
    "contactCategoryImprovement": "تحسين",
    "contactCategoryReport": "بلاغ",
    "contactCategoryOther": "أخرى",
    "contactSubjectLabel": "الموضوع",
    "contactSubjectHint": "ملخص قصير لطلبك",
    "contactDescriptionLabel": "الوصف",
    "contactDescriptionHint": "اشرح التفاصيل لنساعدك بسرعة",
    "contactScreenshotPlaceholder": "إرفاق لقطة شاشة",
    "contactScreenshotSoon": "قريبًا",
    "contactIncludeUserInfo": "تضمين معلومات الحساب",
    "contactUserInfoUnavailable": "لا توجد معلومات مستخدم مسجّل الدخول",
    "contactSend": "إرسال",
    "contactValidationRequired": "هذا الحقل مطلوب",
    "contactValidationMinLength": "يرجى إدخال {min} أحرف على الأقل",
    "contactValidationMaxLength": "يرجى عدم تجاوز {max} حرفًا",
    "contactSending": "جارٍ الإرسال...",
    "contactSendSuccess": "تم الإرسال ✅",
    "contactSendFailure": "تعذر إرسال رسالتك. يرجى المحاولة مرة أخرى.",
    "contactMailOpened": "تم فتح البريد لإرسال رسالتك",
    "contactMailUnavailable": "تعذر فتح تطبيق البريد. يمكنك نسخ الرسالة.",
    "contactCopyDialogTitle": "نسخ الرسالة",
    "contactCopyDialogBody": "انسخ الرسالتك وأرسلها إلى الدعم عبر البريد.",
    "contactCopyAction": "نسخ",
    "contactCopied": "تم نسخ الرسالة",
    "contactMetadataHeader": "بيانات إضافية",
    "contactMetadataUserId": "معرّف المستخدم",
    "contactMetadataEmail": "البريد الإلكتروني",
    "contactMetadataName": "الاسم",
    "contactMetadataPlatform": "المنصة",
    "contactMetadataLocale": "اللغة",
    "contactMetadataTimestamp": "الوقت",
    "contactMetadataAppVersion": "إصدار التطبيق",
    "examCalendar": "رزنامة الامتحانات",
    "smartReviewPlanTitle": "مخطط المراجعة الذكي",
    "smartReviewPlanDescription": "أنشئ خطة مراجعة مركزة بناءً على الامتحانات القادمة وأهدافك الدراسية.",
    "smartReviewPlanCtaCreate": "إنشاء خطة مراجعة",
    "smartReviewPlanComingSoon": "قريباً",
    "smartReviewTitle": "مخطط المراجعة الذكي",
    "smartReviewSubtitle": "حوّل الامتحانات القادمة إلى خطة يومية متوازنة وسهلة.",
    "smartReviewCtaCreate": "إنشاء خطة مراجعة",
    "smartReviewChipExams": "مرتكز على الامتحانات",
    "smartReviewChipTime": "إدارة وقت ذكية",
    "smartReviewChipReminders": "تذكيرات",
    "smartReviewChipSimple": "سهل التطبيق",
    "smartReviewPreviewTitle": "معاينة الأسبوع",
    "smartReviewPreviewItem1": "اليوم · جلستان تركيز (٤٥ دقيقة)",
    "smartReviewPreviewItem2": "غداً · اختبار تجريبي + مراجعة",
    "smartReviewPreviewItem3": "هذا الأسبوع · ركّز على المواد الأصعب",
    "smartReviewBottomSheetTitle": "قبل إنشاء خطتك",
    "smartReviewBottomSheetBody": "أضف المواد ومواعيد الامتحانات لنخصص جدولك.",
    "smartReviewActionAddSubjects": "إضافة مواد",
    "smartReviewActionAddExam": "إضافة امتحان",
    "smartReviewActionLater": "لاحقاً",
    "smartReviewTipsTitle": "كيف يعمل",
    "smartReviewTipsBody": "نحلّل الامتحانات والوقت المتبقي والصعوبة لبناء جلسات يومية واقعية.",
    "smartReviewEmptyNoExamsTitle": "لا توجد امتحانات قادمة",
    "smartReviewEmptyNoExamsBody": "أضف امتحاناً واحداً على الأقل لننشئ خطة مراجعة مركزة.",
    "smartReviewEmptyNoPlanTitle": "جاهز لإنشاء خطتك",
    "smartReviewEmptyNoPlanBody": "سنولّد جدولاً لمدة 7 أيام بناءً على أقرب امتحان ووقت الدراسة.",
    "smartReviewPlanSectionTitle": "خطتك",
    "smartReviewPlanRange": "{start} → {end}",
    "smartReviewPlanCleared": "تم حذف الخطة",
    "smartReviewActionClearPlan": "مسح الخطة",
    "smartReviewTaskDuration": "{minutes} دقيقة",
    "smartReviewTaskFocusTitle": "جلسة تركيز: {subject}",
    "smartReviewTaskPracticeTitle": "اختبار تدريبي: {subject}",
    "smartReviewTaskSummaryTitle": "مراجعة ملخصة: {subject}",
    "smartReviewTaskMockTitle": "اختبار تجريبي: {subject}",
    "soon": "قريباً",
    "addExam": "إضافة امتحان",
    "editExam": "تعديل الامتحان",
    "deleteExam": "حذف الامتحان",
    "confirmDeleteExam": "هل تريد حذف هذا الامتحان؟",
    "examSubject": "المادة",
    "examSubjectRequired": "يرجى إدخال المادة",
    "examRoom": "القاعة",
    "examNote": "ملاحظة",
    "reminders": "التذكيرات",
    "reminder24h": "قبل 24 ساعة",
    "reminder2h": "قبل ساعتين",
    "reminder30m": "قبل 30 دقيقة",
    "saveExam": "حفظ الامتحان",
    "noExamsDay": "لا توجد امتحانات لهذا اليوم",
    "examReminder24h": "تذكير: {subject} بعد 24 ساعة",
    "examReminder2h": "تذكير: {subject} بعد ساعتين",
    "examReminder30m": "تذكير: {subject} بعد 30 دقيقة",
    "drawerSectionAccount": "الحساب",
    "drawerSectionStudent": "الطالب",
    "drawerSectionContent": "المحتوى",
    "drawerSectionApp": "التطبيق",
    "editProfile": "تعديل الملف الشخصي",
    "notificationsSettingsTitle": "الإشعارات",
    "notificationsSettingsDescription": "تحكم في الإشعارات والتنبيهات.",
    "notificationsEnabled": "تفعيل الإشعارات",
    "notificationsEnabledHint": "استلم تنبيهات للتحديثات والتذكيرات.",
    "notificationsExamReminders": "تذكيرات الامتحانات",
    "notificationsExamRemindersHint": "تنبيهات محلية للامتحانات المجدولة.",
    "notificationsAnnouncements": "الإعلانات",
    "notificationsAnnouncementsHint": "ابقَ على اطلاع بأخبار الحرم الجامعي.",
    "notificationsCommunity": "تحديثات المجتمع",
    "notificationsCommunityHint": "تنبيهات نشاط المجتمع.",
    "notificationsDisabledHint": "فعّل الإشعارات لإدارة التذكيرات والتنبيهات.",
    "securityCenterTitle": "الأمان",
    "twoFactorAuthTitle": "المصادقة الثنائية",
    "twoFactorAuthHint": "يتطلب رمز تحقق عند تسجيل الدخول.",
    "twoFactorEnabledToast": "تم تفعيل المصادقة الثنائية.",
    "twoFactorDisabledToast": "تم إيقاف المصادقة الثنائية.",
    "twoFactorEnableConfirmTitle": "تفعيل المصادقة الثنائية؟",
    "twoFactorEnableConfirmBody": "سيُطلب منك إدخال رمز لمرة واحدة يتم إرساله إلى بريدك بعد تسجيل الدخول بكلمة المرور.",
    "twoFactorOtpTitle": "رمز التحقق عبر البريد",
    "twoFactorOtpDescription": "أدخل الرمز المكوّن من 6 أرقام المرسل إلى {email}.",
    "twoFactorCodeLabel": "رمز التحقق",
    "twoFactorCodeHint": "رمز من 6 أرقام",
    "twoFactorConfirmButton": "تأكيد",
    "twoFactorResendCode": "إعادة إرسال الرمز",
    "twoFactorResendIn": "إعادة الإرسال خلال {seconds}ث",
    "twoFactorBackToLogin": "العودة لتسجيل الدخول",
    "twoFactorCodeSent": "تم إرسال رمز التحقق إلى بريدك.",
    "twoFactorCodeExpired": "انتهت صلاحية الرمز. اطلب رمزًا جديدًا.",
    "twoFactorCodeIncorrect": "الرمز غير صحيح. حاول مرة أخرى.",
    "twoFactorTooManyAttempts": "محاولات فاشلة كثيرة. حاول لاحقًا.",
    "twoFactorResendCooldown": "يرجى الانتظار قبل إعادة الإرسال.",
    "twoFactorVerifiedSuccess": "اكتملت المصادقة الثنائية بنجاح.",
    "twoFactorCodeInvalidFormat": "أدخل رمزًا صالحًا من 6 أرقام.",
    "twoFactorChallengeMissing": "تعذر العثور على جلسة التحقق. سجّل الدخول مجددًا.",
    "twoFactorSendFailed": "فشل إرسال رمز التحقق.",
    "twoFactorGenericError": "تعذر إتمام التحقق. حاول مرة أخرى.",
    "twoFactorAttemptsRemaining": "المحاولات المتبقية: {count}",
    "manageDevicesTitle": "إدارة الأجهزة",
    "manageDevicesHint": "راجع الجلسات والأجهزة النشطة.",
    "manageDevicesDescription": "اطلع على أماكن تسجيل الدخول وأزل الوصول عند الحاجة.",
    "currentDeviceTitle": "الجهاز الحالي",
    "activeSessionsTitle": "الجلسات النشطة",
    "activeSessionsEmpty": "لا توجد جلسات أخرى نشطة",
    "activeSessionsHint": "إدارة الجلسات تتطلب خدمة خلفية آمنة.",
    "trustedDevicesTitle": "الأجهزة الموثوقة",
    "devicePrimary": "الجهاز الأساسي",
    "deviceActiveNow": "نشط الآن",
    "signOut": "تسجيل الخروج",
    "logoutAllDevices": "تسجيل الخروج من جميع الأجهزة",
    "logoutAllSuccess": "تم تسجيل الخروج من جميع الأجهزة.",
    "logoutAllDevicesPrompt": "سنقوم بتسجيل خروج هذا الجهاز. لإلغاء جلسات الأجهزة الأخرى فعّل الخدمة الخلفية.",
    "logoutAllConfirm": "تسجيل الخروج",
    "logoutAllLocalOnly": "تم تسجيل الخروج هنا. فعّل الخدمة الخلفية لإلغاء جلسات الأجهزة الأخرى.",
    "logoutAllFailed": "تعذر تسجيل الخروج من جميع الأجهزة.",
    "privacySettingsTitle": "الخصوصية",
    "privacySettingsDescription": "تحكم في ما يراه الآخرون في ملفك.",
    "profileVisibilityTitle": "ظهور الملف الشخصي",
    "profileVisibilityPublic": "عام",
    "profileVisibilityPrivate": "خاص",
    "showEmailInProfileTitle": "إظهار البريد في الملف",
    "showEmailInProfileHint": "السماح للآخرين برؤية بريدك.",
    "blockedUsersTitle": "المستخدمون المحظورون",
    "blockedUsersEmpty": "لا يوجد مستخدمون محظورون",
    "blockedUsersHint": "ستظهر هنا الحسابات المحظورة.",
    "blockedUsersAddTitle": "حظر مستخدم",
    "blockedUsersAddHint": "أدخل معرّف المستخدم أو البريد",
    "blockedUsersAddAction": "حظر",
    "blockedUsersSince": "تم الحظر في {date}",
    "unblockUser": "إلغاء الحظر",
    "academicSettingsTitle": "الإعدادات الأكاديمية",
    "academicSettingsDescription": "حدّث الكلية والتخصص والمستوى.",
    "academicCollegeLabel": "الكلية",
    "academicMajorLabel": "التخصص",
    "academicLevelLabel": "المستوى",
    "academicSettingsSaved": "تم حفظ الإعدادات الأكاديمية.",
    "academicShortcutTitle": "اختصارك الأكاديمي",
    "academicShortcutDetails": "التخصص: {specialty} | المستوى: {level}",
    "academicShortcutGo": "انتقال",
    "academicShortcutEdit": "تعديل",
    "academicShortcutDeleteTitle": "حذف الاختصار",
    "academicShortcutDeleteConfirmTitle": "تأكيد الحذف",
    "academicShortcutDeleteConfirmBody": "هل تريد حذف الاختصار الأكاديمي؟ يمكنك إضافته مرة أخرى لاحقًا.",
    "academicShortcutDeleteCancel": "إلغاء",
    "academicShortcutDeleteConfirm": "حذف",
    "academicShortcutDeleteSuccess": "تم حذف الاختصار بنجاح.",
    "academicShortcutEmptyTitle": "لم يتم إعداد اختصار أكاديمي بعد.",
    "academicShortcutEmptyAction": "إضافة اختصار",
    "academicShortcutNotFound": "لم نعثر على هذا التخصص. يرجى تحديث الإعدادات الأكاديمية.",
    "saveChanges": "حفظ التغييرات",
    "downloadsTitle": "التنزيلات",
    "downloadsDescription": "اعرض الملفات التي تم تنزيلها ونظّف التخزين المؤقت.",
    "downloadsEmptyTitle": "لا توجد تنزيلات بعد",
    "downloadsEmptyHint": "ستظهر العناصر المحمّلة هنا.",
    "downloadsClearCache": "مسح التخزين المؤقت",
    "downloadsCacheCleared": "تم مسح التخزين المؤقت.",
    "downloadsCacheClearFailed": "تعذر مسح التخزين المؤقت.",
    "downloadsRefreshList": "تحديث القائمة",
    "downloadsStorageTitle": "مساحة التنزيلات",
    "downloadsStorageUserLabel": "المستخدم: 0 MB",
    "downloadsStorageCacheLabel": "التخزين المؤقت: 0 MB",
    "downloadsStorageInfo": "سيتم احتساب الأحجام تلقائياً لاحقاً.",
    "downloadsStorageUserLabelValue": "المستخدم: {size}",
    "downloadsStorageCacheLabelValue": "التخزين المؤقت: {size}",
    "downloadsStorageInfoValue": "الإجمالي المستخدم: {size}",
    "downloadsClearCacheDialogTitle": "هل تريد مسح التخزين المؤقت؟",
    "downloadsClearCacheDialogBody": "سيؤدي ذلك إلى إزالة الملفات المخزنة مؤقتاً من هذا الجهاز. يمكنك تنزيلها لاحقاً.",
    "downloadsClearCacheDialogConfirm": "مسح التخزين المؤقت",
    "downloadsExploreCta": "استكشف المحتوى",
    "downloadsFilterAll": "الكل",
    "downloadsFilterFiles": "ملفات",
    "downloadsFilterImages": "صور",
    "downloadsSortLabel": "الترتيب حسب",
    "downloadsSortNewest": "الأحدث",
    "downloadsSortOldest": "الأقدم",
    "downloadsClearAllAction": "مسح جميع التنزيلات",
    "downloadsClearAllDialogTitle": "مسح جميع التنزيلات؟",
    "downloadsClearAllDialogBody": "سيؤدي ذلك إلى إزالة جميع الملفات التي تم تنزيلها من هذا الجهاز.",
    "downloadsClearAllDialogConfirm": "مسح الكل",
    "downloadsClearAllSuccess": "تم مسح جميع التنزيلات.",
    "downloadsClearAllFailed": "تعذر مسح جميع التنزيلات.",
    "downloadsDeleteDialogTitle": "حذف التنزيل؟",
    "downloadsDeleteDialogBody": "هل تريد حذف {fileName} من هذا الجهاز؟",
    "downloadsDeleteSuccess": "تم حذف التنزيل.",
    "downloadsDeleteFailed": "تعذر حذف التنزيل.",
    "downloadsLoadFailed": "تعذر تحميل التنزيلات.",
    "downloadsUpdatedAt": "آخر تحديث {date}",
    "favoritesTitle": "المفضلة",
    "favoritesDescription": "ستظهر عناصر الحفظ هنا.",
    "favoritesEmptyTitle": "لا توجد مفضلات بعد",
    "favoritesEmptyHint": "احفظ المنشورات أو الملفات لتظهر هنا.",
    "favoritesAddTitle": "إضافة مفضلة",
    "favoritesAddHint": "أدخل معرّف العنصر",
    "favoritesAddTypeHint": "النوع (اختياري)",
    "favoritesAddAction": "حفظ",
    "favoritesAdded": "تم حفظ المفضلة.",
    "favoritesRemoved": "تم حذف المفضلة.",
    "favoritesSignInTitle": "سجّل الدخول لحفظ المفضلات",
    "favoritesSignInHint": "تُزامن المفضلات مع حسابك عند تسجيل الدخول.",
    "favoritesTypeLabel": "النوع: {type}",
    "fontSizeTitle": "حجم الخط",
    "fontSizeDescription": "اختر الحجم المناسب للقراءة.",
    "fontSizeSmall": "صغير",
    "fontSizeMedium": "متوسط",
    "fontSizeLarge": "كبير",
    "fontSizePreviewLabel": "معاينة",
    "fontSizePreviewText": "النص التجريبي السريع للقفز فوق الكسل.",
    "rateApp": "قيّم التطبيق",
    "rateAppFailed": "تعذر فتح المتجر الآن.",
    "shareApp": "شارك التطبيق",
    "shareAppMessage": "جرّب UniSpace لأدوات الدراسة الذكية ومجتمع الطلبة!",
    "emailVerified": "البريد موثّق",
    "emailNotVerified": "البريد غير موثّق",
    "sendOtpNow": "أرسل الرمز الآن",
    "otpCooldownLabel": "إرسال الرمز خلال {seconds}ث",
    "otpSentSuccess": "تم إرسال الرمز. تحقق من بريدك.",
    "otpSentFailed": "تعذر إرسال الرمز الآن.",
    "signInRequired": "يرجى تسجيل الدخول للمتابعة.",
    "guestUser": "زائر",
    "emailUnavailable": "البريد غير متاح",
    "emailHidden": "البريد مخفي",
    "aboutAppSummary": "منصة لحساب المعدل الجامعي والتواصل مع الطلبة وتدوين الملاحظات.",
    "aboutAppDescription": "منصة جامعية ذكية تهدف إلى مساعدة الطلبة على تنظيم دراستهم، حساب المعدلات، تتبع الامتحانات، والتخطيط للمراجعة بطريقة سهلة وفعالة.",
    "aboutAppFeatureGpa": "حساب المعدل الجامعي بدقة",
    "aboutAppFeatureReviewPlan": "مخطط المراجعة الذكي",
    "aboutAppFeatureExams": "رزنامة الامتحانات",
    "aboutAppFeatureNotes": "تدوين الملاحظات الدراسية",
    "aboutAppFeatureStudents": "موجّه خصيصًا للطلبة الجامعيين",
    "aboutAppViewLicenses": "الاطلاع على التراخيص",
    "aboutAppFooter": "تم التطوير باستخدام Flutter",
    "commonCore1": "جذع مشترك",
    "academicclass": "القسم",
    "verificationEmailSent": "تم إرسال رسالة التحقق.",
    "emailNotVerifiedYet": "لم يتم تأكيد البريد الإلكتروني بعد. يرجى فتح البريد الإلكتروني والضغط على رابط التحقق، ثم العودة إلى التطبيق والمحاولة مجددًا.",
    "verifyEmailToContinue": "يرجى تأكيد بريدك الإلكتروني للمتابعة.",
    "verifyEmailHelper": "افتح رسالة التحقق في بريدك واضغط على الرابط، ثم ارجع للتطبيق واضغط تحقق الآن.",
    "verifyEmailTitle": "تأكيد البريد الإلكتروني",
    "checkNow": "تحقق الآن",
    "resendVerificationEmail": "إعادة إرسال رسالة التحقق",
    "resendVerificationCooldown": "إعادة الإرسال بعد {seconds}ث",
    "wrongPasswordError": "كلمة المرور غير صحيحة.",
    "emailAlreadyInUseError": "البريد الإلكتروني مستخدم بالفعل.",
    "networkError": "مشكلة في الشبكة. حاول مرة أخرى.",
    "weakPasswordError": "كلمة المرور ضعيفة.",
    "emailAuthDisabledError": "تم تعطيل تسجيل الدخول بالبريد الإلكتروني.",
    "userDisabledError": "هذا الحساب معطل.",
    "genericAuthError": "حدث خطأ غير متوقع. حاول مرة أخرى.",
    "activeSessionNow": "الآن",
    "sessionSignedOutSuccess": "تم تسجيل خروج الجلسة بنجاح.",
    "sessionSignOutFailed": "تعذر تسجيل خروج هذه الجلسة.",
    "otherSessionsSignedOutSuccess": "تم تسجيل الخروج من الأجهزة الأخرى.",
    "logoutAllOtherDevices": "تسجيل خروج الأجهزة الأخرى",
    "sessionUnknownDevice": "جهاز غير معروف",
    "privacyTabTitle": "الخصوصية",
    "privacyTabSubtitle": "تحكم في بيانات حسابك بأمان",
    "privacyAccountOverviewSection": "نظرة عامة على الحساب",
    "privacyNameRowTitle": "الاسم واللقب",
    "privacyEmailRowTitle": "البريد الإلكتروني",
    "privacyNameRuleAllowed": "يمكنك تغيير الاسم مرة واحدة شهريًا.",
    "privacyNameRuleBlockedDays": "يمكنك تغيير الاسم بعد: {days} يوم / {hours} ساعة",
    "privacyNameRuleBlockedHours": "يمكنك تغيير الاسم بعد: {hours} ساعة",
    "privacyReauthTitle": "تأكيد كلمة السر",
    "privacyReauthSubtitle": "لحماية حسابك، يرجى إدخال كلمة المرور الحالية قبل المتابعة.",
    "privacyContinue": "متابعة",
    "privacyReauthFailed": "تعذر التحقق من كلمة المرور. حاول مجددًا.",
    "privacyEditNameTitle": "تعديل الاسم",
    "privacyFirstName": "الاسم",
    "privacyLastName": "اللقب",
    "privacyNameValidationRequired": "هذا الحقل مطلوب",
    "privacyNameValidationShort": "يجب أن يكون الاسم حرفين على الأقل",
    "privacyNameValidationLong": "الحد الأقصى 40 حرفًا",
    "privacyNameSaved": "تم تحديث الاسم بنجاح.",
    "privacyEmailSaved": "تم تحديث البريد الإلكتروني محليًا.",
    "privacyEmailFlowTitle": "تغيير البريد الإلكتروني",
    "privacyStepOf": "الخطوة {current} من {total}",
    "privacyEmailFlowSecurityNote": "ملاحظة أمنية: لا تتم مشاركة كلمة المرور أو حفظها داخل التطبيق.",
    "privacyEmailFlowStep1Help": "أدخل بريدك الحالي للتأكيد. التلميح: {masked}",
    "privacyEmailCurrentLabel": "البريد الإلكتروني الحالي",
    "privacyEmailFlowStep2Help": "سنرسل رابط تغيير البريد إلى بريدك الحالي للتحقق.",
    "privacyEmailFlowSendLink": "إرسال رابط تغيير البريد",
    "privacyEmailFlowStep3Help": "أدخل البريد الإلكتروني الجديد ثم قم بتأكيده.",
    "privacyEmailNewLabel": "البريد الإلكتروني الجديد",
    "privacyEmailConfirmLabel": "تأكيد البريد الإلكتروني الجديد",
    "privacyEmailFlowStep4Help": "راجع البريد الجديد: {masked}",
    "privacyEmailCurrentMismatch": "البريد الحالي غير مطابق.",
    "privacyEmailValidationRequired": "يرجى إدخال البريد الجديد وتأكيده.",
    "privacyEmailConfirmMismatch": "البريدان غير متطابقين.",
    "privacyLoadFailed": "تعذر تحميل بيانات الخصوصية.",
    "securityPrivacyTitle": "الأمان والخصوصية",
    "securitySegmentTitle": "الأمان",
    "privacySegmentTitle": "الخصوصية",
    "privacyPasswordNewLengthError": "كلمة المرور الجديدة يجب أن تتكون من 8 أحرف على الأقل.",
    "privacyPasswordMustDifferError": "يجب أن تكون كلمة المرور الجديدة مختلفة عن الحالية.",
    "privacyPasswordMismatchError": "كلمتا المرور غير متطابقتين.",
    "privacyPasswordStrengthWeak": "ضعيف",
    "privacyPasswordStrengthMedium": "متوسط",
    "privacyPasswordStrengthStrong": "قوي",
    "privacyPasswordUpdateConfirmTitle": "تأكيد التحديث",
    "privacyPasswordUpdateConfirmBody": "هل تريد تحديث كلمة المرور؟",
    "privacyPasswordUpdateAction": "تحديث",
    "privacyPasswordUpdateRequiresSignin": "تعذر تحديث كلمة المرور، يرجى تسجيل الدخول مرة أخرى.",
    "privacyPasswordReauthFailedGeneric": "تعذر التحقق من الهوية، حاول لاحقًا.",
    "privacyPasswordUpdateSuccess": "تم تحديث كلمة المرور بنجاح.",
    "privacyPasswordUpdateFailed": "تعذر تحديث كلمة المرور، حاول لاحقًا.",
    "privacyNotAvailable": "غير متوفر",
    "privacyResetPasswordDialogBody": "سنرسل رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني المسجل: {maskedEmail}",
    "privacySendResetLinkAction": "إرسال الرابط",
    "privacyNoEmailLinked": "لا يوجد بريد إلكتروني مرتبط بالحساب.",
    "privacyResetLinkSent": "تم إرسال رابط إعادة التعيين إلى بريدك الإلكتروني.",
    "privacyResetLinkFailed": "تعذر إرسال الرابط، حاول لاحقًا.",
    "privacyNetworkCellular": "بيانات الهاتف",
    "privacyUnknown": "غير معروف",
    "algeriaLabel": "الجزائر",
    "privacyNoAuditDataYet": "لا توجد بيانات متاحة بعد.",
    "privacyLastPasswordChangeTitle": "آخر تغيير كلمة المرور",
    "privacyDateTimeLabel": "التاريخ والوقت",
    "privacyDeviceLabel": "الجهاز",
    "privacyManufacturerLabel": "الشركة المصنّعة",
    "privacyOperatingSystemLabel": "نظام التشغيل",
    "privacyAppVersionLabel": "إصدار التطبيق",
    "privacyConnectionTypeLabel": "نوع الاتصال",
    "privacyApproxLocationLabel": "الموقع التقريبي",
    "privacyIpAddressLabel": "عنوان IP",
    "privacyCopyFullIp": "نسخ IP الكامل",
    "privacyThisWasNotMe": "هذا ليس أنا",
    "privacyIpUnavailable": "عنوان IP غير متوفر.",
    "privacyCopyIpSuccess": "تم نسخ IP الكامل بأمان.",
    "privacyReauthCopyIpReason": "تحقق من هويتك لنسخ IP الكامل",
    "privacySecurityAlertTitle": "تحذير أمني شديد",
    "privacySecurityAlertBody": "إذا لم تكن أنت من غيّر كلمة المرور، سنقوم بتسجيل الخروج من جميع الجلسات فوراً. هل تريد المتابعة؟",
    "privacyContinueAction": "متابعة",
    "privacyOtherSessionsRevokedPrecaution": "تم إنهاء الجلسات الأخرى كإجراء احترازي.",
    "privacyRevokeSessionsFailed": "تعذر إنهاء جميع الجلسات حالياً.",
    "privacyChangePasswordNowNote": "يرجى تغيير كلمة المرور فوراً. التحقق بخطوتين: قريباً.",
    "privacyChangePasswordTitle": "تغيير كلمة المرور",
    "privacyCurrentPasswordLabel": "كلمة المرور الحالية",
    "privacyCurrentPasswordHelper": "أدخل كلمة المرور الحالية لإثبات ملكية الحساب.",
    "privacyResetEmailHint": "قد يصل البريد خلال دقيقة، وتأكد من مجلد الرسائل غير المرغوب فيها.",
    "privacyNewPasswordLabel": "كلمة المرور الجديدة",
    "privacyNewPasswordHelper": "يجب أن تحتوي على 8 أحرف على الأقل.",
    "privacyPasswordStrengthLabel": "قوة كلمة المرور: ",
    "privacyConfirmNewPasswordLabel": "تأكيد كلمة المرور الجديدة",
    "privacyConfirmNewPasswordHelper": "أعد إدخال كلمة المرور الجديدة للتأكيد.",
    "privacyEnterConfirmToMatch": "قم بإدخال التأكيد للتحقق من التطابق.",
    "privacyPasswordsMatch": "كلمتا المرور متطابقتان.",
    "privacyLoadingLastChange": "جارِ تحميل بيانات آخر تغيير...",
    "privacyLastPasswordChangeUnavailable": "آخر تغيير كلمة المرور: غير متوفر",
    "privacyLastPasswordChangeAt": "آخر تغيير كلمة المرور: {date}",
    "privacyViewDetails": "عرض التفاصيل ⌄",
    "privacySaveNewPassword": "حفظ كلمة المرور الجديدة",
    "sessionAgoMinutes": "منذ {minutes} د",
    "sessionAgoHours": "منذ {hours} س",
    "sessionAgoDays": "منذ {days} ي",
    "sessionDeviceNameLabel": "اسم الجهاز",
    "sessionTrustedDevice": "جهاز موثوق",
    "sessionModelLabel": "الموديل",
    "sessionPlatformLabel": "المنصة",
    "sessionVersionLabel": "الإصدار",
    "sessionLoginDateLabel": "تاريخ الدخول",
    "sessionLastActivityLabel": "آخر نشاط",
    "sessionNetworkLabel": "الشبكة",
    "dangerZone": "منطقة الخطر",
    "gpu": "حساب المعدل الاكاديمي",
  },
    "en":   <String, String>{
    "sections": "Sections",
    "majors": "Majors",
    "comments": "Comments",
    "comment": "Comment",
    "writeYourComment": "Write your comment",
    "publish": "Publish",
    "cancel": "Cancel",
    "delete": "Delete",
    "posted": "Post",
    "searchClipboard": "Search inside Note-pade…",
    "note": "Note",
    "title": "Title",
    "content": "Content",
    "save": "Save",
    "pinNote": "Pin Note",
    "noNotesYet": "No notes yet",
    "archive": "Archive",
    "home": "Home",
    "community": "Community",
    "viewAll": "View All",
    "faculties": "Faculties",
    "clipboard": "Note-pade",
    "changeTheme": "Change Theme",
    "changeLanguage": "Change Language",
    "resetPassword": "Reset Password",
    "logout": "Logout",
    "login": "Login",
    "aboutApp": "About the App",
    "privacyPolicy": "Privacy Policy",
    "privacyPolicyTitle": "Privacy Policy",
    "privacyPolicyBody": "Please review our privacy policy.",
    "welcomeEmoji": "Welcome 👋",
    "homeSubtitle": "Browse faculties, calculate your GPA, share your ideas, and write notes easily.",
    "searchFaculty": "Search for a faculty...",
    "searchStartTyping": "Start typing to search",
    "searchNoResults": "No results found",
    "quickCalc": "Quick Calculation",
    "welcomeUniSpace": "Welcome to UniSpace",
    "email": "Email",
    "password": "Password",
    "forgotPassword": "Forgot password?",
    "resetPasswordTitle": "Reset your password",
    "resetPasswordHelper": "Enter your email and we’ll send you a reset link.",
    "sendResetLink": "Send link",
    "sendResetLinkLoading": "Sending...",
    "invalidEmailValidation": "Please enter a valid email address.",
    "resetLinkSentSuccess": "The reset link was sent to your email.",
    "invalidEmailError": "The email address is invalid.",
    "userNotFoundError": "No account found with that email.",
    "tooManyRequestsError": "Too many requests, try again later.",
    "resetLinkFailed": "Could not send the link, please try again.",
    "resetSent": "Reset link has been sent",
    "resetFailed": "Failed to send: {e}",
    "notRegistered": "Not registered",
    "pinned": "Pinned",
    "otherNotes": "Other Notes",
    "noPostsYet": "No posts yet",
    "startDiscussion": "Start the first discussion in the community and share your experience with colleagues.",
    "createPost": "Post",
    "newPost": "New Post",
    "mediaUrl": "Image/Video URL",
    "hashtag": "#",
    "share": "Share",
    "report": "Report",
    "commentsCount": "تعليقات ({count})",
    "writeComment": "Write your comment…",
    "quickCalc2": "Quick Calc",
    "add": "Add",
    "calculate": "Calculate",
    "pass": " Passed",
    "fail": " Failed",
    "credits": "Credits:",
    "lightMode": "Light Mode",
    "darkMode": "Dark Mode",
    "systemMode": "System Mode",
    "aboutAppDetails": "UniSpace does not collect personal data outside Firebase. All data is secure.",
    "chooseTheme": "Choose Theme",
    "light": "Light",
    "dark": "Dark",
    "system": "System",
    "chooseLanguage": "Choose Language",
    "arabic": "Arabic",
    "register": "Register",
    "post": "Your post has been published ✅",
    "createPoste": "Create a post",
    "oneMajor": "One major",
    "noMajorsYet": "No majors yet",
    "editWeights": "Edit Weights",
    "facultyEconomics": "Faculty of Economics, Commerce, and Management Sciences",
    "basicEducationDept": "Basic Education Department",
    "basicEducation": "Basic Education",
    "managementSciencesDept": "Department of Management Sciences",
    "managementSciences": "Management Sciences",
    "businessAdministration": "Business Administration",
    "financialManagement": "Financial Management",
    "humanResourcesManagement": "Human Resources Management",
    "corporateFinancialManagement": "Corporate Financial Management",
    "commercialSciencesDept": "Department of Commercial Sciences",
    "commercialSciences": "Commercial Sciences",
    "financeInternationalTrade": "Finance and International Trade",
    "marketing": "Marketing",
    "servicesMarketing": "Services Marketing",
    "hotelTourismMarketing": "Hotel and Tourism Marketing",
    "financialAccountingDept": "Department of Financial and Accounting Sciences",
    "financialAccounting": "Financial and Accounting Sciences",
    "finance": "Finance",
    "accounting": "Accounting",
    "accountingTaxation": "Accounting and Taxation",
    "corporateFinance": "Corporate Finance",
    "economicsDept": "Department of Economics",
    "economics": "Economics",
    "monetaryFinancialEconomics": "Monetary and Financial Economics",
    "internationalEconomics": "International Economics",
    "noSubjectsThisSemester": "No subjects in this semester.",
    "coefficient": "Coef:",
    "close": "Close",
    "studyResults": "Study Results",
    "notesTdTpExam": "Grades (TD/TP/Exam)",
    "facultyLawPolitical": "Faculty of Law and Political Sciences",
    "politicalSciences": "Political Sciences",
    "commonCore": "Common Core",
    "basicUnit": "Basic Unit",
    "methodologicalUnit": "Methodological Unit",
    "exploratoryUnit": "Exploratory Unit",
    "horizontalUnit": "Horizontal Unit",
    "politicalAdministrativeOrgs": "Political and Administrative Organizations",
    "law": "Law",
    "publicLaw": "Public Law",
    "privateLaw": "Private Law",
    "advancedPublicLaw": "Advanced Public Law",
    "familyLaw": "Family Law",
    "criminalLaw": "Criminal Law and Criminal Sciences",
    "businessLaw": "Business Law",
    "legalProfessionsLaw": "Legal and Judicial Professions Law",
    "maritimePortLaw": "Maritime and Port Law",
    "energyMiningLaw": "Energy and Mining Law",
    "taxLaw": "Tax Law",
    "internationalRelations": "International Relations",
    "internationalCooperation": "International Cooperation",
    "localAdministration": "Local Administration",
    "contactUs": "Contact Us",
    "blockAccount": "Block Account",
    "followComment": "Follow Comment",
    "copyText": "Copy Text",
    "hide": "Hide",
    "savePost": "Save Post",
    "university": "University",
    "faculty": "Faculty",
    "department": "Department",
    "major": "Major",
    "mood": "Mood",
    "name": "Name",
    "posts": "Posts",
    "profile": "Profile",
    "following": "Following",
    "userInfo": "User Information",
    "facultyArtsLanguages": "Faculty of Arts and Foreign Languages",
    "deptArabicLangLit": "Department of Arabic Language and Literature",
    "deptFrenchLangLit": "Department of French Language and Literature",
    "deptEnglishLangLit": "Department of English Language and Literature",
    "contactUsSubtitle": "We are happy to hear from you. Send your message to support.",
    "contactCategoryLabel": "Category",
    "contactCategoryIssue": "Issue",
    "contactCategoryFeature": "New feature suggestion",
    "contactCategoryImprovement": "Improvement",
    "contactCategoryReport": "Report",
    "contactCategoryOther": "Other",
    "contactSubjectLabel": "Subject",
    "contactSubjectHint": "Short summary of your request",
    "contactDescriptionLabel": "Description",
    "contactDescriptionHint": "Explain the details so we can help quickly",
    "contactScreenshotPlaceholder": "Attach a screenshot",
    "contactScreenshotSoon": "Coming soon",
    "contactIncludeUserInfo": "Include my account information",
    "contactUserInfoUnavailable": "No signed-in user information available",
    "contactSend": "Send",
    "contactValidationRequired": "This field is required",
    "contactValidationMinLength": "Please enter at least {min} characters",
    "contactValidationMaxLength": "Please keep this under {max} characters",
    "contactSending": "Sending...",
    "contactSendSuccess": "Sent ✅",
    "contactSendFailure": "We couldn't send your message. Please try again.",
    "contactMailOpened": "Email app opened to send your message",
    "contactMailUnavailable": "Email app not available. You can copy the message instead.",
    "contactCopyDialogTitle": "Copy message",
    "contactCopyDialogBody": "Copy the message and send it to support via your email app.",
    "contactCopyAction": "Copy",
    "contactCopied": "Message copied",
    "contactMetadataHeader": "Metadata",
    "contactMetadataUserId": "User ID",
    "contactMetadataEmail": "Email",
    "contactMetadataName": "Name",
    "contactMetadataPlatform": "Platform",
    "contactMetadataLocale": "Locale",
    "contactMetadataTimestamp": "Timestamp",
    "contactMetadataAppVersion": "App version",
    "examCalendar": "Exam Calendar",
    "smartReviewPlanTitle": "Smart review plan",
    "smartReviewPlanDescription": "Generate a focused review plan based on your upcoming exams and study goals.",
    "smartReviewPlanCtaCreate": "Create a plan",
    "smartReviewPlanComingSoon": "Coming soon",
    "smartReviewTitle": "Smart Review Plan",
    "smartReviewSubtitle": "Turn upcoming exams into a balanced, achievable daily plan.",
    "smartReviewCtaCreate": "Create review plan",
    "smartReviewChipExams": "Exam-aware",
    "smartReviewChipTime": "Time-smart",
    "smartReviewChipReminders": "Reminders",
    "smartReviewChipSimple": "Easy to follow",
    "smartReviewPreviewTitle": "Preview your week",
    "smartReviewPreviewItem1": "Today · 2 focus sessions (45 min)",
    "smartReviewPreviewItem2": "Tomorrow · 1 mock quiz + recap",
    "smartReviewPreviewItem3": "This week · Prioritize hardest subjects",
    "smartReviewBottomSheetTitle": "Before we build your plan",
    "smartReviewBottomSheetBody": "Add your subjects and exam dates so we can personalize your schedule.",
    "smartReviewActionAddSubjects": "Add subjects",
    "smartReviewActionAddExam": "Add exam",
    "smartReviewActionLater": "Maybe later",
    "smartReviewTipsTitle": "How it works",
    "smartReviewTipsBody": "We analyze your exams, time left, and difficulty to build daily sessions you can actually follow.",
    "smartReviewEmptyNoExamsTitle": "No upcoming exams yet",
    "smartReviewEmptyNoExamsBody": "Add at least one exam so we can build a focused review plan.",
    "smartReviewEmptyNoPlanTitle": "Ready to build your plan",
    "smartReviewEmptyNoPlanBody": "We will generate a 7-day schedule based on your nearest exam and study time.",
    "smartReviewPlanSectionTitle": "Your plan",
    "smartReviewPlanRange": "{start} → {end}",
    "smartReviewPlanCleared": "Plan cleared",
    "smartReviewActionClearPlan": "Clear plan",
    "smartReviewTaskDuration": "{minutes} min",
    "smartReviewTaskFocusTitle": "Focus session: {subject}",
    "smartReviewTaskPracticeTitle": "Practice quiz: {subject}",
    "smartReviewTaskSummaryTitle": "Summary review: {subject}",
    "smartReviewTaskMockTitle": "Mock test: {subject}",
    "soon": "Coming soon",
    "addExam": "Add Exam",
    "editExam": "Edit Exam",
    "deleteExam": "Delete Exam",
    "confirmDeleteExam": "Are you sure you want to delete this exam?",
    "examSubject": "Subject",
    "examSubjectRequired": "Please enter the subject",
    "examRoom": "Room",
    "examNote": "Note",
    "reminders": "Reminders",
    "reminder24h": "24 hours before",
    "reminder2h": "2 hours before",
    "reminder30m": "30 minutes before",
    "saveExam": "Save Exam",
    "noExamsDay": "No exams for this day",
    "examReminder24h": "Reminder: {subject} in 24 hours",
    "examReminder2h": "Reminder: {subject} in 2 hours",
    "examReminder30m": "Reminder: {subject} in 30 minutes",
    "drawerSectionAccount": "Account",
    "drawerSectionStudent": "Student",
    "drawerSectionContent": "Content",
    "drawerSectionApp": "App",
    "editProfile": "Edit Profile",
    "notificationsSettingsTitle": "Notifications",
    "notificationsSettingsDescription": "Manage push notifications and reminders.",
    "notificationsEnabled": "Enable notifications",
    "notificationsEnabledHint": "Get alerts about updates and reminders.",
    "notificationsExamReminders": "Exam reminders",
    "notificationsExamRemindersHint": "Receive local alerts for scheduled exams.",
    "notificationsAnnouncements": "Announcements",
    "notificationsAnnouncementsHint": "Stay up to date on campus news.",
    "notificationsCommunity": "Community updates",
    "notificationsCommunityHint": "Get notified about community activity.",
    "notificationsDisabledHint": "Enable notifications to manage reminders and alerts.",
    "securityCenterTitle": "Security",
    "twoFactorAuthTitle": "Two-factor authentication",
    "twoFactorAuthHint": "Require OTP verification on sign-in.",
    "twoFactorEnabledToast": "Two-factor authentication enabled.",
    "twoFactorDisabledToast": "Two-factor authentication disabled.",
    "twoFactorEnableConfirmTitle": "Enable two-factor authentication?",
    "twoFactorEnableConfirmBody": "You will be asked for a one-time code sent to your email after password login.",
    "twoFactorOtpTitle": "Email verification code",
    "twoFactorOtpDescription": "Enter the 6-digit code sent to {email}.",
    "twoFactorCodeLabel": "Verification code",
    "twoFactorCodeHint": "6-digit code",
    "twoFactorConfirmButton": "Confirm",
    "twoFactorResendCode": "Resend code",
    "twoFactorResendIn": "Resend in {seconds}s",
    "twoFactorBackToLogin": "Back to login",
    "twoFactorCodeSent": "Verification code sent to your email.",
    "twoFactorCodeExpired": "Code expired. Request a new code.",
    "twoFactorCodeIncorrect": "Incorrect code. Try again.",
    "twoFactorTooManyAttempts": "Too many failed attempts. Try again later.",
    "twoFactorResendCooldown": "Please wait before resending.",
    "twoFactorVerifiedSuccess": "Two-factor verification completed.",
    "twoFactorCodeInvalidFormat": "Enter a valid 6-digit code.",
    "twoFactorChallengeMissing": "Verification session not found. Sign in again.",
    "twoFactorSendFailed": "Failed to send verification code.",
    "twoFactorGenericError": "Unable to complete verification. Try again.",
    "twoFactorAttemptsRemaining": "Attempts remaining: {count}",
    "manageDevicesTitle": "Manage devices",
    "manageDevicesHint": "Review active sessions and devices.",
    "manageDevicesDescription": "See where your account is signed in and remove access if needed.",
    "currentDeviceTitle": "Current device",
    "activeSessionsTitle": "Active sessions",
    "activeSessionsEmpty": "No other active sessions",
    "activeSessionsHint": "Session management requires a secure backend.",
    "trustedDevicesTitle": "Trusted devices",
    "devicePrimary": "Primary device",
    "deviceActiveNow": "Active now",
    "signOut": "Sign out",
    "logoutAllDevices": "Log out of all devices",
    "logoutAllSuccess": "Signed out from all devices.",
    "logoutAllDevicesPrompt": "We'll sign you out on this device. For other sessions, enable backend revocation.",
    "logoutAllConfirm": "Log out",
    "logoutAllLocalOnly": "Signed out here. Configure backend revocation for other devices.",
    "logoutAllFailed": "Unable to sign out from all devices.",
    "privacySettingsTitle": "Privacy",
    "privacySettingsDescription": "Control what others can see on your profile.",
    "profileVisibilityTitle": "Profile visibility",
    "profileVisibilityPublic": "Public",
    "profileVisibilityPrivate": "Private",
    "showEmailInProfileTitle": "Show email on profile",
    "showEmailInProfileHint": "Allow others to see your email.",
    "blockedUsersTitle": "Blocked users",
    "blockedUsersEmpty": "No blocked users",
    "blockedUsersHint": "Blocked users will appear here.",
    "blockedUsersAddTitle": "Block a user",
    "blockedUsersAddHint": "Enter user ID or email",
    "blockedUsersAddAction": "Block",
    "blockedUsersSince": "Blocked on {date}",
    "unblockUser": "Unblock",
    "academicSettingsTitle": "Academic settings",
    "academicSettingsDescription": "Update your college, major, and level.",
    "academicCollegeLabel": "College",
    "academicMajorLabel": "Major",
    "academicLevelLabel": "Level",
    "academicSettingsSaved": "Academic settings saved.",
    "academicShortcutTitle": "Your academic shortcut",
    "academicShortcutDetails": "Specialty: {specialty} | Level: {level}",
    "academicShortcutGo": "Go",
    "academicShortcutEdit": "Edit",
    "academicShortcutDeleteTitle": "Delete shortcut",
    "academicShortcutDeleteConfirmTitle": "Confirm deletion",
    "academicShortcutDeleteConfirmBody": "Do you want to delete the academic shortcut? You can add it again later.",
    "academicShortcutDeleteCancel": "Cancel",
    "academicShortcutDeleteConfirm": "Delete",
    "academicShortcutDeleteSuccess": "Shortcut deleted successfully.",
    "academicShortcutEmptyTitle": "No academic shortcut set yet.",
    "academicShortcutEmptyAction": "Add shortcut",
    "academicShortcutNotFound": "We couldn't find that specialty. Please update your academic settings.",
    "saveChanges": "Save changes",
    "downloadsTitle": "Downloads",
    "downloadsDescription": "Browse your downloaded files and clean the cache.",
    "downloadsEmptyTitle": "No downloads yet",
    "downloadsEmptyHint": "Downloaded items will appear here.",
    "downloadsClearCache": "Clear cache",
    "downloadsCacheCleared": "Cache cleared.",
    "downloadsCacheClearFailed": "Unable to clear the cache.",
    "downloadsRefreshList": "Refresh list",
    "downloadsStorageTitle": "Downloads storage",
    "downloadsStorageUserLabel": "User: 0 MB",
    "downloadsStorageCacheLabel": "Cache: 0 MB",
    "downloadsStorageInfo": "Sizes will be calculated automatically later.",
    "downloadsStorageUserLabelValue": "User: {size}",
    "downloadsStorageCacheLabelValue": "Cache: {size}",
    "downloadsStorageInfoValue": "Total used: {size}",
    "downloadsClearCacheDialogTitle": "Clear cached downloads?",
    "downloadsClearCacheDialogBody": "This will remove cached files from this device. You can download them again later.",
    "downloadsClearCacheDialogConfirm": "Clear cache",
    "downloadsExploreCta": "Explore content",
    "downloadsFilterAll": "All",
    "downloadsFilterFiles": "Files",
    "downloadsFilterImages": "Images",
    "downloadsSortLabel": "Sort by",
    "downloadsSortNewest": "Newest",
    "downloadsSortOldest": "Oldest",
    "downloadsClearAllAction": "Clear all downloads",
    "downloadsClearAllDialogTitle": "Clear all downloads?",
    "downloadsClearAllDialogBody": "This will remove all downloaded files from this device.",
    "downloadsClearAllDialogConfirm": "Clear all",
    "downloadsClearAllSuccess": "All downloads cleared.",
    "downloadsClearAllFailed": "Unable to clear all downloads.",
    "downloadsDeleteDialogTitle": "Delete download?",
    "downloadsDeleteDialogBody": "Delete {fileName} from this device?",
    "downloadsDeleteSuccess": "Download deleted.",
    "downloadsDeleteFailed": "Unable to delete the download.",
    "downloadsLoadFailed": "Unable to load downloads.",
    "downloadsUpdatedAt": "Updated {date}",
    "favoritesTitle": "Favorites",
    "favoritesDescription": "Your saved items appear here.",
    "favoritesEmptyTitle": "No favorites yet",
    "favoritesEmptyHint": "Save posts or files to see them here.",
    "favoritesAddTitle": "Add favorite",
    "favoritesAddHint": "Enter item ID",
    "favoritesAddTypeHint": "Type (optional)",
    "favoritesAddAction": "Save",
    "favoritesAdded": "Favorite saved.",
    "favoritesRemoved": "Favorite removed.",
    "favoritesSignInTitle": "Sign in to save favorites",
    "favoritesSignInHint": "Favorites sync to your account when signed in.",
    "favoritesTypeLabel": "Type: {type}",
    "fontSizeTitle": "Font size",
    "fontSizeDescription": "Choose a comfortable reading size.",
    "fontSizeSmall": "Small",
    "fontSizeMedium": "Medium",
    "fontSizeLarge": "Large",
    "fontSizePreviewLabel": "Preview",
    "fontSizePreviewText": "The quick brown fox jumps over the lazy dog.",
    "rateApp": "Rate app",
    "rateAppFailed": "Unable to open the store right now.",
    "shareApp": "Share app",
    "shareAppMessage": "Check out UniSpace for smart study tools and student community!",
    "emailVerified": "Email verified",
    "emailNotVerified": "Email not verified",
    "sendOtpNow": "Send OTP now",
    "otpCooldownLabel": "Send OTP in {seconds}s",
    "otpSentSuccess": "OTP sent. Check your email.",
    "otpSentFailed": "Unable to send OTP right now.",
    "signInRequired": "Please sign in to continue.",
    "guestUser": "Guest",
    "emailUnavailable": "Email unavailable",
    "emailHidden": "Email hidden",
    "aboutAppSummary": "A platform to calculate GPA, connect with students, and take notes.",
    "aboutAppDescription": "A smart university platform that helps students organize their studies, calculate averages, track exams, and plan revision in an easy and effective way.",
    "aboutAppFeatureGpa": "Accurate university GPA calculation",
    "aboutAppFeatureReviewPlan": "Smart revision planner",
    "aboutAppFeatureExams": "Exam calendar",
    "aboutAppFeatureNotes": "Academic note taking",
    "aboutAppFeatureStudents": "Tailored specifically for university students",
    "aboutAppViewLicenses": "View licenses",
    "aboutAppFooter": "Developed with Flutter",
    "commonCore1": "Common Core",
    "academicclass": "class",
    "verificationEmailSent": "Verification email sent.",
    "emailNotVerifiedYet": "Email is not verified yet. Please open your email, click the verification link, then try again.",
    "verifyEmailToContinue": "Please verify your email to continue.",
    "verifyEmailHelper": "Open the verification email and click the link, then tap check now.",
    "verifyEmailTitle": "Verify email",
    "checkNow": "Check now",
    "resendVerificationEmail": "Resend verification email",
    "resendVerificationCooldown": "Resend in {seconds}s",
    "wrongPasswordError": "Wrong password.",
    "emailAlreadyInUseError": "Email is already in use.",
    "networkError": "Network error. Please try again.",
    "weakPasswordError": "Password is too weak.",
    "emailAuthDisabledError": "Email/password sign-in is disabled.",
    "userDisabledError": "This account is disabled.",
    "genericAuthError": "Something went wrong. Please try again.",
    "activeSessionNow": "Just now",
    "sessionSignedOutSuccess": "Session signed out successfully.",
    "sessionSignOutFailed": "Unable to sign out this session.",
    "otherSessionsSignedOutSuccess": "Signed out from other devices.",
    "logoutAllOtherDevices": "Log out other devices",
    "sessionUnknownDevice": "Unknown device",
    "privacyTabTitle": "Privacy",
    "privacyTabSubtitle": "Manage your account data securely",
    "privacyAccountOverviewSection": "Account overview",
    "privacyNameRowTitle": "First and last name",
    "privacyEmailRowTitle": "Email",
    "privacyNameRuleAllowed": "You can change your name once per month.",
    "privacyNameRuleBlockedDays": "You can change your name after: {days} day / {hours} hour",
    "privacyNameRuleBlockedHours": "You can change your name after: {hours} hour",
    "privacyReauthTitle": "Confirm password",
    "privacyReauthSubtitle": "For your security, enter your current password before continuing.",
    "privacyContinue": "Continue",
    "privacyReauthFailed": "Password verification failed. Please try again.",
    "privacyEditNameTitle": "Edit name",
    "privacyFirstName": "First name",
    "privacyLastName": "Last name",
    "privacyNameValidationRequired": "This field is required",
    "privacyNameValidationShort": "Name must be at least 2 characters",
    "privacyNameValidationLong": "Maximum 40 characters",
    "privacyNameSaved": "Name updated successfully.",
    "privacyEmailSaved": "Email updated locally.",
    "privacyEmailFlowTitle": "Change email",
    "privacyStepOf": "Step {current} of {total}",
    "privacyEmailFlowSecurityNote": "Security note: your password is never stored in the app.",
    "privacyEmailFlowStep1Help": "Enter your current email to verify. Hint: {masked}",
    "privacyEmailCurrentLabel": "Current email",
    "privacyEmailFlowStep2Help": "We'll send an email change link to your current inbox for verification.",
    "privacyEmailFlowSendLink": "Send change email link",
    "privacyEmailFlowStep3Help": "Enter your new email and confirm it.",
    "privacyEmailNewLabel": "New email",
    "privacyEmailConfirmLabel": "Confirm new email",
    "privacyEmailFlowStep4Help": "Review new email: {masked}",
    "privacyEmailCurrentMismatch": "Current email does not match.",
    "privacyEmailValidationRequired": "Enter and confirm your new email.",
    "privacyEmailConfirmMismatch": "Emails do not match.",
    "privacyLoadFailed": "Unable to load privacy data.",
    "securityPrivacyTitle": "Security & Privacy",
    "securitySegmentTitle": "Security",
    "privacySegmentTitle": "Privacy",
    "privacyPasswordNewLengthError": "The new password must be at least 8 characters long.",
    "privacyPasswordMustDifferError": "The new password must be different from the current password.",
    "privacyPasswordMismatchError": "Passwords do not match.",
    "privacyPasswordStrengthWeak": "Weak",
    "privacyPasswordStrengthMedium": "Medium",
    "privacyPasswordStrengthStrong": "Strong",
    "privacyPasswordUpdateConfirmTitle": "Confirm update",
    "privacyPasswordUpdateConfirmBody": "Do you want to update the password?",
    "privacyPasswordUpdateAction": "Update",
    "privacyPasswordUpdateRequiresSignin": "Unable to update password. Please sign in again.",
    "privacyPasswordReauthFailedGeneric": "Unable to verify your identity. Please try again later.",
    "privacyPasswordUpdateSuccess": "Password updated successfully.",
    "privacyPasswordUpdateFailed": "Unable to update password. Please try again later.",
    "privacyNotAvailable": "Not available",
    "privacyResetPasswordDialogBody": "We will send a password reset link to your registered email: {maskedEmail}",
    "privacySendResetLinkAction": "Send link",
    "privacyNoEmailLinked": "No email is linked to this account.",
    "privacyResetLinkSent": "Password reset link sent to your email.",
    "privacyResetLinkFailed": "Unable to send reset link. Please try again later.",
    "privacyNetworkCellular": "Mobile data",
    "privacyUnknown": "Unknown",
    "algeriaLabel": "Algeria",
    "privacyNoAuditDataYet": "No data available yet.",
    "privacyLastPasswordChangeTitle": "Last password change",
    "privacyDateTimeLabel": "Date and time",
    "privacyDeviceLabel": "Device",
    "privacyManufacturerLabel": "Manufacturer",
    "privacyOperatingSystemLabel": "Operating system",
    "privacyAppVersionLabel": "App version",
    "privacyConnectionTypeLabel": "Connection type",
    "privacyApproxLocationLabel": "Approximate location",
    "privacyIpAddressLabel": "IP address",
    "privacyCopyFullIp": "Copy full IP",
    "privacyThisWasNotMe": "This wasn't me",
    "privacyIpUnavailable": "IP address is unavailable.",
    "privacyCopyIpSuccess": "Full IP copied securely.",
    "privacyReauthCopyIpReason": "Verify your identity to copy the full IP.",
    "privacySecurityAlertTitle": "Critical security alert",
    "privacySecurityAlertBody": "If you did not change the password, we will immediately sign out all other sessions. Do you want to continue?",
    "privacyContinueAction": "Continue",
    "privacyOtherSessionsRevokedPrecaution": "Other sessions were signed out as a precaution.",
    "privacyRevokeSessionsFailed": "Unable to end all sessions right now.",
    "privacyChangePasswordNowNote": "Please change your password immediately. Two-step verification: coming soon.",
    "privacyChangePasswordTitle": "Change password",
    "privacyCurrentPasswordLabel": "Current password",
    "privacyCurrentPasswordHelper": "Enter your current password to verify account ownership.",
    "privacyResetEmailHint": "The email may arrive within a minute. Check your spam folder too.",
    "privacyNewPasswordLabel": "New password",
    "privacyNewPasswordHelper": "It must contain at least 8 characters.",
    "privacyPasswordStrengthLabel": "Password strength: ",
    "privacyConfirmNewPasswordLabel": "Confirm new password",
    "privacyConfirmNewPasswordHelper": "Re-enter your new password for confirmation.",
    "privacyEnterConfirmToMatch": "Enter confirmation to verify the match.",
    "privacyPasswordsMatch": "Passwords match.",
    "privacyLoadingLastChange": "Loading last change data...",
    "privacyLastPasswordChangeUnavailable": "Last password change: Not available",
    "privacyLastPasswordChangeAt": "Last password change: {date}",
    "privacyViewDetails": "View details ⌄",
    "privacySaveNewPassword": "Save new password",
    "sessionAgoMinutes": "{minutes} min ago",
    "sessionAgoHours": "{hours} h ago",
    "sessionAgoDays": "{days} d ago",
    "sessionDeviceNameLabel": "Device name",
    "sessionTrustedDevice": "Trusted device",
    "sessionModelLabel": "Model",
    "sessionPlatformLabel": "Platform",
    "sessionVersionLabel": "Version",
    "sessionLoginDateLabel": "Login date",
    "sessionLastActivityLabel": "Last activity",
    "sessionNetworkLabel": "Network",
    "dangerZone": "Danger zone",
    "gpu": "Calculating the academic average",
  },
    "fr":   <String, String>{
    "sections": "Sections",
    "majors": "Spécialités",
    "comments": "Commentaires",
    "comment": "Commentaire",
    "writeYourComment": "Écrivez votre commentaire",
    "publish": "Publier",
    "cancel": "Annuler",
    "delete": "Supprimer",
    "posted": "Publication",
    "searchClipboard": "Rechercher dans le Note-pade…",
    "note": "Note",
    "title": "Titre",
    "content": "Contenu",
    "save": "Enregistrer",
    "pinNote": "Épingler la note",
    "noNotesYet": "Aucune note pour le moment",
    "archive": "Archives",
    "home": "Accueil",
    "community": "Communauté",
    "viewAll": "Voir tout",
    "faculties": "Facultés",
    "clipboard": "Note-pade",
    "changeTheme": "Changer le thème",
    "changeLanguage": "Changer la langue",
    "resetPassword": "Réinitialiser le mot de passe",
    "logout": "Se déconnecter",
    "login": "Se connecter",
    "aboutApp": "À propos de l'application",
    "privacyPolicy": "Politique de confidentialité",
    "privacyPolicyTitle": "Politique de confidentialité – UniSpace",
    "privacyPolicyBody": "Chez UniSpace, nous accordons une grande importance à la confidentialité des utilisateurs et nous nous engageons à protéger leurs données et à respecter leur vie privée. Cette politique explique comment les informations sont traitées lors de l'utilisation de l'application.\n\n1) Données que nous collectons\nNous pouvons collecter uniquement le minimum de données nécessaires au bon fonctionnement de l'application, notamment :\n- E-mail : utilisé pour créer un compte, se connecter et vérifier l'identité de l'utilisateur.\n- Nom d'utilisateur ou nom personnel : choisi par l'utilisateur dans l'application.\nNous ne collectons aucune donnée supplémentaire sans l'accord ou la connaissance de l'utilisateur.\n\n2) Données locales sur l'appareil\nL'application peut permettre à l'utilisateur de saisir des données d'étude telles que :\n- Notes\n- Remarques\n- Informations d'organisation des études ou des examens\nImportant :\n- Ces données sont stockées localement uniquement sur l'appareil de l'utilisateur.\n- Elles ne sont pas envoyées à nos serveurs.\n- Nous n'y accédons pas, ne les collectons pas et ne les partageons pas.\n- Elles restent entièrement sous le contrôle de l'utilisateur.\n\n3) Utilisation des données\nNous utilisons les données collectées uniquement pour :\n- Permettre à l'utilisateur de créer un compte et de se connecter.\n- Améliorer l'expérience d'utilisation de l'application.\n- Assurer la sécurité du compte et prévenir l'utilisation non autorisée.\n\n4) Partage des données\n- Nous ne vendons, ne louons ni ne partageons les données des utilisateurs avec aucun tiers.\n- Aucune information personnelle n'est partagée sauf si la loi l'exige.\n\n5) Services tiers\nL'application utilise des services fiables tels que Firebase de Google pour l'authentification et la sécurité des comptes.\nCes services sont soumis à leurs propres politiques de confidentialité, et nous les utilisons conformément aux meilleures pratiques de sécurité.\n\n6) Sécurité des données\nNous appliquons des mesures de sécurité appropriées pour protéger les données des utilisateurs contre l'accès non autorisé, la modification ou la perte.\n\n7) Confidentialité des enfants\nUniSpace est destiné aux étudiants universitaires et ne cible pas les enfants de moins de 13 ans, et nous ne collectons pas sciemment de données à leur sujet.\n\n8) Modifications de la politique de confidentialité\nNous pouvons mettre à jour la politique de confidentialité de temps à autre.\nLes utilisateurs seront informés de tout changement important dans l'application.\n\n9) Nous contacter\nSi vous avez des questions concernant cette politique de confidentialité, vous pouvez nous contacter via la section \"Contactez-nous\" dans l'application.\n\nEn utilisant UniSpace, vous acceptez cette politique de confidentialité.",
    "welcomeEmoji": "Bienvenue 👋",
    "homeSubtitle": "Parcourez les facultés, calculez votre moyenne, partagez vos idées et notez facilement.",
    "searchFaculty": "Rechercher une faculté...",
    "searchStartTyping": "Commencez à taper pour rechercher",
    "searchNoResults": "Aucun résultat",
    "quickCalc": "Calcul rapide",
    "welcomeUniSpace": "Bienvenue sur UniSpace",
    "email": "E-mail",
    "password": "Mot de passe",
    "forgotPassword": "Mot de passe oublié ?",
    "resetPasswordTitle": "Réinitialiser le mot de passe",
    "resetPasswordHelper": "Entrez votre e-mail et nous vous enverrons un lien de réinitialisation.",
    "sendResetLink": "Envoyer le lien",
    "sendResetLinkLoading": "Envoi...",
    "invalidEmailValidation": "Veuillez saisir une adresse e-mail valide.",
    "resetLinkSentSuccess": "Le lien de réinitialisation a été envoyé à votre e-mail.",
    "invalidEmailError": "L’adresse e-mail est invalide.",
    "userNotFoundError": "Aucun compte trouvé avec cet e-mail.",
    "tooManyRequestsError": "Trop de demandes, réessayez plus tard.",
    "resetLinkFailed": "Impossible d’envoyer le lien, réessayez.",
    "resetSent": "Le lien de réinitialisation a été envoyé",
    "resetFailed": "Échec de l'envoi : {e}",
    "notRegistered": "Non enregistré",
    "pinned": "Épinglées",
    "otherNotes": "Autres notes",
    "noPostsYet": "Aucune publication pour le moment",
    "startDiscussion": "Commencez la première discussion dans la communauté et partagez votre expérience avec vos collègues.",
    "createPost": "Publication",
    "newPost": "Nouvelle publication",
    "mediaUrl": "Lien image/vidéo",
    "hashtag": "#",
    "share": "Partager",
    "report": "Signaler",
    "commentsCount": "Commentaires ({count})",
    "writeComment": "Écrivez votre commentaire…",
    "quickCalc2": "Calcul rapide",
    "add": "Ajouter",
    "calculate": "Calculer",
    "pass": " Réussi",
    "fail": " Échoué",
    "credits": "Crédits :",
    "lightMode": "Mode clair",
    "darkMode": "Mode sombre",
    "systemMode": "Mode système",
    "aboutAppDetails": "UniSpace ne collecte pas de données personnelles en dehors de Firebase. Toutes les données sont sécurisées.",
    "chooseTheme": "Choisir le thème",
    "light": "Clair",
    "dark": "Sombre",
    "system": "Système",
    "chooseLanguage": "Choisir la langue",
    "arabic": "Arabe",
    "register": "S'inscrire",
    "post": "Votre publication a été publiée ✅",
    "createPoste": "Créer une publication",
    "oneMajor": "Une spécialité",
    "noMajorsYet": "Aucune spécialité enregistrée pour le moment",
    "facultyEconomics": "Faculté des sciences économiques, commerciales et des sciences de gestion",
    "basicEducationDept": "Département de l'enseignement de base",
    "basicEducation": "Enseignement de base",
    "managementSciencesDept": "Département des sciences de gestion",
    "managementSciences": "Sciences de gestion",
    "businessAdministration": "Administration des affaires",
    "financialManagement": "Gestion financière",
    "humanResourcesManagement": "Gestion des ressources humaines",
    "corporateFinancialManagement": "Gestion financière des entreprises",
    "commercialSciencesDept": "Département des sciences commerciales",
    "commercialSciences": "Sciences commerciales",
    "financeInternationalTrade": "Finance et commerce international",
    "marketing": "Marketing",
    "servicesMarketing": "Marketing des services",
    "hotelTourismMarketing": "Marketing hôtelier et touristique",
    "financialAccountingDept": "Département des sciences financières et comptables",
    "financialAccounting": "Sciences financières et comptables",
    "finance": "Finance",
    "accounting": "Comptabilité",
    "accountingTaxation": "Comptabilité et fiscalité",
    "corporateFinance": "Finance d'entreprise",
    "economicsDept": "Département des sciences économiques",
    "economics": "Sciences économiques",
    "monetaryFinancialEconomics": "Économie monétaire et financière",
    "internationalEconomics": "Économie internationale",
    "noSubjectsThisSemester": "Aucune matière dans ce semestre.",
    "coefficient": "Coef :",
    "close": "Fermer",
    "studyResults": "Résultats d'étude",
    "notesTdTpExam": "Notes (TD/TP/Exam)",
    "facultyLawPolitical": "Faculté de droit et des sciences politiques",
    "politicalSciences": "Sciences politiques",
    "commonCore": "Tronc commun",
    "basicUnit": "Unité fondamentale",
    "methodologicalUnit": "Unité méthodologique",
    "exploratoryUnit": "Unité exploratoire",
    "horizontalUnit": "Unité horizontale",
    "politicalAdministrativeOrgs": "Organisations politiques et administratives",
    "law": "Droit",
    "publicLaw": "Droit public",
    "privateLaw": "Droit privé",
    "advancedPublicLaw": "Droit public approfondi",
    "familyLaw": "Droit de la famille",
    "criminalLaw": "Droit pénal et sciences criminelles",
    "businessLaw": "Droit des affaires",
    "legalProfessionsLaw": "Droit des professions juridiques et judiciaires",
    "maritimePortLaw": "Droit maritime et portuaire",
    "energyMiningLaw": "Droit de l’énergie et des mines",
    "taxLaw": "Droit fiscal",
    "internationalRelations": "Relations internationales",
    "internationalCooperation": "Coopération internationale",
    "localAdministration": "Administration locale",
    "contactUs": "Contactez-nous",
    "blockAccount": "Bloquer le compte",
    "followComment": "Suivre le commentaire",
    "copyText": "Copier le texte",
    "hide": "Masquer",
    "savePost": "Enregistrer la publication",
    "university": "University",
    "faculty": "Faculty",
    "department": "Department",
    "major": "Major",
    "mood": "Humeur",
    "name": "Nom",
    "posts": "Publications",
    "profile": "Profile",
    "following": "Following",
    "userInfo": "User Information",
    "facultyArtsLanguages": "Faculté des lettres et des langues étrangères",
    "deptArabicLangLit": "Département de langue et littérature arabes",
    "deptFrenchLangLit": "Département de langue et littérature françaises",
    "deptEnglishLangLit": "Département de langue et littérature anglaises",
    "contactUsSubtitle": "Nous sommes ravis d'avoir votre message. Envoyez-le au support.",
    "contactCategoryLabel": "Catégorie",
    "contactCategoryIssue": "Problème",
    "contactCategoryFeature": "Suggestion de nouvelle fonctionnalité",
    "contactCategoryImprovement": "Amélioration",
    "contactCategoryReport": "Signalement",
    "contactCategoryOther": "Autre",
    "contactSubjectLabel": "Sujet",
    "contactSubjectHint": "Bref résumé de votre demande",
    "contactDescriptionLabel": "Description",
    "contactDescriptionHint": "Expliquez les détails pour vous aider rapidement",
    "contactScreenshotPlaceholder": "Joindre une capture d'écran",
    "contactScreenshotSoon": "Bientôt disponible",
    "contactIncludeUserInfo": "Inclure mes informations de compte",
    "contactUserInfoUnavailable": "Aucune information de compte disponible",
    "contactSend": "Envoyer",
    "contactValidationRequired": "Ce champ est obligatoire",
    "contactValidationMinLength": "Veuillez saisir au moins {min} caractères",
    "contactValidationMaxLength": "Veuillez rester sous {max} caractères",
    "contactSending": "Envoi en cours...",
    "contactSendSuccess": "Envoyé ✅",
    "contactSendFailure": "Impossible d'envoyer votre message. Veuillez réessayer.",
    "contactMailOpened": "Application e-mail ouverte pour envoyer votre message",
    "contactMailUnavailable": "Aucune application e-mail disponible. Vous pouvez copier le message.",
    "contactCopyDialogTitle": "Copier le message",
    "contactCopyDialogBody": "Copiez le message et envoyez-le au support via votre messagerie.",
    "contactCopyAction": "Copier",
    "contactCopied": "Message copié",
    "contactMetadataHeader": "Métadonnées",
    "contactMetadataUserId": "ID utilisateur",
    "contactMetadataEmail": "E-mail",
    "contactMetadataName": "Nom",
    "contactMetadataPlatform": "Plateforme",
    "contactMetadataLocale": "Langue",
    "contactMetadataTimestamp": "Horodatage",
    "contactMetadataAppVersion": "Version de l'application",
    "examCalendar": "Calendrier des examens",
    "smartReviewPlanTitle": "Plan de révision intelligent",
    "smartReviewPlanDescription": "Générez un plan de révision ciblé selon vos examens à venir et vos objectifs.",
    "smartReviewPlanCtaCreate": "Créer un plan",
    "smartReviewPlanComingSoon": "Bientôt",
    "smartReviewTitle": "Plan de révision intelligent",
    "smartReviewSubtitle": "Transformez vos examens à venir en un planning quotidien équilibré.",
    "smartReviewCtaCreate": "Créer un plan de révision",
    "smartReviewChipExams": "Axé examens",
    "smartReviewChipTime": "Gestion du temps",
    "smartReviewChipReminders": "Rappels",
    "smartReviewChipSimple": "Simple à suivre",
    "smartReviewPreviewTitle": "Aperçu de la semaine",
    "smartReviewPreviewItem1": "Aujourd'hui · 2 sessions focus (45 min)",
    "smartReviewPreviewItem2": "Demain · 1 quiz blanc + récap",
    "smartReviewPreviewItem3": "Cette semaine · Priorisez les matières difficiles",
    "smartReviewBottomSheetTitle": "Avant de créer votre plan",
    "smartReviewBottomSheetBody": "Ajoutez vos matières et dates d’examen pour personnaliser le planning.",
    "smartReviewActionAddSubjects": "Ajouter des matières",
    "smartReviewActionAddExam": "Ajouter un examen",
    "smartReviewActionLater": "Plus tard",
    "smartReviewTipsTitle": "Comment ça marche",
    "smartReviewTipsBody": "Nous analysons vos examens, le temps restant et la difficulté pour créer des sessions quotidiennes réalistes.",
    "smartReviewEmptyNoExamsTitle": "Aucun examen à venir",
    "smartReviewEmptyNoExamsBody": "Ajoutez au moins un examen pour générer un plan de révision ciblé.",
    "smartReviewEmptyNoPlanTitle": "Prêt à créer votre plan",
    "smartReviewEmptyNoPlanBody": "Nous générerons un planning de 7 jours basé sur votre examen le plus proche et votre temps d’étude.",
    "smartReviewPlanSectionTitle": "Votre plan",
    "smartReviewPlanRange": "{start} → {end}",
    "smartReviewPlanCleared": "Plan supprimé",
    "smartReviewActionClearPlan": "Supprimer le plan",
    "smartReviewTaskDuration": "{minutes} min",
    "smartReviewTaskFocusTitle": "Session focus : {subject}",
    "smartReviewTaskPracticeTitle": "Quiz d'entraînement : {subject}",
    "smartReviewTaskSummaryTitle": "Révision synthèse : {subject}",
    "smartReviewTaskMockTitle": "Examen blanc : {subject}",
    "soon": "Bientôt",
    "addExam": "Ajouter un examen",
    "editExam": "Modifier l'examen",
    "deleteExam": "Supprimer l'examen",
    "confirmDeleteExam": "Voulez-vous supprimer cet examen ?",
    "examSubject": "Matière",
    "examSubjectRequired": "Veuillez saisir la matière",
    "examRoom": "Salle",
    "examNote": "Note",
    "reminders": "Rappels",
    "reminder24h": "24 heures avant",
    "reminder2h": "2 heures avant",
    "reminder30m": "30 minutes avant",
    "saveExam": "Enregistrer l'examen",
    "noExamsDay": "Aucun examen pour ce jour",
    "examReminder24h": "Rappel : {subject} dans 24 heures",
    "examReminder2h": "Rappel : {subject} dans 2 heures",
    "examReminder30m": "Rappel : {subject} dans 30 minutes",
    "drawerSectionAccount": "Compte",
    "drawerSectionStudent": "Étudiant",
    "drawerSectionContent": "Contenu",
    "drawerSectionApp": "Application",
    "editProfile": "Modifier le profil",
    "notificationsSettingsTitle": "Notifications",
    "notificationsSettingsDescription": "Gérez les notifications et rappels.",
    "notificationsEnabled": "Activer les notifications",
    "notificationsEnabledHint": "Recevez des alertes sur les mises à jour et rappels.",
    "notificationsExamReminders": "Rappels d'examens",
    "notificationsExamRemindersHint": "Recevez des alertes locales pour les examens planifiés.",
    "notificationsAnnouncements": "Annonces",
    "notificationsAnnouncementsHint": "Restez informé des actualités du campus.",
    "notificationsCommunity": "Mises à jour de la communauté",
    "notificationsCommunityHint": "Soyez notifié de l'activité de la communauté.",
    "notificationsDisabledHint": "Activez les notifications pour gérer les rappels et alertes.",
    "securityCenterTitle": "Sécurité",
    "twoFactorAuthTitle": "Authentification à deux facteurs",
    "twoFactorAuthHint": "Exiger un code OTP lors de la connexion.",
    "twoFactorEnabledToast": "Authentification à deux facteurs activée.",
    "twoFactorDisabledToast": "Authentification à deux facteurs désactivée.",
    "twoFactorEnableConfirmTitle": "Activer l’authentification à deux facteurs ?",
    "twoFactorEnableConfirmBody": "Un code à usage unique sera demandé après la connexion par mot de passe.",
    "twoFactorOtpTitle": "Code de vérification par e-mail",
    "twoFactorOtpDescription": "Saisissez le code à 6 chiffres envoyé à {email}.",
    "twoFactorCodeLabel": "Code de vérification",
    "twoFactorCodeHint": "Code à 6 chiffres",
    "twoFactorConfirmButton": "Confirmer",
    "twoFactorResendCode": "Renvoyer le code",
    "twoFactorResendIn": "Renvoyer dans {seconds}s",
    "twoFactorBackToLogin": "Retour à la connexion",
    "twoFactorCodeSent": "Code de vérification envoyé par e-mail.",
    "twoFactorCodeExpired": "Code expiré. Demandez un nouveau code.",
    "twoFactorCodeIncorrect": "Code incorrect. Réessayez.",
    "twoFactorTooManyAttempts": "Trop de tentatives échouées. Réessayez plus tard.",
    "twoFactorResendCooldown": "Veuillez patienter avant de renvoyer.",
    "twoFactorVerifiedSuccess": "Vérification à deux facteurs terminée.",
    "twoFactorCodeInvalidFormat": "Entrez un code valide à 6 chiffres.",
    "twoFactorChallengeMissing": "Session de vérification introuvable. Reconnectez-vous.",
    "twoFactorSendFailed": "Échec de l’envoi du code de vérification.",
    "twoFactorGenericError": "Vérification impossible. Réessayez.",
    "twoFactorAttemptsRemaining": "Tentatives restantes : {count}",
    "manageDevicesTitle": "Gérer les appareils",
    "manageDevicesHint": "Consultez les sessions actives et les appareils.",
    "manageDevicesDescription": "Consultez les connexions et retirez l'accès si nécessaire.",
    "currentDeviceTitle": "Appareil actuel",
    "activeSessionsTitle": "Sessions actives",
    "activeSessionsEmpty": "Aucune autre session active",
    "activeSessionsHint": "La gestion des sessions nécessite un backend sécurisé.",
    "trustedDevicesTitle": "Appareils de confiance",
    "devicePrimary": "Appareil principal",
    "deviceActiveNow": "Actif maintenant",
    "signOut": "Se déconnecter",
    "logoutAllDevices": "Déconnecter tous les appareils",
    "logoutAllSuccess": "Déconnexion de tous les appareils réussie.",
    "logoutAllDevicesPrompt": "Nous vous déconnecterons sur cet appareil. Activez la révocation backend pour les autres sessions.",
    "logoutAllConfirm": "Se déconnecter",
    "logoutAllLocalOnly": "Déconnecté ici. Configurez la révocation backend pour les autres appareils.",
    "logoutAllFailed": "Impossible de déconnecter tous les appareils.",
    "privacySettingsTitle": "Confidentialité",
    "privacySettingsDescription": "Contrôlez ce que les autres voient sur votre profil.",
    "profileVisibilityTitle": "Visibilité du profil",
    "profileVisibilityPublic": "Public",
    "profileVisibilityPrivate": "Privé",
    "showEmailInProfileTitle": "Afficher l'e-mail dans le profil",
    "showEmailInProfileHint": "Autoriser les autres à voir votre e-mail.",
    "blockedUsersTitle": "Utilisateurs bloqués",
    "blockedUsersEmpty": "Aucun utilisateur bloqué",
    "blockedUsersHint": "Les utilisateurs bloqués apparaîtront ici.",
    "blockedUsersAddTitle": "Bloquer un utilisateur",
    "blockedUsersAddHint": "Saisissez l'identifiant ou l'e-mail",
    "blockedUsersAddAction": "Bloquer",
    "blockedUsersSince": "Bloqué le {date}",
    "unblockUser": "Débloquer",
    "academicSettingsTitle": "Paramètres académiques",
    "academicSettingsDescription": "Mettez à jour votre faculté, spécialité et niveau.",
    "academicCollegeLabel": "Faculté",
    "academicMajorLabel": "Spécialité",
    "academicLevelLabel": "Niveau",
    "academicSettingsSaved": "Paramètres académiques enregistrés.",
    "academicShortcutTitle": "Votre raccourci académique",
    "academicShortcutDetails": "Spécialité : {specialty} | Niveau : {level}",
    "academicShortcutGo": "Aller",
    "academicShortcutEdit": "Modifier",
    "academicShortcutDeleteTitle": "Supprimer le raccourci",
    "academicShortcutDeleteConfirmTitle": "Confirmer la suppression",
    "academicShortcutDeleteConfirmBody": "Voulez-vous supprimer le raccourci académique ? Vous pouvez l'ajouter de nouveau plus tard.",
    "academicShortcutDeleteCancel": "Annuler",
    "academicShortcutDeleteConfirm": "Supprimer",
    "academicShortcutDeleteSuccess": "Raccourci supprimé avec succès.",
    "academicShortcutEmptyTitle": "Aucun raccourci académique n'a encore été configuré.",
    "academicShortcutEmptyAction": "Ajouter un raccourci",
    "academicShortcutNotFound": "Impossible de trouver cette spécialité. Veuillez mettre à jour vos paramètres académiques.",
    "saveChanges": "Enregistrer les modifications",
    "downloadsTitle": "Téléchargements",
    "downloadsDescription": "Consultez vos fichiers téléchargés et nettoyez le cache.",
    "downloadsEmptyTitle": "Aucun téléchargement",
    "downloadsEmptyHint": "Les éléments téléchargés apparaîtront ici.",
    "downloadsClearCache": "Vider le cache",
    "downloadsCacheCleared": "Cache vidé.",
    "downloadsCacheClearFailed": "Impossible de vider le cache.",
    "downloadsRefreshList": "Rafraîchir la liste",
    "downloadsStorageTitle": "Stockage des téléchargements",
    "downloadsStorageUserLabel": "Utilisateur : 0 Mo",
    "downloadsStorageCacheLabel": "Cache : 0 Mo",
    "downloadsStorageInfo": "Les tailles seront calculées automatiquement plus tard.",
    "downloadsStorageUserLabelValue": "Utilisateur : {size}",
    "downloadsStorageCacheLabelValue": "Cache : {size}",
    "downloadsStorageInfoValue": "Total utilisé : {size}",
    "downloadsClearCacheDialogTitle": "Vider le cache des téléchargements ?",
    "downloadsClearCacheDialogBody": "Cela supprimera les fichiers mis en cache sur cet appareil. Vous pourrez les télécharger de nouveau plus tard.",
    "downloadsClearCacheDialogConfirm": "Vider le cache",
    "downloadsExploreCta": "Explorer le contenu",
    "downloadsFilterAll": "Tout",
    "downloadsFilterFiles": "Fichiers",
    "downloadsFilterImages": "Images",
    "downloadsSortLabel": "Trier par",
    "downloadsSortNewest": "Les plus récents",
    "downloadsSortOldest": "Les plus anciens",
    "downloadsClearAllAction": "Tout supprimer",
    "downloadsClearAllDialogTitle": "Supprimer tous les téléchargements ?",
    "downloadsClearAllDialogBody": "Cela supprimera tous les fichiers téléchargés de cet appareil.",
    "downloadsClearAllDialogConfirm": "Tout supprimer",
    "downloadsClearAllSuccess": "Tous les téléchargements ont été supprimés.",
    "downloadsClearAllFailed": "Impossible de supprimer tous les téléchargements.",
    "downloadsDeleteDialogTitle": "Supprimer le téléchargement ?",
    "downloadsDeleteDialogBody": "Supprimer {fileName} de cet appareil ?",
    "downloadsDeleteSuccess": "Téléchargement supprimé.",
    "downloadsDeleteFailed": "Impossible de supprimer le téléchargement.",
    "downloadsLoadFailed": "Impossible de charger les téléchargements.",
    "downloadsUpdatedAt": "Mis à jour {date}",
    "favoritesTitle": "Favoris",
    "favoritesDescription": "Vos éléments enregistrés apparaissent ici.",
    "favoritesEmptyTitle": "Aucun favori",
    "favoritesEmptyHint": "Enregistrez des publications ou fichiers pour les voir ici.",
    "favoritesAddTitle": "Ajouter un favori",
    "favoritesAddHint": "Saisissez l'ID de l'élément",
    "favoritesAddTypeHint": "Type (optionnel)",
    "favoritesAddAction": "Enregistrer",
    "favoritesAdded": "Favori enregistré.",
    "favoritesRemoved": "Favori supprimé.",
    "favoritesSignInTitle": "Connectez-vous pour enregistrer des favoris",
    "favoritesSignInHint": "Les favoris se synchronisent avec votre compte.",
    "favoritesTypeLabel": "Type : {type}",
    "fontSizeTitle": "Taille de police",
    "fontSizeDescription": "Choisissez une taille de lecture confortable.",
    "fontSizeSmall": "Petite",
    "fontSizeMedium": "Moyenne",
    "fontSizeLarge": "Grande",
    "fontSizePreviewLabel": "Aperçu",
    "fontSizePreviewText": "Le vif renard brun saute par-dessus le chien paresseux.",
    "rateApp": "Évaluer l'application",
    "rateAppFailed": "Impossible d'ouvrir la boutique pour le moment.",
    "shareApp": "Partager l'application",
    "shareAppMessage": "Découvrez UniSpace pour des outils d'étude intelligents et une communauté étudiante !",
    "emailVerified": "E-mail vérifié",
    "emailNotVerified": "E-mail non vérifié",
    "sendOtpNow": "Envoyer l'OTP maintenant",
    "otpCooldownLabel": "Envoyer l'OTP dans {seconds}s",
    "otpSentSuccess": "OTP envoyé. Vérifiez votre e-mail.",
    "otpSentFailed": "Impossible d'envoyer l'OTP pour le moment.",
    "signInRequired": "Veuillez vous connecter pour continuer.",
    "guestUser": "Invité",
    "emailUnavailable": "E-mail indisponible",
    "emailHidden": "E-mail masqué",
    "aboutAppSummary": "Plateforme pour calculer la moyenne universitaire, échanger avec les étudiants et prendre des notes.",
    "aboutAppDescription": "Une plateforme universitaire intelligente qui aide les étudiants à organiser leurs études, calculer les moyennes, suivre les examens et planifier les révisions de manière simple et efficace.",
    "aboutAppFeatureGpa": "Calcul précis de la moyenne universitaire",
    "aboutAppFeatureReviewPlan": "Planificateur de révision intelligent",
    "aboutAppFeatureExams": "Calendrier des examens",
    "aboutAppFeatureNotes": "Prise de notes académiques",
    "aboutAppFeatureStudents": "Conçu spécialement pour les étudiants universitaires",
    "aboutAppViewLicenses": "Consulter les licences",
    "aboutAppFooter": "Développé avec Flutter",
    "commonCore1": "Tronc commun",
    "academicclass": "Section",
    "verificationEmailSent": "E-mail de vérification envoyé.",
    "emailNotVerifiedYet": "L'e-mail n'est pas encore vérifié. Veuillez ouvrir votre e-mail, cliquer sur le lien de vérification, puis réessayer.",
    "verifyEmailToContinue": "Veuillez vérifier votre e-mail pour continuer.",
    "verifyEmailHelper": "Ouvrez l'e-mail de vérification et cliquez sur le lien, puis appuyez sur vérifier maintenant.",
    "verifyEmailTitle": "Vérifier l'e-mail",
    "checkNow": "Vérifier maintenant",
    "resendVerificationEmail": "Renvoyer l'e-mail de vérification",
    "resendVerificationCooldown": "Renvoyer dans {seconds}s",
    "wrongPasswordError": "Mot de passe incorrect.",
    "emailAlreadyInUseError": "Cet e-mail est déjà utilisé.",
    "networkError": "Erreur réseau. Veuillez réessayer.",
    "weakPasswordError": "Le mot de passe est trop faible.",
    "emailAuthDisabledError": "La connexion par e-mail est désactivée.",
    "userDisabledError": "Ce compte est désactivé.",
    "genericAuthError": "Une erreur est survenue. Veuillez réessayer.",
    "privacyTabTitle": "Confidentialité",
    "privacyTabSubtitle": "Gérez vos données de compte en toute sécurité",
    "privacyAccountOverviewSection": "Aperçu du compte",
    "privacyNameRowTitle": "Prénom et nom",
    "privacyEmailRowTitle": "E-mail",
    "privacyNameRuleAllowed": "Vous pouvez modifier votre nom une fois par mois.",
    "privacyNameRuleBlockedDays": "Vous pouvez modifier votre nom après : {days} jour / {hours} heure",
    "privacyNameRuleBlockedHours": "Vous pouvez modifier votre nom après : {hours} heure",
    "privacyReauthTitle": "Confirmer le mot de passe",
    "privacyReauthSubtitle": "Pour votre sécurité, saisissez votre mot de passe actuel avant de continuer.",
    "privacyContinue": "Continuer",
    "privacyReauthFailed": "Échec de la vérification du mot de passe. Réessayez.",
    "privacyEditNameTitle": "Modifier le nom",
    "privacyFirstName": "Prénom",
    "privacyLastName": "Nom",
    "privacyNameValidationRequired": "Ce champ est requis",
    "privacyNameValidationShort": "Le nom doit contenir au moins 2 caractères",
    "privacyNameValidationLong": "Maximum 40 caractères",
    "privacyNameSaved": "Nom mis à jour avec succès.",
    "privacyEmailSaved": "E-mail mis à jour localement.",
    "privacyEmailFlowTitle": "Modifier l'e-mail",
    "privacyStepOf": "Étape {current} sur {total}",
    "privacyEmailFlowSecurityNote": "Note de sécurité : votre mot de passe n'est jamais stocké dans l'application.",
    "privacyEmailFlowStep1Help": "Saisissez votre e-mail actuel pour vérifier. Indice : {masked}",
    "privacyEmailCurrentLabel": "E-mail actuel",
    "privacyEmailFlowStep2Help": "Nous enverrons un lien de changement d'e-mail à votre boîte actuelle pour vérification.",
    "privacyEmailFlowSendLink": "Envoyer le lien de changement d'e-mail",
    "privacyEmailFlowStep3Help": "Saisissez votre nouvel e-mail et confirmez-le.",
    "privacyEmailNewLabel": "Nouvel e-mail",
    "privacyEmailConfirmLabel": "Confirmer le nouvel e-mail",
    "privacyEmailFlowStep4Help": "Vérifiez le nouvel e-mail : {masked}",
    "privacyEmailCurrentMismatch": "L'e-mail actuel ne correspond pas.",
    "privacyEmailValidationRequired": "Saisissez et confirmez le nouvel e-mail.",
    "privacyEmailConfirmMismatch": "Les e-mails ne correspondent pas.",
    "privacyLoadFailed": "Impossible de charger les données de confidentialité.",
    "securityPrivacyTitle": "Sécurité et confidentialité",
    "securitySegmentTitle": "Sécurité",
    "privacySegmentTitle": "Confidentialité",
    "privacyPasswordNewLengthError": "Le nouveau mot de passe doit contenir au moins 8 caractères.",
    "privacyPasswordMustDifferError": "Le nouveau mot de passe doit être différent de l'actuel.",
    "privacyPasswordMismatchError": "Les mots de passe ne correspondent pas.",
    "privacyPasswordStrengthWeak": "Faible",
    "privacyPasswordStrengthMedium": "Moyenne",
    "privacyPasswordStrengthStrong": "Forte",
    "privacyPasswordUpdateConfirmTitle": "Confirmer la mise à jour",
    "privacyPasswordUpdateConfirmBody": "Voulez-vous mettre à jour le mot de passe ?",
    "privacyPasswordUpdateAction": "Mettre à jour",
    "privacyPasswordUpdateRequiresSignin": "Impossible de mettre à jour le mot de passe. Veuillez vous reconnecter.",
    "privacyPasswordReauthFailedGeneric": "Impossible de vérifier votre identité. Réessayez plus tard.",
    "privacyPasswordUpdateSuccess": "Mot de passe mis à jour avec succès.",
    "privacyPasswordUpdateFailed": "Impossible de mettre à jour le mot de passe. Réessayez plus tard.",
    "privacyNotAvailable": "Non disponible",
    "privacyResetPasswordDialogBody": "Nous enverrons un lien de réinitialisation à votre e-mail enregistré : {maskedEmail}",
    "privacySendResetLinkAction": "Envoyer le lien",
    "privacyNoEmailLinked": "Aucun e-mail n'est lié à ce compte.",
    "privacyResetLinkSent": "Lien de réinitialisation envoyé à votre e-mail.",
    "privacyResetLinkFailed": "Impossible d'envoyer le lien. Réessayez plus tard.",
    "privacyNetworkCellular": "Données mobiles",
    "privacyUnknown": "Inconnu",
    "algeriaLabel": "Algérie",
    "privacyNoAuditDataYet": "Aucune donnée disponible pour le moment.",
    "privacyLastPasswordChangeTitle": "Dernier changement de mot de passe",
    "privacyDateTimeLabel": "Date et heure",
    "privacyDeviceLabel": "Appareil",
    "privacyManufacturerLabel": "Fabricant",
    "privacyOperatingSystemLabel": "Système d'exploitation",
    "privacyAppVersionLabel": "Version de l'application",
    "privacyConnectionTypeLabel": "Type de connexion",
    "privacyApproxLocationLabel": "Localisation approximative",
    "privacyIpAddressLabel": "Adresse IP",
    "privacyCopyFullIp": "Copier l'IP complète",
    "privacyThisWasNotMe": "Ce n'était pas moi",
    "privacyIpUnavailable": "Adresse IP indisponible.",
    "privacyCopyIpSuccess": "IP complète copiée en toute sécurité.",
    "privacyReauthCopyIpReason": "Vérifiez votre identité pour copier l'IP complète.",
    "privacySecurityAlertTitle": "Alerte de sécurité critique",
    "privacySecurityAlertBody": "Si vous n'avez pas changé le mot de passe, nous déconnecterons immédiatement toutes les autres sessions. Voulez-vous continuer ?",
    "privacyContinueAction": "Continuer",
    "privacyOtherSessionsRevokedPrecaution": "Les autres sessions ont été déconnectées par précaution.",
    "privacyRevokeSessionsFailed": "Impossible de terminer toutes les sessions pour le moment.",
    "privacyChangePasswordNowNote": "Veuillez changer votre mot de passe immédiatement. Vérification en deux étapes : bientôt disponible.",
    "privacyChangePasswordTitle": "Changer le mot de passe",
    "privacyCurrentPasswordLabel": "Mot de passe actuel",
    "privacyCurrentPasswordHelper": "Saisissez votre mot de passe actuel pour vérifier la propriété du compte.",
    "privacyResetEmailHint": "L'e-mail peut arriver dans une minute. Vérifiez aussi le dossier spam.",
    "privacyNewPasswordLabel": "Nouveau mot de passe",
    "privacyNewPasswordHelper": "Il doit contenir au moins 8 caractères.",
    "privacyPasswordStrengthLabel": "Solidité du mot de passe : ",
    "privacyConfirmNewPasswordLabel": "Confirmer le nouveau mot de passe",
    "privacyConfirmNewPasswordHelper": "Saisissez à nouveau le nouveau mot de passe pour confirmation.",
    "privacyEnterConfirmToMatch": "Saisissez la confirmation pour vérifier la correspondance.",
    "privacyPasswordsMatch": "Les mots de passe correspondent.",
    "privacyLoadingLastChange": "Chargement des données du dernier changement...",
    "privacyLastPasswordChangeUnavailable": "Dernier changement de mot de passe : Non disponible",
    "privacyLastPasswordChangeAt": "Dernier changement de mot de passe : {date}",
    "privacyViewDetails": "Voir les détails ⌄",
    "privacySaveNewPassword": "Enregistrer le nouveau mot de passe",
    "sessionAgoMinutes": "Il y a {minutes} min",
    "sessionAgoHours": "Il y a {hours} h",
    "sessionAgoDays": "Il y a {days} j",
    "sessionDeviceNameLabel": "Nom de l'appareil",
    "sessionTrustedDevice": "Appareil de confiance",
    "sessionModelLabel": "Modèle",
    "sessionPlatformLabel": "Plateforme",
    "sessionVersionLabel": "Version",
    "sessionLoginDateLabel": "Date de connexion",
    "sessionLastActivityLabel": "Dernière activité",
    "sessionNetworkLabel": "Réseau",
    "dangerZone": "Zone de danger",
    "gpu": "Calcul de la moyenne scolaire",
  },
  };
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales => const <Locale>[
        Locale("ar"),
        Locale("en"),
        Locale("fr"),
      ];

  @override
  bool isSupported(Locale locale) =>
      <String>{"ar", "en", "fr"}.contains(locale.languageCode);

  @override
  Future<S> load(Locale locale) => S.load(locale);

  @override
  bool shouldReload(AppLocalizationDelegate old) => false;
}
