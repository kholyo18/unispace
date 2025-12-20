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

  /// `Post`
  String get posted {
    return Intl.message(
      'Post',
      name: 'posted',
      desc: '',
      args: [],
    );
  }

  /// `Search inside clipboard…`
  String get searchClipboard {
    return Intl.message(
      'Search inside clipboard…',
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

  /// `Clipboard`
  String get clipboard {
    return Intl.message(
      'Clipboard',
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

  /// `Contact Us`
  String get contactUs {
    return Intl.message(
      'Contact Us',
      name: 'contactUs',
      desc: '',
      args: [],
    );
  }

  /// `Subject`
  String get subject {
    return Intl.message(
      'Subject',
      name: 'subject',
      desc: '',
      args: [],
    );
  }

  /// `Write your message here...`
  String get writeMessageHint {
    return Intl.message(
      'Write your message here...',
      name: 'writeMessageHint',
      desc: '',
      args: [],
    );
  }

  /// `Send`
  String get send {
    return Intl.message(
      'Send',
      name: 'send',
      desc: '',
      args: [],
    );
  }

  /// `Please write a message`
  String get pleaseWriteMessage {
    return Intl.message(
      'Please write a message',
      name: 'pleaseWriteMessage',
      desc: '',
      args: [],
    );
  }

  /// `Failed to open mail app`
  String get failedToOpenMailApp {
    return Intl.message(
      'Failed to open mail app',
      name: 'failedToOpenMailApp',
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
  String get Pass {
    return Intl.message(
      ' Passed',
      name: 'Pass',
      desc: '',
      args: [],
    );
  }

  /// ` Failed`
  String get Fail {
    return Intl.message(
      ' Failed',
      name: 'Fail',
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

  /// `Coefficient:`
  String get coefficient {
    return Intl.message(
      'Coefficient:',
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

  /// `Search posts...`
  String get searchPosts {
    return Intl.message(
      'Search posts...',
      name: 'searchPosts',
      desc: '',
      args: [],
    );
  }

  /// `All`
  String get filterAll {
    return Intl.message(
      'All',
      name: 'filterAll',
      desc: '',
      args: [],
    );
  }

  /// `My University`
  String get filterMyUniversity {
    return Intl.message(
      'My University',
      name: 'filterMyUniversity',
      desc: '',
      args: [],
    );
  }

  /// `Questions`
  String get filterQuestions {
    return Intl.message(
      'Questions',
      name: 'filterQuestions',
      desc: '',
      args: [],
    );
  }

  /// `Trending`
  String get filterTrending {
    return Intl.message(
      'Trending',
      name: 'filterTrending',
      desc: '',
      args: [],
    );
  }

  /// `Saved`
  String get filterSaved {
    return Intl.message(
      'Saved',
      name: 'filterSaved',
      desc: '',
      args: [],
    );
  }

  /// `Later`
  String get savedCategoryLater {
    return Intl.message(
      'Later',
      name: 'savedCategoryLater',
      desc: '',
      args: [],
    );
  }

  /// `Exams`
  String get savedCategoryExams {
    return Intl.message(
      'Exams',
      name: 'savedCategoryExams',
      desc: '',
      args: [],
    );
  }

  /// `Advice`
  String get savedCategoryAdvice {
    return Intl.message(
      'Advice',
      name: 'savedCategoryAdvice',
      desc: '',
      args: [],
    );
  }

  /// `Choose category`
  String get chooseCategory {
    return Intl.message(
      'Choose category',
      name: 'chooseCategory',
      desc: '',
      args: [],
    );
  }

  /// `Saved to {category}`
  String savedToCategory(Object category) {
    return Intl.message(
      'Saved to $category',
      name: 'savedToCategory',
      desc: '',
      args: [category],
    );
  }

  /// `Tags`
  String get tags {
    return Intl.message(
      'Tags',
      name: 'tags',
      desc: '',
      args: [],
    );
  }

  /// `e.g. #campus, #clubs`
  String get tagsHint {
    return Intl.message(
      'e.g. #campus, #clubs',
      name: 'tagsHint',
      desc: '',
      args: [],
    );
  }

  /// `Post as a question`
  String get postAsQuestion {
    return Intl.message(
      'Post as a question',
      name: 'postAsQuestion',
      desc: '',
      args: [],
    );
  }

  /// `Publishing...`
  String get publishing {
    return Intl.message(
      'Publishing...',
      name: 'publishing',
      desc: '',
      args: [],
    );
  }

  /// `Please write something before publishing.`
  String get contentRequired {
    return Intl.message(
      'Please write something before publishing.',
      name: 'contentRequired',
      desc: '',
      args: [],
    );
  }

  /// `Your post has been published ✅`
  String get postPublished {
    return Intl.message(
      'Your post has been published ✅',
      name: 'postPublished',
      desc: '',
      args: [],
    );
  }

  /// `Please log in to continue.`
  String get loginRequired {
    return Intl.message(
      'Please log in to continue.',
      name: 'loginRequired',
      desc: '',
      args: [],
    );
  }

  /// `Sign in to create posts, like, and comment.`
  String get loginToContinue {
    return Intl.message(
      'Sign in to create posts, like, and comment.',
      name: 'loginToContinue',
      desc: '',
      args: [],
    );
  }

  /// `University not set`
  String get universityNotSet {
    return Intl.message(
      'University not set',
      name: 'universityNotSet',
      desc: '',
      args: [],
    );
  }

  /// `Add your university in your profile to see this feed.`
  String get universityNotSetHint {
    return Intl.message(
      'Add your university in your profile to see this feed.',
      name: 'universityNotSetHint',
      desc: '',
      args: [],
    );
  }

  /// `Something went wrong. Please try again.`
  String get somethingWentWrong {
    return Intl.message(
      'Something went wrong. Please try again.',
      name: 'somethingWentWrong',
      desc: '',
      args: [],
    );
  }

  /// `No posts match your search.`
  String get noSearchResults {
    return Intl.message(
      'No posts match your search.',
      name: 'noSearchResults',
      desc: '',
      args: [],
    );
  }

  /// `Save post`
  String get savePost {
    return Intl.message(
      'Save post',
      name: 'savePost',
      desc: '',
      args: [],
    );
  }

  /// `Like`
  String get like {
    return Intl.message(
      'Like',
      name: 'like',
      desc: '',
      args: [],
    );
  }

  /// `Question`
  String get questionTag {
    return Intl.message(
      'Question',
      name: 'questionTag',
      desc: '',
      args: [],
    );
  }

  /// `Post Details`
  String get postDetails {
    return Intl.message(
      'Post Details',
      name: 'postDetails',
      desc: '',
      args: [],
    );
  }

  /// `No comments yet`
  String get noCommentsYet {
    return Intl.message(
      'No comments yet',
      name: 'noCommentsYet',
      desc: '',
      args: [],
    );
  }

  /// `Be the first to add a helpful reply.`
  String get beFirstToComment {
    return Intl.message(
      'Be the first to add a helpful reply.',
      name: 'beFirstToComment',
      desc: '',
      args: [],
    );
  }

  /// `Unanswered`
  String get filterUnanswered {
    return Intl.message(
      'Unanswered',
      name: 'filterUnanswered',
      desc: '',
      args: [],
    );
  }

  /// `Create first post`
  String get createFirstPost {
    return Intl.message(
      'Create first post',
      name: 'createFirstPost',
      desc: '',
      args: [],
    );
  }

  /// `No results`
  String get noResultsTitle {
    return Intl.message(
      'No results',
      name: 'noResultsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Clear search`
  String get clearSearch {
    return Intl.message(
      'Clear search',
      name: 'clearSearch',
      desc: '',
      args: [],
    );
  }

  /// `Clear tags`
  String get clearTags {
    return Intl.message(
      'Clear tags',
      name: 'clearTags',
      desc: '',
      args: [],
    );
  }

  /// `Reset filters`
  String get resetFilters {
    return Intl.message(
      'Reset filters',
      name: 'resetFilters',
      desc: '',
      args: [],
    );
  }

  /// `Suggested tags`
  String get suggestedTags {
    return Intl.message(
      'Suggested tags',
      name: 'suggestedTags',
      desc: '',
      args: [],
    );
  }

  /// `Add tag`
  String get addTag {
    return Intl.message(
      'Add tag',
      name: 'addTag',
      desc: '',
      args: [],
    );
  }

  /// `OP`
  String get opBadge {
    return Intl.message(
      'OP',
      name: 'opBadge',
      desc: '',
      args: [],
    );
  }

  /// `Sort comments`
  String get sortComments {
    return Intl.message(
      'Sort comments',
      name: 'sortComments',
      desc: '',
      args: [],
    );
  }

  /// `Newest`
  String get sortNewest {
    return Intl.message(
      'Newest',
      name: 'sortNewest',
      desc: '',
      args: [],
    );
  }

  /// `Most helpful`
  String get sortMostHelpful {
    return Intl.message(
      'Most helpful',
      name: 'sortMostHelpful',
      desc: '',
      args: [],
    );
  }

  /// `Best Answer`
  String get bestAnswerLabel {
    return Intl.message(
      'Best Answer',
      name: 'bestAnswerLabel',
      desc: '',
      args: [],
    );
  }

  /// `Mark as Best Answer`
  String get markBestAnswer {
    return Intl.message(
      'Mark as Best Answer',
      name: 'markBestAnswer',
      desc: '',
      args: [],
    );
  }

  /// `Unmark Best Answer`
  String get unmarkBestAnswer {
    return Intl.message(
      'Unmark Best Answer',
      name: 'unmarkBestAnswer',
      desc: '',
      args: [],
    );
  }

  /// `Helper`
  String get helperBadge {
    return Intl.message(
      'Helper',
      name: 'helperBadge',
      desc: '',
      args: [],
    );
  }

  /// `Top Contributor`
  String get topContributorBadge {
    return Intl.message(
      'Top Contributor',
      name: 'topContributorBadge',
      desc: '',
      args: [],
    );
  }

  /// `Share something with the community…`
  String get postHint {
    return Intl.message(
      'Share something with the community…',
      name: 'postHint',
      desc: '',
      args: [],
    );
  }

  /// `Question`
  String get questionPrompt {
    return Intl.message(
      'Question',
      name: 'questionPrompt',
      desc: '',
      args: [],
    );
  }

  /// `What do you need help with?`
  String get questionHint {
    return Intl.message(
      'What do you need help with?',
      name: 'questionHint',
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
