// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Sections`
  String get sections {
    return Intl.message(
      'Sections',
      name: 'sections',
      desc: '',
      args: [],
    );
  }

  /// `Majors`
  String get majors {
    return Intl.message(
      'Majors',
      name: 'majors',
      desc: '',
      args: [],
    );
  }

  /// `Comments`
  String get comments {
    return Intl.message(
      'Comments',
      name: 'comments',
      desc: '',
      args: [],
    );
  }

  /// `Comment`
  String get comment {
    return Intl.message(
      'Comment',
      name: 'comment',
      desc: '',
      args: [],
    );
  }

  /// `Write your comment`
  String get writeYourComment {
    return Intl.message(
      'Write your comment',
      name: 'writeYourComment',
      desc: '',
      args: [],
    );
  }

  /// `Publish`
  String get publish {
    return Intl.message(
      'Publish',
      name: 'publish',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `Delete`
  String get delete {
    return Intl.message(
      'Delete',
      name: 'delete',
      desc: '',
      args: [],
    );
  }

  /// `Post`
  String get posted {
    return Intl.message(
      'Post',
      name: 'posted',
      desc: '',
      args: [],
    );
  }

  /// `Search inside Note-pade…`
  String get searchClipboard {
    return Intl.message(
      'Search inside Note-pade…',
      name: 'searchClipboard',
      desc: '',
      args: [],
    );
  }

  /// `Note`
  String get note {
    return Intl.message(
      'Note',
      name: 'note',
      desc: '',
      args: [],
    );
  }

  /// `Title`
  String get title {
    return Intl.message(
      'Title',
      name: 'title',
      desc: '',
      args: [],
    );
  }

  /// `Content`
  String get content {
    return Intl.message(
      'Content',
      name: 'content',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get save {
    return Intl.message(
      'Save',
      name: 'save',
      desc: '',
      args: [],
    );
  }

  /// `Pin Note`
  String get pinNote {
    return Intl.message(
      'Pin Note',
      name: 'pinNote',
      desc: '',
      args: [],
    );
  }

  /// `No notes yet`
  String get noNotesYet {
    return Intl.message(
      'No notes yet',
      name: 'noNotesYet',
      desc: '',
      args: [],
    );
  }

  /// `Archive`
  String get archive {
    return Intl.message(
      'Archive',
      name: 'archive',
      desc: '',
      args: [],
    );
  }

  /// `Home`
  String get home {
    return Intl.message(
      'Home',
      name: 'home',
      desc: '',
      args: [],
    );
  }

  /// `Community`
  String get community {
    return Intl.message(
      'Community',
      name: 'community',
      desc: '',
      args: [],
    );
  }

  /// `View All`
  String get viewAll {
    return Intl.message(
      'View All',
      name: 'viewAll',
      desc: '',
      args: [],
    );
  }

  /// `Faculties`
  String get faculties {
    return Intl.message(
      'Faculties',
      name: 'faculties',
      desc: '',
      args: [],
    );
  }

  /// `Note-pade`
  String get clipboard {
    return Intl.message(
      'Note-pade',
      name: 'clipboard',
      desc: '',
      args: [],
    );
  }

  /// `Change Theme`
  String get changeTheme {
    return Intl.message(
      'Change Theme',
      name: 'changeTheme',
      desc: '',
      args: [],
    );
  }

  /// `Change Language`
  String get changeLanguage {
    return Intl.message(
      'Change Language',
      name: 'changeLanguage',
      desc: '',
      args: [],
    );
  }

  /// `Reset Password`
  String get resetPassword {
    return Intl.message(
      'Reset Password',
      name: 'resetPassword',
      desc: '',
      args: [],
    );
  }

  /// `Logout`
  String get logout {
    return Intl.message(
      'Logout',
      name: 'logout',
      desc: '',
      args: [],
    );
  }

  /// `Login`
  String get login {
    return Intl.message(
      'Login',
      name: 'login',
      desc: '',
      args: [],
    );
  }

  /// `About the App`
  String get aboutApp {
    return Intl.message(
      'About the App',
      name: 'aboutApp',
      desc: '',
      args: [],
    );
  }

  /// `Privacy Policy`
  String get privacyPolicy {
    return Intl.message(
      'Privacy Policy',
      name: 'privacyPolicy',
      desc: '',
      args: [],
    );
  }

  /// `Privacy Policy`
  String get privacyPolicyTitle {
    return Intl.message(
      'Privacy Policy',
      name: 'privacyPolicyTitle',
      desc: '',
      args: [],
    );
  }

  /// `Please review our privacy policy.`
  String get privacyPolicyBody {
    return Intl.message(
      'Please review our privacy policy.',
      name: 'privacyPolicyBody',
      desc: '',
      args: [],
    );
  }

  /// `Welcome 👋`
  String get welcomeEmoji {
    return Intl.message(
      'Welcome 👋',
      name: 'welcomeEmoji',
      desc: '',
      args: [],
    );
  }

  /// `Browse faculties, calculate your GPA, share your ideas, and write notes easily.`
  String get homeSubtitle {
    return Intl.message(
      'Browse faculties, calculate your GPA, share your ideas, and write notes easily.',
      name: 'homeSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Search for a faculty...`
  String get searchFaculty {
    return Intl.message(
      'Search for a faculty...',
      name: 'searchFaculty',
      desc: '',
      args: [],
    );
  }

  /// `Start typing to search`
  String get searchStartTyping {
    return Intl.message(
      'Start typing to search',
      name: 'searchStartTyping',
      desc: '',
      args: [],
    );
  }

  /// `No results found`
  String get searchNoResults {
    return Intl.message(
      'No results found',
      name: 'searchNoResults',
      desc: '',
      args: [],
    );
  }

  /// `Quick Calculation`
  String get quickCalc {
    return Intl.message(
      'Quick Calculation',
      name: 'quickCalc',
      desc: '',
      args: [],
    );
  }

  /// `Welcome to UniSpace`
  String get welcomeUniSpace {
    return Intl.message(
      'Welcome to UniSpace',
      name: 'welcomeUniSpace',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get email {
    return Intl.message(
      'Email',
      name: 'email',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get password {
    return Intl.message(
      'Password',
      name: 'password',
      desc: '',
      args: [],
    );
  }

  /// `Forgot password?`
  String get forgotPassword {
    return Intl.message(
      'Forgot password?',
      name: 'forgotPassword',
      desc: '',
      args: [],
    );
  }

  /// `Reset your password`
  String get resetPasswordTitle {
    return Intl.message(
      'Reset your password',
      name: 'resetPasswordTitle',
      desc: '',
      args: [],
    );
  }

  /// `Enter your email and we’ll send you a reset link.`
  String get resetPasswordHelper {
    return Intl.message(
      'Enter your email and we’ll send you a reset link.',
      name: 'resetPasswordHelper',
      desc: '',
      args: [],
    );
  }

  /// `Send link`
  String get sendResetLink {
    return Intl.message(
      'Send link',
      name: 'sendResetLink',
      desc: '',
      args: [],
    );
  }

  /// `Sending...`
  String get sendResetLinkLoading {
    return Intl.message(
      'Sending...',
      name: 'sendResetLinkLoading',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a valid email address.`
  String get invalidEmailValidation {
    return Intl.message(
      'Please enter a valid email address.',
      name: 'invalidEmailValidation',
      desc: '',
      args: [],
    );
  }

  /// `The reset link was sent to your email.`
  String get resetLinkSentSuccess {
    return Intl.message(
      'The reset link was sent to your email.',
      name: 'resetLinkSentSuccess',
      desc: '',
      args: [],
    );
  }

  /// `The email address is invalid.`
  String get invalidEmailError {
    return Intl.message(
      'The email address is invalid.',
      name: 'invalidEmailError',
      desc: '',
      args: [],
    );
  }

  /// `No account found with that email.`
  String get userNotFoundError {
    return Intl.message(
      'No account found with that email.',
      name: 'userNotFoundError',
      desc: '',
      args: [],
    );
  }

  /// `Too many requests, try again later.`
  String get tooManyRequestsError {
    return Intl.message(
      'Too many requests, try again later.',
      name: 'tooManyRequestsError',
      desc: '',
      args: [],
    );
  }

  /// `Could not send the link, please try again.`
  String get resetLinkFailed {
    return Intl.message(
      'Could not send the link, please try again.',
      name: 'resetLinkFailed',
      desc: '',
      args: [],
    );
  }

  /// `Reset link has been sent`
  String get resetSent {
    return Intl.message(
      'Reset link has been sent',
      name: 'resetSent',
      desc: '',
      args: [],
    );
  }

  /// `Failed to send: {e}`
  String resetFailed(Object e) {
    return Intl.message(
      'Failed to send: $e',
      name: 'resetFailed',
      desc: '',
      args: [e],
    );
  }

  /// `Not registered`
  String get notRegistered {
    return Intl.message(
      'Not registered',
      name: 'notRegistered',
      desc: '',
      args: [],
    );
  }

  /// `Pinned`
  String get pinned {
    return Intl.message(
      'Pinned',
      name: 'pinned',
      desc: '',
      args: [],
    );
  }

  /// `Other Notes`
  String get otherNotes {
    return Intl.message(
      'Other Notes',
      name: 'otherNotes',
      desc: '',
      args: [],
    );
  }

  /// `No posts yet`
  String get noPostsYet {
    return Intl.message(
      'No posts yet',
      name: 'noPostsYet',
      desc: '',
      args: [],
    );
  }

  /// `Start the first discussion in the community and share your experience with colleagues.`
  String get startDiscussion {
    return Intl.message(
      'Start the first discussion in the community and share your experience with colleagues.',
      name: 'startDiscussion',
      desc: '',
      args: [],
    );
  }

  /// `Post`
  String get createPost {
    return Intl.message(
      'Post',
      name: 'createPost',
      desc: '',
      args: [],
    );
  }

  /// `New Post`
  String get newPost {
    return Intl.message(
      'New Post',
      name: 'newPost',
      desc: '',
      args: [],
    );
  }

  /// `Image/Video URL`
  String get mediaUrl {
    return Intl.message(
      'Image/Video URL',
      name: 'mediaUrl',
      desc: '',
      args: [],
    );
  }

  /// `#`
  String get hashtag {
    return Intl.message(
      '#',
      name: 'hashtag',
      desc: '',
      args: [],
    );
  }

  /// `Share`
  String get share {
    return Intl.message(
      'Share',
      name: 'share',
      desc: '',
      args: [],
    );
  }

  /// `Report`
  String get report {
    return Intl.message(
      'Report',
      name: 'report',
      desc: '',
      args: [],
    );
  }

  /// `تعليقات ({count})`
  String commentsCount(Object count) {
    return Intl.message(
      'تعليقات ($count)',
      name: 'commentsCount',
      desc: '',
      args: [count],
    );
  }

  /// `Write your comment…`
  String get writeComment {
    return Intl.message(
      'Write your comment…',
      name: 'writeComment',
      desc: '',
      args: [],
    );
  }

  /// `Quick Calc`
  String get quickCalc2 {
    return Intl.message(
      'Quick Calc',
      name: 'quickCalc2',
      desc: '',
      args: [],
    );
  }

  /// `Add`
  String get add {
    return Intl.message(
      'Add',
      name: 'add',
      desc: '',
      args: [],
    );
  }

  /// `Calculate`
  String get calculate {
    return Intl.message(
      'Calculate',
      name: 'calculate',
      desc: '',
      args: [],
    );
  }

  /// ` Passed`
  String get pass {
    return Intl.message(
      ' Passed',
      name: 'pass',
      desc: '',
      args: [],
    );
  }

  /// ` Failed`
  String get fail {
    return Intl.message(
      ' Failed',
      name: 'fail',
      desc: '',
      args: [],
    );
  }

  /// `Credits:`
  String get credits {
    return Intl.message(
      'Credits:',
      name: 'credits',
      desc: '',
      args: [],
    );
  }

  /// `Light Mode`
  String get lightMode {
    return Intl.message(
      'Light Mode',
      name: 'lightMode',
      desc: '',
      args: [],
    );
  }

  /// `Dark Mode`
  String get darkMode {
    return Intl.message(
      'Dark Mode',
      name: 'darkMode',
      desc: '',
      args: [],
    );
  }

  /// `System Mode`
  String get systemMode {
    return Intl.message(
      'System Mode',
      name: 'systemMode',
      desc: '',
      args: [],
    );
  }

  /// `UniSpace does not collect personal data outside Firebase. All data is secure.`
  String get aboutAppDetails {
    return Intl.message(
      'UniSpace does not collect personal data outside Firebase. All data is secure.',
      name: 'aboutAppDetails',
      desc: '',
      args: [],
    );
  }

  /// `Choose Theme`
  String get chooseTheme {
    return Intl.message(
      'Choose Theme',
      name: 'chooseTheme',
      desc: '',
      args: [],
    );
  }

  /// `Light`
  String get light {
    return Intl.message(
      'Light',
      name: 'light',
      desc: '',
      args: [],
    );
  }

  /// `Dark`
  String get dark {
    return Intl.message(
      'Dark',
      name: 'dark',
      desc: '',
      args: [],
    );
  }

  /// `System`
  String get system {
    return Intl.message(
      'System',
      name: 'system',
      desc: '',
      args: [],
    );
  }

  /// `Choose Language`
  String get chooseLanguage {
    return Intl.message(
      'Choose Language',
      name: 'chooseLanguage',
      desc: '',
      args: [],
    );
  }

  /// `Arabic`
  String get arabic {
    return Intl.message(
      'Arabic',
      name: 'arabic',
      desc: '',
      args: [],
    );
  }

  /// `Register`
  String get register {
    return Intl.message(
      'Register',
      name: 'register',
      desc: '',
      args: [],
    );
  }

  /// `Your post has been published ✅`
  String get post {
    return Intl.message(
      'Your post has been published ✅',
      name: 'post',
      desc: '',
      args: [],
    );
  }

  /// `Create a post`
  String get createPoste {
    return Intl.message(
      'Create a post',
      name: 'createPoste',
      desc: '',
      args: [],
    );
  }

  /// `One major`
  String get oneMajor {
    return Intl.message(
      'One major',
      name: 'oneMajor',
      desc: '',
      args: [],
    );
  }

  /// `No majors yet`
  String get noMajorsYet {
    return Intl.message(
      'No majors yet',
      name: 'noMajorsYet',
      desc: '',
      args: [],
    );
  }

  /// `Edit Weights`
  String get editWeights {
    return Intl.message(
      'Edit Weights',
      name: 'editWeights',
      desc: '',
      args: [],
    );
  }

  /// `Faculty of Economics, Commerce, and Management Sciences`
  String get facultyEconomics {
    return Intl.message(
      'Faculty of Economics, Commerce, and Management Sciences',
      name: 'facultyEconomics',
      desc: '',
      args: [],
    );
  }

  /// `Basic Education Department`
  String get basicEducationDept {
    return Intl.message(
      'Basic Education Department',
      name: 'basicEducationDept',
      desc: '',
      args: [],
    );
  }

  /// `Basic Education`
  String get basicEducation {
    return Intl.message(
      'Basic Education',
      name: 'basicEducation',
      desc: '',
      args: [],
    );
  }

  /// `Department of Management Sciences`
  String get managementSciencesDept {
    return Intl.message(
      'Department of Management Sciences',
      name: 'managementSciencesDept',
      desc: '',
      args: [],
    );
  }

  /// `Management Sciences`
  String get managementSciences {
    return Intl.message(
      'Management Sciences',
      name: 'managementSciences',
      desc: '',
      args: [],
    );
  }

  /// `Business Administration`
  String get businessAdministration {
    return Intl.message(
      'Business Administration',
      name: 'businessAdministration',
      desc: '',
      args: [],
    );
  }

  /// `Financial Management`
  String get financialManagement {
    return Intl.message(
      'Financial Management',
      name: 'financialManagement',
      desc: '',
      args: [],
    );
  }

  /// `Human Resources Management`
  String get humanResourcesManagement {
    return Intl.message(
      'Human Resources Management',
      name: 'humanResourcesManagement',
      desc: '',
      args: [],
    );
  }

  /// `Corporate Financial Management`
  String get corporateFinancialManagement {
    return Intl.message(
      'Corporate Financial Management',
      name: 'corporateFinancialManagement',
      desc: '',
      args: [],
    );
  }

  /// `Department of Commercial Sciences`
  String get commercialSciencesDept {
    return Intl.message(
      'Department of Commercial Sciences',
      name: 'commercialSciencesDept',
      desc: '',
      args: [],
    );
  }

  /// `Commercial Sciences`
  String get commercialSciences {
    return Intl.message(
      'Commercial Sciences',
      name: 'commercialSciences',
      desc: '',
      args: [],
    );
  }

  /// `Finance and International Trade`
  String get financeInternationalTrade {
    return Intl.message(
      'Finance and International Trade',
      name: 'financeInternationalTrade',
      desc: '',
      args: [],
    );
  }

  /// `Marketing`
  String get marketing {
    return Intl.message(
      'Marketing',
      name: 'marketing',
      desc: '',
      args: [],
    );
  }

  /// `Services Marketing`
  String get servicesMarketing {
    return Intl.message(
      'Services Marketing',
      name: 'servicesMarketing',
      desc: '',
      args: [],
    );
  }

  /// `Hotel and Tourism Marketing`
  String get hotelTourismMarketing {
    return Intl.message(
      'Hotel and Tourism Marketing',
      name: 'hotelTourismMarketing',
      desc: '',
      args: [],
    );
  }

  /// `Department of Financial and Accounting Sciences`
  String get financialAccountingDept {
    return Intl.message(
      'Department of Financial and Accounting Sciences',
      name: 'financialAccountingDept',
      desc: '',
      args: [],
    );
  }

  /// `Financial and Accounting Sciences`
  String get financialAccounting {
    return Intl.message(
      'Financial and Accounting Sciences',
      name: 'financialAccounting',
      desc: '',
      args: [],
    );
  }

  /// `Finance`
  String get finance {
    return Intl.message(
      'Finance',
      name: 'finance',
      desc: '',
      args: [],
    );
  }

  /// `Accounting`
  String get accounting {
    return Intl.message(
      'Accounting',
      name: 'accounting',
      desc: '',
      args: [],
    );
  }

  /// `Accounting and Taxation`
  String get accountingTaxation {
    return Intl.message(
      'Accounting and Taxation',
      name: 'accountingTaxation',
      desc: '',
      args: [],
    );
  }

  /// `Corporate Finance`
  String get corporateFinance {
    return Intl.message(
      'Corporate Finance',
      name: 'corporateFinance',
      desc: '',
      args: [],
    );
  }

  /// `Department of Economics`
  String get economicsDept {
    return Intl.message(
      'Department of Economics',
      name: 'economicsDept',
      desc: '',
      args: [],
    );
  }

  /// `Economics`
  String get economics {
    return Intl.message(
      'Economics',
      name: 'economics',
      desc: '',
      args: [],
    );
  }

  /// `Monetary and Financial Economics`
  String get monetaryFinancialEconomics {
    return Intl.message(
      'Monetary and Financial Economics',
      name: 'monetaryFinancialEconomics',
      desc: '',
      args: [],
    );
  }

  /// `International Economics`
  String get internationalEconomics {
    return Intl.message(
      'International Economics',
      name: 'internationalEconomics',
      desc: '',
      args: [],
    );
  }

  /// `No subjects in this semester.`
  String get noSubjectsThisSemester {
    return Intl.message(
      'No subjects in this semester.',
      name: 'noSubjectsThisSemester',
      desc: '',
      args: [],
    );
  }

  /// `Coef:`
  String get coefficient {
    return Intl.message(
      'Coef:',
      name: 'coefficient',
      desc: '',
      args: [],
    );
  }

  /// `Close`
  String get close {
    return Intl.message(
      'Close',
      name: 'close',
      desc: '',
      args: [],
    );
  }

  /// `Study Results`
  String get studyResults {
    return Intl.message(
      'Study Results',
      name: 'studyResults',
      desc: '',
      args: [],
    );
  }

  /// `Grades (TD/TP/Exam)`
  String get notesTdTpExam {
    return Intl.message(
      'Grades (TD/TP/Exam)',
      name: 'notesTdTpExam',
      desc: '',
      args: [],
    );
  }

  /// `Faculty of Law and Political Sciences`
  String get facultyLawPolitical {
    return Intl.message(
      'Faculty of Law and Political Sciences',
      name: 'facultyLawPolitical',
      desc: '',
      args: [],
    );
  }

  /// `Political Sciences`
  String get politicalSciences {
    return Intl.message(
      'Political Sciences',
      name: 'politicalSciences',
      desc: '',
      args: [],
    );
  }

  /// `Common Core`
  String get commonCore {
    return Intl.message(
      'Common Core',
      name: 'commonCore',
      desc: '',
      args: [],
    );
  }

  /// `Basic Unit`
  String get basicUnit {
    return Intl.message(
      'Basic Unit',
      name: 'basicUnit',
      desc: '',
      args: [],
    );
  }

  /// `Methodological Unit`
  String get methodologicalUnit {
    return Intl.message(
      'Methodological Unit',
      name: 'methodologicalUnit',
      desc: '',
      args: [],
    );
  }

  /// `Exploratory Unit`
  String get exploratoryUnit {
    return Intl.message(
      'Exploratory Unit',
      name: 'exploratoryUnit',
      desc: '',
      args: [],
    );
  }

  /// `Horizontal Unit`
  String get horizontalUnit {
    return Intl.message(
      'Horizontal Unit',
      name: 'horizontalUnit',
      desc: '',
      args: [],
    );
  }

  /// `Political and Administrative Organizations`
  String get politicalAdministrativeOrgs {
    return Intl.message(
      'Political and Administrative Organizations',
      name: 'politicalAdministrativeOrgs',
      desc: '',
      args: [],
    );
  }

  /// `Law`
  String get law {
    return Intl.message(
      'Law',
      name: 'law',
      desc: '',
      args: [],
    );
  }

  /// `Public Law`
  String get publicLaw {
    return Intl.message(
      'Public Law',
      name: 'publicLaw',
      desc: '',
      args: [],
    );
  }

  /// `Private Law`
  String get privateLaw {
    return Intl.message(
      'Private Law',
      name: 'privateLaw',
      desc: '',
      args: [],
    );
  }

  /// `Advanced Public Law`
  String get advancedPublicLaw {
    return Intl.message(
      'Advanced Public Law',
      name: 'advancedPublicLaw',
      desc: '',
      args: [],
    );
  }

  /// `Family Law`
  String get familyLaw {
    return Intl.message(
      'Family Law',
      name: 'familyLaw',
      desc: '',
      args: [],
    );
  }

  /// `Criminal Law and Criminal Sciences`
  String get criminalLaw {
    return Intl.message(
      'Criminal Law and Criminal Sciences',
      name: 'criminalLaw',
      desc: '',
      args: [],
    );
  }

  /// `Business Law`
  String get businessLaw {
    return Intl.message(
      'Business Law',
      name: 'businessLaw',
      desc: '',
      args: [],
    );
  }

  /// `Legal and Judicial Professions Law`
  String get legalProfessionsLaw {
    return Intl.message(
      'Legal and Judicial Professions Law',
      name: 'legalProfessionsLaw',
      desc: '',
      args: [],
    );
  }

  /// `Maritime and Port Law`
  String get maritimePortLaw {
    return Intl.message(
      'Maritime and Port Law',
      name: 'maritimePortLaw',
      desc: '',
      args: [],
    );
  }

  /// `Energy and Mining Law`
  String get energyMiningLaw {
    return Intl.message(
      'Energy and Mining Law',
      name: 'energyMiningLaw',
      desc: '',
      args: [],
    );
  }

  /// `Tax Law`
  String get taxLaw {
    return Intl.message(
      'Tax Law',
      name: 'taxLaw',
      desc: '',
      args: [],
    );
  }

  /// `International Relations`
  String get internationalRelations {
    return Intl.message(
      'International Relations',
      name: 'internationalRelations',
      desc: '',
      args: [],
    );
  }

  /// `International Cooperation`
  String get internationalCooperation {
    return Intl.message(
      'International Cooperation',
      name: 'internationalCooperation',
      desc: '',
      args: [],
    );
  }

  /// `Local Administration`
  String get localAdministration {
    return Intl.message(
      'Local Administration',
      name: 'localAdministration',
      desc: '',
      args: [],
    );
  }

  /// `Contact Us`
  String get contactUs {
    return Intl.message(
      'Contact Us',
      name: 'contactUs',
      desc: '',
      args: [],
    );
  }

  /// `Block Account`
  String get blockAccount {
    return Intl.message(
      'Block Account',
      name: 'blockAccount',
      desc: '',
      args: [],
    );
  }

  /// `Follow Comment`
  String get followComment {
    return Intl.message(
      'Follow Comment',
      name: 'followComment',
      desc: '',
      args: [],
    );
  }

  /// `Copy Text`
  String get copyText {
    return Intl.message(
      'Copy Text',
      name: 'copyText',
      desc: '',
      args: [],
    );
  }

  /// `Hide`
  String get hide {
    return Intl.message(
      'Hide',
      name: 'hide',
      desc: '',
      args: [],
    );
  }

  /// `Save Post`
  String get savePost {
    return Intl.message(
      'Save Post',
      name: 'savePost',
      desc: '',
      args: [],
    );
  }

  /// `University`
  String get university {
    return Intl.message(
      'University',
      name: 'university',
      desc: '',
      args: [],
    );
  }

  /// `Faculty`
  String get faculty {
    return Intl.message(
      'Faculty',
      name: 'faculty',
      desc: '',
      args: [],
    );
  }

  /// `Department`
  String get department {
    return Intl.message(
      'Department',
      name: 'department',
      desc: '',
      args: [],
    );
  }

  /// `Major`
  String get major {
    return Intl.message(
      'Major',
      name: 'major',
      desc: '',
      args: [],
    );
  }

  /// `Mood`
  String get mood {
    return Intl.message(
      'Mood',
      name: 'mood',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get name {
    return Intl.message(
      'Name',
      name: 'name',
      desc: '',
      args: [],
    );
  }

  /// `Posts`
  String get posts {
    return Intl.message(
      'Posts',
      name: 'posts',
      desc: '',
      args: [],
    );
  }

  /// `Profile`
  String get profile {
    return Intl.message(
      'Profile',
      name: 'profile',
      desc: '',
      args: [],
    );
  }

  /// `Following`
  String get following {
    return Intl.message(
      'Following',
      name: 'following',
      desc: '',
      args: [],
    );
  }

  /// `User Information`
  String get userInfo {
    return Intl.message(
      'User Information',
      name: 'userInfo',
      desc: '',
      args: [],
    );
  }

  /// `Faculty of Arts and Foreign Languages`
  String get facultyArtsLanguages {
    return Intl.message(
      'Faculty of Arts and Foreign Languages',
      name: 'facultyArtsLanguages',
      desc: '',
      args: [],
    );
  }

  /// `Department of Arabic Language and Literature`
  String get deptArabicLangLit {
    return Intl.message(
      'Department of Arabic Language and Literature',
      name: 'deptArabicLangLit',
      desc: '',
      args: [],
    );
  }

  /// `Department of French Language and Literature`
  String get deptFrenchLangLit {
    return Intl.message(
      'Department of French Language and Literature',
      name: 'deptFrenchLangLit',
      desc: '',
      args: [],
    );
  }

  /// `Department of English Language and Literature`
  String get deptEnglishLangLit {
    return Intl.message(
      'Department of English Language and Literature',
      name: 'deptEnglishLangLit',
      desc: '',
      args: [],
    );
  }

  /// `We are happy to hear from you. Send your message to support.`
  String get contactUsSubtitle {
    return Intl.message(
      'We are happy to hear from you. Send your message to support.',
      name: 'contactUsSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Category`
  String get contactCategoryLabel {
    return Intl.message(
      'Category',
      name: 'contactCategoryLabel',
      desc: '',
      args: [],
    );
  }

  /// `Issue`
  String get contactCategoryIssue {
    return Intl.message(
      'Issue',
      name: 'contactCategoryIssue',
      desc: '',
      args: [],
    );
  }

  /// `New feature suggestion`
  String get contactCategoryFeature {
    return Intl.message(
      'New feature suggestion',
      name: 'contactCategoryFeature',
      desc: '',
      args: [],
    );
  }

  /// `Improvement`
  String get contactCategoryImprovement {
    return Intl.message(
      'Improvement',
      name: 'contactCategoryImprovement',
      desc: '',
      args: [],
    );
  }

  /// `Report`
  String get contactCategoryReport {
    return Intl.message(
      'Report',
      name: 'contactCategoryReport',
      desc: '',
      args: [],
    );
  }

  /// `Other`
  String get contactCategoryOther {
    return Intl.message(
      'Other',
      name: 'contactCategoryOther',
      desc: '',
      args: [],
    );
  }

  /// `Subject`
  String get contactSubjectLabel {
    return Intl.message(
      'Subject',
      name: 'contactSubjectLabel',
      desc: '',
      args: [],
    );
  }

  /// `Short summary of your request`
  String get contactSubjectHint {
    return Intl.message(
      'Short summary of your request',
      name: 'contactSubjectHint',
      desc: '',
      args: [],
    );
  }

  /// `Description`
  String get contactDescriptionLabel {
    return Intl.message(
      'Description',
      name: 'contactDescriptionLabel',
      desc: '',
      args: [],
    );
  }

  /// `Explain the details so we can help quickly`
  String get contactDescriptionHint {
    return Intl.message(
      'Explain the details so we can help quickly',
      name: 'contactDescriptionHint',
      desc: '',
      args: [],
    );
  }

  /// `Attach a screenshot`
  String get contactScreenshotPlaceholder {
    return Intl.message(
      'Attach a screenshot',
      name: 'contactScreenshotPlaceholder',
      desc: '',
      args: [],
    );
  }

  /// `Coming soon`
  String get contactScreenshotSoon {
    return Intl.message(
      'Coming soon',
      name: 'contactScreenshotSoon',
      desc: '',
      args: [],
    );
  }

  /// `Include my account information`
  String get contactIncludeUserInfo {
    return Intl.message(
      'Include my account information',
      name: 'contactIncludeUserInfo',
      desc: '',
      args: [],
    );
  }

  /// `No signed-in user information available`
  String get contactUserInfoUnavailable {
    return Intl.message(
      'No signed-in user information available',
      name: 'contactUserInfoUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `Send`
  String get contactSend {
    return Intl.message(
      'Send',
      name: 'contactSend',
      desc: '',
      args: [],
    );
  }

  /// `This field is required`
  String get contactValidationRequired {
    return Intl.message(
      'This field is required',
      name: 'contactValidationRequired',
      desc: '',
      args: [],
    );
  }

  /// `Please enter at least {min} characters`
  String contactValidationMinLength(Object min) {
    return Intl.message(
      'Please enter at least $min characters',
      name: 'contactValidationMinLength',
      desc: '',
      args: [min],
    );
  }

  /// `Please keep this under {max} characters`
  String contactValidationMaxLength(Object max) {
    return Intl.message(
      'Please keep this under $max characters',
      name: 'contactValidationMaxLength',
      desc: '',
      args: [max],
    );
  }

  /// `Sending...`
  String get contactSending {
    return Intl.message(
      'Sending...',
      name: 'contactSending',
      desc: '',
      args: [],
    );
  }

  /// `Sent ✅`
  String get contactSendSuccess {
    return Intl.message(
      'Sent ✅',
      name: 'contactSendSuccess',
      desc: '',
      args: [],
    );
  }

  /// `We couldn't send your message. Please try again.`
  String get contactSendFailure {
    return Intl.message(
      'We couldn\'t send your message. Please try again.',
      name: 'contactSendFailure',
      desc: '',
      args: [],
    );
  }

  /// `Email app opened to send your message`
  String get contactMailOpened {
    return Intl.message(
      'Email app opened to send your message',
      name: 'contactMailOpened',
      desc: '',
      args: [],
    );
  }

  /// `Email app not available. You can copy the message instead.`
  String get contactMailUnavailable {
    return Intl.message(
      'Email app not available. You can copy the message instead.',
      name: 'contactMailUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `Copy message`
  String get contactCopyDialogTitle {
    return Intl.message(
      'Copy message',
      name: 'contactCopyDialogTitle',
      desc: '',
      args: [],
    );
  }

  /// `Copy the message and send it to support via your email app.`
  String get contactCopyDialogBody {
    return Intl.message(
      'Copy the message and send it to support via your email app.',
      name: 'contactCopyDialogBody',
      desc: '',
      args: [],
    );
  }

  /// `Copy`
  String get contactCopyAction {
    return Intl.message(
      'Copy',
      name: 'contactCopyAction',
      desc: '',
      args: [],
    );
  }

  /// `Message copied`
  String get contactCopied {
    return Intl.message(
      'Message copied',
      name: 'contactCopied',
      desc: '',
      args: [],
    );
  }

  /// `Metadata`
  String get contactMetadataHeader {
    return Intl.message(
      'Metadata',
      name: 'contactMetadataHeader',
      desc: '',
      args: [],
    );
  }

  /// `User ID`
  String get contactMetadataUserId {
    return Intl.message(
      'User ID',
      name: 'contactMetadataUserId',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get contactMetadataEmail {
    return Intl.message(
      'Email',
      name: 'contactMetadataEmail',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get contactMetadataName {
    return Intl.message(
      'Name',
      name: 'contactMetadataName',
      desc: '',
      args: [],
    );
  }

  /// `Platform`
  String get contactMetadataPlatform {
    return Intl.message(
      'Platform',
      name: 'contactMetadataPlatform',
      desc: '',
      args: [],
    );
  }

  /// `Locale`
  String get contactMetadataLocale {
    return Intl.message(
      'Locale',
      name: 'contactMetadataLocale',
      desc: '',
      args: [],
    );
  }

  /// `Timestamp`
  String get contactMetadataTimestamp {
    return Intl.message(
      'Timestamp',
      name: 'contactMetadataTimestamp',
      desc: '',
      args: [],
    );
  }

  /// `App version`
  String get contactMetadataAppVersion {
    return Intl.message(
      'App version',
      name: 'contactMetadataAppVersion',
      desc: '',
      args: [],
    );
  }

  /// `Exam Calendar`
  String get examCalendar {
    return Intl.message(
      'Exam Calendar',
      name: 'examCalendar',
      desc: '',
      args: [],
    );
  }

  /// `Smart review plan`
  String get smartReviewPlanTitle {
    return Intl.message(
      'Smart review plan',
      name: 'smartReviewPlanTitle',
      desc: '',
      args: [],
    );
  }

  /// `Generate a focused review plan based on your upcoming exams and study goals.`
  String get smartReviewPlanDescription {
    return Intl.message(
      'Generate a focused review plan based on your upcoming exams and study goals.',
      name: 'smartReviewPlanDescription',
      desc: '',
      args: [],
    );
  }

  /// `Create a plan`
  String get smartReviewPlanCtaCreate {
    return Intl.message(
      'Create a plan',
      name: 'smartReviewPlanCtaCreate',
      desc: '',
      args: [],
    );
  }

  /// `Coming soon`
  String get smartReviewPlanComingSoon {
    return Intl.message(
      'Coming soon',
      name: 'smartReviewPlanComingSoon',
      desc: '',
      args: [],
    );
  }

  /// `Smart Review Plan`
  String get smartReviewTitle {
    return Intl.message(
      'Smart Review Plan',
      name: 'smartReviewTitle',
      desc: '',
      args: [],
    );
  }

  /// `Turn upcoming exams into a balanced, achievable daily plan.`
  String get smartReviewSubtitle {
    return Intl.message(
      'Turn upcoming exams into a balanced, achievable daily plan.',
      name: 'smartReviewSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Create review plan`
  String get smartReviewCtaCreate {
    return Intl.message(
      'Create review plan',
      name: 'smartReviewCtaCreate',
      desc: '',
      args: [],
    );
  }

  /// `Exam-aware`
  String get smartReviewChipExams {
    return Intl.message(
      'Exam-aware',
      name: 'smartReviewChipExams',
      desc: '',
      args: [],
    );
  }

  /// `Time-smart`
  String get smartReviewChipTime {
    return Intl.message(
      'Time-smart',
      name: 'smartReviewChipTime',
      desc: '',
      args: [],
    );
  }

  /// `Reminders`
  String get smartReviewChipReminders {
    return Intl.message(
      'Reminders',
      name: 'smartReviewChipReminders',
      desc: '',
      args: [],
    );
  }

  /// `Easy to follow`
  String get smartReviewChipSimple {
    return Intl.message(
      'Easy to follow',
      name: 'smartReviewChipSimple',
      desc: '',
      args: [],
    );
  }

  /// `Preview your week`
  String get smartReviewPreviewTitle {
    return Intl.message(
      'Preview your week',
      name: 'smartReviewPreviewTitle',
      desc: '',
      args: [],
    );
  }

  /// `Today · 2 focus sessions (45 min)`
  String get smartReviewPreviewItem1 {
    return Intl.message(
      'Today · 2 focus sessions (45 min)',
      name: 'smartReviewPreviewItem1',
      desc: '',
      args: [],
    );
  }

  /// `Tomorrow · 1 mock quiz + recap`
  String get smartReviewPreviewItem2 {
    return Intl.message(
      'Tomorrow · 1 mock quiz + recap',
      name: 'smartReviewPreviewItem2',
      desc: '',
      args: [],
    );
  }

  /// `This week · Prioritize hardest subjects`
  String get smartReviewPreviewItem3 {
    return Intl.message(
      'This week · Prioritize hardest subjects',
      name: 'smartReviewPreviewItem3',
      desc: '',
      args: [],
    );
  }

  /// `Before we build your plan`
  String get smartReviewBottomSheetTitle {
    return Intl.message(
      'Before we build your plan',
      name: 'smartReviewBottomSheetTitle',
      desc: '',
      args: [],
    );
  }

  /// `Add your subjects and exam dates so we can personalize your schedule.`
  String get smartReviewBottomSheetBody {
    return Intl.message(
      'Add your subjects and exam dates so we can personalize your schedule.',
      name: 'smartReviewBottomSheetBody',
      desc: '',
      args: [],
    );
  }

  /// `Add subjects`
  String get smartReviewActionAddSubjects {
    return Intl.message(
      'Add subjects',
      name: 'smartReviewActionAddSubjects',
      desc: '',
      args: [],
    );
  }

  /// `Add exam`
  String get smartReviewActionAddExam {
    return Intl.message(
      'Add exam',
      name: 'smartReviewActionAddExam',
      desc: '',
      args: [],
    );
  }

  /// `Maybe later`
  String get smartReviewActionLater {
    return Intl.message(
      'Maybe later',
      name: 'smartReviewActionLater',
      desc: '',
      args: [],
    );
  }

  /// `How it works`
  String get smartReviewTipsTitle {
    return Intl.message(
      'How it works',
      name: 'smartReviewTipsTitle',
      desc: '',
      args: [],
    );
  }

  /// `We analyze your exams, time left, and difficulty to build daily sessions you can actually follow.`
  String get smartReviewTipsBody {
    return Intl.message(
      'We analyze your exams, time left, and difficulty to build daily sessions you can actually follow.',
      name: 'smartReviewTipsBody',
      desc: '',
      args: [],
    );
  }

  /// `No upcoming exams yet`
  String get smartReviewEmptyNoExamsTitle {
    return Intl.message(
      'No upcoming exams yet',
      name: 'smartReviewEmptyNoExamsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Add at least one exam so we can build a focused review plan.`
  String get smartReviewEmptyNoExamsBody {
    return Intl.message(
      'Add at least one exam so we can build a focused review plan.',
      name: 'smartReviewEmptyNoExamsBody',
      desc: '',
      args: [],
    );
  }

  /// `Ready to build your plan`
  String get smartReviewEmptyNoPlanTitle {
    return Intl.message(
      'Ready to build your plan',
      name: 'smartReviewEmptyNoPlanTitle',
      desc: '',
      args: [],
    );
  }

  /// `We will generate a 7-day schedule based on your nearest exam and study time.`
  String get smartReviewEmptyNoPlanBody {
    return Intl.message(
      'We will generate a 7-day schedule based on your nearest exam and study time.',
      name: 'smartReviewEmptyNoPlanBody',
      desc: '',
      args: [],
    );
  }

  /// `Your plan`
  String get smartReviewPlanSectionTitle {
    return Intl.message(
      'Your plan',
      name: 'smartReviewPlanSectionTitle',
      desc: '',
      args: [],
    );
  }

  /// `{start} → {end}`
  String smartReviewPlanRange(Object start, Object end) {
    return Intl.message(
      '$start → $end',
      name: 'smartReviewPlanRange',
      desc: '',
      args: [start, end],
    );
  }

  /// `Plan cleared`
  String get smartReviewPlanCleared {
    return Intl.message(
      'Plan cleared',
      name: 'smartReviewPlanCleared',
      desc: '',
      args: [],
    );
  }

  /// `Clear plan`
  String get smartReviewActionClearPlan {
    return Intl.message(
      'Clear plan',
      name: 'smartReviewActionClearPlan',
      desc: '',
      args: [],
    );
  }

  /// `{minutes} min`
  String smartReviewTaskDuration(Object minutes) {
    return Intl.message(
      '$minutes min',
      name: 'smartReviewTaskDuration',
      desc: '',
      args: [minutes],
    );
  }

  /// `Focus session: {subject}`
  String smartReviewTaskFocusTitle(Object subject) {
    return Intl.message(
      'Focus session: $subject',
      name: 'smartReviewTaskFocusTitle',
      desc: '',
      args: [subject],
    );
  }

  /// `Practice quiz: {subject}`
  String smartReviewTaskPracticeTitle(Object subject) {
    return Intl.message(
      'Practice quiz: $subject',
      name: 'smartReviewTaskPracticeTitle',
      desc: '',
      args: [subject],
    );
  }

  /// `Summary review: {subject}`
  String smartReviewTaskSummaryTitle(Object subject) {
    return Intl.message(
      'Summary review: $subject',
      name: 'smartReviewTaskSummaryTitle',
      desc: '',
      args: [subject],
    );
  }

  /// `Mock test: {subject}`
  String smartReviewTaskMockTitle(Object subject) {
    return Intl.message(
      'Mock test: $subject',
      name: 'smartReviewTaskMockTitle',
      desc: '',
      args: [subject],
    );
  }

  /// `Coming soon`
  String get soon {
    return Intl.message(
      'Coming soon',
      name: 'soon',
      desc: '',
      args: [],
    );
  }

  /// `Add Exam`
  String get addExam {
    return Intl.message(
      'Add Exam',
      name: 'addExam',
      desc: '',
      args: [],
    );
  }

  /// `Edit Exam`
  String get editExam {
    return Intl.message(
      'Edit Exam',
      name: 'editExam',
      desc: '',
      args: [],
    );
  }

  /// `Delete Exam`
  String get deleteExam {
    return Intl.message(
      'Delete Exam',
      name: 'deleteExam',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to delete this exam?`
  String get confirmDeleteExam {
    return Intl.message(
      'Are you sure you want to delete this exam?',
      name: 'confirmDeleteExam',
      desc: '',
      args: [],
    );
  }

  /// `Subject`
  String get examSubject {
    return Intl.message(
      'Subject',
      name: 'examSubject',
      desc: '',
      args: [],
    );
  }

  /// `Please enter the subject`
  String get examSubjectRequired {
    return Intl.message(
      'Please enter the subject',
      name: 'examSubjectRequired',
      desc: '',
      args: [],
    );
  }

  /// `Room`
  String get examRoom {
    return Intl.message(
      'Room',
      name: 'examRoom',
      desc: '',
      args: [],
    );
  }

  /// `Note`
  String get examNote {
    return Intl.message(
      'Note',
      name: 'examNote',
      desc: '',
      args: [],
    );
  }

  /// `Reminders`
  String get reminders {
    return Intl.message(
      'Reminders',
      name: 'reminders',
      desc: '',
      args: [],
    );
  }

  /// `24 hours before`
  String get reminder24h {
    return Intl.message(
      '24 hours before',
      name: 'reminder24h',
      desc: '',
      args: [],
    );
  }

  /// `2 hours before`
  String get reminder2h {
    return Intl.message(
      '2 hours before',
      name: 'reminder2h',
      desc: '',
      args: [],
    );
  }

  /// `30 minutes before`
  String get reminder30m {
    return Intl.message(
      '30 minutes before',
      name: 'reminder30m',
      desc: '',
      args: [],
    );
  }

  /// `Save Exam`
  String get saveExam {
    return Intl.message(
      'Save Exam',
      name: 'saveExam',
      desc: '',
      args: [],
    );
  }

  /// `No exams for this day`
  String get noExamsDay {
    return Intl.message(
      'No exams for this day',
      name: 'noExamsDay',
      desc: '',
      args: [],
    );
  }

  /// `Reminder: {subject} in 24 hours`
  String examReminder24h(Object subject) {
    return Intl.message(
      'Reminder: $subject in 24 hours',
      name: 'examReminder24h',
      desc: '',
      args: [subject],
    );
  }

  /// `Reminder: {subject} in 2 hours`
  String examReminder2h(Object subject) {
    return Intl.message(
      'Reminder: $subject in 2 hours',
      name: 'examReminder2h',
      desc: '',
      args: [subject],
    );
  }

  /// `Reminder: {subject} in 30 minutes`
  String examReminder30m(Object subject) {
    return Intl.message(
      'Reminder: $subject in 30 minutes',
      name: 'examReminder30m',
      desc: '',
      args: [subject],
    );
  }

  /// `Account`
  String get drawerSectionAccount {
    return Intl.message(
      'Account',
      name: 'drawerSectionAccount',
      desc: '',
      args: [],
    );
  }

  /// `Student`
  String get drawerSectionStudent {
    return Intl.message(
      'Student',
      name: 'drawerSectionStudent',
      desc: '',
      args: [],
    );
  }

  /// `Content`
  String get drawerSectionContent {
    return Intl.message(
      'Content',
      name: 'drawerSectionContent',
      desc: '',
      args: [],
    );
  }

  /// `App`
  String get drawerSectionApp {
    return Intl.message(
      'App',
      name: 'drawerSectionApp',
      desc: '',
      args: [],
    );
  }

  /// `Edit Profile`
  String get editProfile {
    return Intl.message(
      'Edit Profile',
      name: 'editProfile',
      desc: '',
      args: [],
    );
  }

  /// `Notifications`
  String get notificationsSettingsTitle {
    return Intl.message(
      'Notifications',
      name: 'notificationsSettingsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Manage push notifications and reminders.`
  String get notificationsSettingsDescription {
    return Intl.message(
      'Manage push notifications and reminders.',
      name: 'notificationsSettingsDescription',
      desc: '',
      args: [],
    );
  }

  /// `Enable notifications`
  String get notificationsEnabled {
    return Intl.message(
      'Enable notifications',
      name: 'notificationsEnabled',
      desc: '',
      args: [],
    );
  }

  /// `Get alerts about updates and reminders.`
  String get notificationsEnabledHint {
    return Intl.message(
      'Get alerts about updates and reminders.',
      name: 'notificationsEnabledHint',
      desc: '',
      args: [],
    );
  }

  /// `Exam reminders`
  String get notificationsExamReminders {
    return Intl.message(
      'Exam reminders',
      name: 'notificationsExamReminders',
      desc: '',
      args: [],
    );
  }

  /// `Receive local alerts for scheduled exams.`
  String get notificationsExamRemindersHint {
    return Intl.message(
      'Receive local alerts for scheduled exams.',
      name: 'notificationsExamRemindersHint',
      desc: '',
      args: [],
    );
  }

  /// `Announcements`
  String get notificationsAnnouncements {
    return Intl.message(
      'Announcements',
      name: 'notificationsAnnouncements',
      desc: '',
      args: [],
    );
  }

  /// `Stay up to date on campus news.`
  String get notificationsAnnouncementsHint {
    return Intl.message(
      'Stay up to date on campus news.',
      name: 'notificationsAnnouncementsHint',
      desc: '',
      args: [],
    );
  }

  /// `Community updates`
  String get notificationsCommunity {
    return Intl.message(
      'Community updates',
      name: 'notificationsCommunity',
      desc: '',
      args: [],
    );
  }

  /// `Get notified about community activity.`
  String get notificationsCommunityHint {
    return Intl.message(
      'Get notified about community activity.',
      name: 'notificationsCommunityHint',
      desc: '',
      args: [],
    );
  }

  /// `Enable notifications to manage reminders and alerts.`
  String get notificationsDisabledHint {
    return Intl.message(
      'Enable notifications to manage reminders and alerts.',
      name: 'notificationsDisabledHint',
      desc: '',
      args: [],
    );
  }

  /// `Security`
  String get securityCenterTitle {
    return Intl.message(
      'Security',
      name: 'securityCenterTitle',
      desc: '',
      args: [],
    );
  }

  /// `Two-factor authentication`
  String get twoFactorAuthTitle {
    return Intl.message(
      'Two-factor authentication',
      name: 'twoFactorAuthTitle',
      desc: '',
      args: [],
    );
  }

  /// `Require OTP verification on sign-in.`
  String get twoFactorAuthHint {
    return Intl.message(
      'Require OTP verification on sign-in.',
      name: 'twoFactorAuthHint',
      desc: '',
      args: [],
    );
  }

  /// `Two-factor authentication enabled.`
  String get twoFactorEnabledToast {
    return Intl.message(
      'Two-factor authentication enabled.',
      name: 'twoFactorEnabledToast',
      desc: '',
      args: [],
    );
  }

  /// `Two-factor authentication disabled.`
  String get twoFactorDisabledToast {
    return Intl.message(
      'Two-factor authentication disabled.',
      name: 'twoFactorDisabledToast',
      desc: '',
      args: [],
    );
  }

  /// `Enable two-factor authentication?`
  String get twoFactorEnableConfirmTitle {
    return Intl.message(
      'Enable two-factor authentication?',
      name: 'twoFactorEnableConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `You will be asked for a one-time code sent to your email after password login.`
  String get twoFactorEnableConfirmBody {
    return Intl.message(
      'You will be asked for a one-time code sent to your email after password login.',
      name: 'twoFactorEnableConfirmBody',
      desc: '',
      args: [],
    );
  }

  /// `Email verification code`
  String get twoFactorOtpTitle {
    return Intl.message(
      'Email verification code',
      name: 'twoFactorOtpTitle',
      desc: '',
      args: [],
    );
  }

  /// `Enter the 6-digit code sent to {email}.`
  String twoFactorOtpDescription(Object email) {
    return Intl.message(
      'Enter the 6-digit code sent to $email.',
      name: 'twoFactorOtpDescription',
      desc: '',
      args: [email],
    );
  }

  /// `Verification code`
  String get twoFactorCodeLabel {
    return Intl.message(
      'Verification code',
      name: 'twoFactorCodeLabel',
      desc: '',
      args: [],
    );
  }

  /// `6-digit code`
  String get twoFactorCodeHint {
    return Intl.message(
      '6-digit code',
      name: 'twoFactorCodeHint',
      desc: '',
      args: [],
    );
  }

  /// `Confirm`
  String get twoFactorConfirmButton {
    return Intl.message(
      'Confirm',
      name: 'twoFactorConfirmButton',
      desc: '',
      args: [],
    );
  }

  /// `Resend code`
  String get twoFactorResendCode {
    return Intl.message(
      'Resend code',
      name: 'twoFactorResendCode',
      desc: '',
      args: [],
    );
  }

  /// `Resend in {seconds}s`
  String twoFactorResendIn(Object seconds) {
    return Intl.message(
      'Resend in ${seconds}s',
      name: 'twoFactorResendIn',
      desc: '',
      args: [seconds],
    );
  }

  /// `Back to login`
  String get twoFactorBackToLogin {
    return Intl.message(
      'Back to login',
      name: 'twoFactorBackToLogin',
      desc: '',
      args: [],
    );
  }

  /// `Verification code sent to your email.`
  String get twoFactorCodeSent {
    return Intl.message(
      'Verification code sent to your email.',
      name: 'twoFactorCodeSent',
      desc: '',
      args: [],
    );
  }

  /// `Code expired. Request a new code.`
  String get twoFactorCodeExpired {
    return Intl.message(
      'Code expired. Request a new code.',
      name: 'twoFactorCodeExpired',
      desc: '',
      args: [],
    );
  }

  /// `Incorrect code. Try again.`
  String get twoFactorCodeIncorrect {
    return Intl.message(
      'Incorrect code. Try again.',
      name: 'twoFactorCodeIncorrect',
      desc: '',
      args: [],
    );
  }

  /// `Too many failed attempts. Try again later.`
  String get twoFactorTooManyAttempts {
    return Intl.message(
      'Too many failed attempts. Try again later.',
      name: 'twoFactorTooManyAttempts',
      desc: '',
      args: [],
    );
  }

  /// `Please wait before resending.`
  String get twoFactorResendCooldown {
    return Intl.message(
      'Please wait before resending.',
      name: 'twoFactorResendCooldown',
      desc: '',
      args: [],
    );
  }

  /// `Two-factor verification completed.`
  String get twoFactorVerifiedSuccess {
    return Intl.message(
      'Two-factor verification completed.',
      name: 'twoFactorVerifiedSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Enter a valid 6-digit code.`
  String get twoFactorCodeInvalidFormat {
    return Intl.message(
      'Enter a valid 6-digit code.',
      name: 'twoFactorCodeInvalidFormat',
      desc: '',
      args: [],
    );
  }

  /// `Verification session not found. Sign in again.`
  String get twoFactorChallengeMissing {
    return Intl.message(
      'Verification session not found. Sign in again.',
      name: 'twoFactorChallengeMissing',
      desc: '',
      args: [],
    );
  }

  /// `Failed to send verification code.`
  String get twoFactorSendFailed {
    return Intl.message(
      'Failed to send verification code.',
      name: 'twoFactorSendFailed',
      desc: '',
      args: [],
    );
  }

  /// `Unable to complete verification. Try again.`
  String get twoFactorGenericError {
    return Intl.message(
      'Unable to complete verification. Try again.',
      name: 'twoFactorGenericError',
      desc: '',
      args: [],
    );
  }

  /// `Attempts remaining: {count}`
  String twoFactorAttemptsRemaining(Object count) {
    return Intl.message(
      'Attempts remaining: $count',
      name: 'twoFactorAttemptsRemaining',
      desc: '',
      args: [count],
    );
  }

  /// `Manage devices`
  String get manageDevicesTitle {
    return Intl.message(
      'Manage devices',
      name: 'manageDevicesTitle',
      desc: '',
      args: [],
    );
  }

  /// `Review active sessions and devices.`
  String get manageDevicesHint {
    return Intl.message(
      'Review active sessions and devices.',
      name: 'manageDevicesHint',
      desc: '',
      args: [],
    );
  }

  /// `See where your account is signed in and remove access if needed.`
  String get manageDevicesDescription {
    return Intl.message(
      'See where your account is signed in and remove access if needed.',
      name: 'manageDevicesDescription',
      desc: '',
      args: [],
    );
  }

  /// `Current device`
  String get currentDeviceTitle {
    return Intl.message(
      'Current device',
      name: 'currentDeviceTitle',
      desc: '',
      args: [],
    );
  }

  /// `Active sessions`
  String get activeSessionsTitle {
    return Intl.message(
      'Active sessions',
      name: 'activeSessionsTitle',
      desc: '',
      args: [],
    );
  }

  /// `No other active sessions`
  String get activeSessionsEmpty {
    return Intl.message(
      'No other active sessions',
      name: 'activeSessionsEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Session management requires a secure backend.`
  String get activeSessionsHint {
    return Intl.message(
      'Session management requires a secure backend.',
      name: 'activeSessionsHint',
      desc: '',
      args: [],
    );
  }

  /// `Trusted devices`
  String get trustedDevicesTitle {
    return Intl.message(
      'Trusted devices',
      name: 'trustedDevicesTitle',
      desc: '',
      args: [],
    );
  }

  /// `Primary device`
  String get devicePrimary {
    return Intl.message(
      'Primary device',
      name: 'devicePrimary',
      desc: '',
      args: [],
    );
  }

  /// `Active now`
  String get deviceActiveNow {
    return Intl.message(
      'Active now',
      name: 'deviceActiveNow',
      desc: '',
      args: [],
    );
  }

  /// `Sign out`
  String get signOut {
    return Intl.message(
      'Sign out',
      name: 'signOut',
      desc: '',
      args: [],
    );
  }

  /// `Log out of all devices`
  String get logoutAllDevices {
    return Intl.message(
      'Log out of all devices',
      name: 'logoutAllDevices',
      desc: '',
      args: [],
    );
  }

  /// `Signed out from all devices.`
  String get logoutAllSuccess {
    return Intl.message(
      'Signed out from all devices.',
      name: 'logoutAllSuccess',
      desc: '',
      args: [],
    );
  }

  /// `We'll sign you out on this device. For other sessions, enable backend revocation.`
  String get logoutAllDevicesPrompt {
    return Intl.message(
      'We\'ll sign you out on this device. For other sessions, enable backend revocation.',
      name: 'logoutAllDevicesPrompt',
      desc: '',
      args: [],
    );
  }

  /// `Log out`
  String get logoutAllConfirm {
    return Intl.message(
      'Log out',
      name: 'logoutAllConfirm',
      desc: '',
      args: [],
    );
  }

  /// `Signed out here. Configure backend revocation for other devices.`
  String get logoutAllLocalOnly {
    return Intl.message(
      'Signed out here. Configure backend revocation for other devices.',
      name: 'logoutAllLocalOnly',
      desc: '',
      args: [],
    );
  }

  /// `Unable to sign out from all devices.`
  String get logoutAllFailed {
    return Intl.message(
      'Unable to sign out from all devices.',
      name: 'logoutAllFailed',
      desc: '',
      args: [],
    );
  }

  /// `Privacy`
  String get privacySettingsTitle {
    return Intl.message(
      'Privacy',
      name: 'privacySettingsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Control what others can see on your profile.`
  String get privacySettingsDescription {
    return Intl.message(
      'Control what others can see on your profile.',
      name: 'privacySettingsDescription',
      desc: '',
      args: [],
    );
  }

  /// `Profile visibility`
  String get profileVisibilityTitle {
    return Intl.message(
      'Profile visibility',
      name: 'profileVisibilityTitle',
      desc: '',
      args: [],
    );
  }

  /// `Public`
  String get profileVisibilityPublic {
    return Intl.message(
      'Public',
      name: 'profileVisibilityPublic',
      desc: '',
      args: [],
    );
  }

  /// `Private`
  String get profileVisibilityPrivate {
    return Intl.message(
      'Private',
      name: 'profileVisibilityPrivate',
      desc: '',
      args: [],
    );
  }

  /// `Show email on profile`
  String get showEmailInProfileTitle {
    return Intl.message(
      'Show email on profile',
      name: 'showEmailInProfileTitle',
      desc: '',
      args: [],
    );
  }

  /// `Allow others to see your email.`
  String get showEmailInProfileHint {
    return Intl.message(
      'Allow others to see your email.',
      name: 'showEmailInProfileHint',
      desc: '',
      args: [],
    );
  }

  /// `Blocked users`
  String get blockedUsersTitle {
    return Intl.message(
      'Blocked users',
      name: 'blockedUsersTitle',
      desc: '',
      args: [],
    );
  }

  /// `No blocked users`
  String get blockedUsersEmpty {
    return Intl.message(
      'No blocked users',
      name: 'blockedUsersEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Blocked users will appear here.`
  String get blockedUsersHint {
    return Intl.message(
      'Blocked users will appear here.',
      name: 'blockedUsersHint',
      desc: '',
      args: [],
    );
  }

  /// `Block a user`
  String get blockedUsersAddTitle {
    return Intl.message(
      'Block a user',
      name: 'blockedUsersAddTitle',
      desc: '',
      args: [],
    );
  }

  /// `Enter user ID or email`
  String get blockedUsersAddHint {
    return Intl.message(
      'Enter user ID or email',
      name: 'blockedUsersAddHint',
      desc: '',
      args: [],
    );
  }

  /// `Block`
  String get blockedUsersAddAction {
    return Intl.message(
      'Block',
      name: 'blockedUsersAddAction',
      desc: '',
      args: [],
    );
  }

  /// `Blocked on {date}`
  String blockedUsersSince(Object date) {
    return Intl.message(
      'Blocked on $date',
      name: 'blockedUsersSince',
      desc: '',
      args: [date],
    );
  }

  /// `Unblock`
  String get unblockUser {
    return Intl.message(
      'Unblock',
      name: 'unblockUser',
      desc: '',
      args: [],
    );
  }

  /// `Academic settings`
  String get academicSettingsTitle {
    return Intl.message(
      'Academic settings',
      name: 'academicSettingsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Update your college, major, and level.`
  String get academicSettingsDescription {
    return Intl.message(
      'Update your college, major, and level.',
      name: 'academicSettingsDescription',
      desc: '',
      args: [],
    );
  }

  /// `College`
  String get academicCollegeLabel {
    return Intl.message(
      'College',
      name: 'academicCollegeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Major`
  String get academicMajorLabel {
    return Intl.message(
      'Major',
      name: 'academicMajorLabel',
      desc: '',
      args: [],
    );
  }

  /// `Level`
  String get academicLevelLabel {
    return Intl.message(
      'Level',
      name: 'academicLevelLabel',
      desc: '',
      args: [],
    );
  }

  /// `Academic settings saved.`
  String get academicSettingsSaved {
    return Intl.message(
      'Academic settings saved.',
      name: 'academicSettingsSaved',
      desc: '',
      args: [],
    );
  }

  /// `Your academic shortcut`
  String get academicShortcutTitle {
    return Intl.message(
      'Your academic shortcut',
      name: 'academicShortcutTitle',
      desc: '',
      args: [],
    );
  }

  /// `Specialty: {specialty} | Level: {level}`
  String academicShortcutDetails(Object specialty, Object level) {
    return Intl.message(
      'Specialty: $specialty | Level: $level',
      name: 'academicShortcutDetails',
      desc: '',
      args: [specialty, level],
    );
  }

  /// `Go`
  String get academicShortcutGo {
    return Intl.message(
      'Go',
      name: 'academicShortcutGo',
      desc: '',
      args: [],
    );
  }

  /// `Edit`
  String get academicShortcutEdit {
    return Intl.message(
      'Edit',
      name: 'academicShortcutEdit',
      desc: '',
      args: [],
    );
  }

  /// `Delete shortcut`
  String get academicShortcutDeleteTitle {
    return Intl.message(
      'Delete shortcut',
      name: 'academicShortcutDeleteTitle',
      desc: '',
      args: [],
    );
  }

  /// `Confirm deletion`
  String get academicShortcutDeleteConfirmTitle {
    return Intl.message(
      'Confirm deletion',
      name: 'academicShortcutDeleteConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `Do you want to delete the academic shortcut? You can add it again later.`
  String get academicShortcutDeleteConfirmBody {
    return Intl.message(
      'Do you want to delete the academic shortcut? You can add it again later.',
      name: 'academicShortcutDeleteConfirmBody',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get academicShortcutDeleteCancel {
    return Intl.message(
      'Cancel',
      name: 'academicShortcutDeleteCancel',
      desc: '',
      args: [],
    );
  }

  /// `Delete`
  String get academicShortcutDeleteConfirm {
    return Intl.message(
      'Delete',
      name: 'academicShortcutDeleteConfirm',
      desc: '',
      args: [],
    );
  }

  /// `Shortcut deleted successfully.`
  String get academicShortcutDeleteSuccess {
    return Intl.message(
      'Shortcut deleted successfully.',
      name: 'academicShortcutDeleteSuccess',
      desc: '',
      args: [],
    );
  }

  /// `No academic shortcut set yet.`
  String get academicShortcutEmptyTitle {
    return Intl.message(
      'No academic shortcut set yet.',
      name: 'academicShortcutEmptyTitle',
      desc: '',
      args: [],
    );
  }

  /// `Add shortcut`
  String get academicShortcutEmptyAction {
    return Intl.message(
      'Add shortcut',
      name: 'academicShortcutEmptyAction',
      desc: '',
      args: [],
    );
  }

  /// `We couldn't find that specialty. Please update your academic settings.`
  String get academicShortcutNotFound {
    return Intl.message(
      'We couldn\'t find that specialty. Please update your academic settings.',
      name: 'academicShortcutNotFound',
      desc: '',
      args: [],
    );
  }

  /// `Save changes`
  String get saveChanges {
    return Intl.message(
      'Save changes',
      name: 'saveChanges',
      desc: '',
      args: [],
    );
  }

  /// `Downloads`
  String get downloadsTitle {
    return Intl.message(
      'Downloads',
      name: 'downloadsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Browse your downloaded files and clean the cache.`
  String get downloadsDescription {
    return Intl.message(
      'Browse your downloaded files and clean the cache.',
      name: 'downloadsDescription',
      desc: '',
      args: [],
    );
  }

  /// `No downloads yet`
  String get downloadsEmptyTitle {
    return Intl.message(
      'No downloads yet',
      name: 'downloadsEmptyTitle',
      desc: '',
      args: [],
    );
  }

  /// `Downloaded items will appear here.`
  String get downloadsEmptyHint {
    return Intl.message(
      'Downloaded items will appear here.',
      name: 'downloadsEmptyHint',
      desc: '',
      args: [],
    );
  }

  /// `Clear cache`
  String get downloadsClearCache {
    return Intl.message(
      'Clear cache',
      name: 'downloadsClearCache',
      desc: '',
      args: [],
    );
  }

  /// `Cache cleared.`
  String get downloadsCacheCleared {
    return Intl.message(
      'Cache cleared.',
      name: 'downloadsCacheCleared',
      desc: '',
      args: [],
    );
  }

  /// `Unable to clear the cache.`
  String get downloadsCacheClearFailed {
    return Intl.message(
      'Unable to clear the cache.',
      name: 'downloadsCacheClearFailed',
      desc: '',
      args: [],
    );
  }

  /// `Refresh list`
  String get downloadsRefreshList {
    return Intl.message(
      'Refresh list',
      name: 'downloadsRefreshList',
      desc: '',
      args: [],
    );
  }

  /// `Downloads storage`
  String get downloadsStorageTitle {
    return Intl.message(
      'Downloads storage',
      name: 'downloadsStorageTitle',
      desc: '',
      args: [],
    );
  }

  /// `User: 0 MB`
  String get downloadsStorageUserLabel {
    return Intl.message(
      'User: 0 MB',
      name: 'downloadsStorageUserLabel',
      desc: '',
      args: [],
    );
  }

  /// `Cache: 0 MB`
  String get downloadsStorageCacheLabel {
    return Intl.message(
      'Cache: 0 MB',
      name: 'downloadsStorageCacheLabel',
      desc: '',
      args: [],
    );
  }

  /// `Sizes will be calculated automatically later.`
  String get downloadsStorageInfo {
    return Intl.message(
      'Sizes will be calculated automatically later.',
      name: 'downloadsStorageInfo',
      desc: '',
      args: [],
    );
  }

  /// `User: {size}`
  String downloadsStorageUserLabelValue(Object size) {
    return Intl.message(
      'User: $size',
      name: 'downloadsStorageUserLabelValue',
      desc: '',
      args: [size],
    );
  }

  /// `Cache: {size}`
  String downloadsStorageCacheLabelValue(Object size) {
    return Intl.message(
      'Cache: $size',
      name: 'downloadsStorageCacheLabelValue',
      desc: '',
      args: [size],
    );
  }

  /// `Total used: {size}`
  String downloadsStorageInfoValue(Object size) {
    return Intl.message(
      'Total used: $size',
      name: 'downloadsStorageInfoValue',
      desc: '',
      args: [size],
    );
  }

  /// `Clear cached downloads?`
  String get downloadsClearCacheDialogTitle {
    return Intl.message(
      'Clear cached downloads?',
      name: 'downloadsClearCacheDialogTitle',
      desc: '',
      args: [],
    );
  }

  /// `This will remove cached files from this device. You can download them again later.`
  String get downloadsClearCacheDialogBody {
    return Intl.message(
      'This will remove cached files from this device. You can download them again later.',
      name: 'downloadsClearCacheDialogBody',
      desc: '',
      args: [],
    );
  }

  /// `Clear cache`
  String get downloadsClearCacheDialogConfirm {
    return Intl.message(
      'Clear cache',
      name: 'downloadsClearCacheDialogConfirm',
      desc: '',
      args: [],
    );
  }

  /// `Explore content`
  String get downloadsExploreCta {
    return Intl.message(
      'Explore content',
      name: 'downloadsExploreCta',
      desc: '',
      args: [],
    );
  }

  /// `All`
  String get downloadsFilterAll {
    return Intl.message(
      'All',
      name: 'downloadsFilterAll',
      desc: '',
      args: [],
    );
  }

  /// `Files`
  String get downloadsFilterFiles {
    return Intl.message(
      'Files',
      name: 'downloadsFilterFiles',
      desc: '',
      args: [],
    );
  }

  /// `Images`
  String get downloadsFilterImages {
    return Intl.message(
      'Images',
      name: 'downloadsFilterImages',
      desc: '',
      args: [],
    );
  }

  /// `Sort by`
  String get downloadsSortLabel {
    return Intl.message(
      'Sort by',
      name: 'downloadsSortLabel',
      desc: '',
      args: [],
    );
  }

  /// `Newest`
  String get downloadsSortNewest {
    return Intl.message(
      'Newest',
      name: 'downloadsSortNewest',
      desc: '',
      args: [],
    );
  }

  /// `Oldest`
  String get downloadsSortOldest {
    return Intl.message(
      'Oldest',
      name: 'downloadsSortOldest',
      desc: '',
      args: [],
    );
  }

  /// `Clear all downloads`
  String get downloadsClearAllAction {
    return Intl.message(
      'Clear all downloads',
      name: 'downloadsClearAllAction',
      desc: '',
      args: [],
    );
  }

  /// `Clear all downloads?`
  String get downloadsClearAllDialogTitle {
    return Intl.message(
      'Clear all downloads?',
      name: 'downloadsClearAllDialogTitle',
      desc: '',
      args: [],
    );
  }

  /// `This will remove all downloaded files from this device.`
  String get downloadsClearAllDialogBody {
    return Intl.message(
      'This will remove all downloaded files from this device.',
      name: 'downloadsClearAllDialogBody',
      desc: '',
      args: [],
    );
  }

  /// `Clear all`
  String get downloadsClearAllDialogConfirm {
    return Intl.message(
      'Clear all',
      name: 'downloadsClearAllDialogConfirm',
      desc: '',
      args: [],
    );
  }

  /// `All downloads cleared.`
  String get downloadsClearAllSuccess {
    return Intl.message(
      'All downloads cleared.',
      name: 'downloadsClearAllSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Unable to clear all downloads.`
  String get downloadsClearAllFailed {
    return Intl.message(
      'Unable to clear all downloads.',
      name: 'downloadsClearAllFailed',
      desc: '',
      args: [],
    );
  }

  /// `Delete download?`
  String get downloadsDeleteDialogTitle {
    return Intl.message(
      'Delete download?',
      name: 'downloadsDeleteDialogTitle',
      desc: '',
      args: [],
    );
  }

  /// `Delete {fileName} from this device?`
  String downloadsDeleteDialogBody(Object fileName) {
    return Intl.message(
      'Delete $fileName from this device?',
      name: 'downloadsDeleteDialogBody',
      desc: '',
      args: [fileName],
    );
  }

  /// `Download deleted.`
  String get downloadsDeleteSuccess {
    return Intl.message(
      'Download deleted.',
      name: 'downloadsDeleteSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Unable to delete the download.`
  String get downloadsDeleteFailed {
    return Intl.message(
      'Unable to delete the download.',
      name: 'downloadsDeleteFailed',
      desc: '',
      args: [],
    );
  }

  /// `Unable to load downloads.`
  String get downloadsLoadFailed {
    return Intl.message(
      'Unable to load downloads.',
      name: 'downloadsLoadFailed',
      desc: '',
      args: [],
    );
  }

  /// `Updated {date}`
  String downloadsUpdatedAt(Object date) {
    return Intl.message(
      'Updated $date',
      name: 'downloadsUpdatedAt',
      desc: '',
      args: [date],
    );
  }

  /// `Favorites`
  String get favoritesTitle {
    return Intl.message(
      'Favorites',
      name: 'favoritesTitle',
      desc: '',
      args: [],
    );
  }

  /// `Your saved items appear here.`
  String get favoritesDescription {
    return Intl.message(
      'Your saved items appear here.',
      name: 'favoritesDescription',
      desc: '',
      args: [],
    );
  }

  /// `No favorites yet`
  String get favoritesEmptyTitle {
    return Intl.message(
      'No favorites yet',
      name: 'favoritesEmptyTitle',
      desc: '',
      args: [],
    );
  }

  /// `Save posts or files to see them here.`
  String get favoritesEmptyHint {
    return Intl.message(
      'Save posts or files to see them here.',
      name: 'favoritesEmptyHint',
      desc: '',
      args: [],
    );
  }

  /// `Add favorite`
  String get favoritesAddTitle {
    return Intl.message(
      'Add favorite',
      name: 'favoritesAddTitle',
      desc: '',
      args: [],
    );
  }

  /// `Enter item ID`
  String get favoritesAddHint {
    return Intl.message(
      'Enter item ID',
      name: 'favoritesAddHint',
      desc: '',
      args: [],
    );
  }

  /// `Type (optional)`
  String get favoritesAddTypeHint {
    return Intl.message(
      'Type (optional)',
      name: 'favoritesAddTypeHint',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get favoritesAddAction {
    return Intl.message(
      'Save',
      name: 'favoritesAddAction',
      desc: '',
      args: [],
    );
  }

  /// `Favorite saved.`
  String get favoritesAdded {
    return Intl.message(
      'Favorite saved.',
      name: 'favoritesAdded',
      desc: '',
      args: [],
    );
  }

  /// `Favorite removed.`
  String get favoritesRemoved {
    return Intl.message(
      'Favorite removed.',
      name: 'favoritesRemoved',
      desc: '',
      args: [],
    );
  }

  /// `Sign in to save favorites`
  String get favoritesSignInTitle {
    return Intl.message(
      'Sign in to save favorites',
      name: 'favoritesSignInTitle',
      desc: '',
      args: [],
    );
  }

  /// `Favorites sync to your account when signed in.`
  String get favoritesSignInHint {
    return Intl.message(
      'Favorites sync to your account when signed in.',
      name: 'favoritesSignInHint',
      desc: '',
      args: [],
    );
  }

  /// `Type: {type}`
  String favoritesTypeLabel(Object type) {
    return Intl.message(
      'Type: $type',
      name: 'favoritesTypeLabel',
      desc: '',
      args: [type],
    );
  }

  /// `Font size`
  String get fontSizeTitle {
    return Intl.message(
      'Font size',
      name: 'fontSizeTitle',
      desc: '',
      args: [],
    );
  }

  /// `Choose a comfortable reading size.`
  String get fontSizeDescription {
    return Intl.message(
      'Choose a comfortable reading size.',
      name: 'fontSizeDescription',
      desc: '',
      args: [],
    );
  }

  /// `Small`
  String get fontSizeSmall {
    return Intl.message(
      'Small',
      name: 'fontSizeSmall',
      desc: '',
      args: [],
    );
  }

  /// `Medium`
  String get fontSizeMedium {
    return Intl.message(
      'Medium',
      name: 'fontSizeMedium',
      desc: '',
      args: [],
    );
  }

  /// `Large`
  String get fontSizeLarge {
    return Intl.message(
      'Large',
      name: 'fontSizeLarge',
      desc: '',
      args: [],
    );
  }

  /// `Preview`
  String get fontSizePreviewLabel {
    return Intl.message(
      'Preview',
      name: 'fontSizePreviewLabel',
      desc: '',
      args: [],
    );
  }

  /// `The quick brown fox jumps over the lazy dog.`
  String get fontSizePreviewText {
    return Intl.message(
      'The quick brown fox jumps over the lazy dog.',
      name: 'fontSizePreviewText',
      desc: '',
      args: [],
    );
  }

  /// `Rate app`
  String get rateApp {
    return Intl.message(
      'Rate app',
      name: 'rateApp',
      desc: '',
      args: [],
    );
  }

  /// `Unable to open the store right now.`
  String get rateAppFailed {
    return Intl.message(
      'Unable to open the store right now.',
      name: 'rateAppFailed',
      desc: '',
      args: [],
    );
  }

  /// `Share app`
  String get shareApp {
    return Intl.message(
      'Share app',
      name: 'shareApp',
      desc: '',
      args: [],
    );
  }

  /// `Check out UniSpace for smart study tools and student community!`
  String get shareAppMessage {
    return Intl.message(
      'Check out UniSpace for smart study tools and student community!',
      name: 'shareAppMessage',
      desc: '',
      args: [],
    );
  }

  /// `Email verified`
  String get emailVerified {
    return Intl.message(
      'Email verified',
      name: 'emailVerified',
      desc: '',
      args: [],
    );
  }

  /// `Email not verified`
  String get emailNotVerified {
    return Intl.message(
      'Email not verified',
      name: 'emailNotVerified',
      desc: '',
      args: [],
    );
  }

  /// `Send OTP now`
  String get sendOtpNow {
    return Intl.message(
      'Send OTP now',
      name: 'sendOtpNow',
      desc: '',
      args: [],
    );
  }

  /// `Send OTP in {seconds}s`
  String otpCooldownLabel(Object seconds) {
    return Intl.message(
      'Send OTP in ${seconds}s',
      name: 'otpCooldownLabel',
      desc: '',
      args: [seconds],
    );
  }

  /// `OTP sent. Check your email.`
  String get otpSentSuccess {
    return Intl.message(
      'OTP sent. Check your email.',
      name: 'otpSentSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Unable to send OTP right now.`
  String get otpSentFailed {
    return Intl.message(
      'Unable to send OTP right now.',
      name: 'otpSentFailed',
      desc: '',
      args: [],
    );
  }

  /// `Please sign in to continue.`
  String get signInRequired {
    return Intl.message(
      'Please sign in to continue.',
      name: 'signInRequired',
      desc: '',
      args: [],
    );
  }

  /// `Guest`
  String get guestUser {
    return Intl.message(
      'Guest',
      name: 'guestUser',
      desc: '',
      args: [],
    );
  }

  /// `Email unavailable`
  String get emailUnavailable {
    return Intl.message(
      'Email unavailable',
      name: 'emailUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `Email hidden`
  String get emailHidden {
    return Intl.message(
      'Email hidden',
      name: 'emailHidden',
      desc: '',
      args: [],
    );
  }

  /// `A platform to calculate GPA, connect with students, and take notes.`
  String get aboutAppSummary {
    return Intl.message(
      'A platform to calculate GPA, connect with students, and take notes.',
      name: 'aboutAppSummary',
      desc: '',
      args: [],
    );
  }

  /// `A smart university platform that helps students organize their studies, calculate averages, track exams, and plan revision in an easy and effective way.`
  String get aboutAppDescription {
    return Intl.message(
      'A smart university platform that helps students organize their studies, calculate averages, track exams, and plan revision in an easy and effective way.',
      name: 'aboutAppDescription',
      desc: '',
      args: [],
    );
  }

  /// `Accurate university GPA calculation`
  String get aboutAppFeatureGpa {
    return Intl.message(
      'Accurate university GPA calculation',
      name: 'aboutAppFeatureGpa',
      desc: '',
      args: [],
    );
  }

  /// `Smart revision planner`
  String get aboutAppFeatureReviewPlan {
    return Intl.message(
      'Smart revision planner',
      name: 'aboutAppFeatureReviewPlan',
      desc: '',
      args: [],
    );
  }

  /// `Exam calendar`
  String get aboutAppFeatureExams {
    return Intl.message(
      'Exam calendar',
      name: 'aboutAppFeatureExams',
      desc: '',
      args: [],
    );
  }

  /// `Academic note taking`
  String get aboutAppFeatureNotes {
    return Intl.message(
      'Academic note taking',
      name: 'aboutAppFeatureNotes',
      desc: '',
      args: [],
    );
  }

  /// `Tailored specifically for university students`
  String get aboutAppFeatureStudents {
    return Intl.message(
      'Tailored specifically for university students',
      name: 'aboutAppFeatureStudents',
      desc: '',
      args: [],
    );
  }

  /// `View licenses`
  String get aboutAppViewLicenses {
    return Intl.message(
      'View licenses',
      name: 'aboutAppViewLicenses',
      desc: '',
      args: [],
    );
  }

  /// `Developed with Flutter`
  String get aboutAppFooter {
    return Intl.message(
      'Developed with Flutter',
      name: 'aboutAppFooter',
      desc: '',
      args: [],
    );
  }

  /// `Common Core`
  String get commonCore1 {
    return Intl.message(
      'Common Core',
      name: 'commonCore1',
      desc: '',
      args: [],
    );
  }

  /// `class`
  String get academicclass {
    return Intl.message(
      'class',
      name: 'academicclass',
      desc: '',
      args: [],
    );
  }

  /// `Verification email sent.`
  String get verificationEmailSent {
    return Intl.message(
      'Verification email sent.',
      name: 'verificationEmailSent',
      desc: '',
      args: [],
    );
  }

  /// `Email is not verified yet. Please open your email, click the verification link, then try again.`
  String get emailNotVerifiedYet {
    return Intl.message(
      'Email is not verified yet. Please open your email, click the verification link, then try again.',
      name: 'emailNotVerifiedYet',
      desc: '',
      args: [],
    );
  }

  /// `Please verify your email to continue.`
  String get verifyEmailToContinue {
    return Intl.message(
      'Please verify your email to continue.',
      name: 'verifyEmailToContinue',
      desc: '',
      args: [],
    );
  }

  /// `Open the verification email and click the link, then tap check now.`
  String get verifyEmailHelper {
    return Intl.message(
      'Open the verification email and click the link, then tap check now.',
      name: 'verifyEmailHelper',
      desc: '',
      args: [],
    );
  }

  /// `Verify email`
  String get verifyEmailTitle {
    return Intl.message(
      'Verify email',
      name: 'verifyEmailTitle',
      desc: '',
      args: [],
    );
  }

  /// `Check now`
  String get checkNow {
    return Intl.message(
      'Check now',
      name: 'checkNow',
      desc: '',
      args: [],
    );
  }

  /// `Resend verification email`
  String get resendVerificationEmail {
    return Intl.message(
      'Resend verification email',
      name: 'resendVerificationEmail',
      desc: '',
      args: [],
    );
  }

  /// `Resend in {seconds}s`
  String resendVerificationCooldown(Object seconds) {
    return Intl.message(
      'Resend in ${seconds}s',
      name: 'resendVerificationCooldown',
      desc: '',
      args: [seconds],
    );
  }

  /// `Wrong password.`
  String get wrongPasswordError {
    return Intl.message(
      'Wrong password.',
      name: 'wrongPasswordError',
      desc: '',
      args: [],
    );
  }

  /// `Email is already in use.`
  String get emailAlreadyInUseError {
    return Intl.message(
      'Email is already in use.',
      name: 'emailAlreadyInUseError',
      desc: '',
      args: [],
    );
  }

  /// `Network error. Please try again.`
  String get networkError {
    return Intl.message(
      'Network error. Please try again.',
      name: 'networkError',
      desc: '',
      args: [],
    );
  }

  /// `Password is too weak.`
  String get weakPasswordError {
    return Intl.message(
      'Password is too weak.',
      name: 'weakPasswordError',
      desc: '',
      args: [],
    );
  }

  /// `Email/password sign-in is disabled.`
  String get emailAuthDisabledError {
    return Intl.message(
      'Email/password sign-in is disabled.',
      name: 'emailAuthDisabledError',
      desc: '',
      args: [],
    );
  }

  /// `This account is disabled.`
  String get userDisabledError {
    return Intl.message(
      'This account is disabled.',
      name: 'userDisabledError',
      desc: '',
      args: [],
    );
  }

  /// `Something went wrong. Please try again.`
  String get genericAuthError {
    return Intl.message(
      'Something went wrong. Please try again.',
      name: 'genericAuthError',
      desc: '',
      args: [],
    );
  }

  /// `Just now`
  String get activeSessionNow {
    return Intl.message(
      'Just now',
      name: 'activeSessionNow',
      desc: '',
      args: [],
    );
  }

  /// `Session signed out successfully.`
  String get sessionSignedOutSuccess {
    return Intl.message(
      'Session signed out successfully.',
      name: 'sessionSignedOutSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Unable to sign out this session.`
  String get sessionSignOutFailed {
    return Intl.message(
      'Unable to sign out this session.',
      name: 'sessionSignOutFailed',
      desc: '',
      args: [],
    );
  }

  /// `Signed out from other devices.`
  String get otherSessionsSignedOutSuccess {
    return Intl.message(
      'Signed out from other devices.',
      name: 'otherSessionsSignedOutSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Log out other devices`
  String get logoutAllOtherDevices {
    return Intl.message(
      'Log out other devices',
      name: 'logoutAllOtherDevices',
      desc: '',
      args: [],
    );
  }

  /// `Unknown device`
  String get sessionUnknownDevice {
    return Intl.message(
      'Unknown device',
      name: 'sessionUnknownDevice',
      desc: '',
      args: [],
    );
  }

  /// `Privacy`
  String get privacyTabTitle {
    return Intl.message(
      'Privacy',
      name: 'privacyTabTitle',
      desc: '',
      args: [],
    );
  }

  /// `Manage your account data securely`
  String get privacyTabSubtitle {
    return Intl.message(
      'Manage your account data securely',
      name: 'privacyTabSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Account overview`
  String get privacyAccountOverviewSection {
    return Intl.message(
      'Account overview',
      name: 'privacyAccountOverviewSection',
      desc: '',
      args: [],
    );
  }

  /// `First and last name`
  String get privacyNameRowTitle {
    return Intl.message(
      'First and last name',
      name: 'privacyNameRowTitle',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get privacyEmailRowTitle {
    return Intl.message(
      'Email',
      name: 'privacyEmailRowTitle',
      desc: '',
      args: [],
    );
  }

  /// `You can change your name once per month.`
  String get privacyNameRuleAllowed {
    return Intl.message(
      'You can change your name once per month.',
      name: 'privacyNameRuleAllowed',
      desc: '',
      args: [],
    );
  }

  /// `You can change your name after: {days} day / {hours} hour`
  String privacyNameRuleBlockedDays(Object days, Object hours) {
    return Intl.message(
      'You can change your name after: $days day / $hours hour',
      name: 'privacyNameRuleBlockedDays',
      desc: '',
      args: [days, hours],
    );
  }

  /// `You can change your name after: {hours} hour`
  String privacyNameRuleBlockedHours(Object hours) {
    return Intl.message(
      'You can change your name after: $hours hour',
      name: 'privacyNameRuleBlockedHours',
      desc: '',
      args: [hours],
    );
  }

  /// `Confirm password`
  String get privacyReauthTitle {
    return Intl.message(
      'Confirm password',
      name: 'privacyReauthTitle',
      desc: '',
      args: [],
    );
  }

  /// `For your security, enter your current password before continuing.`
  String get privacyReauthSubtitle {
    return Intl.message(
      'For your security, enter your current password before continuing.',
      name: 'privacyReauthSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Continue`
  String get privacyContinue {
    return Intl.message(
      'Continue',
      name: 'privacyContinue',
      desc: '',
      args: [],
    );
  }

  /// `Password verification failed. Please try again.`
  String get privacyReauthFailed {
    return Intl.message(
      'Password verification failed. Please try again.',
      name: 'privacyReauthFailed',
      desc: '',
      args: [],
    );
  }

  /// `Edit name`
  String get privacyEditNameTitle {
    return Intl.message(
      'Edit name',
      name: 'privacyEditNameTitle',
      desc: '',
      args: [],
    );
  }

  /// `First name`
  String get privacyFirstName {
    return Intl.message(
      'First name',
      name: 'privacyFirstName',
      desc: '',
      args: [],
    );
  }

  /// `Last name`
  String get privacyLastName {
    return Intl.message(
      'Last name',
      name: 'privacyLastName',
      desc: '',
      args: [],
    );
  }

  /// `This field is required`
  String get privacyNameValidationRequired {
    return Intl.message(
      'This field is required',
      name: 'privacyNameValidationRequired',
      desc: '',
      args: [],
    );
  }

  /// `Name must be at least 2 characters`
  String get privacyNameValidationShort {
    return Intl.message(
      'Name must be at least 2 characters',
      name: 'privacyNameValidationShort',
      desc: '',
      args: [],
    );
  }

  /// `Maximum 40 characters`
  String get privacyNameValidationLong {
    return Intl.message(
      'Maximum 40 characters',
      name: 'privacyNameValidationLong',
      desc: '',
      args: [],
    );
  }

  /// `Name updated successfully.`
  String get privacyNameSaved {
    return Intl.message(
      'Name updated successfully.',
      name: 'privacyNameSaved',
      desc: '',
      args: [],
    );
  }

  /// `Email updated locally.`
  String get privacyEmailSaved {
    return Intl.message(
      'Email updated locally.',
      name: 'privacyEmailSaved',
      desc: '',
      args: [],
    );
  }

  /// `Change email`
  String get privacyEmailFlowTitle {
    return Intl.message(
      'Change email',
      name: 'privacyEmailFlowTitle',
      desc: '',
      args: [],
    );
  }

  /// `Step {current} of {total}`
  String privacyStepOf(Object current, Object total) {
    return Intl.message(
      'Step $current of $total',
      name: 'privacyStepOf',
      desc: '',
      args: [current, total],
    );
  }

  /// `Security note: your password is never stored in the app.`
  String get privacyEmailFlowSecurityNote {
    return Intl.message(
      'Security note: your password is never stored in the app.',
      name: 'privacyEmailFlowSecurityNote',
      desc: '',
      args: [],
    );
  }

  /// `Enter your current email to verify. Hint: {masked}`
  String privacyEmailFlowStep1Help(Object masked) {
    return Intl.message(
      'Enter your current email to verify. Hint: $masked',
      name: 'privacyEmailFlowStep1Help',
      desc: '',
      args: [masked],
    );
  }

  /// `Current email`
  String get privacyEmailCurrentLabel {
    return Intl.message(
      'Current email',
      name: 'privacyEmailCurrentLabel',
      desc: '',
      args: [],
    );
  }

  /// `We'll send an email change link to your current inbox for verification.`
  String get privacyEmailFlowStep2Help {
    return Intl.message(
      'We\'ll send an email change link to your current inbox for verification.',
      name: 'privacyEmailFlowStep2Help',
      desc: '',
      args: [],
    );
  }

  /// `Send change email link`
  String get privacyEmailFlowSendLink {
    return Intl.message(
      'Send change email link',
      name: 'privacyEmailFlowSendLink',
      desc: '',
      args: [],
    );
  }

  /// `Enter your new email and confirm it.`
  String get privacyEmailFlowStep3Help {
    return Intl.message(
      'Enter your new email and confirm it.',
      name: 'privacyEmailFlowStep3Help',
      desc: '',
      args: [],
    );
  }

  /// `New email`
  String get privacyEmailNewLabel {
    return Intl.message(
      'New email',
      name: 'privacyEmailNewLabel',
      desc: '',
      args: [],
    );
  }

  /// `Confirm new email`
  String get privacyEmailConfirmLabel {
    return Intl.message(
      'Confirm new email',
      name: 'privacyEmailConfirmLabel',
      desc: '',
      args: [],
    );
  }

  /// `Review new email: {masked}`
  String privacyEmailFlowStep4Help(Object masked) {
    return Intl.message(
      'Review new email: $masked',
      name: 'privacyEmailFlowStep4Help',
      desc: '',
      args: [masked],
    );
  }

  /// `Current email does not match.`
  String get privacyEmailCurrentMismatch {
    return Intl.message(
      'Current email does not match.',
      name: 'privacyEmailCurrentMismatch',
      desc: '',
      args: [],
    );
  }

  /// `Enter and confirm your new email.`
  String get privacyEmailValidationRequired {
    return Intl.message(
      'Enter and confirm your new email.',
      name: 'privacyEmailValidationRequired',
      desc: '',
      args: [],
    );
  }

  /// `Emails do not match.`
  String get privacyEmailConfirmMismatch {
    return Intl.message(
      'Emails do not match.',
      name: 'privacyEmailConfirmMismatch',
      desc: '',
      args: [],
    );
  }

  /// `Unable to load privacy data.`
  String get privacyLoadFailed {
    return Intl.message(
      'Unable to load privacy data.',
      name: 'privacyLoadFailed',
      desc: '',
      args: [],
    );
  }

  /// `Security & Privacy`
  String get securityPrivacyTitle {
    return Intl.message(
      'Security & Privacy',
      name: 'securityPrivacyTitle',
      desc: '',
      args: [],
    );
  }

  /// `Security`
  String get securitySegmentTitle {
    return Intl.message(
      'Security',
      name: 'securitySegmentTitle',
      desc: '',
      args: [],
    );
  }

  /// `Privacy`
  String get privacySegmentTitle {
    return Intl.message(
      'Privacy',
      name: 'privacySegmentTitle',
      desc: '',
      args: [],
    );
  }

  /// `The new password must be at least 8 characters long.`
  String get privacyPasswordNewLengthError {
    return Intl.message(
      'The new password must be at least 8 characters long.',
      name: 'privacyPasswordNewLengthError',
      desc: '',
      args: [],
    );
  }

  /// `The new password must be different from the current password.`
  String get privacyPasswordMustDifferError {
    return Intl.message(
      'The new password must be different from the current password.',
      name: 'privacyPasswordMustDifferError',
      desc: '',
      args: [],
    );
  }

  /// `Passwords do not match.`
  String get privacyPasswordMismatchError {
    return Intl.message(
      'Passwords do not match.',
      name: 'privacyPasswordMismatchError',
      desc: '',
      args: [],
    );
  }

  /// `Weak`
  String get privacyPasswordStrengthWeak {
    return Intl.message(
      'Weak',
      name: 'privacyPasswordStrengthWeak',
      desc: '',
      args: [],
    );
  }

  /// `Medium`
  String get privacyPasswordStrengthMedium {
    return Intl.message(
      'Medium',
      name: 'privacyPasswordStrengthMedium',
      desc: '',
      args: [],
    );
  }

  /// `Strong`
  String get privacyPasswordStrengthStrong {
    return Intl.message(
      'Strong',
      name: 'privacyPasswordStrengthStrong',
      desc: '',
      args: [],
    );
  }

  /// `Confirm update`
  String get privacyPasswordUpdateConfirmTitle {
    return Intl.message(
      'Confirm update',
      name: 'privacyPasswordUpdateConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `Do you want to update the password?`
  String get privacyPasswordUpdateConfirmBody {
    return Intl.message(
      'Do you want to update the password?',
      name: 'privacyPasswordUpdateConfirmBody',
      desc: '',
      args: [],
    );
  }

  /// `Update`
  String get privacyPasswordUpdateAction {
    return Intl.message(
      'Update',
      name: 'privacyPasswordUpdateAction',
      desc: '',
      args: [],
    );
  }

  /// `Unable to update password. Please sign in again.`
  String get privacyPasswordUpdateRequiresSignin {
    return Intl.message(
      'Unable to update password. Please sign in again.',
      name: 'privacyPasswordUpdateRequiresSignin',
      desc: '',
      args: [],
    );
  }

  /// `Unable to verify your identity. Please try again later.`
  String get privacyPasswordReauthFailedGeneric {
    return Intl.message(
      'Unable to verify your identity. Please try again later.',
      name: 'privacyPasswordReauthFailedGeneric',
      desc: '',
      args: [],
    );
  }

  /// `Password updated successfully.`
  String get privacyPasswordUpdateSuccess {
    return Intl.message(
      'Password updated successfully.',
      name: 'privacyPasswordUpdateSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Unable to update password. Please try again later.`
  String get privacyPasswordUpdateFailed {
    return Intl.message(
      'Unable to update password. Please try again later.',
      name: 'privacyPasswordUpdateFailed',
      desc: '',
      args: [],
    );
  }

  /// `Not available`
  String get privacyNotAvailable {
    return Intl.message(
      'Not available',
      name: 'privacyNotAvailable',
      desc: '',
      args: [],
    );
  }

  /// `We will send a password reset link to your registered email: {maskedEmail}`
  String privacyResetPasswordDialogBody(Object maskedEmail) {
    return Intl.message(
      'We will send a password reset link to your registered email: $maskedEmail',
      name: 'privacyResetPasswordDialogBody',
      desc: '',
      args: [maskedEmail],
    );
  }

  /// `Send link`
  String get privacySendResetLinkAction {
    return Intl.message(
      'Send link',
      name: 'privacySendResetLinkAction',
      desc: '',
      args: [],
    );
  }

  /// `No email is linked to this account.`
  String get privacyNoEmailLinked {
    return Intl.message(
      'No email is linked to this account.',
      name: 'privacyNoEmailLinked',
      desc: '',
      args: [],
    );
  }

  /// `Password reset link sent to your email.`
  String get privacyResetLinkSent {
    return Intl.message(
      'Password reset link sent to your email.',
      name: 'privacyResetLinkSent',
      desc: '',
      args: [],
    );
  }

  /// `Unable to send reset link. Please try again later.`
  String get privacyResetLinkFailed {
    return Intl.message(
      'Unable to send reset link. Please try again later.',
      name: 'privacyResetLinkFailed',
      desc: '',
      args: [],
    );
  }

  /// `Mobile data`
  String get privacyNetworkCellular {
    return Intl.message(
      'Mobile data',
      name: 'privacyNetworkCellular',
      desc: '',
      args: [],
    );
  }

  /// `Unknown`
  String get privacyUnknown {
    return Intl.message(
      'Unknown',
      name: 'privacyUnknown',
      desc: '',
      args: [],
    );
  }

  /// `Algeria`
  String get algeriaLabel {
    return Intl.message(
      'Algeria',
      name: 'algeriaLabel',
      desc: '',
      args: [],
    );
  }

  /// `No data available yet.`
  String get privacyNoAuditDataYet {
    return Intl.message(
      'No data available yet.',
      name: 'privacyNoAuditDataYet',
      desc: '',
      args: [],
    );
  }

  /// `Last password change`
  String get privacyLastPasswordChangeTitle {
    return Intl.message(
      'Last password change',
      name: 'privacyLastPasswordChangeTitle',
      desc: '',
      args: [],
    );
  }

  /// `Date and time`
  String get privacyDateTimeLabel {
    return Intl.message(
      'Date and time',
      name: 'privacyDateTimeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Device`
  String get privacyDeviceLabel {
    return Intl.message(
      'Device',
      name: 'privacyDeviceLabel',
      desc: '',
      args: [],
    );
  }

  /// `Manufacturer`
  String get privacyManufacturerLabel {
    return Intl.message(
      'Manufacturer',
      name: 'privacyManufacturerLabel',
      desc: '',
      args: [],
    );
  }

  /// `Operating system`
  String get privacyOperatingSystemLabel {
    return Intl.message(
      'Operating system',
      name: 'privacyOperatingSystemLabel',
      desc: '',
      args: [],
    );
  }

  /// `App version`
  String get privacyAppVersionLabel {
    return Intl.message(
      'App version',
      name: 'privacyAppVersionLabel',
      desc: '',
      args: [],
    );
  }

  /// `Connection type`
  String get privacyConnectionTypeLabel {
    return Intl.message(
      'Connection type',
      name: 'privacyConnectionTypeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Approximate location`
  String get privacyApproxLocationLabel {
    return Intl.message(
      'Approximate location',
      name: 'privacyApproxLocationLabel',
      desc: '',
      args: [],
    );
  }

  /// `IP address`
  String get privacyIpAddressLabel {
    return Intl.message(
      'IP address',
      name: 'privacyIpAddressLabel',
      desc: '',
      args: [],
    );
  }

  /// `Copy full IP`
  String get privacyCopyFullIp {
    return Intl.message(
      'Copy full IP',
      name: 'privacyCopyFullIp',
      desc: '',
      args: [],
    );
  }

  /// `This wasn't me`
  String get privacyThisWasNotMe {
    return Intl.message(
      'This wasn\'t me',
      name: 'privacyThisWasNotMe',
      desc: '',
      args: [],
    );
  }

  /// `IP address is unavailable.`
  String get privacyIpUnavailable {
    return Intl.message(
      'IP address is unavailable.',
      name: 'privacyIpUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `Full IP copied securely.`
  String get privacyCopyIpSuccess {
    return Intl.message(
      'Full IP copied securely.',
      name: 'privacyCopyIpSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Verify your identity to copy the full IP.`
  String get privacyReauthCopyIpReason {
    return Intl.message(
      'Verify your identity to copy the full IP.',
      name: 'privacyReauthCopyIpReason',
      desc: '',
      args: [],
    );
  }

  /// `Critical security alert`
  String get privacySecurityAlertTitle {
    return Intl.message(
      'Critical security alert',
      name: 'privacySecurityAlertTitle',
      desc: '',
      args: [],
    );
  }

  /// `If you did not change the password, we will immediately sign out all other sessions. Do you want to continue?`
  String get privacySecurityAlertBody {
    return Intl.message(
      'If you did not change the password, we will immediately sign out all other sessions. Do you want to continue?',
      name: 'privacySecurityAlertBody',
      desc: '',
      args: [],
    );
  }

  /// `Continue`
  String get privacyContinueAction {
    return Intl.message(
      'Continue',
      name: 'privacyContinueAction',
      desc: '',
      args: [],
    );
  }

  /// `Other sessions were signed out as a precaution.`
  String get privacyOtherSessionsRevokedPrecaution {
    return Intl.message(
      'Other sessions were signed out as a precaution.',
      name: 'privacyOtherSessionsRevokedPrecaution',
      desc: '',
      args: [],
    );
  }

  /// `Unable to end all sessions right now.`
  String get privacyRevokeSessionsFailed {
    return Intl.message(
      'Unable to end all sessions right now.',
      name: 'privacyRevokeSessionsFailed',
      desc: '',
      args: [],
    );
  }

  /// `Please change your password immediately. Two-step verification: coming soon.`
  String get privacyChangePasswordNowNote {
    return Intl.message(
      'Please change your password immediately. Two-step verification: coming soon.',
      name: 'privacyChangePasswordNowNote',
      desc: '',
      args: [],
    );
  }

  /// `Change password`
  String get privacyChangePasswordTitle {
    return Intl.message(
      'Change password',
      name: 'privacyChangePasswordTitle',
      desc: '',
      args: [],
    );
  }

  /// `Current password`
  String get privacyCurrentPasswordLabel {
    return Intl.message(
      'Current password',
      name: 'privacyCurrentPasswordLabel',
      desc: '',
      args: [],
    );
  }

  /// `Enter your current password to verify account ownership.`
  String get privacyCurrentPasswordHelper {
    return Intl.message(
      'Enter your current password to verify account ownership.',
      name: 'privacyCurrentPasswordHelper',
      desc: '',
      args: [],
    );
  }

  /// `The email may arrive within a minute. Check your spam folder too.`
  String get privacyResetEmailHint {
    return Intl.message(
      'The email may arrive within a minute. Check your spam folder too.',
      name: 'privacyResetEmailHint',
      desc: '',
      args: [],
    );
  }

  /// `New password`
  String get privacyNewPasswordLabel {
    return Intl.message(
      'New password',
      name: 'privacyNewPasswordLabel',
      desc: '',
      args: [],
    );
  }

  /// `It must contain at least 8 characters.`
  String get privacyNewPasswordHelper {
    return Intl.message(
      'It must contain at least 8 characters.',
      name: 'privacyNewPasswordHelper',
      desc: '',
      args: [],
    );
  }

  /// `Password strength: `
  String get privacyPasswordStrengthLabel {
    return Intl.message(
      'Password strength: ',
      name: 'privacyPasswordStrengthLabel',
      desc: '',
      args: [],
    );
  }

  /// `Confirm new password`
  String get privacyConfirmNewPasswordLabel {
    return Intl.message(
      'Confirm new password',
      name: 'privacyConfirmNewPasswordLabel',
      desc: '',
      args: [],
    );
  }

  /// `Re-enter your new password for confirmation.`
  String get privacyConfirmNewPasswordHelper {
    return Intl.message(
      'Re-enter your new password for confirmation.',
      name: 'privacyConfirmNewPasswordHelper',
      desc: '',
      args: [],
    );
  }

  /// `Enter confirmation to verify the match.`
  String get privacyEnterConfirmToMatch {
    return Intl.message(
      'Enter confirmation to verify the match.',
      name: 'privacyEnterConfirmToMatch',
      desc: '',
      args: [],
    );
  }

  /// `Passwords match.`
  String get privacyPasswordsMatch {
    return Intl.message(
      'Passwords match.',
      name: 'privacyPasswordsMatch',
      desc: '',
      args: [],
    );
  }

  /// `Loading last change data...`
  String get privacyLoadingLastChange {
    return Intl.message(
      'Loading last change data...',
      name: 'privacyLoadingLastChange',
      desc: '',
      args: [],
    );
  }

  /// `Last password change: Not available`
  String get privacyLastPasswordChangeUnavailable {
    return Intl.message(
      'Last password change: Not available',
      name: 'privacyLastPasswordChangeUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `Last password change: {date}`
  String privacyLastPasswordChangeAt(Object date) {
    return Intl.message(
      'Last password change: $date',
      name: 'privacyLastPasswordChangeAt',
      desc: '',
      args: [date],
    );
  }

  /// `View details ⌄`
  String get privacyViewDetails {
    return Intl.message(
      'View details ⌄',
      name: 'privacyViewDetails',
      desc: '',
      args: [],
    );
  }

  /// `Save new password`
  String get privacySaveNewPassword {
    return Intl.message(
      'Save new password',
      name: 'privacySaveNewPassword',
      desc: '',
      args: [],
    );
  }

  /// `{minutes} min ago`
  String sessionAgoMinutes(Object minutes) {
    return Intl.message(
      '$minutes min ago',
      name: 'sessionAgoMinutes',
      desc: '',
      args: [minutes],
    );
  }

  /// `{hours} h ago`
  String sessionAgoHours(Object hours) {
    return Intl.message(
      '$hours h ago',
      name: 'sessionAgoHours',
      desc: '',
      args: [hours],
    );
  }

  /// `{days} d ago`
  String sessionAgoDays(Object days) {
    return Intl.message(
      '$days d ago',
      name: 'sessionAgoDays',
      desc: '',
      args: [days],
    );
  }

  /// `Device name`
  String get sessionDeviceNameLabel {
    return Intl.message(
      'Device name',
      name: 'sessionDeviceNameLabel',
      desc: '',
      args: [],
    );
  }

  /// `Trusted device`
  String get sessionTrustedDevice {
    return Intl.message(
      'Trusted device',
      name: 'sessionTrustedDevice',
      desc: '',
      args: [],
    );
  }

  /// `Model`
  String get sessionModelLabel {
    return Intl.message(
      'Model',
      name: 'sessionModelLabel',
      desc: '',
      args: [],
    );
  }

  /// `Platform`
  String get sessionPlatformLabel {
    return Intl.message(
      'Platform',
      name: 'sessionPlatformLabel',
      desc: '',
      args: [],
    );
  }

  /// `Version`
  String get sessionVersionLabel {
    return Intl.message(
      'Version',
      name: 'sessionVersionLabel',
      desc: '',
      args: [],
    );
  }

  /// `Login date`
  String get sessionLoginDateLabel {
    return Intl.message(
      'Login date',
      name: 'sessionLoginDateLabel',
      desc: '',
      args: [],
    );
  }

  /// `Last activity`
  String get sessionLastActivityLabel {
    return Intl.message(
      'Last activity',
      name: 'sessionLastActivityLabel',
      desc: '',
      args: [],
    );
  }

  /// `Network`
  String get sessionNetworkLabel {
    return Intl.message(
      'Network',
      name: 'sessionNetworkLabel',
      desc: '',
      args: [],
    );
  }

  /// `Danger zone`
  String get dangerZone {
    return Intl.message(
      'Danger zone',
      name: 'dangerZone',
      desc: '',
      args: [],
    );
  }

  /// `Calculating the academic average`
  String get gpu {
    return Intl.message(
      'Calculating the academic average',
      name: 'gpu',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ar'),
      Locale.fromSubtags(languageCode: 'fr'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
