import 'package:flutter/material.dart';

import '../generated/l10n.dart';
import '../moduls3.dart';

class FacultySearchPage extends StatefulWidget {
  const FacultySearchPage({
    super.key,
    required this.faculties,
    required this.onFacultySelected,
    this.initialQuery = '',
  });

  final List<ProgramFaculty> faculties;
  final String initialQuery;
  final void Function(BuildContext context, ProgramFaculty faculty)
      onFacultySelected;

  @override
  State<FacultySearchPage> createState() => _FacultySearchPageState();
}

class _FacultySearchPageState extends State<FacultySearchPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _controller.addListener(_handleQueryChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleQueryChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleQueryChanged() {
    setState(() {});
  }

  String _normalizeQuery(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  List<ProgramFaculty> _filteredFaculties(String query) {
    if (query.isEmpty) {
      return const [];
    }
    final normalizedQuery = _normalizeQuery(query).toLowerCase();
    if (normalizedQuery.isEmpty) {
      return const [];
    }
    return widget.faculties
        .where((faculty) {
          final name = faculty.name.trim();
          return name.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final query = _normalizeQuery(_controller.text);
    final results = _filteredFaculties(query);
    final theme = Theme.of(context);

    final inputTheme = theme.inputDecorationTheme;

    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          height: 48,
          child: TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: S.of(context).searchFaculty,
              isDense: true,
              contentPadding: const EdgeInsetsDirectional.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              prefixIcon: const Icon(Icons.search),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              border: inputTheme.border,
              enabledBorder: inputTheme.enabledBorder,
              focusedBorder: inputTheme.focusedBorder,
              errorBorder: inputTheme.errorBorder,
              focusedErrorBorder: inputTheme.focusedErrorBorder,
              filled: inputTheme.filled,
              fillColor: inputTheme.fillColor,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Builder(
          builder: (context) {
            if (query.isEmpty) {
              return Center(
                child: Text(
                  S.of(context).searchStartTyping,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              );
            }
            if (results.isEmpty) {
              return Center(
                child: Text(
                  S.of(context).searchNoResults,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              );
            }
            return ListView.separated(
              itemCount: results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final faculty = results[index];
                return _FacultySearchCard(
                  faculty: faculty,
                  onTap: () => widget.onFacultySelected(context, faculty),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _FacultySearchCard extends StatelessWidget {
  const _FacultySearchCard({
    required this.faculty,
    required this.onTap,
  });

  final ProgramFaculty faculty;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSecondary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.onSurface.withOpacity(.08),
                blurRadius: 18,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primary.withOpacity(.2),
                foregroundColor: theme.colorScheme.primary,
                child: const Icon(Icons.apartment_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  faculty.name,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.start,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
