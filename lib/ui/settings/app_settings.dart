import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ProfileVisibility { public, private }

enum FontScaleOption { small, medium, large }

extension FontScaleOptionX on FontScaleOption {
  double get scale {
    switch (this) {
      case FontScaleOption.small:
        return 0.9;
      case FontScaleOption.medium:
        return 1.0;
      case FontScaleOption.large:
        return 1.15;
    }
  }

  String get storageKey {
    switch (this) {
      case FontScaleOption.small:
        return 'small';
      case FontScaleOption.medium:
        return 'medium';
      case FontScaleOption.large:
        return 'large';
    }
  }

  static FontScaleOption fromStorageKey(String? key) {
    switch (key) {
      case 'small':
        return FontScaleOption.small;
      case 'large':
        return FontScaleOption.large;
      case 'medium':
      default:
        return FontScaleOption.medium;
    }
  }
}

@immutable
class SettingsData {
  const SettingsData({
    required this.notificationsEnabled,
    required this.examRemindersEnabled,
    required this.announcementsEnabled,
    required this.communityUpdatesEnabled,
    required this.showEmailInProfile,
    required this.profileVisibility,
    required this.fontScale,
  });

  final bool notificationsEnabled;
  final bool examRemindersEnabled;
  final bool announcementsEnabled;
  final bool communityUpdatesEnabled;
  final bool showEmailInProfile;
  final ProfileVisibility profileVisibility;
  final FontScaleOption fontScale;

  factory SettingsData.initial() => const SettingsData(
        notificationsEnabled: true,
        examRemindersEnabled: true,
        announcementsEnabled: true,
        communityUpdatesEnabled: true,
        showEmailInProfile: true,
        profileVisibility: ProfileVisibility.public,
        fontScale: FontScaleOption.medium,
      );

  SettingsData copyWith({
    bool? notificationsEnabled,
    bool? examRemindersEnabled,
    bool? announcementsEnabled,
    bool? communityUpdatesEnabled,
    bool? showEmailInProfile,
    ProfileVisibility? profileVisibility,
    FontScaleOption? fontScale,
  }) {
    return SettingsData(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      examRemindersEnabled:
          examRemindersEnabled ?? this.examRemindersEnabled,
      announcementsEnabled: announcementsEnabled ?? this.announcementsEnabled,
      communityUpdatesEnabled:
          communityUpdatesEnabled ?? this.communityUpdatesEnabled,
      showEmailInProfile: showEmailInProfile ?? this.showEmailInProfile,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      fontScale: fontScale ?? this.fontScale,
    );
  }
}

class AppSettings {
  AppSettings._();

  static final AppSettings instance = AppSettings._();

  static const _kNotificationsEnabled = 'settings_notifications_enabled';
  static const _kExamRemindersEnabled = 'settings_exam_reminders_enabled';
  static const _kAnnouncementsEnabled = 'settings_announcements_enabled';
  static const _kCommunityUpdatesEnabled =
      'settings_community_updates_enabled';
  static const _kShowEmailInProfile = 'settings_show_email_in_profile';
  static const _kProfileVisibility = 'settings_profile_visibility';
  static const _kFontScale = 'settings_font_scale';

  final ValueNotifier<SettingsData> notifier =
      ValueNotifier<SettingsData>(SettingsData.initial());

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs!;
    final notificationsEnabled =
        prefs.getBool(_kNotificationsEnabled) ?? true;
    final examRemindersEnabled =
        prefs.getBool(_kExamRemindersEnabled) ?? true;
    final announcementsEnabled =
        prefs.getBool(_kAnnouncementsEnabled) ?? true;
    final communityUpdatesEnabled =
        prefs.getBool(_kCommunityUpdatesEnabled) ?? true;
    final showEmailInProfile = prefs.getBool(_kShowEmailInProfile) ?? true;
    final profileVisibilityRaw = prefs.getString(_kProfileVisibility);
    final fontScaleRaw = prefs.getString(_kFontScale);

    notifier.value = SettingsData(
      notificationsEnabled: notificationsEnabled,
      examRemindersEnabled: examRemindersEnabled,
      announcementsEnabled: announcementsEnabled,
      communityUpdatesEnabled: communityUpdatesEnabled,
      showEmailInProfile: showEmailInProfile,
      profileVisibility: profileVisibilityRaw == 'private'
          ? ProfileVisibility.private
          : ProfileVisibility.public,
      fontScale: FontScaleOptionX.fromStorageKey(fontScaleRaw),
    );
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _update(notifier.value.copyWith(notificationsEnabled: value));
  }

  Future<void> setExamRemindersEnabled(bool value) async {
    await _update(notifier.value.copyWith(examRemindersEnabled: value));
  }

  Future<void> setAnnouncementsEnabled(bool value) async {
    await _update(notifier.value.copyWith(announcementsEnabled: value));
  }

  Future<void> setCommunityUpdatesEnabled(bool value) async {
    await _update(notifier.value.copyWith(communityUpdatesEnabled: value));
  }

  Future<void> setShowEmailInProfile(bool value) async {
    await _update(notifier.value.copyWith(showEmailInProfile: value));
  }

  Future<void> setProfileVisibility(ProfileVisibility value) async {
    await _update(notifier.value.copyWith(profileVisibility: value));
  }

  Future<void> setFontScale(FontScaleOption value) async {
    await _update(notifier.value.copyWith(fontScale: value));
  }

  Future<void> _update(SettingsData data) async {
    notifier.value = data;
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs!;
    await prefs.setBool(_kNotificationsEnabled, data.notificationsEnabled);
    await prefs.setBool(_kExamRemindersEnabled, data.examRemindersEnabled);
    await prefs.setBool(_kAnnouncementsEnabled, data.announcementsEnabled);
    await prefs.setBool(
      _kCommunityUpdatesEnabled,
      data.communityUpdatesEnabled,
    );
    await prefs.setBool(_kShowEmailInProfile, data.showEmailInProfile);
    await prefs.setString(
      _kProfileVisibility,
      data.profileVisibility == ProfileVisibility.private ? 'private' : 'public',
    );
    await prefs.setString(_kFontScale, data.fontScale.storageKey);
  }
}
