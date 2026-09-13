import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as m;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';

import '../../generated/l10n.dart';
import '../../moduls3.dart';
import 'app_settings.dart';
import 'blocked_users_service.dart';
import '../../features/downloads/download_item.dart';
import '../../features/downloads/downloads_repository.dart';
import 'favorites_service.dart';
import 'security_service.dart';
import 'session_service.dart';
import '../../services/auth_session_service.dart';
import 'user_profile_service.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:math';


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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).securityCenterTitle),
      ),
      body: const SecurityCenterContent(),
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
  final DownloadsRepository _repository = const DownloadsRepository();
  List<DownloadItem> _downloads = [];
  bool _isLoading = true;
  bool _isWorking = false;
  int _downloadsSizeBytes = 0;
  int _cacheSizeBytes = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads({bool showError = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final downloads = await _repository.listDownloads();
      final downloadsSize = await _repository.computeDownloadsSizeBytes();
      final cacheSize = await _repository.computeCacheSizeBytes();
      if (!mounted) return;
      setState(() {
        _downloads = downloads;
        _downloadsSizeBytes = downloadsSize;
        _cacheSizeBytes = cacheSize;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
      if (showError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).downloadsLoadFailed)),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _formatBytes(int bytes) {
    return DownloadItem.humanReadableBytes(bytes);
  }

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
    setState(() => _isWorking = true);
    try {
      await _repository.clearCache();
      await _loadDownloads();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.downloadsCacheCleared)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.downloadsCacheClearFailed)),
      );
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
      }
    }
  }

  Future<void> _confirmClearAllDownloads() async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.downloadsClearAllDialogTitle),
        content: Text(s.downloadsClearAllDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.downloadsClearAllDialogConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isWorking = true);
    try {
      await _repository.clearAllDownloads();
      await _loadDownloads();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.downloadsClearAllSuccess)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.downloadsClearAllFailed)),
      );
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
      }
    }
  }

  Future<void> _refreshDownloads() async {
    await _loadDownloads(showError: true);
  }

  Future<void> _handleExplore() async {
    await Navigator.of(context).maybePop();
  }

  List<DownloadItem> _applyFilters(List<DownloadItem> items) {
    Iterable<DownloadItem> filtered = items;
    if (_selectedFilter == _DownloadFilter.images) {
      filtered = filtered.where((item) => item.isImage);
    } else if (_selectedFilter == _DownloadFilter.files) {
      filtered = filtered.where((item) => !item.isImage);
    }
    final sorted = filtered.toList()
      ..sort((a, b) => _selectedSort == _DownloadSort.newest
          ? b.modifiedAt.compareTo(a.modifiedAt)
          : a.modifiedAt.compareTo(b.modifiedAt));
    return sorted;
  }

  Future<void> _confirmDeleteDownload(DownloadItem item) async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.downloadsDeleteDialogTitle),
        content: Text(s.downloadsDeleteDialogBody(item.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isWorking = true);
    try {
      await _repository.deleteDownload(item.path);
      await _loadDownloads();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.downloadsDeleteSuccess)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.downloadsDeleteFailed)),
      );
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final colorScheme = theme.colorScheme;
    final filteredDownloads = _applyFilters(_downloads);
    final totalBytes = _downloadsSizeBytes + _cacheSizeBytes;
    final progress = totalBytes == 0 ? 0.0 : _downloadsSizeBytes / totalBytes;
    final dateFormatter =
        DateFormat.yMMMd(Localizations.localeOf(context).languageCode);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.downloadsTitle),
        actions: [
          IconButton(
            tooltip: s.downloadsRefreshList,
            onPressed: _isWorking ? null : _refreshDownloads,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: s.downloadsClearAllAction,
            onPressed: _isWorking || _downloads.isEmpty
                ? null
                : _confirmClearAllDownloads,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDownloads,
        child: ListView(
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
                        value: progress,
                        minHeight: 8,
                        backgroundColor: colorScheme.surfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.downloadsStorageUserLabelValue(
                              _formatBytes(_downloadsSizeBytes),
                            ),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            s.downloadsStorageCacheLabelValue(
                              _formatBytes(_cacheSizeBytes),
                            ),
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.downloadsStorageInfoValue(
                        _formatBytes(totalBytes),
                      ),
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
                    onPressed: _isWorking ? null : _confirmClearCache,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(s.downloadsClearCache),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isWorking ? null : _refreshDownloads,
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
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filteredDownloads.isEmpty)
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
                        _errorMessage == null
                            ? s.downloadsEmptyHint
                            : s.downloadsLoadFailed,
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
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredDownloads.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = filteredDownloads[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        item.isImage
                            ? Icons.image_outlined
                            : Icons.insert_drive_file_outlined,
                        color: colorScheme.primary,
                      ),
                      title: Text(item.name),
                      subtitle: Text(
                        s.downloadsUpdatedAt(
                          dateFormatter.format(item.modifiedAt),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatBytes(item.sizeBytes),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          IconButton(
                            tooltip: s.delete,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: _isWorking
                                ? null
                                : () => _confirmDeleteDownload(item),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
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

class ManageDevicesScreen extends StatefulWidget {
  const ManageDevicesScreen({super.key});

  @override
  State<ManageDevicesScreen> createState() => _ManageDevicesScreenState();
}

class _ManageDevicesScreenState extends State<ManageDevicesScreen> {
  String? _localSessionId;

  @override
  void initState() {
    super.initState();
    _loadSessionId();
  }

  Future<void> _loadSessionId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final id = await SessionService.instance.getCurrentSessionId(user.uid) ??
        await SessionService.instance.getOrCreateSessionId(user.uid);
    if (!mounted) return;
    setState(() => _localSessionId = id);
  }

  String _relativeSince(Timestamp? timestamp, BuildContext context) {
    final s = S.of(context);
    if (timestamp == null) return S.of(context).activeSessionNow;
    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inMinutes < 1) return S.of(context).activeSessionNow;
    if (diff.inHours < 1) return s.sessionAgoMinutes('${diff.inMinutes}');
    if (diff.inDays < 1) return s.sessionAgoHours('${diff.inHours}');
    return s.sessionAgoDays('${diff.inDays}');
  }

  String _formatTimestamp(Timestamp? timestamp, BuildContext context) {
    if (timestamp == null) return S.of(context).activeSessionNow;
    return DateFormat.yMMMMd(Localizations.localeOf(context).toLanguageTag())
        .add_Hm()
        .format(timestamp.toDate());
  }

  Future<void> _logoutSession(User user, String sessionId) async {
    try {
      await SessionService.instance.revokeSession(user: user, sessionId: sessionId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).sessionSignedOutSuccess)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).sessionSignOutFailed)),
      );
    }
  }

  Future<void> _logoutAllOther(String uid) async {
    final current = _localSessionId;
    if (current == null) return;
    try {
      await SessionService.instance.revokeAllOtherSessions(uid: uid, currentSessionId: current);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).otherSessionsSignedOutSuccess)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).sessionSignOutFailed)),
      );
    }
  }

  Future<void> _showSessionDetails({
    required User user,
    required SessionModel session,
    required bool isCurrent,
  }) async {
    final aliasController = TextEditingController(text: session.alias);
    bool trusted = session.isTrusted;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.circle, size: 10, color: session.isOnline ? Colors.green : Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            session.alias,
                            style: Theme.of(context).textTheme.titleMedium,
                            textDirection: m.TextDirection.rtl,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: aliasController,
                      textDirection: m.TextDirection.rtl,
                      decoration: InputDecoration(labelText: S.of(context).sessionDeviceNameLabel),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      value: trusted,
                      onChanged: (value) async {
                        setSheetState(() => trusted = value);
                        await SessionService.instance.setSessionTrusted(
                          uid: user.uid,
                          sessionId: session.id,
                          trusted: value,
                        );
                      },
                      title: Text(S.of(context).sessionTrustedDevice),
                    ),
                    const Divider(),
                    Text('${S.of(context).sessionModelLabel}: ${session.model}'),
                    Text('${S.of(context).sessionPlatformLabel}: ${session.platform} ${session.osVersion}'),
                    Text('${S.of(context).sessionVersionLabel}: ${session.appVersion} (${session.buildNumber})'),
                    Text('${S.of(context).sessionLoginDateLabel}: ${_formatTimestamp(session.createdAt, context)}'),
                    Text('${S.of(context).sessionLastActivityLabel}: ${_formatTimestamp(session.lastSeenAt, context)} (${_relativeSince(session.lastSeenAt, context)})'),
                    if ((session.locale ?? '').isNotEmpty) Text('${S.of(context).changeLanguage}: ${session.locale}'),
                    if ((session.networkType ?? '').isNotEmpty) Text('${S.of(context).sessionNetworkLabel}: ${session.networkType}'),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () async {
                        await SessionService.instance.updateSessionAlias(
                          uid: user.uid,
                          sessionId: session.id,
                          alias: aliasController.text,
                        );
                        if (!mounted) return;
                        Navigator.of(context).pop();
                      },
                      child: Text(S.of(context).save),
                    ),
                    const SizedBox(height: 8),
                    if (!isCurrent)
                      FilledButton(
                        onPressed: () async {
                          await _logoutSession(user, session.id);
                          if (!mounted) return;
                          Navigator.of(context).pop();
                        },
                        child: Text(S.of(context).signOut),
                      ),
                    const SizedBox(height: 12),
                    Text(S.of(context).dangerZone, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.red)),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => _logoutAllOther(user.uid),
                      child: Text(S.of(context).logoutAllOtherDevices),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        await SecurityService.instance.logoutAllDevices();
                      },
                      child: Text(S.of(context).logoutAllDevices),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final allSessionsStream = user == null
        ? const Stream<List<SessionModel>>.empty()
        : SessionService.instance.watchAllSessions(user: user);
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).manageDevicesTitle)),
      body: user == null
          ? Center(child: Text(S.of(context).signInRequired))
          : StreamBuilder<List<SessionModel>>(
              stream: allSessionsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting || _localSessionId == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                final sessions = (snapshot.data ?? const <SessionModel>[]).where((s) => !s.isRevoked).toList()
                  ..sort((a, b) {
                    if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
                    final aTs = a.lastSeenAt ?? a.createdAt;
                    final bTs = b.lastSeenAt ?? b.createdAt;
                    if (aTs == null && bTs == null) return 0;
                    if (aTs == null) return 1;
                    if (bTs == null) return -1;
                    return bTs.compareTo(aTs);
                  });

                final currentId = _localSessionId!;
                final currentSession = sessions.cast<SessionModel?>().firstWhere(
                      (s) => s?.id == currentId,
                      orElse: () => null,
                    );
                final otherSessions = sessions.where((s) => s.id != currentId).toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(S.of(context).manageDevicesDescription, textDirection: m.TextDirection.rtl),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        onTap: currentSession == null
                            ? null
                            : () => _showSessionDetails(user: user, session: currentSession, isCurrent: true),
                        leading: Icon(Icons.circle, color: (currentSession?.isOnline ?? false) ? Colors.green : Colors.grey, size: 12),
                        title: Text(S.of(context).currentDeviceTitle, textDirection: m.TextDirection.rtl),
                        subtitle: Text(
                          currentSession == null
                              ? S.of(context).activeSessionNow
                              : '${currentSession.alias}\n${_relativeSince(currentSession.lastSeenAt, context)}',
                          textDirection: m.TextDirection.rtl,
                        ),
                        isThreeLine: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            S.of(context).activeSessionsTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                            textDirection: m.TextDirection.rtl,
                          ),
                        ),
                        TextButton(onPressed: () => _logoutAllOther(user.uid), child: Text(S.of(context).logoutAllOtherDevices)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (otherSessions.isEmpty)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.devices_other),
                          title: Text(S.of(context).activeSessionsEmpty, textDirection: m.TextDirection.rtl),
                        ),
                      )
                    else
                      ...otherSessions.map((session) {
                        return Card(
                          child: ListTile(
                            onTap: () => _showSessionDetails(user: user, session: session, isCurrent: false),
                            leading: Icon(Icons.circle, color: session.isOnline ? Colors.green : Colors.grey, size: 10),
                            title: Text(session.alias, textDirection: m.TextDirection.rtl),
                            subtitle: Text(_relativeSince(session.lastSeenAt, context), textDirection: m.TextDirection.rtl),
                            trailing: TextButton(
                              onPressed: () => _logoutSession(user, session.id),
                              child: Text(S.of(context).signOut),
                            ),
                          ),
                        );
                      }),
                  ],
                );
              },
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







const Color kSecurityAccent = Color(0xFF0D9488);

const _sessionPrefKey = 'security_session_id';

Future<void> ensureSecuritySession() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_sessionPrefKey);
    final userRef =
    FirebaseFirestore.instance.collection('users').doc(user.uid);
    final col = userRef.collection('sessions');
    if (id == null || id.isEmpty) {
      id = col.doc().id;
      await prefs.setString(_sessionPrefKey, id);
    }

    final existing = await col.doc(id).get();
    final isNew = !existing.exists;

    await col.doc(id).set({
      'deviceName': securityDeviceLabel(),
      'platform': defaultTargetPlatform.name,
      'lastActiveAt': FieldValue.serverTimestamp(),
      if (isNew) 'createdAt': FieldValue.serverTimestamp(),
      'app': 'unispace',
    }, SetOptions(merge: true));

    if (!isNew) return;

    final profile = await userRef.get();
    final alertsOn = profile.data()?['security']?['loginAlerts'] != false;
    if (!alertsOn) return;

    await userRef.set({
      'security': {
        'lastLoginAlert': {
          'sessionId': id,
          'deviceName': securityDeviceLabel(),
          'platform': defaultTargetPlatform.name,
          'at': FieldValue.serverTimestamp(),
        },
      },
    }, SetOptions(merge: true));
  } catch (e) {
    debugPrint('ensureSecuritySession: $e');
  }
}

String securityDeviceLabel() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return 'iPhone';
    case TargetPlatform.android:
      return 'جهاز Android';
    case TargetPlatform.macOS:
      return 'Mac';
    case TargetPlatform.windows:
      return 'Windows';
    default:
      return 'هذا الجهاز';
  }
}

String _securityTimeAgo(DateTime? dt) {
  if (dt == null) return '';
  final d = DateTime.now().difference(dt);
  if (d.inSeconds < 60) return 'الآن';
  if (d.inMinutes < 60) return 'قبل ${d.inMinutes} د';
  if (d.inHours < 24) return 'قبل ${d.inHours} س';
  if (d.inDays < 7) return 'قبل ${d.inDays} ي';
  return '${dt.day}/${dt.month}/${dt.year}';
}

bool _hasPasswordProvider(User user) {
  return user.providerData.any((p) => p.providerId == 'password');
}

class SecurityCenterContent extends StatefulWidget {
  const SecurityCenterContent({super.key});

  @override
  State<SecurityCenterContent> createState() => _SecurityCenterContentState();
}

class _SecurityCenterContentState extends State<SecurityCenterContent> {
  User? _user;
  bool _alerts = true;
  bool _loadingAlerts = true;
  String? _sessionId;
  bool _appLockOn = false;
  bool _twoFactorOn = false;
  bool _frozen = false;

  DocumentReference<Map<String, dynamic>>? get _userRef {
    final uid = _user?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    unawaited(_boot());
  }

  Future<void> _boot() async {
    await ensureSecuritySession();
    final prefs = await SharedPreferences.getInstance();
    await _user?.reload();
    if (!mounted) return;
    setState(() {
      _user = FirebaseAuth.instance.currentUser;
      _sessionId = prefs.getString(_sessionPrefKey);
    });
    await _loadAlerts();

    final lock = prefs.getBool('security_app_lock_on') ?? false;
    if (mounted) setState(() => _appLockOn = lock);

    try {
      final u = FirebaseAuth.instance.currentUser;
      if (u != null) {
        final factors = await u.multiFactor.getEnrolledFactors();
        if (mounted) {
          setState(() => _twoFactorOn = factors.isNotEmpty);
        }
      }
    } catch (_) {}
  }

  Future<void> _loadAlerts() async {
    final ref = _userRef;
    if (ref == null) {
      if (mounted) setState(() => _loadingAlerts = false);
      return;
    }
    try {
      final snap = await ref.get();
      final security =
      Map<String, dynamic>.from(snap.data()?['security'] ?? {});
      if (!mounted) return;
      setState(() {
        _alerts = security['loginAlerts'] != false;
        _loadingAlerts = false;
        _frozen = security['frozen'] == true;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingAlerts = false);
    }
  }

  Future<void> _reloadUser() async {
    await _user?.reload();
    if (!mounted) return;
    setState(() => _user = FirebaseAuth.instance.currentUser);
  }

  Future<void> _toggleAlerts(bool value) async {
    final ref = _userRef;
    if (ref == null) return;
    setState(() => _alerts = value);
    try {
      await ref.set({
        'security': {
          'loginAlerts': value,
          'loginAlertsEmail': value,
        },
      }, SetOptions(merge: true));
    } catch (e) {
      if (!mounted) return;
      setState(() => _alerts = !value);
      _toast('تعذر حفظ التنبيهات');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _open<T>(Widget page) async {
    await Navigator.of(context).push(
      MaterialPageRoute<T>(builder: (_) => page),
    );
    await _reloadUser();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    if (user == null) {
      return const Center(child: Text('سجّل الدخول أولًا'));
    }

    final email = (user.email ?? '').trim();
    final phone = (user.phoneNumber ?? '').trim();
    final emailVerified = user.emailVerified;
    final hasPhone = phone.isNotEmpty;
    final hasPassword = _hasPasswordProvider(user);

    final missing = <_SecMissingStep>[
      if (!_twoFactorOn)
        _SecMissingStep(
          'فعّل التأكيد بخطوتين',
          Icons.verified_user_outlined,
              () => _open(const _TwoFactorPage()),
        ),
      if (!_appLockOn)
        _SecMissingStep(
          'فعّل قفل التطبيق',
          Icons.lock_outline_rounded,
              () => _open(const _AppLockPage()),
        ),
      if (email.isNotEmpty && !emailVerified)
        _SecMissingStep(
          'أكّد بريدك الإلكتروني',
          Icons.mark_email_unread_outlined,
              () => _open(const _EmailSecurityPage()),
        ),
      if (!hasPhone)
        _SecMissingStep(
          'أضف رقم هاتف للاستعادة',
          Icons.phone_iphone_rounded,
              () => _open(const _PhoneSecurityPage()),
        ),
      if (!_alerts)
        _SecMissingStep(
          'فعّل تنبيهات الدخول',
          Icons.notifications_active_outlined,
              () => _toggleAlerts(true),
        ),
    ];

    const totalChecks = 6;
    var done = 0;
    if (email.isNotEmpty) done++;
    if (emailVerified) done++;
    if (hasPhone) done++;
    if (_alerts) done++;
    if (_appLockOn) done++;
    if (_appLockOn) done++;
    final score = done.clamp(0, totalChecks);

    return RefreshIndicator(
      color: kSecurityAccent,
      onRefresh: _boot,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _SecScoreCard(score: score, total: totalChecks, missing: missing),
          const SizedBox(height: 22),
          _SecGroup(
            title: 'تسجيل الدخول',
            children: [
              _SecRowTile(
                icon: Icons.password_rounded,
                title: 'كلمة المرور',
                subtitle: hasPassword
                    ? 'تغيير كلمة مرور الحساب'
                    : 'الحساب مرتبط بطريقة دخول خارجية',
                onTap: hasPassword
                    ? () => _open(const _ChangePasswordPage())
                    : () => _toast('لا توجد كلمة مرور محلية لهذا الحساب'),
              ),
              const _SecRowDivider(),
              _SecRowTile(
                icon: Icons.verified_user_outlined,
                title: 'التأكيد بخطوتين',
                subtitle: _twoFactorOn
                    ? 'مفعّل عبر تطبيق المصادقة'
                    : 'يمنع الدخول حتى مع معرفة كلمة المرور',
                badge: _twoFactorOn ? 'مفعّل' : 'غير مفعّل',
                badgeTone: _twoFactorOn
                    ? _SecBadgeTone.ok
                    : _SecBadgeTone.warn,
                onTap: () async {
                  await _open(const _TwoFactorPage());
                  try {
                    final u = FirebaseAuth.instance.currentUser;
                    final factors =
                        await u?.multiFactor.getEnrolledFactors() ?? [];
                    if (!mounted) return;
                    setState(() => _twoFactorOn = factors.isNotEmpty);
                  } catch (_) {}
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SecGroup(
            title: 'البريد والهاتف',
            children: [
              _SecRowTile(
                icon: Icons.mail_outline_rounded,
                title: 'البريد الإلكتروني',
                subtitle: email.isEmpty ? 'غير مضاف' : email,
                badge: email.isEmpty
                    ? 'ناقص'
                    : (emailVerified ? 'مؤكَّد' : 'غير مؤكَّد'),
                badgeTone: email.isEmpty
                    ? _SecBadgeTone.danger
                    : (emailVerified ? _SecBadgeTone.ok : _SecBadgeTone.warn),
                onTap: () => _open(const _EmailSecurityPage()),
              ),
              const _SecRowDivider(),
              _SecRowTile(
                icon: Icons.phone_outlined,
                title: 'رقم الهاتف',
                subtitle: hasPhone ? phone : 'يُستخدم لاستعادة الحساب',
                badge: hasPhone ? 'مضاف' : 'غير مضاف',
                badgeTone:
                hasPhone ? _SecBadgeTone.ok : _SecBadgeTone.warn,
                onTap: () => _open(const _PhoneSecurityPage()),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SecGroup(
            title: 'الأجهزة والجلسات',
            children: [
              _SecSessionsPreview(
                uid: user.uid,
                currentSessionId: _sessionId,
                onOpenAll: () => _open(_SessionsPage(
                  uid: user.uid,
                  currentSessionId: _sessionId,
                )),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SecGroup(
            title: 'التنبيهات',
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                secondary: Icon(
                  _alerts
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                  color: kSecurityAccent,
                ),
                title: const Text(
                  'تنبيهات الدخول',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  _alerts
                      ? 'نُعلمك عند دخول جديد من جهاز غير معروف'
                      : 'لن يصلك تنبيه عند دخول جديد',
                ),
                value: _loadingAlerts ? true : _alerts,
                activeColor: kSecurityAccent,
                onChanged: _loadingAlerts ? null : _toggleAlerts,
              ),
            ],
          ),

          const SizedBox(height: 18),
          _SecGroup(
            title: 'قفل التطبيق',
            children: [
              _SecRowTile(
                icon: Icons.lock_outline_rounded,
                title: 'قفل UniSpace',
                subtitle: _appLockOn
                    ? 'مطلوب بصمة أو PIN بعد مغادرة التطبيق'
                    : 'أي شخص يفتح الهاتف يصل لحسابك',
                badge: _appLockOn ? 'مفعّل' : 'غير مفعّل',
                badgeTone:
                _appLockOn ? _SecBadgeTone.ok : _SecBadgeTone.warn,
                onTap: () async {
                  await _open(const _AppLockPage());
                  final prefs = await SharedPreferences.getInstance();
                  if (!mounted) return;
                  setState(() {
                    _appLockOn =
                        prefs.getBool('security_app_lock_on') ?? false;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SecGroup(
            title: 'حالات الطوارئ',
            children: [
              _SecRowTile(
                icon: Icons.gpp_bad_outlined,
                title: 'تم اختراق حسابي',
                subtitle: 'إنهاء الأجهزة الأخرى فورًا',
                onTap: () => _open(const _CompromisedAccountPage()),
              ),
              const _SecRowDivider(),
              _SecRowTile(
                icon: Icons.pause_circle_outline_rounded,
                title: 'تجميد الحساب',
                subtitle: _frozen
                    ? 'ملفك مخفي — اضغط لإلغاء التجميد'
                    : 'إخفاء الملف ووقف الرسائل مؤقتًا',
                badge: _frozen ? 'مجمّد' : null,
                badgeTone: _frozen ? _SecBadgeTone.warn : null,
                onTap: () async {
                  await _open(const _FreezeAccountPage());
                  await _loadAlerts();
                },
              ),
              const _SecRowDivider(),
              _SecRowTile(
                icon: Icons.delete_outline_rounded,
                title: 'حذف الحساب',
                subtitle: 'حذف نهائي لا يمكن التراجع عنه',
                onTap: () => _open(const _DeleteAccountPage()),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'هذه الإعدادات تحمي دخول حسابك. من يرى منشوراتك ومن يراسلك في تبويب الخصوصية.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecMissingStep {
  const _SecMissingStep(this.label, this.icon, this.onTap);
  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

enum _SecBadgeTone { ok, warn, danger }

class _SecScoreCard extends StatelessWidget {
  const _SecScoreCard({
    required this.score,
    required this.total,
    required this.missing,
  });

  final int score;
  final int total;
  final List<_SecMissingStep> missing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ratio = total == 0 ? 0.0 : score / total;
    final Color tone;
    final String headline;
    final String sub;
    if (ratio >= 1) {
      tone = const Color(0xFF16A34A);
      headline = 'حسابك محمي جيدًا';
      sub = 'كل خطوات الحماية الأساسية مكتملة.';
    } else if (ratio >= 0.5) {
      tone = const Color(0xFFD97706);
      headline = 'حسابك يحتاج تعزيزًا';
      sub = 'أكمل ${missing.length} خطوة لحماية أفضل.';
    } else {
      tone = const Color(0xFFDC2626);
      headline = 'حسابك معرض للخطر';
      sub = 'فعّل الخطوات الناقصة في أقرب وقت.';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16181C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: ratio,
                      strokeWidth: 6,
                      backgroundColor: tone.withValues(alpha: 0.16),
                      color: tone,
                    ),
                    Text(
                      '$score/$total',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: tone,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sub,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final step in missing)
                  ActionChip(
                    avatar: Icon(step.icon, size: 16, color: tone),
                    label: Text(step.label),
                    onPressed: step.onTap,
                    backgroundColor: tone.withValues(alpha: 0.10),
                    side: BorderSide(color: tone.withValues(alpha: 0.25)),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SecGroup extends StatelessWidget {
  const _SecGroup({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 8, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF16181C) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SecRowDivider extends StatelessWidget {
  const _SecRowDivider();
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
    );
  }
}

class _SecRowTile extends StatelessWidget {
  const _SecRowTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingLabel,
    this.badge,
    this.badgeTone,
    this.muted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? trailingLabel;
  final String? badge;
  final _SecBadgeTone? badgeTone;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: kSecurityAccent.withValues(alpha: 0.12),
        child: Icon(icon, size: 18, color: kSecurityAccent),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            _SecBadge(label: badge!, tone: badgeTone ?? _SecBadgeTone.warn),
          if (trailingLabel != null) ...[
            const SizedBox(width: 6),
            Text(
              trailingLabel!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.hintColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          Icon(
            Icons.chevron_left_rounded,
            color: muted ? theme.hintColor : theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _SecBadge extends StatelessWidget {
  const _SecBadge({required this.label, required this.tone});
  final String label;
  final _SecBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final Color c;
    switch (tone) {
      case _SecBadgeTone.ok:
        c = const Color(0xFF16A34A);
      case _SecBadgeTone.warn:
        c = const Color(0xFFD97706);
      case _SecBadgeTone.danger:
        c = const Color(0xFFDC2626);
    }
    return Container(
      margin: const EdgeInsetsDirectional.only(end: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SecSessionsPreview extends StatelessWidget {
  const _SecSessionsPreview({
    required this.uid,
    required this.currentSessionId,
    required this.onOpenAll,
  });

  final String uid;
  final String? currentSessionId;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? const [];
        final count = docs.length;
        String subtitle;
        if (!snap.hasData) {
          subtitle = 'جاري التحميل…';
        } else if (count <= 1) {
          subtitle = 'جهاز واحد نشط — ${securityDeviceLabel()}';
        } else {
          subtitle = '$count أجهزة متصلة';
        }
        return _SecRowTile(
          icon: Icons.devices_rounded,
          title: 'الأجهزة المتصلة',
          subtitle: subtitle,
          badge: count > 1 ? '$count' : null,
          badgeTone: count > 1 ? _SecBadgeTone.warn : _SecBadgeTone.ok,
          onTap: onOpenAll,
        );
      },
    );
  }
}

class _ChangePasswordPage extends StatefulWidget {
  const _ChangePasswordPage();

  @override
  State<_ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<_ChangePasswordPage> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _show1 = false;
  bool _show2 = false;
  bool _show3 = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_current.text.isEmpty) return 'أدخل كلمة المرور الحالية';
    if (_next.text.length < 8) return 'كلمة المرور الجديدة 8 أحرف على الأقل';
    if (_next.text == _current.text) {
      return 'اختر كلمة مرور مختلفة عن الحالية';
    }
    if (_next.text != _confirm.text) return 'كلمتا المرور غير متطابقتين';
    return null;
  }

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) {
      _snack(err);
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null) return;

    setState(() => _busy = true);
    try {
      final cred = EmailAuthProvider.credential(
        email: email,
        password: _current.text,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_next.text);

      if (!mounted) return;
      final logoutOthers = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تم تغيير كلمة المرور'),
          content: const Text(
            'هل تريد إنهاء الجلسات على الأجهزة الأخرى؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إبقاء الجلسات'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: kSecurityAccent,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('إنهاء الأخرى'),
            ),
          ],
        ),
      ) ??
          false;

      if (logoutOthers) await _revokeOtherSessions();

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث كلمة المرور')),
      );
    } on FirebaseAuthException catch (e) {
      _snack(_secAuthError(e));
    } catch (e) {
      _snack('تعذر تغيير كلمة المرور');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('كلمة المرور')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const Text(
            'استخدم كلمة مرور طويلة وغير مستخدمة في حسابات أخرى.',
            style: TextStyle(height: 1.45),
          ),
          const SizedBox(height: 18),
          _SecPasswordField(
            controller: _current,
            label: 'كلمة المرور الحالية',
            visible: _show1,
            onToggle: () => setState(() => _show1 = !_show1),
          ),
          const SizedBox(height: 12),
          _SecPasswordField(
            controller: _next,
            label: 'كلمة المرور الجديدة',
            visible: _show2,
            onToggle: () => setState(() => _show2 = !_show2),
          ),
          const SizedBox(height: 12),
          _SecPasswordField(
            controller: _confirm,
            label: 'تأكيد كلمة المرور',
            visible: _show3,
            onToggle: () => setState(() => _show3 = !_show3),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: kSecurityAccent,
              minimumSize: const Size.fromHeight(48),
            ),
            child: _busy
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text('حفظ كلمة المرور'),
          ),
        ],
      ),
    );
  }
}

class _SecPasswordField extends StatelessWidget {
  const _SecPasswordField({
    required this.controller,
    required this.label,
    required this.visible,
    required this.onToggle,
  });

  final TextEditingController controller;
  final String label;
  final bool visible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: !visible,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            visible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ),
      ),
    );
  }
}

class _EmailSecurityPage extends StatefulWidget {
  const _EmailSecurityPage();

  @override
  State<_EmailSecurityPage> createState() => _EmailSecurityPageState();
}

class _EmailSecurityPageState extends State<_EmailSecurityPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _sentVerify = false;

  @override
  void initState() {
    super.initState();
    _email.text = FirebaseAuth.instance.currentUser?.email ?? '';
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _sendVerify() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      await user.sendEmailVerification();
      setState(() => _sentVerify = true);
      _snack('أُرسل رابط التأكيد إلى بريدك');
    } on FirebaseAuthException catch (e) {
      _snack(_secAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    final current = (user?.email ?? '').trim();
    final next = _email.text.trim();
    if (user == null) return;
    if (next.isEmpty || !next.contains('@')) {
      _snack('أدخل بريدًا صالحًا');
      return;
    }
    if (next == current) {
      _snack('هذا هو بريدك الحالي');
      return;
    }
    if (_password.text.isEmpty) {
      _snack('أدخل كلمة المرور لتأكيد التغيير');
      return;
    }
    setState(() => _busy = true);
    try {
      final cred = EmailAuthProvider.credential(
        email: current,
        password: _password.text,
      );
      await user.reauthenticateWithCredential(cred);
      await user.verifyBeforeUpdateEmail(next);
      if (!mounted) return;
      _snack(
        'أُرسل رابط تأكيد إلى $next. لن يُعتمد البريد الجديد قبل فتح الرابط.',
      );
    } on FirebaseAuthException catch (e) {
      _snack(_secAuthError(e));
    } catch (_) {
      _snack('تعذر تحديث البريد');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final verified = user?.emailVerified == true;

    return Scaffold(
      appBar: AppBar(title: const Text('البريد الإلكتروني')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              verified
                  ? Icons.verified_rounded
                  : Icons.mark_email_unread_outlined,
              color: verified
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFD97706),
            ),
            title: Text(verified ? 'البريد مؤكَّد' : 'البريد غير مؤكَّد'),
            subtitle: Text(user?.email ?? ''),
            trailing: verified
                ? null
                : TextButton(
              onPressed: _busy ? null : _sendVerify,
              child: Text(_sentVerify ? 'أُرسل' : 'إرسال التأكيد'),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'تغيير البريد',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'سنرسل رابطًا إلى العنوان الجديد. لن يتبدل البريد قبل التأكيد.',
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'البريد الجديد',
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'كلمة المرور الحالية',
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _changeEmail,
            style: FilledButton.styleFrom(
              backgroundColor: kSecurityAccent,
              minimumSize: const Size.fromHeight(48),
            ),
            child: _busy
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text('إرسال رابط التأكيد'),
          ),
        ],
      ),
    );
  }
}

class _PhoneSecurityPage extends StatefulWidget {
  const _PhoneSecurityPage();

  @override
  State<_PhoneSecurityPage> createState() => _PhoneSecurityPageState();
}

class _PhoneSecurityPageState extends State<_PhoneSecurityPage> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  bool _busy = false;
  String? _verificationId;

  @override
  void initState() {
    super.initState();
    _phone.text = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
  }

  @override
  void dispose() {
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    var phone = _phone.text.trim();
    if (phone.isEmpty) {
      _snack('أدخل رقمًا بصيغة دولية مثل +213…');
      return;
    }
    if (!phone.startsWith('+')) phone = '+$phone';
    setState(() => _busy = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (cred) async {
          await _applyCredential(cred);
        },
        verificationFailed: (e) {
          if (mounted) {
            setState(() => _busy = false);
            _snack(_secAuthError(e));
          }
        },
        codeSent: (id, _) {
          if (!mounted) return;
          setState(() {
            _verificationId = id;
            _busy = false;
          });
          _snack('أُرسل رمز التحقق');
        },
        codeAutoRetrievalTimeout: (id) {
          _verificationId = id;
        },
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _busy = false);
      _snack(_secAuthError(e));
    } catch (_) {
      setState(() => _busy = false);
      _snack('تعذر إرسال الرمز');
    }
  }

  Future<void> _confirm() async {
    final id = _verificationId;
    if (id == null) {
      _snack('أرسل الرمز أولًا');
      return;
    }
    if (_otp.text.trim().length < 6) {
      _snack('أدخل رمز التحقق');
      return;
    }
    setState(() => _busy = true);
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: id,
        smsCode: _otp.text.trim(),
      );
      await _applyCredential(cred);
    } on FirebaseAuthException catch (e) {
      _snack(_secAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _applyCredential(PhoneAuthCredential cred) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      if (user.phoneNumber == null || user.phoneNumber!.isEmpty) {
        await user.linkWithCredential(cred);
      } else {
        await user.updatePhoneNumber(cred);
      }
      await user.reload();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ رقم الهاتف')),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked' ||
          e.code == 'credential-already-in-use') {
        _snack('هذا الرقم مرتبط بحساب آخر');
      } else {
        _snack(_secAuthError(e));
      }
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final current = FirebaseAuth.instance.currentUser?.phoneNumber;

    return Scaffold(
      appBar: AppBar(title: const Text('رقم الهاتف')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            current == null || current.isEmpty
                ? 'أضف رقمًا لاستعادة الحساب إذا فقدت البريد أو كلمة المرور.'
                : 'رقمك الحالي: $current',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
            ],
            decoration: InputDecoration(
              labelText: 'رقم الهاتف (صيغة دولية)',
              hintText: '+213555000000',
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _busy ? null : _sendCode,
            style: OutlinedButton.styleFrom(
              foregroundColor: kSecurityAccent,
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('إرسال رمز التحقق'),
          ),
          if (_verificationId != null) ...[
            const SizedBox(height: 18),
            TextField(
              controller: _otp,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'رمز التحقق',
                filled: true,
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _confirm,
              style: FilledButton.styleFrom(
                backgroundColor: kSecurityAccent,
                minimumSize: const Size.fromHeight(48),
              ),
              child: _busy
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text('تأكيد الرقم'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SessionsPage extends StatelessWidget {
  const _SessionsPage({
    required this.uid,
    required this.currentSessionId,
  });

  final String uid;
  final String? currentSessionId;

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore
      .instance
      .collection('users')
      .doc(uid)
      .collection('sessions');

  Future<void> _endOne(BuildContext context, String id) async {
    if (id == currentSessionId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن إنهاء جلسة هذا الجهاز من هنا')),
      );
      return;
    }
    await _col.doc(id).delete();
  }

  Future<void> _endOthers(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إنهاء الأجهزة الأخرى؟'),
        content: const Text(
          'ستُغلق الجلسات على كل الأجهزة ما عدا هذا الجهاز.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('إنهاء'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _revokeOtherSessions();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنهاء الجلسات الأخرى')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأجهزة المتصلة'),
        actions: [
          TextButton(
            onPressed: () async {
              final snap = await _col.get();
              final batch = FirebaseFirestore.instance.batch();
              for (final d in snap.docs) {
                batch.set(
                  d.reference,
                  {'trusted': false},
                  SetOptions(merge: true),
                );
              }
              await batch.commit();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('أُلغي توثيق كل الأجهزة')),
                );
              }
            },
            child: const Text('نسيان الموثوقة'),
          ),
          TextButton(
            onPressed: () => _endOthers(context),
            child: const Text('إنهاء الأخرى'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _col.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('تعذر تحميل الجلسات'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = [...snap.data!.docs];
          docs.sort((a, b) {
            final at = a.data()['lastActiveAt'];
            final bt = b.data()['lastActiveAt'];
            if (at is Timestamp && bt is Timestamp) return bt.compareTo(at);
            return 0;
          });
          if (docs.isEmpty) {
            return const Center(child: Text('لا توجد جلسات مسجّلة بعد'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data();
              final mine = d.id == currentSessionId;
              final trusted = data['trusted'] == true;
              final name = (data['deviceName'] ?? 'جهاز').toString();
              final platform = (data['platform'] ?? '').toString();
              final last = data['lastActiveAt'];
              final lastDt = last is Timestamp ? last.toDate() : null;
              final loc = [
                if ((data['city'] ?? '').toString().isNotEmpty) data['city'],
                if ((data['country'] ?? '').toString().isNotEmpty)
                  data['country'],
              ].join('، ');

              return Material(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF16181C)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: kSecurityAccent.withValues(alpha: 0.12),
                    child: Icon(
                      mine
                          ? Icons.phone_iphone_rounded
                          : Icons.devices_rounded,
                      color: kSecurityAccent,
                    ),
                  ),
                  title: Text(
                    mine
                        ? (trusted
                        ? '$name (هذا الجهاز · موثوق)'
                        : '$name (هذا الجهاز)')
                        : (trusted ? '$name · موثوق' : name),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    [
                      if (platform.isNotEmpty) platform,
                      if (loc.isNotEmpty) loc,
                      _securityTimeAgo(lastDt),
                    ].where((e) => e.toString().isNotEmpty).join(' · '),
                  ),
                  trailing: mine
                      ? TextButton(
                    onPressed: () async {
                      await _col.doc(d.id).set(
                        {'trusted': !trusted},
                        SetOptions(merge: true),
                      );
                    },
                    child: Text(trusted ? 'إلغاء التوثيق' : 'توثيق الجهاز'),
                  )
                      : IconButton(
                    tooltip: 'إنهاء الجلسة',
                    onPressed: () => _endOne(context, d.id),
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Future<void> _revokeOtherSessions() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final prefs = await SharedPreferences.getInstance();
  final mine = prefs.getString(_sessionPrefKey);
  final col = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('sessions');
  final snap = await col.get();
  final batch = FirebaseFirestore.instance.batch();
  for (final d in snap.docs) {
    if (d.id != mine) batch.delete(d.reference);
  }
  batch.set(
    FirebaseFirestore.instance.collection('users').doc(user.uid),
    {
      'security': {
        'sessionsRevokedAt': FieldValue.serverTimestamp(),
      },
    },
    SetOptions(merge: true),
  );
  await batch.commit();
}

String _secAuthError(FirebaseAuthException e) {
  switch (e.code) {
    case 'wrong-password':
    case 'invalid-credential':
      return 'كلمة المرور غير صحيحة';
    case 'requires-recent-login':
      return 'أعد تسجيل الدخول ثم حاول مرة أخرى';
    case 'email-already-in-use':
      return 'هذا البريد مستخدم بالفعل';
    case 'invalid-email':
      return 'البريد غير صالح';
    case 'weak-password':
      return 'كلمة المرور ضعيفة';
    case 'too-many-requests':
      return 'محاولات كثيرة، انتظر قليلًا';
    case 'invalid-phone-number':
      return 'رقم الهاتف غير صالح';
    case 'invalid-verification-code':
      return 'رمز التحقق غير صحيح';
    case 'session-expired':
      return 'انتهت صلاحية الرمز، أعد الإرسال';
    default:
      return e.message ?? 'حدث خطأ';
  }
}


const _lockOnKey = 'security_app_lock_on';
const _lockPinKey = 'security_app_lock_pin';
const _lockHideNotifKey = 'security_hide_notif_preview';

String _hashPin(String pin) {
  return pin.codeUnits
      .fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff)
      .toString();
}

class _AppLockPage extends StatefulWidget {
  const _AppLockPage();

  @override
  State<_AppLockPage> createState() => _AppLockPageState();
}

class _AppLockPageState extends State<_AppLockPage> {
  bool _on = false;
  bool _hideNotif = true;
  bool _hasPin = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _on = prefs.getBool(_lockOnKey) ?? false;
      _hideNotif = prefs.getBool(_lockHideNotifKey) ?? true;
      _hasPin = (prefs.getString(_lockPinKey) ?? '').isNotEmpty;
    });
  }

  Future<void> _setOn(bool value) async {
    if (value && !_hasPin) {
      final ok = await _askNewPin();
      if (ok != true) return;
    }
    if (value) {
      final bioOk = await _tryBiometric(reason: 'فعّل قفل UniSpace');
      if (!bioOk) {
        // البصمة اختيارية؛ PIN يكفي
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lockOnKey, value);
    if (!mounted) return;
    setState(() => _on = value);
  }

  Future<void> _setHideNotif(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lockHideNotifKey, value);
    if (!mounted) return;
    setState(() => _hideNotif = value);
  }

  Future<bool?> _askNewPin() async {
    final c1 = TextEditingController();
    final c2 = TextEditingController();
    final ok = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'تعيين رمز PIN',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const SizedBox(height: 6),
              const Text('4 إلى 6 أرقام. يُستخدم إن تعذّرت البصمة.'),
              const SizedBox(height: 12),
              TextField(
                controller: c1,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'PIN',
                  counterText: '',
                ),
              ),
              TextField(
                controller: c2,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'تأكيد PIN',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: kSecurityAccent,
                ),
                onPressed: () {
                  final a = c1.text.trim();
                  final b = c2.text.trim();
                  if (a.length < 4) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('4 أرقام على الأقل')),
                    );
                    return;
                  }
                  if (a != b) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('الرمزان غير متطابقين')),
                    );
                    return;
                  }
                  Navigator.pop(ctx, a);
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
        );
      },
    );
    c1.dispose();
    c2.dispose();
    if (ok == null || ok.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lockPinKey, _hashPin(ok));
    if (mounted) setState(() => _hasPin = true);
    return true;
  }

  Future<void> _changePin() async {
    final saved = (await SharedPreferences.getInstance()).getString(_lockPinKey);
    final current = TextEditingController();
    final next = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'تغيير PIN',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: current,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'PIN الحالي'),
              ),
              TextField(
                controller: next,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(labelText: 'PIN الجديد'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: kSecurityAccent,
                ),
                onPressed: () {
                  if (_hashPin(current.text.trim()) != (saved ?? '')) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('PIN الحالي غير صحيح')),
                    );
                    return;
                  }
                  if (next.text.trim().length < 4) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('4 أرقام على الأقل')),
                    );
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
        );
      },
    );
    final newPin = next.text.trim();
    current.dispose();
    next.dispose();
    if (ok != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lockPinKey, _hashPin(newPin));
    if (mounted) setState(() => _hasPin = true);
  }

  Future<bool> _tryBiometric({required String reason}) async {
    setState(() => _busy = true);
    try {
      final auth = LocalAuthentication();
      final can = await auth.canCheckBiometrics ||
          await auth.isDeviceSupported();
      if (!can) return false;
      return await auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('قفل التطبيق')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _on,
            activeColor: kSecurityAccent,
            title: const Text(
              'قفل UniSpace',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text(
              'يُطلب فتح القفل عند العودة إلى التطبيق',
            ),
            onChanged: _busy ? null : _setOn,
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _hideNotif,
            activeColor: kSecurityAccent,
            title: const Text(
              'إخفاء محتوى الإشعارات',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text(
              'على شاشة القفل يظهر «رسالة جديدة» بدون النص',
            ),
            onChanged: _setHideNotif,
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.pin_outlined, color: kSecurityAccent),
            title: const Text('تغيير رمز PIN'),
            subtitle: Text(_hasPin ? 'معيَّن' : 'غير معيَّن'),
            trailing: const Icon(Icons.chevron_left_rounded),
            onTap: _changePin,
          ),
          const SizedBox(height: 16),
          Text(
            'البصمة أو الوجه يُستخدمان إن كانا مفعّلين في الجهاز. PIN احتياطي إذا تعذّرا.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// غلّف به مادّة التطبيق (انظر الخطوة 6).
class SecurityLockGate extends StatefulWidget {
  const SecurityLockGate({super.key, required this.child});
  final Widget child;

  @override
  State<SecurityLockGate> createState() => _SecurityLockGateState();
}

class _SecurityLockGateState extends State<SecurityLockGate>
    with WidgetsBindingObserver {
  bool _locked = false;
  bool _checking = true;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _boot();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _boot() async {
    final prefs = await SharedPreferences.getInstance();
    final on = prefs.getBool(_lockOnKey) ?? false;
    if (!mounted) return;
    setState(() {
      _locked = on;
      _checking = false;
    });
    if (on) unawaited(_unlock());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _paused = true;
    }
    if (state == AppLifecycleState.resumed && _paused) {
      _paused = false;
      unawaited(_maybeLock());
    }
  }

  Future<void> _maybeLock() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_lockOnKey) != true) return;
    if (!mounted) return;
    setState(() => _locked = true);
    await _unlock();
  }

  Future<void> _unlock() async {
    try {
      final auth = LocalAuthentication();
      final can =
          await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (can) {
        final ok = await auth.authenticate(
          localizedReason: 'افتح UniSpace',
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
          ),
        );
        if (ok && mounted) {
          setState(() => _locked = false);
          return;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _locked = true);
  }

  Future<void> _unlockWithPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_lockPinKey) ?? '';
    if (saved.isEmpty || _hashPin(pin) != saved) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN غير صحيح')),
      );
      return;
    }
    if (mounted) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Stack(
      children: [
        widget.child,
        if (_locked) _LockScrim(onPin: _unlockWithPin, onBio: _unlock),
      ],
    );
  }
}

class _LockScrim extends StatefulWidget {
  const _LockScrim({required this.onPin, required this.onBio});
  final ValueChanged<String> onPin;
  final VoidCallback onBio;

  @override
  State<_LockScrim> createState() => _LockScrimState();
}

class _LockScrimState extends State<_LockScrim> {
  String _pin = '';

  void _digit(String d) {
    if (_pin.length >= 6) return;
    setState(() => _pin += d);
    if (_pin.length >= 4) widget.onPin(_pin);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0B0B0D),
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Icon(Icons.lock_rounded, color: Colors.white, size: 42),
            const SizedBox(height: 12),
            const Text(
              'UniSpace مقفل',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'بصمة أو PIN للمتابعة',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                final on = i < _pin.length;
                return Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: on ? kSecurityAccent : Colors.white24,
                  ),
                );
              }),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                childAspectRatio: 1.6,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final n in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
                    TextButton(
                      onPressed: () => _digit(n),
                      child: Text(
                        n,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  IconButton(
                    onPressed: widget.onBio,
                    icon: const Icon(
                      Icons.fingerprint_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _digit('0'),
                    child: const Text(
                      '0',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_pin.isEmpty) return;
                      setState(() => _pin = _pin.substring(0, _pin.length - 1));
                    },
                    icon: const Icon(Icons.backspace_outlined, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _TwoFactorPage extends StatefulWidget {
  const _TwoFactorPage();

  @override
  State<_TwoFactorPage> createState() => _TwoFactorPageState();
}

class _TwoFactorPageState extends State<_TwoFactorPage> {
  bool _on = false;
  bool _busy = false;
  TotpSecret? _secret;
  String? _otpauth;
  final _code = TextEditingController();
  List<String>? _backupShownOnce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final u = FirebaseAuth.instance.currentUser;
      final factors = await u?.multiFactor.getEnrolledFactors() ?? [];
      if (!mounted) return;
      setState(() => _on = factors.isNotEmpty);
    } catch (_) {}
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<String?> _askPassword() async {
    final c = TextEditingController();
    final ok = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('أكّد هويتك'),
        content: TextField(
          controller: c,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'كلمة المرور الحالية',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kSecurityAccent),
            onPressed: () => Navigator.pop(ctx, c.text),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );
    c.dispose();
    if (ok == null || ok.isEmpty) return null;
    return ok;
  }

  Future<bool> _reauth(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null) return false;
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _snack(_secAuthError(e));
      return false;
    }
  }

  Future<void> _startEnroll() async {
    final password = await _askPassword();
    if (password == null) return;
    if (!await _reauth(password)) return;

    setState(() => _busy = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final session = await user.multiFactor.getSession();
      final secret = await TotpMultiFactorGenerator.generateSecret(session);
      final url = await secret.generateQrCodeUrl(
        accountName: user.email ?? 'UniSpace',
        issuer: 'UniSpace',
      );
      if (!mounted) return;
      setState(() {
        _secret = secret;
        _otpauth = url;
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'unsupported' ||
          (e.message ?? '').toLowerCase().contains('second factor')) {
        _snack(
          'فعّل TOTP من Firebase Console ← Authentication ← Settings ← MFA',
        );
      } else {
        _snack(_secAuthError(e));
      }
    } catch (e) {
      _snack('تعذر بدء التفعيل. تأكد أن MFA مفعّل في Firebase.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmEnroll() async {
    final secret = _secret;
    final code = _code.text.trim();
    if (secret == null) return;
    if (code.length < 6) {
      _snack('أدخل رمز 6 أرقام من التطبيق');
      return;
    }
    setState(() => _busy = true);
    try {
      final assertion =
      await TotpMultiFactorGenerator.getAssertionForEnrollment(
        secret,
        code,
      );
      await FirebaseAuth.instance.currentUser!.multiFactor.enroll(
        assertion,
        displayName: 'Authenticator',
      );
      final codes = _generateBackupCodes();
      await _saveBackupHashes(codes);
      if (!mounted) return;
      setState(() {
        _on = true;
        _secret = null;
        _otpauth = null;
        _backupShownOnce = codes;
      });
      _code.clear();
    } on FirebaseAuthException catch (e) {
      _snack(_secAuthError(e));
    } catch (_) {
      _snack('رمز غير صحيح أو انتهت صلاحيته');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disable() async {
    final password = await _askPassword();
    if (password == null) return;
    if (!await _reauth(password)) return;
    setState(() => _busy = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final factors = await user.multiFactor.getEnrolledFactors();
      for (final f in factors) {
        await user.multiFactor.unenroll(factorUid: f.uid);
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'security': {
          'mfaEnabled': false,
          'backupCodes': [],
        },
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() {
        _on = false;
        _backupShownOnce = null;
      });
      _snack('تم إيقاف التأكيد بخطوتين');
    } on FirebaseAuthException catch (e) {
      _snack(_secAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<String> _generateBackupCodes() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(8, (_) {
      return List.generate(8, (_) => chars[r.nextInt(chars.length)]).join();
    });
  }

  Future<void> _saveBackupHashes(List<String> codes) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'security': {
        'mfaEnabled': true,
        'backupCodes': codes.map(_hashPin).toList(),
        'backupCodesCreatedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final qr = _otpauth;
    return Scaffold(
      appBar: AppBar(title: const Text('التأكيد بخطوتين')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              _on ? Icons.verified_user : Icons.gpp_maybe_outlined,
              color: _on ? const Color(0xFF16A34A) : const Color(0xFFD97706),
            ),
            title: Text(_on ? 'مفعّل' : 'غير مفعّل'),
            subtitle: const Text(
              'عند الدخول من جهاز جديد يُطلب رمز من تطبيق مثل Google Authenticator أو Authy.',
            ),
          ),
          const SizedBox(height: 8),
          if (!_on && qr == null)
            FilledButton(
              onPressed: _busy ? null : _startEnroll,
              style: FilledButton.styleFrom(
                backgroundColor: kSecurityAccent,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(_busy ? 'جاري التحضير…' : 'تفعيل تطبيق المصادقة'),
            ),
          if (qr != null) ...[
            const Text(
              '1) امسح الرمز من تطبيق المصادقة، أو أدخل المفتاح يدويًا.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: Image.network(
                  'https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=${Uri.encodeComponent(qr)}',
                  width: 220,
                  height: 220,
                  errorBuilder: (_, __, ___) => SelectableText(
                    _secret?.secretKey ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              'المفتاح: ${_secret?.secretKey ?? ''}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                letterSpacing: 8,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
              decoration: InputDecoration(
                labelText: '2) أدخل الرمز الظاهر في التطبيق',
                counterText: '',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _confirmEnroll,
              style: FilledButton.styleFrom(
                backgroundColor: kSecurityAccent,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('تأكيد التفعيل'),
            ),
          ],
          if (_backupShownOnce != null) ...[
            const SizedBox(height: 18),
            const Text(
              'احفظ هذه الرموز في مكان آمن. تظهر مرة واحدة.',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            for (final c in _backupShownOnce!)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: SelectableText(
                  c,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
          ],
          if (_on) ...[
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: _busy ? null : _disable,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('إيقاف التأكيد بخطوتين'),
            ),
          ],
        ],
      ),
    );
  }
}

/// استدعها من شاشة الدخول عندما يرمي Firebase خطأ MFA.
class MfaSignInPage extends StatefulWidget {
  const MfaSignInPage({super.key, required this.resolver});
  final MultiFactorResolver resolver;

  @override
  State<MfaSignInPage> createState() => _MfaSignInPageState();
}

class _MfaSignInPageState extends State<MfaSignInPage> {
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _code.text.trim();
    if (code.length < 6) return;

    MultiFactorInfo? hint;
    for (final h in widget.resolver.hints) {
      if (h.factorId == 'totp') {
        hint = h;
        break;
      }
    }
    hint ??=
    widget.resolver.hints.isNotEmpty ? widget.resolver.hints.first : null;
    if (hint == null) return;

    setState(() => _busy = true);
    try {
      final assertion =
      await TotpMultiFactorGenerator.getAssertionForSignIn(
        hint.uid,
        code,
      );
      await widget.resolver.resolveSignIn(assertion);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_secAuthError(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('رمز التحقق')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('أدخل الرمز من تطبيق المصادقة.'),
            const SizedBox(height: 16),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                letterSpacing: 8,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
              decoration: InputDecoration(
                labelText: 'الرمز',
                counterText: '',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: kSecurityAccent,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> _secReauthWithPassword(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  final email = user?.email;
  if (user == null || email == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('أعد تسجيل الدخول ثم حاول')),
    );
    return false;
  }
  final c = TextEditingController();
  final password = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('أكّد هويتك'),
      content: TextField(
        controller: c,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'كلمة المرور'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: kSecurityAccent),
          onPressed: () => Navigator.pop(ctx, c.text),
          child: const Text('متابعة'),
        ),
      ],
    ),
  );
  c.dispose();
  if (password == null || password.isEmpty) return false;
  try {
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: email, password: password),
    );
    return true;
  } on FirebaseAuthException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_secAuthError(e))),
      );
    }
    return false;
  }
}

class _CompromisedAccountPage extends StatefulWidget {
  const _CompromisedAccountPage();

  @override
  State<_CompromisedAccountPage> createState() =>
      _CompromisedAccountPageState();
}

class _CompromisedAccountPageState extends State<_CompromisedAccountPage> {
  bool _busy = false;

  Future<void> _run() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأمين الحساب؟'),
        content: const Text(
          'سننهي كل الجلسات على الأجهزة الأخرى. نوصي بتغيير كلمة المرور مباشرة بعد ذلك.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأمين الآن'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!await _secReauthWithPassword(context)) return;

    setState(() => _busy = true);
    try {
      await _revokeOtherSessions();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'security': {
            'compromisedAt': FieldValue.serverTimestamp(),
            'sessionsRevokedAt': FieldValue.serverTimestamp(),
          },
        }, SetOptions(merge: true));
      }
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const _ChangePasswordPage()),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنهاء الجلسات الأخرى')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تأمين الحساب')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تم اختراق حسابي')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const Text(
            'استخدم هذا إن دخل أحد إلى حسابك أو رأيت جهازًا لا تعرفه.',
            style: TextStyle(height: 1.45),
          ),
          const SizedBox(height: 16),
          const Text('• إنهاء كل الأجهزة ما عدا هذا الجهاز'),
          const Text('• ثم تغيير كلمة المرور'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _run,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(_busy ? 'جاري التأمين…' : 'تأمين الحساب'),
          ),
        ],
      ),
    );
  }
}

class _FreezeAccountPage extends StatefulWidget {
  const _FreezeAccountPage();

  @override
  State<_FreezeAccountPage> createState() => _FreezeAccountPageState();
}

class _FreezeAccountPageState extends State<_FreezeAccountPage> {
  bool _frozen = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final snap =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final security =
    Map<String, dynamic>.from(snap.data()?['security'] ?? {});
    if (!mounted) return;
    setState(() => _frozen = security['frozen'] == true);
  }

  Future<void> _toggle() async {
    if (!await _secReauthWithPassword(context)) return;
    setState(() => _busy = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final next = !_frozen;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'security': {
          'frozen': next,
          'frozenAt': next ? FieldValue.serverTimestamp() : null,
        },
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() => _frozen = next);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(next ? 'تم تجميد الحساب' : 'تم إلغاء التجميد'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديث حالة الحساب')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تجميد الحساب')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            _frozen
                ? 'الحساب مجمّد. ملفك مخفي ولن تصلك رسائل جديدة حتى إلغاء التجميد.'
                : 'التجميد يخفي ملفك ويوقف الرسائل دون حذف المنشورات أو المحادثات.',
            style: const TextStyle(height: 1.45),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _toggle,
            style: FilledButton.styleFrom(
              backgroundColor:
              _frozen ? kSecurityAccent : const Color(0xFFD97706),
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(_frozen ? 'إلغاء التجميد' : 'تجميد الحساب'),
          ),
        ],
      ),
    );
  }
}

class _DeleteAccountPage extends StatefulWidget {
  const _DeleteAccountPage();

  @override
  State<_DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<_DeleteAccountPage> {
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_confirm.text.trim() != 'حذف') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب حذف للتأكيد')),
      );
      return;
    }
    if (!await _secReauthWithPassword(context)) return;
    setState(() => _busy = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final uid = user.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'security': {
          'deletedAt': FieldValue.serverTimestamp(),
        },
        'isDeleted': true,
      }, SetOptions(merge: true));
      await _revokeOtherSessions();
      await user.delete();
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_secAuthError(e))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حذف الحساب')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حذف الحساب')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const Text(
            'سيُحذف حساب الدخول نهائيًا. لن تستطيع استخدام نفس البريد للدخول بعد ذلك.',
            style: TextStyle(height: 1.45),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirm,
            decoration: InputDecoration(
              labelText: 'اكتب حذف للتأكيد',
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _delete,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(_busy ? 'جاري الحذف…' : 'حذف الحساب نهائيًا'),
          ),
        ],
      ),
    );
  }
}

class FrozenAccountScreen extends StatelessWidget {
  const FrozenAccountScreen({super.key, required this.onUnfrozen});
  final VoidCallback onUnfrozen;

  Future<void> _unfreeze(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'security': {
          'frozen': false,
          'frozenAt': null,
        },
      }, SetOptions(merge: true));
      onUnfrozen();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر إلغاء التجميد')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pause_circle_outline_rounded, size: 64),
              const SizedBox(height: 16),
              const Text(
                'الحساب مجمّد',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'ملفك مخفي ولن تظهر في البحث حتى إلغاء التجميد.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => _unfreeze(context),
                child: const Text('إلغاء التجميد'),
              ),
              TextButton(
                onPressed: () async {
                  await AuthSessionService.signOutFully();
                },
                child: const Text('تسجيل الخروج'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginAlertWatcher extends StatefulWidget {
  const LoginAlertWatcher({super.key, required this.child});
  final Widget child;

  @override
  State<LoginAlertWatcher> createState() => _LoginAlertWatcherState();
}

class _LoginAlertWatcherState extends State<LoginAlertWatcher> {
  static const _seenKey = 'security_seen_login_alert';
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_attach);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }

  Future<void> _attach(User? user) async {
    await _userSub?.cancel();
    _userSub = null;
    if (user == null) return;
    await ensureSecuritySession();
    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(_onUserDoc);
  }

  Future<void> _onUserDoc(
      DocumentSnapshot<Map<String, dynamic>> snap,
      ) async {
    if (!snap.exists || !mounted || _dialogOpen) return;
    final alert = Map<String, dynamic>.from(
      snap.data()?['security']?['lastLoginAlert'] ?? {},
    );
    final sessionId = (alert['sessionId'] ?? '').toString();
    if (sessionId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final mine = prefs.getString(_sessionPrefKey);
    if (sessionId == mine) return;

    final at = alert['at'];
    final atMs = at is Timestamp ? at.millisecondsSinceEpoch : 0;
    final seenKey = '${sessionId}_$atMs';
    if (prefs.getString(_seenKey) == seenKey) return;

    if (at is Timestamp) {
      final age = DateTime.now().difference(at.toDate());
      if (age > const Duration(minutes: 30)) {
        await prefs.setString(_seenKey, seenKey);
        return;
      }
    }

    await prefs.setString(_seenKey, seenKey);
    if (!mounted) return;
    _dialogOpen = true;
    final device = (alert['deviceName'] ?? 'جهاز غير معروف').toString();
    final platform = (alert['platform'] ?? '').toString();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('دخول جديد على حسابك'),
        content: Text(
          [
            'تم فتح الجلسة من:',
            device,
            if (platform.isNotEmpty) '($platform)',
            '',
            'إذا لم تكن أنت، أمِّن الحساب فورًا.',
          ].join('\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('كنتُ أنا'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const _CompromisedAccountPage(),
                ),
              );
            },
            child: const Text('لم أكن أنا'),
          ),
        ],
      ),
    );
    _dialogOpen = false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}