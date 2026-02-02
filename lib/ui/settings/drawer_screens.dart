import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../generated/l10n.dart';
import 'app_settings.dart';
import 'blocked_users_service.dart';
import 'favorites_service.dart';
import 'security_service.dart';
import 'user_profile_service.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).notificationsSettingsTitle),
      ),
      body: ValueListenableBuilder<SettingsData>(
        valueListenable: AppSettings.instance.notifier,
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                S.of(context).notificationsSettingsDescription,
                style: theme.textTheme.bodyMedium,
              ),
              // TODO: Hook these preferences to FCM or a backend notification hub.
              const SizedBox(height: 16),
              SwitchListTile.adaptive(
                value: settings.notificationsEnabled,
                title: Text(S.of(context).notificationsEnabled),
                subtitle: Text(S.of(context).notificationsEnabledHint),
                onChanged: (value) =>
                    AppSettings.instance.setNotificationsEnabled(value),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                value: settings.examRemindersEnabled,
                title: Text(S.of(context).notificationsExamReminders),
                subtitle: Text(S.of(context).notificationsExamRemindersHint),
                onChanged: settings.notificationsEnabled
                    ? (value) =>
                        AppSettings.instance.setExamRemindersEnabled(value)
                    : null,
              ),
              SwitchListTile.adaptive(
                value: settings.announcementsEnabled,
                title: Text(S.of(context).notificationsAnnouncements),
                subtitle: Text(S.of(context).notificationsAnnouncementsHint),
                onChanged: settings.notificationsEnabled
                    ? (value) =>
                        AppSettings.instance.setAnnouncementsEnabled(value)
                    : null,
              ),
              SwitchListTile.adaptive(
                value: settings.communityUpdatesEnabled,
                title: Text(S.of(context).notificationsCommunity),
                subtitle: Text(S.of(context).notificationsCommunityHint),
                onChanged: settings.notificationsEnabled
                    ? (value) =>
                        AppSettings.instance.setCommunityUpdatesEnabled(value)
                    : null,
              ),
              if (!settings.notificationsEnabled)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    S.of(context).notificationsDisabledHint,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class SecurityCenterScreen extends StatefulWidget {
  const SecurityCenterScreen({super.key});

  @override
  State<SecurityCenterScreen> createState() => _SecurityCenterScreenState();
}

class _SecurityCenterScreenState extends State<SecurityCenterScreen> {
  Future<void> _logoutAllDevices(BuildContext context) async {
    final s = S.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.signInRequired)),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.logoutAllDevices),
        content: Text(s.logoutAllDevicesPrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.logoutAllConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final result = await SecurityService.instance.logoutAllDevices();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.backendSupported
                ? s.logoutAllSuccess
                : s.logoutAllLocalOnly,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.logoutAllFailed)),
      );
    }
  }

  String _currentDeviceLabel() {
    if (kIsWeb) return 'Web';
    return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).securityCenterTitle),
      ),
      body: ValueListenableBuilder<UserProfileData>(
        valueListenable: UserProfileService.instance.notifier,
        builder: (context, profile, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile.adaptive(
                value: profile.twoFactorEnabled,
                title: Text(S.of(context).twoFactorAuthTitle),
                subtitle: Text(S.of(context).twoFactorAuthHint),
                onChanged: (value) async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(S.of(context).signInRequired)),
                    );
                    return;
                  }
                  await UserProfileService.instance
                      .updateProfile(twoFactorEnabled: value);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value
                            ? S.of(context).twoFactorEnabledToast
                            : S.of(context).twoFactorDisabledToast,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.devices_other),
                title: Text(S.of(context).manageDevicesTitle),
                subtitle: Text(S.of(context).manageDevicesHint),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ManageDevicesScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                S.of(context).trustedDevicesTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.phone_android),
                  title: Text(S.of(context).devicePrimary),
                  subtitle: Text(_currentDeviceLabel()),
                  trailing: TextButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                    child: Text(S.of(context).signOut),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _logoutAllDevices(context),
                icon: const Icon(Icons.logout),
                label: Text(S.of(context).logoutAllDevices),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  Future<void> _promptBlockUser() async {
    final s = S.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.signInRequired)),
      );
      return;
    }
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.blockedUsersAddTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: s.blockedUsersAddHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.blockedUsersAddAction),
          ),
        ],
      ),
    );
    final value = controller.text.trim();
    if (confirmed == true && value.isNotEmpty) {
      await BlockedUsersService.instance.blockUser(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).privacySettingsTitle),
      ),
      body: ValueListenableBuilder<UserProfileData>(
        valueListenable: UserProfileService.instance.notifier,
        builder: (context, profile, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                S.of(context).privacySettingsDescription,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                S.of(context).profileVisibilityTitle,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              RadioListTile<ProfileVisibility>(
                value: ProfileVisibility.public,
                groupValue: profile.profileVisibility,
                title: Text(S.of(context).profileVisibilityPublic),
                onChanged: (value) {
                  if (value != null) {
                    UserProfileService.instance
                        .updateProfile(profileVisibility: value);
                  }
                },
              ),
              RadioListTile<ProfileVisibility>(
                value: ProfileVisibility.private,
                groupValue: profile.profileVisibility,
                title: Text(S.of(context).profileVisibilityPrivate),
                onChanged: (value) {
                  if (value != null) {
                    UserProfileService.instance
                        .updateProfile(profileVisibility: value);
                  }
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile.adaptive(
                value: profile.showEmailInProfile,
                title: Text(S.of(context).showEmailInProfileTitle),
                subtitle: Text(S.of(context).showEmailInProfileHint),
                onChanged: (value) => UserProfileService.instance
                    .updateProfile(showEmailInProfile: value),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    S.of(context).blockedUsersTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  TextButton.icon(
                    onPressed: _promptBlockUser,
                    icon: const Icon(Icons.person_add_disabled),
                    label: Text(S.of(context).blockedUsersAddAction),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<BlockedUser>>(
                stream: BlockedUsersService.instance.streamBlockedUsers(),
                builder: (context, snapshot) {
                  final blockedUsers = snapshot.data ?? [];
                  if (blockedUsers.isEmpty) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.block),
                        title: Text(S.of(context).blockedUsersEmpty),
                        subtitle: Text(S.of(context).blockedUsersHint),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final blocked in blockedUsers)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.block),
                            title: Text(blocked.identifier),
                            subtitle: blocked.createdAt == null
                                ? null
                                : Text(
                                    S.of(context).blockedUsersSince(
                                      MaterialLocalizations.of(context)
                                          .formatShortDate(blocked.createdAt!),
                                    ),
                                  ),
                            trailing: TextButton(
                              onPressed: () async {
                                await BlockedUsersService.instance
                                    .unblockUser(blocked.id);
                              },
                              child: Text(S.of(context).unblockUser),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class AcademicSettingsScreen extends StatefulWidget {
  const AcademicSettingsScreen({super.key});

  @override
  State<AcademicSettingsScreen> createState() => _AcademicSettingsScreenState();
}

class _AcademicSettingsScreenState extends State<AcademicSettingsScreen> {
  final _collegeController = TextEditingController();
  final _majorController = TextEditingController();
  final _levelController = TextEditingController();
  bool _seededProfileValues = false;
  late final VoidCallback _profileListener;

  @override
  void initState() {
    super.initState();
    _profileListener = () {
      if (_seededProfileValues) return;
      final data = UserProfileService.instance.notifier.value;
      if (data.college.isEmpty && data.major.isEmpty && data.level.isEmpty) {
        return;
      }
      _collegeController.text = data.college;
      _majorController.text = data.major;
      _levelController.text = data.level;
      _seededProfileValues = true;
    };
    UserProfileService.instance.notifier.addListener(_profileListener);
    _profileListener();
  }

  @override
  void dispose() {
    UserProfileService.instance.notifier.removeListener(_profileListener);
    _collegeController.dispose();
    _majorController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).academicSettingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            S.of(context).academicSettingsDescription,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _collegeController,
            decoration: InputDecoration(
              labelText: S.of(context).academicCollegeLabel,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _majorController,
            decoration: InputDecoration(
              labelText: S.of(context).academicMajorLabel,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _levelController,
            decoration: InputDecoration(
              labelText: S.of(context).academicLevelLabel,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(S.of(context).signInRequired)),
                );
                return;
              }
              await UserProfileService.instance.updateAcademic(
                college: _collegeController.text.trim(),
                major: _majorController.text.trim(),
                level: _levelController.text.trim(),
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(S.of(context).academicSettingsSaved)),
              );
            },
            child: Text(S.of(context).saveChanges),
          ),
        ],
      ),
    );
  }
}

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

enum _DownloadFilter { all, files, images }

enum _DownloadSort { newest, oldest }

class _DownloadsScreenState extends State<DownloadsScreen> {
  _DownloadFilter _selectedFilter = _DownloadFilter.all;
  _DownloadSort _selectedSort = _DownloadSort.newest;

  Future<void> _confirmClearCache() async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.downloadsClearCacheDialogTitle),
        content: Text(s.downloadsClearCacheDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.downloadsClearCacheDialogConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.downloadsCacheClearedExperimental)),
    );
  }

  void _showRefreshSnack() {
    final s = S.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.downloadsRefreshSoon)),
    );
  }

  Future<void> _handleExplore() async {
    await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.downloadsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            s.downloadsTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.downloadsDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.storage_outlined,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        s.downloadsStorageTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: 0,
                      minHeight: 8,
                      backgroundColor: colorScheme.surfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.downloadsStorageUserLabel,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          s.downloadsStorageCacheLabel,
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.downloadsStorageInfo,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _confirmClearCache,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(s.downloadsClearCache),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showRefreshSnack,
                  icon: const Icon(Icons.refresh),
                  label: Text(s.downloadsRefreshList),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(s.downloadsFilterAll),
                      selected: _selectedFilter == _DownloadFilter.all,
                      onSelected: (_) => setState(() {
                        _selectedFilter = _DownloadFilter.all;
                      }),
                    ),
                    ChoiceChip(
                      label: Text(s.downloadsFilterFiles),
                      selected: _selectedFilter == _DownloadFilter.files,
                      onSelected: (_) => setState(() {
                        _selectedFilter = _DownloadFilter.files;
                      }),
                    ),
                    ChoiceChip(
                      label: Text(s.downloadsFilterImages),
                      selected: _selectedFilter == _DownloadFilter.images,
                      onSelected: (_) => setState(() {
                        _selectedFilter = _DownloadFilter.images;
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 140,
                child: DropdownButtonFormField<_DownloadSort>(
                  value: _selectedSort,
                  decoration: InputDecoration(
                    labelText: s.downloadsSortLabel,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: _DownloadSort.newest,
                      child: Text(s.downloadsSortNewest),
                    ),
                    DropdownMenuItem(
                      value: _DownloadSort.oldest,
                      child: Text(s.downloadsSortOldest),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedSort = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_download_outlined,
                    size: 72,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.downloadsEmptyTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.downloadsEmptyHint,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _handleExplore,
                    child: Text(s.downloadsExploreCta),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  Future<void> _promptAddFavorite() async {
    final s = S.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.signInRequired)),
      );
      return;
    }
    final idController = TextEditingController();
    final typeController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.favoritesAddTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idController,
              decoration: InputDecoration(hintText: s.favoritesAddHint),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: typeController,
              decoration: InputDecoration(hintText: s.favoritesAddTypeHint),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.favoritesAddAction),
          ),
        ],
      ),
    );
    if (confirmed == true && idController.text.trim().isNotEmpty) {
      await FavoritesService.instance.addFavorite(
        itemId: idController.text.trim(),
        itemType: typeController.text.trim().isEmpty
            ? 'generic'
            : typeController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.favoritesAdded)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).favoritesTitle),
        actions: [
          IconButton(
            onPressed: _promptAddFavorite,
            icon: const Icon(Icons.star_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            S.of(context).favoritesDescription,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<FavoriteItem>>(
            stream: FavoritesService.instance.streamFavorites(),
            builder: (context, snapshot) {
              final favorites = snapshot.data ?? [];
              if (FirebaseAuth.instance.currentUser == null) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(S.of(context).favoritesSignInTitle),
                    subtitle: Text(S.of(context).favoritesSignInHint),
                  ),
                );
              }
              if (favorites.isEmpty) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.star_border),
                    title: Text(S.of(context).favoritesEmptyTitle),
                    subtitle: Text(S.of(context).favoritesEmptyHint),
                  ),
                );
              }
              return Column(
                children: [
                  for (final favorite in favorites)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.star),
                        title: Text(favorite.itemId),
                        subtitle: Text(
                          S.of(context).favoritesTypeLabel(favorite.itemType),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await FavoritesService.instance
                                .removeFavorite(favorite.id);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(S.of(context).favoritesRemoved)),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class ManageDevicesScreen extends StatelessWidget {
  const ManageDevicesScreen({super.key});

  String _deviceSummary() {
    if (kIsWeb) return 'Web';
    return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).manageDevicesTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            S.of(context).manageDevicesDescription,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.phone_android),
              title: Text(S.of(context).currentDeviceTitle),
              subtitle: Text(_deviceSummary()),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            S.of(context).activeSessionsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.devices_other),
              title: Text(user == null
                  ? S.of(context).signInRequired
                  : S.of(context).activeSessionsEmpty),
              subtitle: Text(S.of(context).activeSessionsHint),
            ),
          ),
        ],
      ),
    );
  }
}

class FontSizeScreen extends StatelessWidget {
  const FontSizeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).fontSizeTitle),
      ),
      body: ValueListenableBuilder<SettingsData>(
        valueListenable: AppSettings.instance.notifier,
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                S.of(context).fontSizeDescription,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _FontScaleOptionTile(
                value: FontScaleOption.small,
                groupValue: settings.fontScale,
                title: S.of(context).fontSizeSmall,
                onChanged: (value) =>
                    AppSettings.instance.setFontScale(value),
              ),
              _FontScaleOptionTile(
                value: FontScaleOption.medium,
                groupValue: settings.fontScale,
                title: S.of(context).fontSizeMedium,
                onChanged: (value) =>
                    AppSettings.instance.setFontScale(value),
              ),
              _FontScaleOptionTile(
                value: FontScaleOption.large,
                groupValue: settings.fontScale,
                title: S.of(context).fontSizeLarge,
                onChanged: (value) =>
                    AppSettings.instance.setFontScale(value),
              ),
              const SizedBox(height: 20),
              Text(
                S.of(context).fontSizePreviewLabel,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Text(
                  S.of(context).fontSizePreviewText,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FontScaleOptionTile extends StatelessWidget {
  const _FontScaleOptionTile({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.onChanged,
  });

  final FontScaleOption value;
  final FontScaleOption groupValue;
  final String title;
  final ValueChanged<FontScaleOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<FontScaleOption>(
      value: value,
      groupValue: groupValue,
      title: Text(title),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}
