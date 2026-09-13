import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';

import '../../core/branding.dart';
// الترجمة المولَّدة:
import '../../generated/l10n.dart'; // أو المسار الصحيح لـ S عندك
import '../../moduls3.dart';
import 'package:flutter/widgets.dart';
import '../../../ui/widgets/app_scaffold.dart';
import '../../core/translate_subject.dart';
import 'package:UniSpace/main.dart';
import 'package:UniSpace/ui/settings/drawer_screens.dart';
import 'package:UniSpace/ui/faculty_search_page.dart';
import 'package:UniSpace/ui/settings/app_settings.dart';
import 'package:UniSpace/ui/widgets/metric_tile.dart';
import 'package:UniSpace/ui/settings/user_profile_service.dart';
import 'package:translator/translator.dart';

SemesterSpec _pickSemester(List<SemesterSpec> specs, String label) {
  final normalizedLabel = label.toUpperCase();
  if (specs.isEmpty) {
    return const SemesterSpec(name: 'S?', modules: []);
  }
  return specs.firstWhere(
        (s) => s.name.toUpperCase() == normalizedLabel,
    orElse: () {
      if (normalizedLabel == 'S1') {
        return specs.first;
      }
      if (normalizedLabel == 'S2' && specs.length > 1) {
        return specs.last;
      }
      return specs.first;
    },
  );
}

class HomeLandingScreen extends StatefulWidget {
  const HomeLandingScreen({
    super.key,
    this.showAppBar = false,
    this.bottomPadding = 0,
    this.onOpenDrawer,
  });

  final bool showAppBar;
  final double bottomPadding;
  final VoidCallback? onOpenDrawer;   // ← added

  @override
  State<HomeLandingScreen> createState() => _HomeLandingScreenState();
}

class _HomeLandingScreenState extends State<HomeLandingScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchOpen = false;

  Future<void> _openSearch(BuildContext context, String initialQuery) async {
    if (_isSearchOpen) {
      return;
    }
    _isSearchOpen = true;
    FocusScope.of(context).unfocus();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FacultySearchPage(
          faculties: getDemoFaculties(context),
          initialQuery: initialQuery,
          onFacultySelected: _openFaculty,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    _searchController.clear();
    _isSearchOpen = false;
  }

  void _openFaculty(BuildContext context, ProgramFaculty faculty) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FacultyMajorsScreen(faculty: faculty)),
    );
  }

  void _openAcademicShortcut(BuildContext context, SettingsData settings) {
    final faculties = getDemoFaculties(context);
    final targetFaculty = settings.academicFacultyName.isNotEmpty
        ? settings.academicFacultyName
        : settings.academicFacultyId;
    final targetDepartment = settings.academicDepartmentName.isNotEmpty
        ? settings.academicDepartmentName
        : settings.academicDepartmentId;
    final targetSpecialty = settings.academicSpecialtyName.isNotEmpty
        ? settings.academicSpecialtyName
        : settings.academicSpecialtyId;
    final targetLevel = settings.academicLevel;

    ProgramFaculty? matchedFaculty;
    ProgramMajor? matchedMajor;
    ProgramTrack? matchedTrack;

    for (final faculty in faculties) {
      if (targetFaculty.isNotEmpty && faculty.name != targetFaculty) {
        continue;
      }
      matchedFaculty = faculty;
      for (final major in faculty.majors) {
        if (targetDepartment.isNotEmpty && major.name != targetDepartment) {
          continue;
        }
        matchedMajor = major;
        for (final track in major.tracks) {
          final matchesSpecialty = track.name == targetSpecialty ||
              (settings.academicSpecialtyId.isNotEmpty &&
                  track.name == settings.academicSpecialtyId);
          final matchesLevel =
              targetLevel.isEmpty || track.level == targetLevel;
          if (matchesSpecialty && matchesLevel) {
            matchedTrack = track;
            break;
          }
        }
        if (matchedTrack != null) {
          break;
        }
      }
      if (matchedTrack != null) {
        break;
      }
    }

    if (matchedTrack != null &&
        matchedMajor != null &&
        matchedFaculty != null) {
      final selectedFaculty = matchedFaculty;
      final selectedMajor = matchedMajor;
      final selectedTrack = matchedTrack;
      if (selectedFaculty == null ||
          selectedMajor == null ||
          selectedTrack == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).academicShortcutNotFound)),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AcademicSettingsScreen(),
          ),
        );
        return;
      }
      final specs = createSemesterSpecsForTrack(selectedTrack);
      final sem1 = _pickSemester(specs, 'S1');
      final sem2 = _pickSemester(specs, 'S2');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudiesTableScreen(
            facultyName: selectedFaculty.name,
            programName: '${selectedMajor.name} • ${selectedTrack.name}',
            collegeId: selectedFaculty.name,
            departmentId: selectedMajor.name,
            specialtyId: selectedTrack.name,
            level: selectedTrack.level,
            academicScopeId: buildAcademicStorageSignature(
              semester1: sem1,
              semester2: sem2,
              level: selectedTrack.level,
            ),
            semester1Modules: sem1,
            semester2Modules: sem2,
          ),
        ),
      );
      return;
    }

    if (matchedMajor != null && matchedFaculty != null) {
      final selectedMajor = matchedMajor;
      final selectedFaculty = matchedFaculty;
      if (selectedMajor == null || selectedFaculty == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).academicShortcutNotFound)),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AcademicSettingsScreen(),
          ),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MajorTracksScreen(
            major: selectedMajor,
            faculty: selectedFaculty,
          ),
        ),
      );
      return;
    }

    if (matchedFaculty != null) {
      final selectedFaculty = matchedFaculty;
      if (selectedFaculty == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).academicShortcutNotFound)),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AcademicSettingsScreen(),
          ),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FacultyMajorsScreen(faculty: selectedFaculty),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).academicShortcutNotFound)),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AcademicSettingsScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final faculties = getDemoFaculties(context).take(6).toList();
    final quickFaculty = faculties.isNotEmpty ? faculties.first : null;

    return AppScaffold(
      padding: EdgeInsets.zero,
      appBar: widget.showAppBar
          ? AppBar(
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: true,
        titleSpacing: 16,
        title: Text(
          S.of(context).gpu,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      )
          : null,
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).gpu,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,fontSize: 23.5
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                      child:Text(
                    'ابحث عن تخصصك, قم بادخال علاماتك واضطلع على معدلك',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  )),
                  const SizedBox(height: 18),
                  Material(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.65,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onTap: () {
                        _openSearch(
                          context,
                          _searchController.text,
                        );
                      },
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          _openSearch(context, value.trim());
                        }
                      },
                      decoration: InputDecoration(
                        hintText: S.of(context).searchFaculty,
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: colorScheme.primary,
                        ),
                        suffixIcon: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _searchController,
                          builder: (context, value, child) {
                            if (value.text.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            return IconButton(
                              tooltip: 'مسح',
                              onPressed: _searchController.clear,
                              icon: const Icon(Icons.close_rounded),
                            );
                          },
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 15,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.15),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.15),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: ValueListenableBuilder<SettingsData>(
              valueListenable: AppSettings.instance.notifier,
              builder: (context, settings, _) {
                final specialtyId =
                settings.academicSpecialtyId.trim();

                if (!settings.hasAcademicShortcut) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                    child: _AcademicShortcutCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _AcademicShortcutHeader(),
                          const SizedBox(height: 18),
                          Text(
                            S.of(context).academicShortcutEmptyTitle,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'اختر كليتك وتخصصك للوصول السريع إلى حساب المعدل والمواد.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _AcademicShortcutActions(
                            primaryLabel:
                            S.of(context).academicShortcutEmptyAction,
                            primaryIcon: Icons.add_circle_outline_rounded,
                            onPrimaryPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                  const AcademicSettingsScreen(),
                                ),
                              );
                            },
                            secondaryLabel: S.of(context).quickCalc2,
                            secondaryIcon: Icons.calculate_rounded,
                            onSecondaryPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                  const QuickAverageScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final facultyName =
                (settings.academicFacultyName.isNotEmpty
                    ? settings.academicFacultyName
                    : settings.academicFacultyId)
                    .trim();

                final specialtyName =
                (settings.academicSpecialtyName.isNotEmpty
                    ? settings.academicSpecialtyName
                    : specialtyId)
                    .trim();

                final displaySpecialty =
                specialtyName.isNotEmpty ? specialtyName : '—';

                final level = settings.academicLevel.trim();
                final displayLevel = level.isNotEmpty ? level : '—';

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Dismissible(
                    key: ValueKey<String>(
                      'academic-shortcut-'
                          '${settings.academicSpecialtyId}-'
                          '${settings.academicLevel}',
                    ),
                    direction: DismissDirection.startToEnd,
                    background: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: AlignmentDirectional.centerStart,
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: colorScheme.onError,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            S.of(context).academicShortcutDeleteTitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onError,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    confirmDismiss: (_) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) {
                          return AlertDialog(
                            title: Text(
                              S.of(dialogContext)
                                  .academicShortcutDeleteConfirmTitle,
                            ),
                            content: Text(
                              S.of(dialogContext)
                                  .academicShortcutDeleteConfirmBody,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext, false);
                                },
                                child: Text(
                                  S.of(dialogContext)
                                      .academicShortcutDeleteCancel,
                                ),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext, true);
                                },
                                child: Text(
                                  S.of(dialogContext)
                                      .academicShortcutDeleteConfirm,
                                ),
                              ),
                            ],
                          );
                        },
                      ) ??
                          false;
                    },
                    onDismissed: (_) async {
                      await AppSettings.instance.clearAcademicShortcut();

                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                            S.of(context).academicShortcutDeleteSuccess,
                          ),
                        ),
                      );
                    },
                    child: _AcademicShortcutCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _AcademicShortcutHeader(),
                          const SizedBox(height: 18),
                          if (facultyName.isNotEmpty)
                            Text(
                              facultyName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            S.of(context).academicShortcutDetails(
                              displaySpecialty,
                              displayLevel,
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _AcademicShortcutActions(
                            primaryLabel:
                            S.of(context).academicShortcutGo,
                            primaryIcon: Icons.auto_stories_rounded,
                            onPrimaryPressed: () {
                              _openAcademicShortcut(
                                context,
                                settings,
                              );
                            },
                            secondaryLabel: S.of(context).quickCalc2,
                            secondaryIcon: Icons.calculate_rounded,
                            onSecondaryPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                  const QuickAverageScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const AcademicSettingsScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.tune_rounded,
                                size: 18,
                              ),
                              label: Text(
                                S.of(context).academicShortcutEdit,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (quickFaculty != null) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الكليات',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${faculties.length}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final faculty = faculties[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _FacultyQuickCard(
                        faculty: faculty,
                        onTap: () {
                          _openFaculty(context, faculty);
                        },
                      ),
                    );
                  },
                  childCount: faculties.length,
                ),
              ),
            ),
          ] else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'لا توجد كليات متاحة حالياً',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: widget.bottomPadding + 20,
            ),
          ),
        ],
      ),
    );
  }

}



class _AcademicShortcutCard extends StatelessWidget {
  const _AcademicShortcutCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16181C) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE6E8EC),
        ),
      ),
      child: child,
    );
  }
}

class _AcademicShortcutHeader extends StatelessWidget {
  const _AcademicShortcutHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AppTeal.main;

    final colors = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: isDark ? 0.18 : 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.school_rounded, color: colors.primary, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            S.of(context).academicShortcutTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'جامعي',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark ? Colors.white70 : const Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _AcademicShortcutActions extends StatelessWidget {
  const _AcademicShortcutActions({
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimaryPressed,
    required this.secondaryLabel,
    required this.secondaryIcon,
    required this.onSecondaryPressed,
  });

  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimaryPressed;
  final String secondaryLabel;
  final IconData secondaryIcon;
  final VoidCallback onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: _AcademicShortcutButton(
            label: primaryLabel,
            icon: primaryIcon,
            onPressed: onPrimaryPressed,
            primary: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: _AcademicShortcutButton(
            label: secondaryLabel,
            icon: secondaryIcon,
            onPressed: onSecondaryPressed,
            primary: false,
          ),
        ),
      ],
    );
  }
}

class _AcademicShortcutButton extends StatelessWidget {
  const _AcademicShortcutButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.primary,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final accent = AppTeal.main;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 44,
      child: Material(
        color: primary
            ? accent
            : (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF4F6F8)),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: primary
                      ? Colors.white
                      : (isDark ? Colors.white : const Color(0xFF111827)),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primary
                          ? Colors.white
                          : (isDark ? Colors.white : const Color(0xFF111827)),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _FacultyQuickCard extends StatelessWidget {
  const _FacultyQuickCard({
    required this.faculty,
    required this.onTap,
  });

  final ProgramFaculty faculty;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final majorsCount = faculty.majors.length;

    final tracksCount = faculty.majors.fold<int>(
      0,
          (sum, major) => sum + major.tracks.length,
    );

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.apartment_outlined,
                      color: colors.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      faculty.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(
                height: 1,
                color: colors.outlineVariant.withValues(alpha: 0.35),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _FacultySimpleMetric(
                      label: S.of(context).sections,
                      value: majorsCount.toString(),
                      icon: Icons.view_list_outlined,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: colors.outlineVariant.withValues(alpha: 0.4),
                  ),
                  Expanded(
                    child: _FacultySimpleMetric(
                      label: S.of(context).majors,
                      value: tracksCount.toString(),
                      icon: Icons.track_changes_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FacultySimpleMetric extends StatelessWidget {
  const _FacultySimpleMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 18,
          color: colors.primary,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
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
      _specialtyController.text = matchedSpecialty?.name ??
          (matchedDepartment == null ? savedMajor : '');
      _levelController.text = matchedSpecialty?.level ?? savedLevel;
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
    if (query.isEmpty) return const Iterable<ProgramFaculty>.empty();
    return _faculties.where(
          (faculty) => faculty.name.toLowerCase().contains(query),
    );
  }

  Iterable<ProgramMajor> _departmentOptions(TextEditingValue textEditingValue) {
    if (_selectedFaculty == null) return const Iterable<ProgramMajor>.empty();
    final query = _normalizeQuery(textEditingValue.text).toLowerCase();
    if (query.isEmpty) return const Iterable<ProgramMajor>.empty();
    return _selectedFaculty!.majors.where(
          (major) => major.name.toLowerCase().contains(query),
    );
  }

  Iterable<ProgramTrack> _specialtyOptions(TextEditingValue textEditingValue) {
    if (_selectedDepartment == null) return const Iterable<ProgramTrack>.empty();
    final query = _normalizeQuery(textEditingValue.text).toLowerCase();
    if (query.isEmpty) return const Iterable<ProgramTrack>.empty();
    return _selectedDepartment!.tracks.where(
          (track) => track.name.toLowerCase().contains(query),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? hint,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fill = isDark ? const Color(0xFF1C1E22) : const Color(0xFFF6F7F9);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: enabled ? fill : fill.withValues(alpha: 0.55),
      prefixIcon: Icon(icon, size: 20, color: AppTeal.main),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTeal.main, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).signInRequired)),
      );
      return;
    }
    final faculty = _selectedFaculty?.name ?? '';
    final department = _selectedDepartment?.name ?? '';
    final specialty = _selectedSpecialty?.name ?? '';
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

  Widget _buildAutocompleteField<T extends Object>({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String labelText,
    required IconData icon,
    required String hint,
    required bool enabled,
    required Iterable<T> Function(TextEditingValue) optionsBuilder,
    required String Function(T) displayStringForOption,
    required ValueChanged<T> onSelected,
  }) {
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: RawAutocomplete<T>(
          textEditingController: controller,
          focusNode: focusNode,
          optionsBuilder: optionsBuilder,
          displayStringForOption: displayStringForOption,
          onSelected: onSelected,
          fieldViewBuilder:
              (context, textController, focusNode, onFieldSubmitted) {
            return TextField(
              controller: textController,
              focusNode: focusNode,
              enabled: enabled,
              textAlign: TextAlign.start,
              decoration: _fieldDecoration(
                label: labelText,
                icon: icon,
                hint: hint,
                enabled: enabled,
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Align(
              alignment: AlignmentDirectional.topStart,
              child: Material(
                elevation: 8,
                color: isDark ? const Color(0xFF1C1E22) : Colors.white,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(14),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.06),
                    ),
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        title: Text(
                          displayStringForOption(option),
                          textAlign: TextAlign.start,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
      backgroundColor:
      isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: Text(S.of(context).academicSettingsTitle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTeal.main,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'بياناتك الأكاديمية',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        S.of(context).academicSettingsDescription,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16181C) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE6E8EC),
              ),
            ),
            child: Column(
              children: [
                _buildAutocompleteField<ProgramFaculty>(
                  controller: _collegeController,
                  focusNode: _collegeFocusNode,
                  labelText: S.of(context).academicCollegeLabel,
                  icon: Icons.account_balance_rounded,
                  hint: 'ابدأ الكتابة لاختيار الكلية',
                  enabled: true,
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
                  icon: Icons.apartment_rounded,
                  hint: _selectedFaculty == null
                      ? 'اختر الكلية أولاً'
                      : 'اختر القسم',
                  enabled: _selectedFaculty != null,
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
                  icon: Icons.school_outlined,
                  hint: _selectedDepartment == null
                      ? 'اختر القسم أولاً'
                      : 'اختر التخصص',
                  enabled: _selectedDepartment != null,
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
                  readOnly: true,
                  decoration: _fieldDecoration(
                    label: S.of(context).academicLevelLabel,
                    icon: Icons.layers_rounded,
                    hint: 'يُملأ تلقائيًا',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: canSave ? _save : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppTeal.main,
                disabledBackgroundColor:
                AppTeal.main.withValues(alpha: 0.35),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                S.of(context).saveChanges,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class QuickAverageScreen extends StatefulWidget {
  const QuickAverageScreen({super.key});

  @override
  State<QuickAverageScreen> createState() => _QuickAverageScreenState();
}

class _QuickAverageScreenState extends State<QuickAverageScreen> {
  static const String _quickCalcStorageKey = 'quick_calc_state_v1';
  static const double _dismissThreshold = 0.4;
  final List<NoteData> subjects = [];
  double threshold = 10;
  double avg = 0;
  double totalcred = 0;
  bool _hasSavedState = false;

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  void _add() => setState(() {
    subjects.add(NoteData(subject: ''));
  });

  void _calc() {
    double totalWeighted = 0;
    double totalCoef = 0;
    double totalCred = 0;

    for (final s in subjects) {
      final moy = s.moy;
      totalWeighted += moy * s.coef;
      totalCoef += s.coef;
      if (moy >= 10) {
        totalCred += s.cred;
      }
    }

    setState(() {
      avg = totalCoef == 0 ? 0 : totalWeighted / totalCoef;
      totalcred = totalCred;
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'threshold': threshold,
      'avg': avg,
      'totalcred': totalcred,
      'isSucceeded': avg >= threshold,
      'subjects': subjects
          .map(
            (s) => <String, dynamic>{
          'subject': s.subject,
          'coef': s.coef,
          'cred': s.cred,
          'td': s.td,
          'exam': s.exam,
          'tp': s.tp,
          'wtd': s.Wtd,
          'wexam': s.Wexam,
          'wtp': s.Wtp,
        },
      )
          .toList(),
    };
    await prefs.setString(_quickCalcStorageKey, jsonEncode(payload));
    _hasSavedState = true;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved ✅')),
    );
  }

  Future<void> _persistStateSilently() async {
    if (!_hasSavedState) return;
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'threshold': threshold,
      'avg': avg,
      'totalcred': totalcred,
      'isSucceeded': avg >= threshold,
      'subjects': subjects
          .map(
            (s) => <String, dynamic>{
          'subject': s.subject,
          'coef': s.coef,
          'cred': s.cred,
          'td': s.td,
          'exam': s.exam,
          'tp': s.tp,
          'wtd': s.Wtd,
          'wexam': s.Wexam,
          'wtp': s.Wtp,
        },
      )
          .toList(),
    };
    await prefs.setString(_quickCalcStorageKey, jsonEncode(payload));
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_quickCalcStorageKey);
    if (raw == null || raw.isEmpty) return;
    _hasSavedState = true;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return;
    final decodedSubjects = decoded['subjects'];
    final List<NoteData> loaded = [];
    if (decodedSubjects is List) {
      for (final entry in decodedSubjects) {
        if (entry is! Map) continue;
        loaded.add(
          NoteData(
            subject: entry['subject']?.toString() ?? '',
            coef: _toInt(entry['coef'], fallback: 1),
            cred: _toInt(entry['cred'], fallback: 1),
            td: _toDouble(entry['td'], fallback: 0),
            exam: _toDouble(entry['exam'], fallback: 0),
            tp: _toDouble(entry['tp'], fallback: 0),
            Wtd: _toDouble(entry['wtd'], fallback: 0.4),
            Wexam: _toDouble(entry['wexam'], fallback: 0.6),
            Wtp: _toDouble(entry['wtp'], fallback: 0),
          ),
        );
      }
    }
    if (!mounted) return;
    setState(() {
      subjects
        ..clear()
        ..addAll(loaded);
      threshold = _toDouble(decoded['threshold'], fallback: 10);
      avg = _toDouble(decoded['avg'], fallback: 0);
      totalcred = _toDouble(decoded['totalcred'], fallback: 0);
    });
  }

  Future<void> _clearSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_quickCalcStorageKey);
    _hasSavedState = false;
    if (!mounted) return;
    setState(() {
      subjects.clear();
      avg = 0;
      totalcred = 0;
      threshold = 10;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cleared ✅')),
    );
  }

  Future<void> _removeSubjectAt(int index) async {
    final removed = subjects.removeAt(index);
    setState(() {});
    await _persistStateSilently();
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            subjects.insert(index, removed);
            setState(() {});
            await _persistStateSilently();
          },
        ),
      ),
    );
  }

  double _toDouble(dynamic value, {required double fallback}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  int _toInt(dynamic value, {required int fallback}) {
    if (value == null) return fallback;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  Color get _statusColor {
    if (avg == 0) return const Color(0xFF9CA3AF);
    return avg >= threshold ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
  }

  String get _statusText {
    if (avg == 0) return '—';
    return avg >= threshold ? 'Succeeded' : 'Failed';
  }

  Widget _calcKey({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    VoidCallback? onLongPress,
    required Color bg,
    Color fg = Colors.white,
  }) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(40),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(40),
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final passed = avg > 0 && avg >= threshold;
    final failed = avg > 0 && avg < threshold;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0D),
      appBar: AppBar(
        title: Text(S.of(context).quickCalc),
        centerTitle: true,
        backgroundColor: const Color(0xFF0B0B0D),
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    failed
                        ? 'FAILED'
                        : passed
                        ? 'SUCCEED'
                        : 'MOYENNE',
                    style: TextStyle(
                      color: failed
                          ? const Color(0xFFFF453A)
                          : passed
                          ? const Color(0xFF30D158)
                          : const Color(0xFF8E8E93),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    avg.toStringAsFixed(2),
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 64,
                      height: 1,
                      fontWeight: FontWeight.w300,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'CRED  ${totalcred.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: subjects.isEmpty
                ? const Center(
              child: Text(
                'أضف مادة',
                style: TextStyle(color: Color(0xFF8E8E93)),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: subjects.length,
              itemBuilder: (context, i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Theme(
                    data: ThemeData.dark(),
                    child: _QuickCalcDismissibleItem(
                      data: subjects[i],
                      index: i,
                      threshold: _dismissThreshold,
                      onRemove: _removeSubjectAt,
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _calcKey(
                      label: S.of(context).add,
                      icon: Icons.add,
                      onTap: _add,
                      bg: const Color(0xFF2C2C2E),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _calcKey(
                      label: S.of(context).calculate,
                      icon: Icons.calculate,
                      onTap: _calc,
                      bg: const Color(0xFFFF9F0A),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _calcKey(
                      label: S.of(context).save,
                      icon: Icons.save_outlined,
                      onTap: _saveState,
                      onLongPress: _clearSavedState,
                      bg: const Color(0xFF2C2C2E),
                    ),
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



// -------------------------
// بيانات البطاقة
// -------------------------
class NoteData {
  String subject;
  int coef;
  int cred;
  double td;
  double exam;
  double tp;
  double Wtd;
  double Wexam;
  double Wtp;

  NoteData({
    this.subject = '',
    this.coef = 1,
    this.cred = 1,
    this.td = 0,
    this.exam = 0,
    this.tp = 0,
    this.Wtd = 0.4,
    this.Wexam = 0.6,
    this.Wtp = 0,
  });

  double get moy => (td * Wtd + exam * Wexam + tp * Wtp);
}

class _QuickCalcDismissibleItem extends StatefulWidget {
  const _QuickCalcDismissibleItem({
    required this.data,
    required this.index,
    required this.threshold,
    required this.onRemove,
  });

  final NoteData data;
  final int index;
  final double threshold;
  final Future<void> Function(int index) onRemove;

  @override
  State<_QuickCalcDismissibleItem> createState() =>
      _QuickCalcDismissibleItemState();
}
class _QuickCalcDismissibleItemState extends State<_QuickCalcDismissibleItem> {
  double _progress = 0;
  bool _hapticTriggered = false;

  void _handleUpdate(DismissUpdateDetails details) {
    final progress = details.progress.clamp(0.0, 1.0);
    if (progress >= widget.threshold && !_hapticTriggered) {
      HapticFeedback.lightImpact();
      _hapticTriggered = true;
    }
    if (progress < widget.threshold && _hapticTriggered) {
      _hapticTriggered = false;
    }
    if (_progress != progress) {
      setState(() {
        _progress = progress;
      });
    }
  }

  Future<bool> _confirmDismiss() async {
    return _progress >= widget.threshold;
  }

  @override
  Widget build(BuildContext context) {
    final ambientDirection = Directionality.of(context);
    final eased = Curves.easeOut.transform(_progress);
    final backgroundColor = Color.lerp(
      Colors.red.withValues(alpha: 0.08),
      Colors.red.shade600,
      eased,
    )!;
    final iconScale = 0.9 + (0.2 * eased);

    final dismissBackground = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              backgroundColor.withValues(alpha: 0.9),
              backgroundColor,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: iconScale,
              child: const Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'حذف',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Dismissible(
        key: ValueKey(widget.data),
        direction: DismissDirection.startToEnd,
        movementDuration: const Duration(milliseconds: 220),
        resizeDuration: const Duration(milliseconds: 200),
        dismissThresholds: {DismissDirection.startToEnd: widget.threshold},
        background: dismissBackground,
        confirmDismiss: (_) => _confirmDismiss(),
        onUpdate: _handleUpdate,
        onDismissed: (_) => widget.onRemove(widget.index),
        child: Directionality(
          textDirection: ambientDirection,
          child: NoteCardWidget(
            data: widget.data,
          ),
        ),
      ),
    );
  }
}

class NoteCardWidget extends StatefulWidget {
  final NoteData data;

  const NoteCardWidget({
    super.key,
    required this.data,
  });

  @override
  State<NoteCardWidget> createState() => _NoteCardWidgetState();
}
class _NoteCardWidgetState extends State<NoteCardWidget> {
  late TextEditingController nameController;
  late TextEditingController coefController;
  late TextEditingController credController;
  late TextEditingController tdController;
  late TextEditingController tpController;
  late TextEditingController WtdController;
  late TextEditingController WtpController;
  late TextEditingController WexamController;
  late TextEditingController examController;

  bool expanded = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.data.subject);
    coefController = TextEditingController(text: widget.data.coef.toString());
    credController = TextEditingController(text: widget.data.cred.toString());
    tdController = TextEditingController(
        text: widget.data.td == 0 ? '' : widget.data.td.toString());
    examController = TextEditingController(
        text: widget.data.exam == 0 ? '' : widget.data.exam.toString());
    tpController = TextEditingController(
        text: widget.data.tp == 0 ? '' : widget.data.tp.toString());
    WexamController = TextEditingController(text: widget.data.Wexam.toString());
    WtdController = TextEditingController(text: widget.data.Wtd.toString());
    WtpController = TextEditingController(text: widget.data.Wtp.toString());
  }

  @override
  void dispose() {
    nameController.dispose();
    coefController.dispose();
    credController.dispose();
    tdController.dispose();
    tpController.dispose();
    WtdController.dispose();
    WtpController.dispose();
    WexamController.dispose();
    examController.dispose();
    super.dispose();
  }

  Color get _moyColor {
    final m = widget.data.moy;
    if (m <= 0) return const Color(0xFF8E8E93);
    return m >= 10 ? const Color(0xFF30D158) : const Color(0xFFFF453A);
  }

  Widget _keyPad({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textAlign: TextAlign.center,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      maxLength: maxLength,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF8E8E93),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        counterText: '',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF9F0A), width: 1.3),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: nameController,
                  onChanged: (v) {
                    widget.data.subject = v;
                    setState(() {});
                  },
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'المادة',
                    hintStyle: TextStyle(
                      color: Color(0xFF636366),
                      fontWeight: FontWeight.w600,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Text(
                widget.data.moy.toStringAsFixed(2),
                style: TextStyle(
                  color: _moyColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => expanded = !expanded),
                icon: Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
          if (expanded) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _keyPad(
                    label: 'COEF',
                    controller: coefController,
                    maxLength: 1,
                    onChanged: (v) {
                      widget.data.coef = int.tryParse(v) ?? 1;
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _keyPad(
                    label: 'CRED',
                    controller: credController,
                    maxLength: 1,
                    onChanged: (v) {
                      widget.data.cred = int.tryParse(v) ?? 1;
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _keyPad(
                    label: 'TD',
                    controller: tdController,
                    onChanged: (v) {
                      widget.data.td = double.tryParse(v) ?? 0;
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _keyPad(
                    label: 'TP',
                    controller: tpController,
                    onChanged: (v) {
                      widget.data.tp = double.tryParse(v) ?? 0;
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _keyPad(
                    label: 'EXAM',
                    controller: examController,
                    onChanged: (v) {
                      widget.data.exam = double.tryParse(v) ?? 0;
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _keyPad(
                    label: 'W.TD',
                    controller: WtdController,
                    onChanged: (v) {
                      widget.data.Wtd = double.tryParse(v) ?? 0;
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _keyPad(
                    label: 'W.TP',
                    controller: WtpController,
                    onChanged: (v) {
                      widget.data.Wtp = double.tryParse(v) ?? 0;
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _keyPad(
                    label: 'W.EX',
                    controller: WexamController,
                    onChanged: (v) {
                      widget.data.Wexam = double.tryParse(v) ?? 0;
                      setState(() {});
                    },
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

// ===================== GPA Table Data Model (public) ========================
class EvalWeight {
  final String label;
  final double weight;
  const EvalWeight({required this.label, required this.weight});
}

class ModuleSpec {
  final String id;
  final String name;
  final double coef;
  final double credits;
  final List<EvalWeight> evalWeights;
  final String unitLabel;

  const ModuleSpec({
    required this.id,
    required this.name,
    required this.coef,
    required this.credits,
    required this.evalWeights,
    this.unitLabel = '',
  });

  double get totalWeight =>
      evalWeights.fold<double>(0, (sum, item) => sum + item.weight);
}

class SemesterSpec {
  final String name;
  final List<ModuleSpec> modules;
  const SemesterSpec({required this.name, required this.modules});
}

List<SemesterSpec> createSemesterSpecsForTrack(ProgramTrack track) {
  return track.semesters.asMap().entries.map((semEntry) {
    final semIndex = semEntry.key;
    final sem = semEntry.value;
    final modules = <ModuleSpec>[];
    var moduleIndex = 0;

    for (final unit in sem.unit) {
      for (final module in unit.modules) {
        modules.add(
          ModuleSpec(
            id: 'sem${semIndex + 1}-module${moduleIndex + 1}',
            name: module.name,
            coef: module.coef.toDouble(),
            credits: module.credits.toDouble(),
            evalWeights: _normalizeEvalWeights(module.components),
            unitLabel: unit.label,
          ),
        );
        moduleIndex++;
      }
    }

    return SemesterSpec(name: sem.label, modules: modules);
  }).toList(growable: false);
}
List<SemesterSpec> demoL1GpaSpecs(BuildContext context) {
  final track = getDemoFaculties(context).first.majors.first.tracks.first;

  return createSemesterSpecsForTrack(track);
}

List<EvalWeight> _normalizeEvalWeights(List<ProgramComponent> components) {
  final Map<String, double> weights = {
    'TD': 0,
    'TP': 0,
    'EXAM': 0,
  };
  for (final c in components) {
    final key = c.label.toUpperCase();
    if (weights.containsKey(key)) {
      weights[key] = c.weight;
    }
  }
  return [
    EvalWeight(label: 'TD', weight: weights['TD']!),
    EvalWeight(label: 'TP', weight: weights['TP']!),
    EvalWeight(label: 'EXAM', weight: weights['EXAM']!),
  ];
}

String _slugifyModuleId(String value) {
  final slug = value
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (slug.isNotEmpty) {
    return slug;
  }
  final encoded = base64UrlEncode(utf8.encode(value));
  return encoded.replaceAll('=', '');
}

String _moduleIdForSemester(String semester, String moduleName) {
  final normalizedSemester = semester.trim().toUpperCase();
  final normalizedModule = moduleName.trim();
  return _slugifyModuleId('$normalizedSemester-$normalizedModule');
}

String buildAcademicStorageSignature({
  required SemesterSpec semester1,
  required SemesterSpec semester2,
  required String level,
}) {
  String moduleFingerprint(ModuleSpec module) {
    final weights = module.evalWeights
        .map((weight) => '${weight.label.toUpperCase()}:${weight.weight}')
        .join('|');
    return '${module.name.trim()}#${module.coef}#${module.credits}#$weights';
  }

  String semesterFingerprint(SemesterSpec semester) {
    final modules = semester.modules
        .map(moduleFingerprint)
        .join('||');
    return '${semester.name.trim().toUpperCase()}::${modules}';
  }

  final raw = [
    level.trim().toUpperCase(),
    semesterFingerprint(semester1),
    semesterFingerprint(semester2),
  ].join('###');

  return base64UrlEncode(utf8.encode(raw)).replaceAll('=', '');
}

class ModuleModel {
  ModuleModel({
    required this.id,
    required this.title,
    this.unitLabel = '',
    required num coef,
    required num credits,
    required double tdWeight,
    required double tpWeight,
    required double examWeight,
  })  : coef = coef.toDouble(),
        credits = credits.toDouble(),
        _hasTD = tdWeight > 0,
        _hasTP = tpWeight > 0,
        wTD = tdWeight / 100,
        wTP = tpWeight / 100,
        wEX = examWeight / 100,
        td = 0,
        tp = 0,
        exam = 0;

  final String id;
  final String title;
  final String unitLabel;
  double coef;
  double credits;
  final bool _hasTD;
  final bool _hasTP;
  double wTD;
  double wTP;
  double wEX;
  double? td;
  double? tp;
  double? exam;
  double? tdWeight = 0.4;
  double? tpWeight = 0;
  double? examWeight = 0.6;

  bool get hasTD => _hasTD;
  bool get hasTP => _hasTP;

  double get moy {
    final totalW = wTD + wTP + wEX; // مجموع الأوزان
    if (totalW <= 0) return 0;

    double normalize(double weight) => weight / totalW;

    final value = (td ?? 0) * normalize(wTD) +
        (tp ?? 0) * normalize(wTP) +
        (exam ?? 0) * normalize(wEX);

    return double.parse(value.toStringAsFixed(2));
  }
}

class SemesterModel {
  SemesterModel({
    required this.name,
    required this.modules,
    required VoidCallback onChanged,
  }) : _onChanged = onChanged;

  factory SemesterModel.fromSpec(
      SemesterSpec spec, {
        required VoidCallback onChanged,
      }) {
    final modules = spec.modules.map((module) {
      double weightFor(String label) {
        return module.evalWeights
            .firstWhere(
              (w) => w.label.toUpperCase() == label,
          orElse: () => const EvalWeight(label: 'TMP', weight: 0),
        )
            .weight;
      }

      return ModuleModel(
        id: module.id.trim().isNotEmpty
            ? module.id
            : _moduleIdForSemester(spec.name, module.name),
        title: module.name,
        unitLabel: module.unitLabel,
        coef: module.coef,
        credits: module.credits,
        tdWeight: weightFor('TD'),
        tpWeight: weightFor('TP'),
        examWeight: weightFor('EXAM'),
      );
    }).toList(growable: false);

    return SemesterModel(
        name: spec.name, modules: modules, onChanged: onChanged);
  }

  final String name;
  final List<ModuleModel> modules;
  final VoidCallback _onChanged;

  void recompute() => _onChanged();

  double moduleAverage(ModuleModel module) {
    return module.moy;
  }

  double moduleCreditsEarned(ModuleModel module) {
    final avg = moduleAverage(module);
    return avg >= 10 ? module.credits : 0;
  }

  double semesterAverage() {
    double weighted = 0;
    double coefs = 0;
    for (final module in modules) {
      weighted += moduleAverage(module) * module.coef;
      coefs += module.coef;
    }
    if (coefs == 0) {
      return 0;
    }
    final value = weighted / coefs;
    return double.parse(value.toStringAsFixed(2));
  }

  double creditsEarned() {
    if (semesterAverage() >= 10) {
      return modules.fold<double>(0, (sum, module) => sum + module.credits);
    }
    return modules.fold<double>(
        0, (sum, module) => sum + moduleCreditsEarned(module));
  }

  SemesterModel convertProgramSemester(
      ProgramSemester ps,
      VoidCallback onChanged,
      ) {
    final allModules =
    ps.unit.expand((u) => u.modules).toList(growable: false);
    return SemesterModel(
      name: ps.label,
      onChanged: onChanged,
      modules: allModules.asMap().entries.map((entry) {
        final moduleIndex = entry.key;
        final m = entry.value;
        // تحويل ProgramComponent إلى أوزان TD/TP/EXAM
        double td = 0;
        double tp = 0;
        double exam = 0;

        for (var c in m.components) {
          if (c.label.toUpperCase() == 'TD') td = c.weight.toDouble();
          if (c.label.toUpperCase() == 'TP') tp = c.weight.toDouble();
          if (c.label.toUpperCase() == 'EXAM') exam = c.weight.toDouble();
        }

        return ModuleModel(
          id: 'sem${ps.label.trim().toUpperCase()}-module${moduleIndex + 1}',
          title: m.name,
          coef: m.coef,
          credits: m.credits,
          tdWeight: td,
          tpWeight: tp,
          examWeight: exam,
        );
      }).toList(),
    );
  }
}

// ---------- Table helpers ----------
class DecimalSanitizer extends TextInputFormatter {
  DecimalSanitizer({this.decimalPlaces = 2});

  final int decimalPlaces;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final sanitized = newValue.text.replaceAll(',', '.');
    final pattern = decimalPlaces > 0
        ? RegExp(r'^\d*([.]\d{0,' + decimalPlaces.toString() + r'})?$')
        : RegExp(r'^\d*$');
    if (sanitized.isEmpty || pattern.hasMatch(sanitized)) {
      return newValue.copyWith(text: sanitized);
    }
    return oldValue;
  }
}

class _NumField extends StatelessWidget {
  const _NumField({
    required this.value,
    required this.onChanged,
    this.width = 64,
    this.decimalPlaces = 2,
    this.inputRangePattern,
  });

  final double? value;
  final ValueChanged<double?> onChanged;
  final double width;
  final int decimalPlaces;
  final RegExp? inputRangePattern;

  @override
  Widget build(BuildContext context) {
    final initial = value == null ? '' : value!.toStringAsFixed(decimalPlaces);
    return SizedBox(
      width: width,
      child: TextFormField(
        textAlign: TextAlign.center,
        initialValue: initial,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        ),
        inputFormatters: [
          DecimalSanitizer(decimalPlaces: decimalPlaces),
          if (inputRangePattern != null)
            FilteringTextInputFormatter.allow(inputRangePattern!),
        ],
        onChanged: (s) {
          final sanitized = s.replaceAll(',', '.');
          if (sanitized.isEmpty) {
            onChanged(null);
            return;
          }
          final parsed = double.tryParse(sanitized);
          if (parsed == null) {
            return;
          }
          onChanged(parsed);
        },
      ),
    );
  }
}

// Compact text widget that never wraps:
Widget _cell(String s, {bool bold = false, bool center = false}) => Text(
  s,
  maxLines: 1,
  softWrap: false,
  overflow: TextOverflow.ellipsis,
  textAlign: center ? TextAlign.center : TextAlign.start,
  style: TextStyle(fontWeight: bold ? FontWeight.w600 : FontWeight.w400),
);
// -----------------------------------


// ================================ UI: Faculties ==============================
class FacultiesScreen extends StatelessWidget {
  final List<ProgramFaculty> faculties;
  const FacultiesScreen({super.key, required this.faculties});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return AppScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(S.of(context).faculties),
      ),
      padding: EdgeInsets.zero,
      body: ListView.separated(
        itemCount: faculties.length,
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) {
          final f = faculties[i];
          final theme = Theme.of(context);
          final majorsCount = f.majors.length;
          final subtitleText = majorsCount == 0
              ? S.of(context).noMajorsYet
              : majorsCount == 1
              ? S.of(context).oneMajor
              : '$majorsCount تخصصات';
          return Card(
            margin: EdgeInsets.zero,
            color: theme.colorScheme.surfaceVariant
                .withValues(alpha: theme.brightness == Brightness.dark ? .35 : .6),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => FacultyMajorsScreen(faculty: f)),
                );
              },
              child: ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: .12),
                  foregroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.apartment_rounded),
                ),
                title: Text(f.name),
                subtitle: Text(
                  subtitleText,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                trailing: Icon(Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================== UI: Majors =================================

class FacultyMajorsScreen extends StatelessWidget {
  final ProgramFaculty faculty;

  const FacultyMajorsScreen({
    super.key,
    required this.faculty,
  });

  static final Color _primaryColor = AppTeal.main;
  static const Color _blueColor = Color(0xFF1565C0);
  static const Color _lightBackgroundColor = Color(0xFFEAF7F8);

  static const _accents = <Color>[
    Color(0xFF0D9488),
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFFE11D48),
    Color(0xFFEA580C),
    Color(0xFF0891B2),
    Color(0xFF16A34A),
    Color(0xFFDB2777),
    Color(0xFF4F46E5),
    Color(0xFFCA8A04),
    Color(0xFF0E7490),
    Color(0xFF9333EA),
    Color(0xFF65A30D),
    Color(0xFFBE123C),
    Color(0xFF0284C7),
    Color(0xFFB45309),
  ];



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final majors = faculty.majors;
    final tracksTotal = majors.fold<int>(0, (n, m) => n + m.tracks.length);

    return AppScaffold(
      padding: EdgeInsets.zero,
      appBar: AppBar(
        title: Text(faculty.name),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _FacultySummary(
            facultyName: faculty.name,
            totalMajors: majors.length,
            totalTracks: tracksTotal,
          ),
          const SizedBox(height: 18),
          if (majors.isEmpty)
            const _EmptyMajorsState()
          else
            ...List.generate(majors.length, (index) {
              final major = majors[index];
              final accent = _accents[index % _accents.length];
              final tracksCount = major.tracks.length;
              final subtitle = tracksCount == 0
                  ? 'لا توجد مسارات'
                  : tracksCount == 1
                  ? 'مسار واحد'
                  : '$tracksCount مسارات';

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == majors.length - 1 ? 0 : 10,
                ),
                child: Material(
                  color: isDark ? const Color(0xFF1C1C1F) : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.22),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MajorTracksScreen(
                            major: major,
                            faculty: faculty,
                          ),
                        ),
                      );
                    },
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Container(width: 4, color: accent),
                          Expanded(
                            child: Padding(
                              padding:
                              const EdgeInsets.fromLTRB(12, 14, 12, 14),
                              child: Row(
                                children: [
                                  // Container(
                                  //   width: 48,
                                  //   height: 48,
                                  //   alignment: Alignment.center,
                                  //   decoration: BoxDecoration(
                                  //     border: Border.all(color:Theme.of(context).colorScheme.onSurface ),
                                  //     borderRadius: BorderRadius.circular(14),
                                  //   ),
                                  //   child: Text(
                                  //     '${index + 1}'.padLeft(2, '0'),
                                  //     style: theme.textTheme.titleSmall
                                  //         ?.copyWith(
                                  //       color: accent,
                                  //       fontWeight: FontWeight.w900,
                                  //     ),
                                  //   ),
                                  // ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          major.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            height: 1.25,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            _MajorChip(
                                              label: subtitle,
                                              accent: accent,
                                              isDark: isDark,
                                            ),
                                            _MajorChip(
                                              label: 'عرض المسارات',
                                              accent: theme.colorScheme
                                                  .onSurfaceVariant,
                                              isDark: isDark,
                                              outlined: true,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.chevron_left_rounded,
                                      size: 18,
                                      color: accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _FacultySummary extends StatelessWidget {
  const _FacultySummary({
    required this.facultyName,
    required this.totalMajors,
    required this.totalTracks,
  });

  final String facultyName;
  final int totalMajors;
  final int totalTracks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = AppTeal.main;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: isDark
              ? [
            accent.withValues(alpha: 0.22),
            const Color(0xFF1C1C1F),
          ]
              : [
            accent.withValues(alpha: 0.16),
            const Color(0xFFEAF7F8),
            Colors.white,
          ],
        ),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.28 : 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      facultyName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'التخصصات الأكاديمية المتاحة',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  value: '$totalMajors',
                  label: 'تخصص',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryStat(
                  value: '$totalTracks',
                  label: 'مسار',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTeal.main,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MajorChip extends StatelessWidget {
  const _MajorChip({
    required this.label,
    required this.accent,
    required this.isDark,
    this.outlined = false,
  });

  final String label;
  final Color accent;
  final bool isDark;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: outlined
            ? Colors.transparent
            : accent.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(20),
        border: outlined
            ? Border.all(color: accent.withValues(alpha: 0.35))
            : null,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyMajorsState extends StatelessWidget {
  const _EmptyMajorsState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Icon(
            Icons.school_outlined,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'لا توجد أقسام متاحة حاليًا',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================== UI: Tracks =================================
class MajorTracksScreen extends StatelessWidget {
  final ProgramMajor major;
  final ProgramFaculty faculty;

  const MajorTracksScreen({
    super.key,
    required this.major,
    required this.faculty,
  });

  static final Color _primaryColor = AppTeal.main;
  static const Color _blueColor = Color(0xFF2563EB);
  static const Color _lightBackgroundColor = Color(0xFFEAF7F8);

  static const _accents = <Color>[
    Color(0xFF0D9488),
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFFE11D48),
    Color(0xFFEA580C),
    Color(0xFF0891B2),
    Color(0xFF16A34A),
    Color(0xFFDB2777),
    Color(0xFF4F46E5),
    Color(0xFFCA8A04),
    Color(0xFF0E7490),
    Color(0xFF9333EA),
    Color(0xFF65A30D),
    Color(0xFFBE123C),
    Color(0xFF0284C7),
    Color(0xFFB45309),
  ];

  @override
  Widget build(BuildContext context) {
    final Map<String, List<ProgramTrack>> tracksByLevel = {};
    for (final track in major.tracks) {
      tracksByLevel.putIfAbsent(track.level, () => []).add(track);
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final levels = tracksByLevel.entries.toList();

    return AppScaffold(
      padding: EdgeInsets.zero,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(major.name),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _TrackSummary(
            majorName: major.name,
            facultyName: faculty.name,
            totalTracks: major.tracks.length,
            totalLevels: levels.length,
          ),
          const SizedBox(height: 18),
          if (levels.isEmpty)
            const _EmptyTracksState()
          else
            ...List.generate(levels.length, (sectionIndex) {
              final entry = levels[sectionIndex];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: sectionIndex == levels.length - 1 ? 0 : 22,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TrackLevelHeader(
                      level: entry.key,
                      count: entry.value.length,
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(entry.value.length, (index) {
                      final track = entry.value[index];
                      final globalIndex = levels
                          .take(sectionIndex)
                          .fold<int>(0, (n, e) => n + e.value.length) +
                          index;
                      final accent =
                      _accents[globalIndex % _accents.length];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == entry.value.length - 1 ? 0 : 10,
                        ),
                        child: _TrackSpecialtyCard(
                          track: track,
                          major: major,
                          faculty: faculty,
                          index: index,
                          accent: accent,
                          isDark: isDark,
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _TrackSummary extends StatelessWidget {
  const _TrackSummary({
    required this.majorName,
    required this.facultyName,
    required this.totalTracks,
    required this.totalLevels,
  });

  final String majorName;
  final String facultyName;
  final int totalTracks;
  final int totalLevels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = AppTeal.main;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: isDark
              ? [
            accent.withValues(alpha: 0.22),
            const Color(0xFF1C1C1F),
          ]
              : [
            accent.withValues(alpha: 0.16),
            const Color(0xFFEAF7F8),
            Colors.white,
          ],
        ),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.28 : 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      majorName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      facultyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TrackSummaryStat(
                  value: '$totalTracks',
                  label: 'مسار',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TrackSummaryStat(
                  value: '$totalLevels',
                  label: 'مستوى',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackSummaryStat extends StatelessWidget {
  const _TrackSummaryStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTeal.main,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackLevelHeader extends StatelessWidget {
  const _TrackLevelHeader({
    required this.level,
    required this.count,
  });

  final String level;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppTeal.main;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          level,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.labelSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrackSpecialtyCard extends StatelessWidget {
  const _TrackSpecialtyCard({
    required this.track,
    required this.major,
    required this.faculty,
    required this.index,
    required this.accent,
    required this.isDark,
  });

  final ProgramTrack track;
  final ProgramMajor major;
  final ProgramFaculty faculty;
  final int index;
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isDark ? const Color(0xFF1C1C1F) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.22),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          final specs = createSemesterSpecsForTrack(track);
          final sem1 = _pickSemester(specs, 'S1');
          final sem2 = _pickSemester(specs, 'S2');

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudiesTableScreen(
                facultyName: track.name,
                programName: '${major.name} • ${track.name}',
                collegeId: faculty.name,
                departmentId: major.name,
                specialtyId: track.name,
                level: track.level,
                academicScopeId: buildAcademicStorageSignature(
                  semester1: sem1,
                  semester2: sem2,
                  level: track.level,
                ),
                semester1Modules: sem1,
                semester2Modules: sem2,
              ),
            ),
          );
        },
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 4, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                  child: Row(
                    children: [
                      // Container(
                      //   width: 48,
                      //   height: 48,
                      //   alignment: Alignment.center,
                      //   decoration: BoxDecoration(
                      //     color: accent.withValues(alpha: 0.14),
                      //     borderRadius: BorderRadius.circular(14),
                      //   ),
                      //   child: Text(
                      //     '${index + 1}'.padLeft(2, '0'),
                      //     style: theme.textTheme.titleSmall?.copyWith(
                      //       color: accent,
                      //       fontWeight: FontWeight.w900,
                      //     ),
                      //   ),
                      // ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              track.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(
                                    alpha: isDark ? 0.18 : 0.10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                track.level,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          size: 18,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTracksState extends StatelessWidget {
  const _EmptyTracksState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'لا توجد مسارات متاحة حاليًا',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ========================== UI: Studies GPA Table ============================
class StudiesTableScreen extends StatefulWidget {
  final String facultyName;
  final String programName;
  final String collegeId;
  final String departmentId;
  final String specialtyId;
  final String level;
  final String academicScopeId;
  final SemesterSpec semester1Modules;
  final SemesterSpec semester2Modules;

  const StudiesTableScreen({
    super.key,
    required this.facultyName,
    required this.programName,
    required this.collegeId,
    required this.departmentId,
    required this.specialtyId,
    required this.level,
    required this.academicScopeId,
    required this.semester1Modules,
    required this.semester2Modules,
  });

  @override
  State<StudiesTableScreen> createState() => _StudiesTableScreenState();
}
class _StudiesTableScreenState extends State<StudiesTableScreen> {
  late final PageController _pageController;
  int _settledPage = 0;
  late SemesterModel _semester1;
  late SemesterModel _semester2;
  late GradesLocalStore _gradesStore;
  final Set<String> _loadedModuleStates = {};

  @override
  void initState() {
    super.initState();
    _initializeGradesStore();
    _pageController = PageController();
    _pageController.addListener(_onPageScroll);
    _initSemesters();
    Future.microtask(loadSemesterNotes);
  }

  void _onPageScroll() {
    final page = _pageController.page;
    if (page == null) return;
    if ((page - page.round()).abs() > 0.001) return;
    final i = page.round();
    if (i == _settledPage) return;
    _settledPage = i;
    loadSemesterNotes();
  }

  int get _semesterIndex => _pageController.hasClients
      ? (_pageController.page?.round() ?? _settledPage)
      : _settledPage;

  void _initializeGradesStore() {
    _gradesStore = GradesLocalStore(
      scope: GradesStorageScope(
        collegeId: widget.collegeId,
        departmentId: widget.departmentId,
        specialtyId: widget.specialtyId,
        level: widget.level,
        academicScopeId: widget.academicScopeId,
      ),
    );
  }

  void _initSemesters() {
    _semester1 = SemesterModel.fromSpec(
      widget.semester1Modules,
      onChanged: () => setState(() {}),
    );
    _semester2 = SemesterModel.fromSpec(
      widget.semester2Modules,
      onChanged: () => setState(() {}),
    );
  }

  Future<void> saveCurrentSemesterNotes() async {
    debugPrint('SAVE_CLICKED');
    FocusScope.of(context).unfocus();

    final currentSemester =
    _semesterIndex == 0 ? _semester1 : _semester2;
    final semesterKey = currentSemester.name.trim().toUpperCase();
    for (final module in currentSemester.modules) {
      debugPrint(
        'SAVE_PAYLOAD semesterKey=$semesterKey moduleId=${module.id} '
            'cred=${module.credits} coef=${module.coef} td=${module.td} '
            'exam=${module.exam} tp=${module.tp} '
            'wTd=${module.wTD} wExam=${module.wEX} wTp=${module.wTP}',
      );
    }
    try {
      await _gradesStore.saveModuleStates(
        semesterKey,
        currentSemester.modules,
      );
      final readBack = await _gradesStore.loadModuleStates(semesterKey);
      debugPrint(
        'SAVE_READBACK semesterKey=$semesterKey data=${jsonEncode(readBack)}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved')),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('SAVE_ERROR semesterKey=$semesterKey error=$error');
      debugPrint('SAVE_STACK $stackTrace');
    }
  }

  Future<void> loadSemesterNotes() async {
    final currentSemester =
    _semesterIndex == 0 ? _semester1 : _semester2;
    final semesterKey = currentSemester.name.trim().toUpperCase();
    debugPrint('LOAD_START semesterKey=$semesterKey');
    final overrides = await _gradesStore.loadModuleStates(semesterKey);
    debugPrint(
      'LOAD_OVERRIDES semesterKey=$semesterKey data=${jsonEncode(overrides)}',
    );

    var updated = false;
    if (!_loadedModuleStates.contains(semesterKey)) {
      for (final module in currentSemester.modules) {
        final moduleOverride = overrides[module.id];
        if (moduleOverride == null) continue;
        module.coef = moduleOverride['coef']?.toDouble() ?? module.coef;
        module.credits = moduleOverride['cred']?.toDouble() ?? module.credits;
        module.td = moduleOverride['td'] ?? module.td;
        module.tp = moduleOverride['tp'] ?? module.tp;
        module.exam = moduleOverride['exam'] ?? module.exam;
        module.wTD = moduleOverride['wTD'] ?? module.wTD;
        module.wEX = moduleOverride['wEX'] ?? module.wEX;
        module.wTP = moduleOverride['wTP'] ?? module.wTP;
        updated = true;
      }
      _loadedModuleStates.add(semesterKey);
    }

    if (mounted && updated) setState(() {});
  }

  @override
  void didUpdateWidget(covariant StudiesTableScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final trackChanged = oldWidget.collegeId != widget.collegeId ||
        oldWidget.departmentId != widget.departmentId ||
        oldWidget.specialtyId != widget.specialtyId ||
        oldWidget.level != widget.level;
    final modulesChanged =
        oldWidget.semester1Modules != widget.semester1Modules ||
            oldWidget.semester2Modules != widget.semester2Modules;
    if (trackChanged || modulesChanged) {
      if (trackChanged) _initializeGradesStore();
      _initSemesters();
      _loadedModuleStates.clear();
      Future.microtask(loadSemesterNotes);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    super.dispose();
  }



  Widget _cinematicPage({
    required int index,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        final page =
        _pageController.hasClients ? (_pageController.page ?? 0) : 0.0;
        final delta = page - index;
        final t = (1 - delta.abs()).clamp(0.0, 1.0);
        return Opacity(
          opacity: 0.35 + (0.65 * t),
          child: Transform.translate(
            offset: Offset(delta * 56, (1 - t) * 18),
            child: Transform.scale(
              scale: 0.94 + (0.06 * t),
              child: child,
            ),
          ),
        );
      },
      child: RepaintBoundary(child: child),
    );
  }

  Future<void> _goToSemester(int index) {
    return _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  Widget _buildSemesterTabContent(
      SemesterModel semester, {
        required bool showS1,
        required bool showS2,
        required bool showAnnual,
      }) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        buildSemesterTable(context, semester),
        const SizedBox(height: 8),
        _AnnualSummaryCard(
          semester1: _semester1,
          semester2: _semester2,
          showS1: showS1,
          showS2: showS2,
          showAnnual: showAnnual,
        ),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    final accent = AppTeal.main;

    return AppScaffold(
      padding: EdgeInsets.zero,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.facultyName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'حفظ',
            onPressed: saveCurrentSemesterNotes,
            icon: const Icon(Icons.save_outlined),
          ),
          IconButton(
            tooltip: 'كشف النقاط',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ResultsScreen(
                    semester1: _semester1,
                    semester2: _semester2,
                    programLabel: widget.programName,
                    facultyName: widget.collegeId,
                    level: widget.level,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: AnimatedBuilder(
              animation: _pageController,
              builder: (context, _) {
                final page = _pageController.hasClients
                    ? (_pageController.page ?? 0)
                    : 0.0;
                return _CinemaSemesterSwitch(
                  page: page,
                  accent: accent,
                  onSelect: _goToSemester,
                );
              },
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              children: [
                _cinematicPage(
                  index: 0,
                  child: _KeepAlive(
                    child: _buildSemesterTabContent(
                      _semester1,
                      showS1: true,
                      showS2: false,
                      showAnnual: false,
                    ),
                  ),
                ),
                _cinematicPage(
                  index: 1,
                  child: _KeepAlive(
                    child: _buildSemesterTabContent(
                      _semester2,
                      showS1: false,
                      showS2: true,
                      showAnnual: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CinemaSemesterSwitch extends StatelessWidget {
  const _CinemaSemesterSwitch({
    required this.page,
    required this.accent,
    required this.onSelect,
  });

  final double page;
  final Color accent;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 44,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.lerp(
              AlignmentDirectional.centerStart,
              AlignmentDirectional.centerEnd,
              page.clamp(0.0, 1.0),
            )!,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1F) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.28),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              _cell(theme, 'الفصل 1', () => onSelect(0)),
              _cell(theme, 'الفصل 2', () => onSelect(1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cell(ThemeData theme, String title, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}



class _KeepAlive extends StatefulWidget {
  final Widget child;

  const _KeepAlive({required this.child});

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}
class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // مهم لمنع ضياع الحالة
    return widget.child;
  }
}






class GradesStorageScope {
  const GradesStorageScope({
    required this.collegeId,
    required this.departmentId,
    required this.specialtyId,
    required this.level,
    required this.academicScopeId,
  });

  final String collegeId;
  final String departmentId;
  final String specialtyId;
  final String level;
  final String academicScopeId;

  String _sanitize(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return '';
    // Keep non-latin identifiers stable (e.g. Arabic) to avoid collisions
    // across tracks that would otherwise be reduced to empty/unknown values.
    return Uri.encodeComponent(normalized);
  }

  String get storageKey {
    final scope = _sanitize(academicScopeId);
    if (scope.isNotEmpty) {
      return 'scope__$scope';
    }

    // Fallback for safety in case the new scope id is missing unexpectedly.
    final lvl = _sanitize(level);
    return [
      'scope__legacy',
      if (lvl.isNotEmpty) lvl else 'unknown_level',
    ].join('__');
  }
}

class GradesLocalStore {
  static const bool _debugGradeStorageKeys = false;
  static const String _globalStorageKey = 'unispace_grades_v1';
  static const String _modulesStoragePrefix = 'modules_';
  static const String _scopedStoragePrefix = 'unispace_grades_v2_';

  GradesLocalStore({required this.scope});

  final GradesStorageScope scope;

  String get _storageKey => '$_scopedStoragePrefix${scope.storageKey}';

  String _normalizeSemesterKey(String semester) {
    return semester.trim().toUpperCase();
  }

  String _entryKey(String semester, String moduleId) {
    final normalizedSemester = _normalizeSemesterKey(semester);
    return '$normalizedSemester|$moduleId';
  }

  String _legacyModulesKey(String semester) {
    final normalizedSemester = _normalizeSemesterKey(semester).toLowerCase();
    return '$_modulesStoragePrefix$normalizedSemester';
  }

  String _modulesKey(String semester) {
    final normalizedSemester = _normalizeSemesterKey(semester).toLowerCase();
    return '$_modulesStoragePrefix${scope.storageKey}_$normalizedSemester';
  }

  Future<Map<String, dynamic>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (_debugGradeStorageKeys) {
      debugPrint('GRADES_LOAD_ALL key=$_storageKey');
    }
    if (raw == null || raw.isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> _loadLegacyGlobalAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_globalStorageKey);
    if (raw == null || raw.isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{};
  }

  Future<void> _saveAll(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    if (_debugGradeStorageKeys) {
      debugPrint('GRADES_SAVE_ALL key=$_storageKey entries=${data.length}');
    }
    try {
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (error, stackTrace) {
      debugPrint('SAVE_ALL_ERROR error=$error');
      debugPrint('SAVE_ALL_STACK $stackTrace');
      rethrow;
    }
  }


  Future<void> _migrateLegacyGradeEntryIfNeeded(
      String semester,
      String moduleId,
      ) async {
    final scoped = await _loadAll();
    final key = _entryKey(semester, moduleId);
    if (scoped.containsKey(key)) {
      return;
    }
    final legacy = await _loadLegacyGlobalAll();
    final legacyEntry = legacy[key];
    if (legacyEntry == null) {
      return;
    }
    scoped[key] = legacyEntry;
    await _saveAll(scoped);
  }

  Future<void> _migrateLegacyModulesIfNeeded(String semester) async {
    final prefs = await SharedPreferences.getInstance();
    final scopedKey = _modulesKey(semester);
    final scopedRaw = prefs.getString(scopedKey);
    if (scopedRaw != null && scopedRaw.isNotEmpty) {
      return;
    }

    final legacyKey = _legacyModulesKey(semester);
    final legacyRaw = prefs.getString(legacyKey);
    if (legacyRaw != null && legacyRaw.isNotEmpty) {
      await prefs.setString(scopedKey, legacyRaw);
      return;
    }

    final legacyGlobal = await _loadLegacyGlobalAll();
    final normalizedSemester = _normalizeSemesterKey(semester);
    final migratedPayload = <Map<String, dynamic>>[];
    for (final entry in legacyGlobal.entries) {
      final key = entry.key;
      if (!key.startsWith('$normalizedSemester|')) continue;
      final data = entry.value;
      if (data is! Map) continue;
      final moduleId = key.substring('$normalizedSemester|'.length);
      if (moduleId.isEmpty) continue;
      migratedPayload.add({
        'moduleId': moduleId,
        'moduleName': null,
        'semester': semester,
        'coef': data['coef'],
        'cred': data['cred'],
        'td': data['td'],
        'tp': data['tp'],
        'exam': data['exam'],
        'moy': data['moy'],
        'wTD': data['wTD'],
        'wEX': data['wEX'],
        'wTP': data['wTP'],
      });
    }
    if (migratedPayload.isNotEmpty) {
      await prefs.setString(scopedKey, jsonEncode(migratedPayload));
    }
  }

  Future<Map<String, double?>?> loadGrade(
      String semester,
      String moduleId,
      ) async {
    await _migrateLegacyGradeEntryIfNeeded(semester, moduleId);
    final all = await _loadAll();
    final entryKey = _entryKey(semester, moduleId);
    if (_debugGradeStorageKeys) {
      debugPrint('GRADES_LOAD_GRADE key=$_storageKey entry=$entryKey');
    }
    final entry = all[entryKey];
    if (entry is! Map) {
      return null;
    }
    double? toDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return {
      'td': toDouble(entry['td']),
      'exam': toDouble(entry['exam']),
      'tp': toDouble(entry['tp']),
      'moy': toDouble(entry['moy']),
      'coef': toDouble(entry['coef']),
      'cred': toDouble(entry['cred']),
      'wTD': toDouble(entry['wTD']),
      'wEX': toDouble(entry['wEX']),
      'wTP': toDouble(entry['wTP']),
    };

  }

  Future<void> saveGrade(
      String semester,
      String moduleId,
      double? td,
      double? exam,
      double? tp,
      double? moy,
      double coef,
      double cred,
      double wTD,
      double wEX,
      double wTP,
      ) async {
    final all = await _loadAll();

    final hasValues =
        td != null ||
            exam != null ||
            tp != null ||
            moy != null ||
            coef != 0 ||
            cred != 0;

    final key = _entryKey(semester, moduleId);
    if (_debugGradeStorageKeys) {
      debugPrint('GRADES_SAVE_GRADE key=$_storageKey entry=$key');
    }

    if (!hasValues) {
      all.remove(key);
      try {
        await _saveAll(all);
      } catch (error, stackTrace) {
        debugPrint('SAVE_GRADE_REMOVE_ERROR key=$key error=$error');
        debugPrint('SAVE_GRADE_REMOVE_STACK $stackTrace');
        rethrow;
      }
      return;
    }

    all[key] = <String, dynamic>{
      'td': td,
      'exam': exam,
      'tp': tp,
      'moy': moy,
      'coef': coef,
      'cred': cred,
      'wTD': wTD,
      'wEX': wEX,
      'wTP': wTP,
    };

    try {
      await _saveAll(all);
    } catch (error, stackTrace) {
      debugPrint('SAVE_GRADE_ERROR key=$key error=$error');
      debugPrint('SAVE_GRADE_STACK $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, Map<String, dynamic>>> loadModuleStates(
      String semester) async {
    double? toDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    final Map<String, Map<String, dynamic>> states = {};
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyModulesIfNeeded(semester);
    final modulesKey = _modulesKey(semester);
    final raw = prefs.getString(modulesKey);
    debugPrint('LOAD_MODULES_RAW key=$modulesKey raw=$raw');
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        debugPrint(
          'LOAD_MODULES_PARSED key=$modulesKey payload=${jsonEncode(decoded)}',
        );
        if (decoded is List) {
          for (final entry in decoded) {
            if (entry is! Map) continue;
            final id = entry['moduleId']?.toString() ?? entry['id']?.toString();
            if (id == null || id.isEmpty) continue;
            states[id] = {
              'moduleId': id,
              'moduleName': entry['moduleName']?.toString() ??
                  entry['name']?.toString(),
              'semester': entry['semester']?.toString() ?? semester,
              'coef': toDouble(entry['coef']),
              'cred': toDouble(entry['cred']),
              'td': toDouble(entry['td']),
              'tp': toDouble(entry['tp']),
              'exam': toDouble(entry['exam']),
              'moy': toDouble(entry['moy']),
              'wTD': toDouble(entry['wTD']),
              'wEX': toDouble(entry['wEX']),
              'wTP': toDouble(entry['wTP']),
            };
          }
        }
      } catch (error, stackTrace) {
        debugPrint('LOAD_MODULES_ERROR key=$modulesKey error=$error');
        debugPrint('LOAD_MODULES_STACK $stackTrace');
      }
    }

    return states;
  }

  Future<void> saveModuleStates(
      String semester, List<ModuleModel> modules) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = modules
        .map(
          (module) {
        final hasValues =
            module.td != null || module.tp != null || module.exam != null;
        final moy = hasValues ? module.moy : null;
        return <String, dynamic>{
          'moduleId': module.id,
          'moduleName': module.title,
          'semester': semester,
          'coef': module.coef,
          'cred': module.credits,
          'td': module.td,
          'tp': module.tp,
          'exam': module.exam,
          'moy': moy,
          'wTD': module.wTD,
          'wEX': module.wEX,
          'wTP': module.wTP,
        };
      },
    )
        .toList(growable: false);
    final modulesKey = _modulesKey(semester);
    debugPrint(
      'SAVE_MODULES key=$modulesKey payload=${jsonEncode(payload)}',
    );
    try {
      await prefs.setString(modulesKey, jsonEncode(payload));
    } catch (error, stackTrace) {
      debugPrint('SAVE_MODULES_ERROR key=$modulesKey error=$error');
      debugPrint('SAVE_MODULES_STACK $stackTrace');
      rethrow;
    }
    final readBack = prefs.getString(modulesKey);
    debugPrint('SAVE_MODULES_READBACK key=$modulesKey raw=$readBack');
  }

  Future<void> clearGrade(String semester, String moduleId) async {
    final all = await _loadAll();
    all.remove(_entryKey(semester, moduleId));
    await _saveAll(all);
  }
}

Widget buildSemesterTable(BuildContext context, SemesterModel sem) {
  return Padding(
    padding: const EdgeInsets.all(5),
    child: SingleChildScrollView(
      child: Column(
        children: sem.modules.map((module) {
          return Column(
            children: [
              NoteCard(
                coef: module.coef,
                cred: module.credits,
                subject: module.title,
                wTD: module.wTD,
                wEX: module.wEX,
                wTP: module.wTP,

                initialTd: module.td == 0 ? null : module.td,
                initialTp: module.tp == 0 ? null : module.tp,
                initialExam: module.exam == 0 ? null : module.exam,

                onChanged: (td, tp, exam, moy, coef, cred, wTD, wEX, wTP) {
                  module.td = td ?? 0;
                  module.tp = tp ?? 0;
                  module.exam = exam ?? 0;

                  module.coef = coef;
                  module.credits = cred;

                  module.wTD = wTD;
                  module.wEX = wEX;
                  module.wTP = wTP;

                  sem.recompute();
                  (context as Element).markNeedsBuild();
                },

              ),

              const SizedBox(height: 20),
            ],
          );
        }).toList(),
      ),
    ),
  );
}

/// بطاقة المادة NoteCard
class NoteCard extends StatefulWidget {
  final double coef;
  final double cred;
  final String subject;
  final double wTD;
  final double wEX;
  final double wTP;
  final double? initialTd;
  final double? initialTp;
  final double? initialExam;
  final Function(
      double? td,
      double? tp,
      double? exam,
      double moy,
      double coef,
      double cred,
      double wTD,
      double wEX,
      double wTP
      ) onChanged;




  const NoteCard({
    super.key,

    required this.coef,
    required this.cred,
    required this.subject,
    required this.onChanged,
    required this.wTD,
    required this.wEX,
    required this.wTP,
    this.initialTd,
    this.initialTp,
    this.initialExam,

  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}
class NoteResult {
  final double td;
  final double tp;
  final double exam;
  final double moy;
  final double coef;
  final double cred;

  NoteResult(
      this.td,
      this.tp,
      this.exam,
      this.moy,
      this.coef,
      this.cred);
}
class _NoteCardState extends State<NoteCard> {
  double? td;
  double? tp;
  double? exam;
  double moy = 0.0;

  late double coef;
  late double cred;
  late double wTD;
  late double wEX;
  late double wTP;
  late TextEditingController _tdController;
  late TextEditingController _tpController;
  late TextEditingController _examController;
  late TextEditingController _coefController;
  late TextEditingController _credController;

  String? translatedSubject;

  @override
  void initState() {
    super.initState();
    cred = widget.cred; // نهيئه بالقيمة الأصلية
    coef = widget.coef;
    wTD = widget.wTD;
    wEX = widget.wEX;
    wTP = widget.wTP;
    td = widget.initialTd;
    tp = widget.initialTp;
    exam = widget.initialExam;
    calculateMoy();
    _tdController = TextEditingController(text: _formatGrade(td));
    _tpController = TextEditingController(text: _formatGrade(tp));
    _examController = TextEditingController(text: _formatGrade(exam));
    _coefController = TextEditingController(text: coef.toStringAsFixed(0));
    _credController = TextEditingController(text: cred.toStringAsFixed(0));
    _loadTranslatedSubject();

  }
  void _loadTranslatedSubject() async {
    try {
      final result = await translateSubject(context, widget.subject);
      if (mounted) {
        setState(() {
          translatedSubject = result;
        });
      }
    } catch (_) {
      translatedSubject = widget.subject; // fallback عند الخطأ
    }
  }

  @override
  void didUpdateWidget(covariant NoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTd != td ||
        widget.initialTp != tp ||
        widget.initialExam != exam) {
      setState(() {
        td = widget.initialTd;
        tp = widget.initialTp;
        exam = widget.initialExam;
        calculateMoy();
        _tdController.text = _formatGrade(td);
        _tpController.text = _formatGrade(tp);
        _examController.text = _formatGrade(exam);
      });
    }
    if (widget.coef != coef || widget.cred != cred) {
      setState(() {
        coef = widget.coef;
        cred = widget.cred;
        _coefController.text = coef.toStringAsFixed(0);
        _credController.text = cred.toStringAsFixed(0);
      });
    }
    if (widget.wTD != wTD || widget.wEX != wEX || widget.wTP != wTP) {
      setState(() {
        wTD = widget.wTD;
        wEX = widget.wEX;
        wTP = widget.wTP;
        calculateMoy();
      });
    }
  }

  @override
  void dispose() {
    _tdController.dispose();
    _tpController.dispose();
    _examController.dispose();
    _coefController.dispose();
    _credController.dispose();
    super.dispose();
  }

  String _formatGrade(double? value) {
    if (value == null || value == 0) return '';
    return value.toString();
  }


  double? _parseGrade(String value) {
    final sanitized = value.replaceAll(',', '.').trim();
    if (sanitized.isEmpty) return null;
    return double.tryParse(sanitized);
  }

  int? _parseNonNegativeInt(String value) {
    final sanitized = value.trim();
    if (sanitized.isEmpty) return 0;
    final parsed = int.tryParse(sanitized);
    if (parsed == null || parsed < 0) return null;
    return parsed;
  }
  void onTDChanged(String v) {
    setState(() {
      td = _parseGrade(v);
      calculateMoy();
      notifyParent();
    });
  }
  void notifyParent() {
    widget.onChanged(td, tp, exam, moy, coef, cred, wTD, wEX, wTP);
  }

  void onExamChanged(String v) {
    setState(() {
      exam = _parseGrade(v);
      calculateMoy();
      notifyParent();
    });
  }
  void onTPChanged(String v) {
    setState(() {
      tp = _parseGrade(v);
      calculateMoy();
      notifyParent();
    });
  }
  void calculateMoy() {
    if (td == null && tp == null && exam == null) {
      moy = 0;
      return;
    }
// هنا معادلة حساب المعدل
    moy = ((td ?? 0) * wTD) + ((exam ?? 0) * wEX) + ((tp ?? 0) * wTP);
  }
  void updateCred(double newValue) {
    setState(() {
      cred = newValue;
      notifyParent();
    });
  }
  void updateCoef(double newValue) {
    setState(() {
      coef = newValue;
      notifyParent();
    });
  }
  void _showWeightsDialog() {
    TextEditingController wTDController = TextEditingController(text: wTD.toString());
    TextEditingController wEXController = TextEditingController(text: wEX.toString());
    TextEditingController wTPController = TextEditingController(text: wTP.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(S.of(context).editWeights),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              FutureBuilder<String>(
                future: translateSubject(context,widget.subject),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text('...'); // أثناء التحميل
                  } else if (snapshot.hasError) {
                    return Text(widget.subject); // fallback عند الخطأ
                  } else {
                    return Text(
                      textAlign: TextAlign.start,
                      snapshot.data!,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 15,),
              TextField(
                  controller: wTDController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: "W. TD"),
                  textAlign: TextAlign.center
              ),const SizedBox(height: 10,),
              TextField(
                controller: wEXController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "W. EXAM",),
                textAlign: TextAlign.center,
              ),const SizedBox(height: 10,),
              TextField(
                controller: wTPController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "W. TP"),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  wTD = double.tryParse(wTDController.text) ?? wTD;
                  wEX = double.tryParse(wEXController.text) ?? wEX;
                  wTP = double.tryParse(wTPController.text) ?? wTP;
                  calculateMoy();
                  notifyParent();
                });

                Navigator.pop(context);
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Container(width: double.infinity,height: 218,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        border:  Border.all(
          width: 3,
          color: moy == 0
              ? Theme.of(context).colorScheme.onSurface
              : moy < 10
              ? Colors.red.withValues(alpha: 0.7)
              : Colors.green.withValues(alpha: 0.7),
        ),

      ),
      child: Column(
        children: [
          //------------------ الصف العلوي --------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // اسم المادة
              Expanded(
                child:
                Column(
                  children: [

                    Text(
                      translatedSubject ?? widget.subject, // يظهر الاسم الثابت أو fallback أثناء التحميل
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Container(

                      child:
                      const SizedBox(width: 10, height: 15,),
                    ),
                  ],
                ),),
              Row(

                children: [
                  // Coef
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text("Coef", style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 2),
                      Container(
                        width: 60,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              width: 1,
                              color: Theme.of(context).colorScheme.onSurface,)
                        ),
                        child:

                        TextField(
                          controller: _coefController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final parsed = _parseNonNegativeInt(v);
                            if (parsed == null) return;
                            setState(() {
                              coef = parsed.toDouble();
                              notifyParent();
                            });
                          }
                          ,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(fontSize: 15),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.only(top: 2, bottom: 0, left: 0, right: 0),
                            border: InputBorder.none, // إزالة الحد الافتراضي إذا تريد
                          ),
                        ),



                      ),

                    ],
                  ),

                  const SizedBox(width: 5),

                  // Cred
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text("Cred", style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 2),
                      Container(
                          width: 60,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                width: 1,
                                color: Theme.of(context).colorScheme.onSurface,)
                          ),
                          child:
                          TextField(
                            controller: _credController,
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              final parsed = _parseNonNegativeInt(v);
                              if (parsed == null) return;
                              setState(() {
                                cred = parsed.toDouble();
                                notifyParent();
                              });
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(fontSize: 15),
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.only(top: 2, bottom: 0, left: 0, right: 0),
                              border: InputBorder.none, // إزالة الحد الافتراضي إذا تريد
                            ),
                          )


                      ),
                    ],
                  ),
                ],
              ),




            ],
          ),

          const SizedBox(height: 5),
          Container(height: 2,
            color: moy == 0
                ? Theme.of(context).colorScheme.onSurface
                : moy < 10
                ? Colors.red.withValues(alpha: 0.7)
                : Colors.green.withValues(alpha: 0.7),),

          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  S.of(context).notesTdTpExam,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,

                  ),),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
                  onPressed: () {
                    _showWeightsDialog();
                  },
                ),

              ]),

          const SizedBox(height: 0),

          //------------------ حقول TD + EXAM + MOY --------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              Row(children: [

                // EXAM
                if (wEX != 0)
                  Column(
                    children: [
                      const Text("EXAM"),
                      const SizedBox(height: 2),
                      Container(
                        width: 70,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: TextField(
                          controller: _examController,
                          textAlign: TextAlign.center,
                          maxLength: 5,
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            onExamChanged(v);
                          },
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.only(top: 50, bottom: 23, left: 0, right: 0),
                            border: InputBorder.none,
                            counterText: '',

                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(width: 5,),

                // TD
                if (wTD != 0)
                  Column(
                    children: [

                      const Text("TD"),
                      const SizedBox(height: 2),
                      Container(
                        width: 70,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(40),

                        ),
                        child: TextField(
                          controller: _tdController,
                          textAlign: TextAlign.center,
                          maxLength: 5,
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            onTDChanged(v);
                          },

                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.only(top: 50, bottom: 23, left: 0, right: 0),
                            border: InputBorder.none,
                            counterText: '',
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(width: 5,),
                //TP
                if (wTP != 0)
                  Column(
                    children: [

                      const Text("TP"),
                      const SizedBox(height: 2),
                      Container(
                        width: 70,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(40),

                        ),
                        child: TextField(
                          controller: _tpController,
                          textAlign: TextAlign.center,
                          maxLength: 5,
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            onTPChanged(v);
                          },

                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.only(top: 50, bottom: 23, left: 0, right: 0),
                            border: InputBorder.none,
                            counterText: '',
                          ),
                        ),
                      ),
                    ],
                  )

              ]),
              // MOY
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Moy:        ",
                      style: TextStyle(
                        fontSize: 15,

                      )),
                  Text(
                    moy.toStringAsFixed(2),
                    style:  TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: moy == 0
                          ? Theme.of(context).colorScheme.onSurface
                          : moy < 10
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }


}


class TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  TabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Material يعطي خلفية ورفع مناسب للـ TabBar
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant TabBarDelegate oldDelegate) {
    // عدّل إلى true لو أردت إعادة البناء عند تغيّر محتوى الـ TabBar
    return false;
  }
}
/// ------------------------ Résumé annuel -------------------------------
class _AnnualSummaryCard extends StatelessWidget {
  const _AnnualSummaryCard({
    Key? key,
    required this.semester1,
    required this.semester2,
    this.showAnnual = true,
    this.showS1 = true,
    this.showS2 = true,
  }) : super(key: key);

  final SemesterModel semester1;
  final SemesterModel semester2;

  final bool showAnnual; // عرض الملخص السنوي
  final bool showS1; // عرض بطاقة S1
  final bool showS2; // عرض بطاقة S2

  Widget buildInfoCard(
      String title, double value, IconData icon, BuildContext cx) {
    return Container(
      width: 140,
      height: 63,
      padding: const EdgeInsets.fromLTRB(15, 10, 5, 2),
      decoration: BoxDecoration(
        color: Theme.of(cx).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(width: 2, color: Theme.of(cx).colorScheme.onSurface),
      ),
      child: Column(
        children: [
          Row(children: [
            Icon(icon, size: 20),
            const SizedBox(
              width: 5,
            ),
            Text(title, style: const TextStyle(fontSize: 14)),
          ]),
          Text(
            value.toStringAsFixed(2),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final moy1 = semester1.semesterAverage();
    final moy2 = semester2.semesterAverage();
    final ann = ((moy1 + moy2) / 2);
    final creds = semester1.creditsEarned() + semester2.creditsEarned();
    final S1cred = semester1.creditsEarned();
    final S2cred = semester2.creditsEarned();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---------------------- قسم S1 ----------------------
        if (showS1)
          Directionality(
              textDirection:
              TextDirection.ltr, // ← يمنع الانعكاس داخل البطاقة فقط
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(
                      width: 3, color: Theme.of(context).colorScheme.onSurface),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text("S1 Résumé",
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 10),
                    Row(
                      textDirection: TextDirection.ltr,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        buildInfoCard(
                            "S1 Moyenne", moy1, Icons.filter_1, context),
                        buildInfoCard(
                            "S1 Credits", S1cred, Icons.auto_graph, context),
                      ],
                    ),
                  ],
                ),
              )),

        // ---------------------- قسم S2 ----------------------
        if (showS2)
          Directionality(
              textDirection:
              TextDirection.ltr, // ← يمنع الانعكاس داخل البطاقة فقط
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(
                      width: 3, color: Theme.of(context).colorScheme.onSurface),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text("S2 Résumé",
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 10),
                    Row(
                      textDirection: TextDirection.ltr,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        buildInfoCard(
                            "S2 Moyenne", moy2, Icons.filter_2, context),
                        buildInfoCard(
                            "S2 Credits", S2cred, Icons.auto_graph, context),
                      ],
                    ),
                  ],
                ),
              )),

        // ---------------------- الملخص السنوي ----------------------
        if (showAnnual)
          Directionality(
              textDirection:
              TextDirection.ltr, // ← يمنع الانعكاس داخل البطاقة فقط
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(
                      width: 3, color: Theme.of(context).colorScheme.onSurface),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Résumé Annual",
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 10),
                    Row(
                      textDirection: TextDirection.ltr,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        buildInfoCard("Année", ann, Icons.verified, context),
                        buildInfoCard(
                            "Total Credits", creds, Icons.auto_graph, context),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          width: 3,
                          color: ann == 0
                              ? Theme.of(context).colorScheme.onSurface
                              : ann < 10
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start, // Résultat: في البداية
                        children: [
                          Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Résultat:",
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              )),

                          const SizedBox(height: 0),

                          // النتيجة في الوسط
                          Center(
                            child: Text(
                              ann == 0
                                  ? '---'
                                  : (ann >= 10
                                  ? '✨u Succeeded✨'
                                  : 'u Failed ❌'),
                              style: GoogleFonts.dmMono(
                                  textStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                    color: ann == 0
                                        ? Theme.of(context).colorScheme.onSurface
                                        : ann < 10
                                        ? Colors.red
                                        : Colors.green,
                                  )),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              )),
      ],
    );
  }
}

Widget buildInfoCard(String title, double value, IconData icon) {
  return Card(
    //color:Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    )),
                Icon(
                  icon,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 0),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ));
}

extension SafeStringExt on String {
  String ellipsize(int max, {String ellipsis = '…'}) {
    if (length <= max) return this;
    if (max <= 0) return '';
    return substring(0, max) + ellipsis;
  }
}

// دالة تأخذك مباشرةً إلى واجهة “الدراسة”
void openStudiesNavigator(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
        builder: (_) => FacultiesScreen(faculties: getDemoFaculties(context))),
  );
}
/////////////////////////////////////////////////////////////////////////////
/////////////////////result screen///////////////////////////////
/////////////////////////////////////////////////////////////////////////////////

class ResultsScreen extends StatelessWidget {
  final SemesterModel semester1;
  final SemesterModel semester2;
  final String programLabel; // مثال: "Licence 2ème Année" (اختياري)
  final String facultyName;
  final String level;

  const ResultsScreen({
    super.key,
    required this.semester1,
    required this.semester2,
    this.programLabel = '',
    this.facultyName = '',
    this.level = '',
  });

  @override
  Widget build(BuildContext context) {
    // حسابات
    final double moy1 = semester1.semesterAverage();
    final double moy2 = semester2.semesterAverage();
    // إذا كان أحد الفصول فارغاً، إبقاء المتوسط = 0
    final double ann = _computeAnnual(moy1, moy2);
    final double cred1 = semester1.creditsEarned();
    final double cred2 = semester2.creditsEarned();
    final double totalCred = cred1 + cred2;

    final decisionColor = _decisionColor(context, ann);
    final decisionText = _decisionText(ann);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).studyResults),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final file = await PdfReportService.generateReport(
            faculty: facultyName.isNotEmpty ? facultyName : programLabel,
            program: programLabel,
            level: level,
            semester1: semester1,
            semester2: semester2,
          );
          await OpenFilex.open(file.path);
        },
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('PDF'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- عنوان السنة / البرنامج ----------
            if (programLabel.isNotEmpty) ...[
              Text(
                programLabel,
                style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
            ],
            // ---------- العنوان العام + البطاقة العليا ----------
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: ann == 0
                    ? Theme.of(context).colorScheme.surface
                    : decisionColor.withValues(alpha: 0.10),
                border: Border.all(
                  color: ann == 0
                      ? Theme.of(context).colorScheme.outline
                      : decisionColor,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Decision :',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      )),
                  const SizedBox(height: 8),
                  Row(
                    textDirection: TextDirection.ltr,
                    children: [
                      // -------- بطاقة المعدل السنوي --------
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context).colorScheme.surface,
                            border: Border.all(
                              color:
                              Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Année',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color:
                                  Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 0),
                              Text(
                                ann == 0 ? '0.0' : ann.toStringAsFixed(2),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: ann == 0
                                      ? Theme.of(context).colorScheme.onSurface
                                      : decisionColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // -------- بطاقة الرصيد الإجمالي --------
                      Container(
                        width: 100,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context).colorScheme.surface,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Total Credits',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 0),
                            Text(
                              totalCred.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // -------- بطاقة النتيجة النهائية --------
                      Container(
                        width: 120,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: ann == 0
                              ? Theme.of(context).colorScheme.surface
                              : decisionColor,
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Résultat',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: ann == 0
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 0),
                            Text(
                              ann == 0 ? '---' : decisionText,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: ann == 0
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ---------- متوسط الفصل الأول و رصيده ----------
            _buildSemesterSummaryRow('S1', moy1, cred1, context),
            const SizedBox(height: 8),
            _buildSemesterSummaryRow('S2', moy2, cred2, context),
            const SizedBox(height: 12),

            const Divider(),

            // ---------- قوائم المواد: S1 ثم S2 ----------

            _buildModuleListSection(context, 'S1 Modules', semester1.modules),
            const SizedBox(height: 16),
            _buildModuleListSection(context, 'S2 Modules', semester2.modules),
          ],
        ),
      ),
    );
  }

  static double _computeAnnual(double moy1, double moy2) {
    // نعتبر 0 إن لم تكن هناك مواد؛ يمكن تعديل المنطق إذا كان مطلوباً غير ذلك
    if (moy1 == 0 && moy2 == 0) return 0.0;
    // لو أحدهم صفر ونريد حساب السنوي بناءً على الموجود فقط:
    if (moy1 == 0) return double.parse(moy2.toStringAsFixed(2));
    if (moy2 == 0) return double.parse(moy1.toStringAsFixed(2));
    return double.parse(((moy1 + moy2) / 2).toStringAsFixed(2));
  }

  static Color _decisionColor(BuildContext cx, double ann) {
    if (ann == 0) return Colors.grey.shade400;
    return ann < 10 ? Colors.red : Colors.green;
  }

  static String _decisionText(double ann) {
    if (ann == 0) return '---';
    return ann < 10 ? 'Failed' : 'Succeed';
  }

  Widget _buildSemesterSummaryRow(
      String label, double moy, double creds, BuildContext ctx) {
    final scheme = Theme.of(ctx).colorScheme;

    final Color color = moy == 0
        ? scheme.onSurface.withValues(alpha: 0.6)
        : (moy < 10 ? Colors.red : Colors.green);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
          ),
        ),
        Row(
          children: [
            // بطاقة المعدل
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color),
                color: scheme.surface,
              ),
              child: Text(
                'Moy: ${moy == 0 ? '---' : moy.toStringAsFixed(2)}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 10),

            // بطاقة الرصيد
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: scheme.outlineVariant),
                color: scheme.surface,
              ),
              child: Text(
                'Credits: ${creds.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModuleListSection(
      BuildContext context,
      String title,
      List<ModuleModel> modules,
      ) {
    final theme = Theme.of(context);
    final accent = AppTeal.main;

    if (modules.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            S.of(context).noSubjectsThisSemester,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      );
    }

    final grouped = <String, List<ModuleModel>>{};
    for (final m in modules) {
      final key = m.unitLabel.trim().isEmpty ? 'مواد أخرى' : m.unitLabel;
      grouped.putIfAbsent(key, () => []).add(m);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        ...grouped.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${entry.value.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...entry.value.map((m) => _buildModuleRow(context, m)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildModuleRow(BuildContext context, ModuleModel m) {
    final scheme = Theme.of(context).colorScheme;

    final grade = m.moy;
    final gradeColor = _getGradeColor(grade);

    return Card(
      color: scheme.surface,
      shadowColor: scheme.shadow,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        title: FutureBuilder<String>(
          future: translateSubject(context, m.title),
          builder: (context, snapshot) {
            return Text(
              snapshot.data ?? m.title,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            );
          },
        ),
        subtitle: Text(
          '${S.of(context).credits}: ${m.credits.toStringAsFixed(0)}  /  '
              '${S.of(context).coefficient}: ${m.coef.toStringAsFixed(0)}',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        trailing: SizedBox(
          width: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    grade.toStringAsFixed(2),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: gradeColor,
                    ),
                  ),
                  Text(
                    _gradeLabel(grade),
                    style: TextStyle(color: gradeColor),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(
                icon:
                Icon(Icons.info_outline, size: 20, color: scheme.onSurface),
                onPressed: () => _showModuleWeightsDialog(context, m),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showModuleWeightsDialog(BuildContext context, ModuleModel m) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: FutureBuilder<String>(
          future: translateSubject(context, m.title),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('...'); // أثناء التحميل
            } else if (snapshot.hasError) {
              return Text(m.title); // fallback عند الخطأ
            } else {
              return Text(
                snapshot.data!,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              );
            }
          },
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _infoRow('wTD', m.wTD),
            _infoRow('wTP', m.wTP),
            _infoRow('wEX', m.wEX),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(S.of(context).close)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value.toStringAsFixed(2)),
        ],
      ),
    );
  }

  Color _getGradeColor(double grade) {
    if (grade >= 10) return Colors.green;
    //if (grade >= 8) return Colors.orange;
    return Colors.red;
  }

  String _gradeLabel(double grade) {
    if (grade >= 10) return 'SUCCEED';
    //if (grade >= 8) return 'FAILED';
    return 'FAILED';
  }
}

class PdfReportService {
  static Future<File> generateReport({
    required String faculty,
    required String program,
    required SemesterModel semester1,
    required SemesterModel semester2,
    String level = '',
    String department = '',
  }) async {
    final generatedAt = DateTime.now();
    final regularFont =
    pw.Font.ttf(await rootBundle.load('assets/fonts/Tajawal-Regular.ttf'));
    final boldFont =
    pw.Font.ttf(await rootBundle.load('assets/fonts/Tajawal-Bold.ttf'));

    final moy1 = semester1.semesterAverage();
    final moy2 = semester2.semesterAverage();
    final ann = _annualAverage(moy1, moy2);
    final cred1 = semester1.creditsEarned();
    final cred2 = semester2.creditsEarned();
    final totalCred = cred1 + cred2;
    final decision = ann == 0
        ? '---'
        : (ann >= 10 ? 'Admitted (regular session)' : 'Not admitted');
    final academicYear = _academicYear(generatedAt);
    final docId = _buildDocumentId(generatedAt, semester1, semester2);

    final user = FirebaseAuth.instance.currentUser;
    final fullName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : 'UniSpace student';
    final names = _splitName(fullName);
    final email = _maskEmail(user?.email);

    final logo = _graduationCap();
    final translatedTitles = await _translateAll([
      ...semester1.modules,
      ...semester2.modules,
    ]);

    final pdf = pw.Document(
      title: 'UniSpace grade report',
      author: 'UniSpace',
      subject: 'Annual grade report',
      creator: 'UniSpace Flutter App',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(18, 16, 18, 18),
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        footer: (context) => _footer(context, generatedAt, docId),
        build: (context) => [
          _header(
            logo: logo,
            faculty: faculty,
            program: program,
            department: department,
            bold: boldFont,
          ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'GRADE REPORT',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          _identityBlock(
            year: academicYear,
            lastName: names.$1,
            firstName: names.$2,
            level: level,
            faculty: faculty,
            program: program,
            email: email,
            inscription: user?.uid != null
                ? 'US-${user!.uid.substring(0, user.uid.length.clamp(0, 12))}'
                : '—',
            bold: boldFont,
          ),
          pw.SizedBox(height: 10),
          _semesterBlock(
            title: 'Semester 1',
            semester: semester1,
            moyenne: moy1,
            credits: cred1,
            semNumber: 1,
            bold: boldFont,
            translatedTitles: translatedTitles,
          ),
          pw.SizedBox(height: 10),
          _semesterBlock(
            title: 'Semester 2',
            semester: semester2,
            moyenne: moy2,
            credits: cred2,
            semNumber: 2,
            bold: boldFont,
            translatedTitles: translatedTitles,
          ),
          pw.SizedBox(height: 10),
          _decisionBlock(
            moyenne: ann,
            decision: decision,
            yearCredits: totalCred,
            bold: boldFont,
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/results.pdf');
    return file.writeAsBytes(await pdf.save());
  }

  static pw.Widget _header({
    required pw.Widget logo,
    required String faculty,
    required String program,
    required String department,
    required pw.Font bold,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('UniSpace',
                  style: pw.TextStyle(font: bold, fontSize: 11)),
              pw.Text('University platform',
                  style: const pw.TextStyle(fontSize: 8)),
              pw.Text(
                'Faculty: ${faculty.isEmpty ? 'Not specified' : faculty}',
                style: const pw.TextStyle(fontSize: 8),
              ),
              if (department.isNotEmpty)
                pw.Text('Department: $department',
                    style: const pw.TextStyle(fontSize: 8)),
              pw.Text(
                'Major: ${program.isEmpty ? 'Not specified' : program}',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
        ),
        pw.Container(width: 64, height: 64, child: logo),
        pw.Expanded(child: pw.SizedBox()),
      ],
    );
  }

  static pw.Widget _identityBlock({
    required String year,
    required String lastName,
    required String firstName,
    required String level,
    required String faculty,
    required String program,
    required String? email,
    required String inscription,
    required pw.Font bold,
  }) {
    pw.Widget cell(String k, String v) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2, right: 8),
        child: pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: '$k: ',
                style: pw.TextStyle(font: bold, fontSize: 8),
              ),
              pw.TextSpan(
                text: v.isEmpty ? '—' : v,
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
        ),
      );
    }

    return pw.Column(
      children: [
        pw.Row(children: [
          pw.Expanded(child: cell('Academic year', year)),
          pw.Expanded(child: cell('Last name', lastName)),
          pw.Expanded(child: cell('First name', firstName)),
        ]),
        pw.Row(children: [
          pw.Expanded(child: cell('ID', inscription)),
          pw.Expanded(child: cell('Level', level)),
          pw.Expanded(child: cell('Major', program)),
        ]),
        pw.Row(children: [
          pw.Expanded(child: cell('Faculty', faculty)),
          pw.Expanded(child: cell('Email', email ?? 'Not specified')),
          pw.Expanded(child: cell('Degree', level)),
        ]),
      ],
    );
  }

  static const _ueWidths = <double>[1.1, 1.7, 0.9, 0.8, 0.8, 0.95, 0.7];
  static const _modWidths = <double>[3.4, 0.85, 0.8, 0.85, 0.95, 0.7];

  static pw.Widget _semesterBlock({
    required String title,
    required SemesterModel semester,
    required double moyenne,
    required double credits,
    required int semNumber,
    required pw.Font bold,
    required Map<String, String> translatedTitles,
  }) {
    final groups = _groupUnits(semester.modules);
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _headCell('Teaching unit (UE)'),
          _headCell('Subject(s) of the teaching unit'),
        ],
      ),
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          _innerTable(
            widths: _ueWidths,
            rows: [
              pw.TableRow(children: [
                _th('Type'),
                _th('UE code'),
                _th('Credits'),
                _th('Coef'),
                _th('Avg'),
                _th('Earned'),
                _th('Sess'),
              ]),
            ],
          ),
          _innerTable(
            widths: _modWidths,
            rows: [
              pw.TableRow(children: [
                _th('Title'),
                _th('Credits'),
                _th('Coef'),
                _th('Avg'),
                _th('Earned'),
                _th('Sess'),
              ]),
            ],
          ),
        ],
      ),
    ];

    if (groups.isEmpty) {
      rows.add(
        pw.TableRow(children: [_td('—'), _td('—')]),
      );
    } else {
      for (var u = 0; u < groups.length; u++) {
        final g = groups[u];
        final ueCoef = g.modules.fold<double>(0, (n, m) => n + m.coef);
        final ueCred = g.modules.fold<double>(0, (n, m) => n + m.credits);
        final ueEarned = g.modules.fold<double>(
          0,
              (n, m) => n + (m.moy >= 10 ? m.credits : 0),
        );
        final ueWeighted =
        g.modules.fold<double>(0, (n, m) => n + (m.moy * m.coef));
        final ueMoy = ueCoef == 0 ? 0.0 : ueWeighted / ueCoef;
        final ueSess = ueMoy == 0 ? '—' : (ueMoy >= 10 ? 'N' : 'R');
        final nature = _ueNature(g.label);
        final code =
            '$nature${(u + 1).toString().padLeft(3, '0')}S$semNumber';

        rows.add(
          pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: [
              _innerTable(
                widths: _ueWidths,
                rows: [
                  pw.TableRow(children: [
                    _td(nature),
                    _td(code),
                    _td(ueCred.toStringAsFixed(0)),
                    _td(ueCoef.toStringAsFixed(1)),
                    _td(ueMoy.toStringAsFixed(2)),
                    _td(ueEarned.toStringAsFixed(0)),
                    _td(ueSess),
                  ]),
                ],
              ),
              _innerTable(
                widths: _modWidths,
                rows: [
                  for (final m in g.modules)
                    pw.TableRow(children: [
                      _td(
                        translatedTitles[m.id] ?? m.title,
                        align: pw.TextAlign.left,
                      ),
                      _td(m.credits.toStringAsFixed(0)),
                      _td(m.coef.toStringAsFixed(0)),
                      _td(m.moy.toStringAsFixed(2)),
                      _td((m.moy >= 10 ? m.credits : 0).toStringAsFixed(0)),
                      _td(m.moy == 0 ? '—' : (m.moy >= 10 ? 'N' : 'R')),
                    ]),
                ],
              ),
            ],
          ),
        );
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.5),
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
          columnWidths: const {
            0: pw.FlexColumnWidth(4.3),
            1: pw.FlexColumnWidth(5.7),
          },
          children: rows,
        ),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey700, width: 0.5),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '$title average: ${moyenne == 0 ? '—' : moyenne.toStringAsFixed(2)}',
                style: pw.TextStyle(font: bold, fontSize: 8),
              ),
              pw.Text(
                '$title credits: ${credits.toStringAsFixed(0)}',
                style: pw.TextStyle(font: bold, fontSize: 8),
              ),
              pw.Text(
                'N = regular session    R = resit',
                style: const pw.TextStyle(fontSize: 7),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Table _innerTable({
    required List<double> widths,
    required List<pw.TableRow> rows,
  }) {
    return pw.Table(
      border: pw.TableBorder.symmetric(
        inside: const pw.BorderSide(color: PdfColors.grey500, width: 0.3),
      ),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      columnWidths: {
        for (var i = 0; i < widths.length; i++) i: pw.FlexColumnWidth(widths[i]),
      },
      children: rows,
    );
  }

  static pw.Widget _decisionBlock({
    required double moyenne,
    required String decision,
    required double yearCredits,
    required pw.Font bold,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Annual average: ${moyenne == 0 ? '—' : moyenne.toStringAsFixed(2)}',
          style: pw.TextStyle(font: bold, fontSize: 10),
        ),
        pw.Text(
          'Decision: $decision',
          style: pw.TextStyle(font: bold, fontSize: 10),
        ),
        pw.Text(
          'Credits earned this year: ${yearCredits.toStringAsFixed(0)}',
          style: const pw.TextStyle(fontSize: 9),
        ),
      ],
    );
  }

  static List<({String label, List<ModuleModel> modules})> _groupUnits(
      List<ModuleModel> modules,
      ) {
    final grouped = <String, List<ModuleModel>>{};
    final order = <String>[];
    for (final m in modules) {
      String key = 'Teaching unit';
      try {
        final v = m.unitLabel.trim();
        if (v.isNotEmpty) key = v;
      } catch (_) {}
      if (!grouped.containsKey(key)) order.add(key);
      grouped.putIfAbsent(key, () => []).add(m);
    }
    return [for (final k in order) (label: k, modules: grouped[k]!)];
  }

  static String _ueNature(String label) {
    final t = label.toLowerCase();
    if (t.contains('fond') || t.contains('uef') || t.contains('أساس')) {
      return 'UEF';
    }
    if (t.contains('method') ||
        t.contains('méthod') ||
        t.contains('uem') ||
        t.contains('منهج')) {
      return 'UEM';
    }
    if (t.contains('decouv') ||
        t.contains('découv') ||
        t.contains('ued') ||
        t.contains('استكش')) {
      return 'UED';
    }
    if (t.contains('trans') || t.contains('uet') || t.contains('أفق')) {
      return 'UET';
    }
    return 'UE';
  }

  static pw.Widget _headCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _th(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _td(String text, {pw.TextAlign align = pw.TextAlign.center}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(
        text,
        textAlign: align,
        style: const pw.TextStyle(fontSize: 7),
      ),
    );
  }

  static Future<Map<String, String>> _translateAll(
      List<ModuleModel> modules,
      ) async {
    final out = <String, String>{};
    final cache = <String, String>{};

    Future<String> fr(String raw) async {
      final src = raw.trim();
      if (src.isEmpty) return src;
      if (cache.containsKey(src)) return cache[src]!;
      try {
        final result = await GoogleTranslator().translate(src, to: 'fr');
        final text = result.text.trim();
        cache[src] = text.isEmpty ? src : text;
      } catch (_) {
        cache[src] = src;
      }
      return cache[src]!;
    }

    for (final m in modules) {
      out[m.id] = await fr(m.title);
      String unit = 'Teaching unit';
      try {
        if (m.unitLabel.trim().isNotEmpty) unit = m.unitLabel.trim();
      } catch (_) {}
      out['unit:$unit'] = await fr(unit);
    }
    return out;
  }

  static pw.Widget _graduationCap() {
    final color = PdfColor.fromInt(0xFF0F766E);
    return pw.SizedBox(
      width: 58,
      height: 58,
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          pw.Positioned(
            top: 10,
            child: pw.Transform.rotate(
              angle: 0.785398,
              child: pw.Container(
                width: 22,
                height: 22,
                color: color,
              ),
            ),
          ),
          pw.Positioned(
            top: 28,
            child: pw.Container(
              width: 20,
              height: 9,
              decoration: pw.BoxDecoration(
                color: color,
                borderRadius: const pw.BorderRadius.only(
                  bottomLeft: pw.Radius.circular(2),
                  bottomRight: pw.Radius.circular(2),
                ),
              ),
            ),
          ),
          pw.Positioned(
            right: 8,
            top: 20,
            child: pw.Container(width: 1.4, height: 16, color: color),
          ),
          pw.Positioned(
            right: 5,
            top: 36,
            child: pw.Container(
              width: 6,
              height: 6,
              decoration: pw.BoxDecoration(
                color: color,
                shape: pw.BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static (String, String) _splitName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return (parts.first, '—');
    return (parts.sublist(1).join(' '), parts.first);
  }

  static double _annualAverage(double moy1, double moy2) {
    if (moy1 == 0 && moy2 == 0) return 0;
    if (moy1 == 0) return moy2;
    if (moy2 == 0) return moy1;
    return double.parse(((moy1 + moy2) / 2).toStringAsFixed(2));
  }

  static pw.Widget _footer(
      pw.Context context,
      DateTime generatedAt,
      String docId,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.Text(
          'Generated on ${_formatDate(generatedAt)}  •  Document ID: $docId  •  Page ${context.pageNumber}/${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
        ),
        pw.Text(
          'Generated by UniSpace. This document has no official administrative value.',
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static String _academicYear(DateTime now) {
    final startYear = now.month >= 9 ? now.year : now.year - 1;
    return '$startYear-${startYear + 1}';
  }

  static String? _maskEmail(String? email) {
    if (email == null || !email.contains('@')) return null;
    final parts = email.split('@');
    final local = parts.first;
    final domain = parts.last;
    if (local.length <= 2) return '$local@$domain';
    return '${local.substring(0, 2)}***@$domain';
  }

  static String _buildDocumentId(
      DateTime generatedAt,
      SemesterModel semester1,
      SemesterModel semester2,
      ) {
    final ts =
        '${generatedAt.year}${_two(generatedAt.month)}${_two(generatedAt.day)}-${_two(generatedAt.hour)}${_two(generatedAt.minute)}${_two(generatedAt.second)}';
    final hashSeed = [
      semester1.modules.length,
      semester2.modules.length,
      (semester1.semesterAverage() * 100).round(),
      (semester2.semesterAverage() * 100).round(),
    ].join('-');
    final shortHash =
    hashSeed.codeUnits.fold<int>(0, (a, b) => (a + b) % 99999);
    return 'US-$ts-${shortHash.toRadixString(16).padLeft(4, '0')}';
  }

  static String _formatDate(DateTime date) {
    return '${_two(date.day)}/${_two(date.month)}/${date.year} ${_two(date.hour)}:${_two(date.minute)}';
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}