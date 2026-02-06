import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  final _departmentController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _levelController = TextEditingController();
  final _collegeFocusNode = FocusNode();
  final _departmentFocusNode = FocusNode();
  final _specialtyFocusNode = FocusNode();
  List<ProgramFaculty> _faculties = const [];
  ProgramFaculty? _selectedFaculty;
  ProgramMajor? _selectedDepartment;
  ProgramTrack? _selectedSpecialty;
  bool _seededProfileValues = false;
  late final VoidCallback _profileListener;

  @override
  void initState() {
    super.initState();
    _collegeController.addListener(_handleFacultyChanged);
    _departmentController.addListener(_handleDepartmentChanged);
    _specialtyController.addListener(_handleSpecialtyChanged);
    _profileListener = () {
      if (_seededProfileValues || _faculties.isEmpty) return;
      final data = UserProfileService.instance.notifier.value;
      if (data.college.isEmpty && data.major.isEmpty && data.level.isEmpty) {
        return;
      }
      _seedFromProfile(data.college, data.major, data.level);
    };
    UserProfileService.instance.notifier.addListener(_profileListener);
    _profileListener();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_faculties.isEmpty) {
      _faculties = getDemoFaculties(context);
      _profileListener();
    }
  }

  @override
  void dispose() {
    UserProfileService.instance.notifier.removeListener(_profileListener);
    _collegeController.dispose();
    _departmentController.dispose();
    _specialtyController.dispose();
    _levelController.dispose();
    _collegeFocusNode.dispose();
    _departmentFocusNode.dispose();
    _specialtyFocusNode.dispose();
    super.dispose();
  }

  void _seedFromProfile(String college, String major, String level) {
    final savedCollege = college.trim();
    final savedMajor = major.trim();
    final savedLevel = level.trim();
    ProgramFaculty? matchedFaculty = savedCollege.isEmpty
        ? null
        : _faculties.cast<ProgramFaculty?>().firstWhere(
              (faculty) => faculty?.name == savedCollege,
              orElse: () => null,
            );
    Iterable<ProgramFaculty> facultyPool =
        matchedFaculty == null ? _faculties : [matchedFaculty];
    ProgramMajor? matchedDepartment;
    ProgramTrack? matchedSpecialty;

    if (savedMajor.isNotEmpty) {
      for (final faculty in facultyPool) {
        for (final major in faculty.majors) {
          for (final track in major.tracks) {
            final matchesName = track.name == savedMajor;
            final matchesLevel =
                savedLevel.isEmpty || track.level == savedLevel;
            if (matchesName && matchesLevel) {
              matchedFaculty = faculty;
              matchedDepartment = major;
              matchedSpecialty = track;
              break;
            }
          }
          if (matchedSpecialty != null) break;
        }
        if (matchedSpecialty != null) break;
      }
    }

    if (matchedSpecialty == null && savedMajor.isNotEmpty) {
      for (final faculty in facultyPool) {
        for (final major in faculty.majors) {
          if (major.name == savedMajor) {
            matchedFaculty ??= faculty;
            matchedDepartment = major;
            if (savedLevel.isNotEmpty) {
              matchedSpecialty = major.tracks.cast<ProgramTrack?>().firstWhere(
                    (track) => track?.level == savedLevel,
                    orElse: () => null,
                  );
            }
            break;
          }
        }
        if (matchedDepartment != null) break;
      }
    }

    setState(() {
      _selectedFaculty = matchedFaculty;
      _selectedDepartment = matchedDepartment;
      _selectedSpecialty = matchedSpecialty;
      _collegeController.text = matchedFaculty?.name ?? savedCollege;
      _departmentController.text = matchedDepartment?.name ?? '';
      _specialtyController.text =
          matchedSpecialty?.name ?? (matchedDepartment == null ? savedMajor : '');
      _levelController.text =
          matchedSpecialty?.level ?? savedLevel;
      _seededProfileValues = true;
    });
  }

  void _handleFacultyChanged() {
    final text = _collegeController.text.trim();
    if (_selectedFaculty != null && _selectedFaculty?.name != text) {
      setState(() {
        _selectedFaculty = null;
        _clearDepartmentSelection();
        _clearSpecialtySelection();
      });
    }
  }

  void _handleDepartmentChanged() {
    final text = _departmentController.text.trim();
    if (_selectedDepartment != null && _selectedDepartment?.name != text) {
      setState(() {
        _selectedDepartment = null;
        _clearSpecialtySelection();
      });
    }
  }

  void _handleSpecialtyChanged() {
    final text = _specialtyController.text.trim();
    if (_selectedSpecialty != null && _selectedSpecialty?.name != text) {
      setState(() {
        _selectedSpecialty = null;
        _levelController.clear();
      });
    }
  }

  void _clearDepartmentSelection() {
    _selectedDepartment = null;
    _departmentController.clear();
  }

  void _clearSpecialtySelection() {
    _selectedSpecialty = null;
    _specialtyController.clear();
    _levelController.clear();
  }

  String _normalizeQuery(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  Iterable<ProgramFaculty> _facultyOptions(TextEditingValue textEditingValue) {
    final query = _normalizeQuery(textEditingValue.text).toLowerCase();
    if (query.isEmpty) {
      return const Iterable<ProgramFaculty>.empty();
    }
    return _faculties.where(
      (faculty) => faculty.name.toLowerCase().contains(query),
    );
  }

  Iterable<ProgramMajor> _departmentOptions(TextEditingValue textEditingValue) {
    if (_selectedFaculty == null) {
      return const Iterable<ProgramMajor>.empty();
    }
    final query = _normalizeQuery(textEditingValue.text).toLowerCase();
    if (query.isEmpty) {
      return const Iterable<ProgramMajor>.empty();
    }
    return _selectedFaculty!.majors.where(
      (major) => major.name.toLowerCase().contains(query),
    );
  }

  Iterable<ProgramTrack> _specialtyOptions(TextEditingValue textEditingValue) {
    if (_selectedDepartment == null) {
      return const Iterable<ProgramTrack>.empty();
    }
    final query = _normalizeQuery(textEditingValue.text).toLowerCase();
    if (query.isEmpty) {
      return const Iterable<ProgramTrack>.empty();
    }
    return _selectedDepartment!.tracks.where(
      (track) => track.name.toLowerCase().contains(query),
    );
  }

  Widget _buildAutocompleteField<T extends Object>({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String labelText,
    required Iterable<T> Function(TextEditingValue) optionsBuilder,
    required String Function(T) displayStringForOption,
    required ValueChanged<T> onSelected,
  }) {
    return RawAutocomplete<T>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: optionsBuilder,
      displayStringForOption: displayStringForOption,
      onSelected: onSelected,
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: textController,
          focusNode: focusNode,
          textAlign: TextAlign.start,
          decoration: InputDecoration(
            labelText: labelText,
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: AlignmentDirectional.topStart,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(
                      displayStringForOption(option),
                      textAlign: TextAlign.start,
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasValidSelections = _selectedFaculty != null &&
        _selectedDepartment != null &&
        _selectedSpecialty != null &&
        _levelController.text.trim().isNotEmpty;
    final allFieldsEmpty = _collegeController.text.trim().isEmpty &&
        _departmentController.text.trim().isEmpty &&
        _specialtyController.text.trim().isEmpty &&
        _levelController.text.trim().isEmpty;
    final canSave = hasValidSelections || allFieldsEmpty;

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
          _buildAutocompleteField<ProgramFaculty>(
            controller: _collegeController,
            focusNode: _collegeFocusNode,
            labelText: S.of(context).academicCollegeLabel,
            optionsBuilder: _facultyOptions,
            displayStringForOption: (faculty) => faculty.name,
            onSelected: (faculty) {
              setState(() {
                _selectedFaculty = faculty;
                _collegeController.text = faculty.name;
                _clearDepartmentSelection();
                _clearSpecialtySelection();
              });
            },
          ),
          const SizedBox(height: 12),
          _buildAutocompleteField<ProgramMajor>(
            controller: _departmentController,
            focusNode: _departmentFocusNode,
            labelText: S.of(context).academicclass,
            optionsBuilder: _departmentOptions,
            displayStringForOption: (major) => major.name,
            onSelected: (major) {
              setState(() {
                _selectedDepartment = major;
                _departmentController.text = major.name;
                _clearSpecialtySelection();
              });
            },
          ),
          const SizedBox(height: 12),
          _buildAutocompleteField<ProgramTrack>(
            controller: _specialtyController,
            focusNode: _specialtyFocusNode,
            labelText: S.of(context).academicMajorLabel,
            optionsBuilder: _specialtyOptions,
            displayStringForOption: (track) => track.name,
            onSelected: (track) {
              setState(() {
                _selectedSpecialty = track;
                _specialtyController.text = track.name;
                _levelController.text = track.level;
              });
            },
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
            onPressed: canSave
                ? () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(S.of(context).signInRequired)),
                      );
                      return;
                    }
                    final selectedFaculty = _selectedFaculty;
                    final selectedDepartment = _selectedDepartment;
                    final selectedSpecialty = _selectedSpecialty;
                    final faculty = selectedFaculty?.name ?? '';
                    final department = selectedDepartment?.name ?? '';
                    final specialty = selectedSpecialty?.name ?? '';
                    final level = _levelController.text.trim();
                    final hasShortcut = faculty.isNotEmpty ||
                        department.isNotEmpty ||
                        specialty.isNotEmpty ||
                        level.isNotEmpty;
                    await AppSettings.instance.setAcademicShortcut(
                      hasAcademicShortcut: hasShortcut,
                      facultyId: faculty,
                      departmentId: department,
                      specialtyId: specialty,
                      level: level,
                      facultyName: faculty,
                      departmentName: department,
                      specialtyName: specialty,
                    );
                    var syncFailed = false;
                    try {
                      await UserProfileService.instance.updateAcademic(
                        college: faculty,
                        major: specialty,
                        level: level,
                      );
                    } on FirebaseException {
                      syncFailed = true;
                    }
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          syncFailed
                              ? 'Saved locally. Sync failed.'
                              : S.of(context).academicSettingsSaved,
                        ),
                      ),
                    );
                    Navigator.pop(context);
                  }
                : null,
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
    final id = await SessionService.instance.getOrCreateSessionId(user.uid);
    if (!mounted) return;
    setState(() => _localSessionId = id);
  }

  String _formatTimestamp(Timestamp? timestamp, BuildContext context) {
    if (timestamp == null) {
      return S.of(context).activeSessionNow;
    }
    return DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
        .add_jm()
        .format(timestamp.toDate());
  }

  bool _isActiveSession(Map<String, dynamic> data) {
    final isActive = data['isActive'] as bool? ?? false;
    final lastSeen = data['lastSeenAt'] as Timestamp?;
    if (!isActive || lastSeen == null) return false;
    final now = DateTime.now();
    return now.difference(lastSeen.toDate()) <= const Duration(days: 7);
  }

  Future<void> _logoutSession(String uid, String sessionId) async {
    try {
      await SessionService.instance.revokeSession(uid: uid, sessionId: sessionId);
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
      await SessionService.instance.revokeAllOtherSessions(
        uid: uid,
        currentSessionId: current,
      );
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).manageDevicesTitle),
      ),
      body: user == null
          ? Center(child: Text(S.of(context).signInRequired))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: SessionService.instance.sessionsStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting || _localSessionId == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                final sessionDocs = snapshot.data?.docs ?? const [];
                final activeDocs = sessionDocs.where((doc) => _isActiveSession(doc.data())).toList();
                final currentId = _localSessionId!;
                final currentIndex = activeDocs.indexWhere((doc) => doc.id == currentId);
                final QueryDocumentSnapshot<Map<String, dynamic>>? currentDoc =
                    currentIndex >= 0 ? activeDocs[currentIndex] : null;
                final otherDocs = activeDocs.where((doc) => doc.id != currentId).toList();

                return ListView(
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
                        title: Row(
                          children: [
                            Expanded(child: Text(S.of(context).currentDeviceTitle)),
                            Chip(label: Text(S.of(context).currentDeviceTitle)),
                          ],
                        ),
                        subtitle: Text(
                          currentDoc == null
                              ? S.of(context).activeSessionNow
                              : '${(currentDoc.data()['deviceName'] as String? ?? S.of(context).sessionUnknownDevice)}\n${_formatTimestamp(currentDoc.data()['lastSeenAt'] as Timestamp?, context)}',
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
                          ),
                        ),
                        TextButton(
                          onPressed: () => _logoutAllOther(user.uid),
                          child: Text(S.of(context).logoutAllOtherDevices),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (otherDocs.isEmpty)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.devices_other),
                          title: Text(S.of(context).activeSessionsEmpty),
                        ),
                      )
                    else
                      ...otherDocs.map(
                        (doc) {
                          final data = doc.data();
                          final deviceName = data['deviceName'] as String? ?? S.of(context).sessionUnknownDevice;
                          final lastSeen = data['lastSeenAt'] as Timestamp?;
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.devices_other),
                              title: Text(deviceName),
                              subtitle: Text(_formatTimestamp(lastSeen, context)),
                              trailing: TextButton(
                                onPressed: () => _logoutSession(user.uid, doc.id),
                                child: Text(S.of(context).signOut),
                              ),
                            ),
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
