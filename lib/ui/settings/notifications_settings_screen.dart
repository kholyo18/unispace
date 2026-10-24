import '../../features/exams/notifications/exam_notifications_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import '../../generated/l10n.dart';
import '../../l10n/auth_settings_strings.dart';
import 'app_settings.dart';
import 'push_preferences_service.dart';
import 'settings_components.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});
  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> with WidgetsBindingObserver {
  AuthorizationStatus? _permission;
  bool _saving = false;
  bool _checking = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refreshPermission());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refreshPermission());
  }

  Future<void> _refreshPermission({bool request = false}) async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final settings = request
          ? await FirebaseMessaging.instance
              .requestPermission(alert: true, badge: true, sound: true)
          : await FirebaseMessaging.instance.getNotificationSettings();
      if (mounted) setState(() => _permission = settings.authorizationStatus);
    } catch (_) {
      if (mounted) setState(() => _permission = null);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _save(Future<void> Function() update,
      {bool enable = false}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await update();
      if (enable && mounted)
        await _refreshPermission(
            request: _permission == AuthorizationStatus.notDetermined);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(authSettingsText(context, 'تعذر حفظ الإعداد'))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final blocked = _permission == AuthorizationStatus.denied;
    final permissionText = _checking
        ? 'جارٍ التحقق من إذن الإشعارات…'
        : blocked
            ? 'الإشعارات محظورة في إعدادات الهاتف. اسمح بها لتلقي التنبيهات.'
            : _permission == AuthorizationStatus.authorized ||
                    _permission == AuthorizationStatus.provisional
                ? 'إذن الإشعارات متاح على هذا الجهاز.'
                : _permission == AuthorizationStatus.notDetermined
                    ? 'لم يُمنح إذن الإشعارات بعد.'
                    : 'تعذر التحقق من إذن الإشعارات.';
    return Scaffold(
      appBar: AppBar(title: Text(s.notificationsSettingsTitle)),
      body: ValueListenableBuilder<SettingsData>(
        valueListenable: AppSettings.instance.notifier,
        builder: (context, settings, _) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              SettingsIntro(
                  icon: Icons.notifications_outlined,
                  title: s.notificationsSettingsTitle,
                  subtitle: s.notificationsSettingsDescription),
              SettingsPanel(children: [
                SwitchListTile.adaptive(
                    key: const ValueKey('notifications-master'),
                    secondary:
                        const SettingsIcon(Icons.notifications_active_outlined),
                    title: Text(s.notificationsEnabled),
                    subtitle: Text(s.notificationsEnabledHint),
                    value: settings.notificationsEnabled,
                    onChanged: _saving
                        ? null
                        : (v) => _save(
                            () =>
                                AppSettings.instance.setNotificationsEnabled(v),
                            enable: v)),
              ]),
              const SizedBox(height: 20),
              SettingsSectionTitle(
                  authSettingsText(context, 'أنواع الإشعارات')),
              SettingsPanel(dividers: true, children: [
                _toggle(
                    'exams',
                    Icons.event_note_outlined,
                    s.notificationsExamReminders,
                    s.notificationsExamRemindersHint,
                    settings.examRemindersEnabled,
                    settings.notificationsEnabled,
                    AppSettings.instance.setExamRemindersEnabled),
                _toggle(
                    'announcements',
                    Icons.campaign_outlined,
                    s.notificationsAnnouncements,
                    s.notificationsAnnouncementsHint,
                    settings.announcementsEnabled,
                    settings.notificationsEnabled,
                    AppSettings.instance.setAnnouncementsEnabled),
                _toggle(
                    'community',
                    Icons.groups_outlined,
                    s.notificationsCommunity,
                    s.notificationsCommunityHint,
                    settings.communityUpdatesEnabled,
                    settings.notificationsEnabled,
                    AppSettings.instance.setCommunityUpdatesEnabled),
              ]),
              if (!settings.notificationsEnabled)
                Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(s.notificationsDisabledHint)),
              const SizedBox(height: 20),
              ValueListenableBuilder<String?>(
                  valueListenable: ExamNotificationsService.instance.error,
                  builder: (context, error, _) => error == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SettingsPanel(children: [
                            ListTile(
                                title: Text(authSettingsText(context, error)),
                                trailing: IconButton(
                                    icon: const Icon(Icons.refresh),
                                    tooltip: authSettingsText(
                                        context, 'إعادة المحاولة'),
                                    onPressed: () async {
                                      try {
                                        await ExamNotificationsService.instance
                                            .refreshSavedReminders();
                                      } catch (_) {}
                                    })),
                          ]))),
              SettingsSectionTitle(
                  authSettingsText(context, 'إشعارات هذا الجهاز')),
              SettingsPanel(dividers: true, children: [
                ListTile(
                    leading: SettingsIcon(blocked
                        ? Icons.notifications_off_outlined
                        : Icons.phonelink_setup),
                    title: Text(authSettingsText(context, 'إذن الإشعارات')),
                    subtitle: Text(authSettingsText(context, permissionText))),
                Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton(
                            onPressed: _checking
                                ? null
                                : () async {
                                    if (blocked) {
                                      await Geolocator.openAppSettings();
                                    } else {
                                      await _refreshPermission(
                                          request: _permission ==
                                              AuthorizationStatus
                                                  .notDetermined);
                                    }
                                  },
                            child: Text(authSettingsText(
                                context,
                                blocked
                                    ? 'فتح إعدادات الهاتف'
                                    : 'التحقق من الإذن'))))),
                ValueListenableBuilder<String>(
                    valueListenable: PushPreferencesService.instance.status,
                    builder: (context, status, _) => ListTile(
                          leading: const SettingsIcon(Icons.sync),
                          title: Text(
                              authSettingsText(context, 'مزامنة الإشعارات')),
                          subtitle: Text(authSettingsText(context, status)),
                          trailing: IconButton(
                              tooltip:
                                  authSettingsText(context, 'إعادة المزامنة'),
                              icon: const Icon(Icons.refresh),
                              onPressed: () =>
                                  PushPreferencesService.instance.sync()),
                        )),
              ]),
            ]),
      ),
    );
  }

  Widget _toggle(String key, IconData icon, String title, String hint,
          bool value, bool enabled, Future<void> Function(bool) update) =>
      SwitchListTile.adaptive(
          key: ValueKey('notifications-$key'),
          secondary: SettingsIcon(icon),
          title: Text(title),
          subtitle: Text(hint),
          value: value,
          onChanged:
              !enabled || _saving ? null : (v) => _save(() => update(v)));
}
