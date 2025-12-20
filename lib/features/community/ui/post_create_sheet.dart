import 'package:flutter/material.dart';

import '../../../generated/l10n.dart';
import '../data/community_repository.dart';
import '../utils/bad_words_filter.dart';
import '../utils/tag_utils.dart';

class PostCreateSheet extends StatefulWidget {
  const PostCreateSheet({
    super.key,
    required this.repository,
    required this.university,
    required this.universityId,
  });

  final CommunityRepository repository;
  final String? university;
  final String? universityId;

  @override
  State<PostCreateSheet> createState() => _PostCreateSheetState();
}

class _PostCreateSheetState extends State<PostCreateSheet> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  bool _isQuestion = false;
  bool _loading = false;
  final List<String> _selectedTags = [];

  static const List<String> _suggestedTags = [
    'campus',
    'clubs',
    'events',
    'housing',
    'exams',
    'notes',
    'study',
    'tips',
    'internships',
    'scholarships',
    'cafeteria',
  ];

  @override
  void dispose() {
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).contentRequired)),
      );
      return;
    }

    _addTagFromInput();
    final tags = List<String>.from(_selectedTags);
    if (containsBadWords(content) || containsBadWordsInList(tags)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).badWordsError)),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.repository.createPost(
        content: content,
        tags: tags,
        isQuestion: _isQuestion,
        university: widget.university,
        universityId: widget.universityId,
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).loginRequired)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _addTagFromInput() {
    final text = _tagsController.text.trim();
    if (text.isEmpty) return;
    for (final raw in text.split(',')) {
      _addTag(raw);
    }
    _tagsController.clear();
    setState(() {});
  }

  void _addTag(String tag) {
    final normalized = normalizeTag(tag);
    if (normalized == null) return;
    final exists = _selectedTags.contains(normalized);
    if (exists) return;
    setState(() => _selectedTags.add(normalized));
  }

  void _removeTag(String tag) {
    setState(() => _selectedTags.remove(tag));
  }

  List<String> _filteredSuggestions(String query) {
    final normalized = normalizeTag(query) ?? '';
    final available = _suggestedTags
        .where(
          (tag) => !_selectedTags
              .any((selected) => selected.toLowerCase() == tag.toLowerCase()),
        )
        .toList();
    if (normalized.isEmpty) return available;
    return available.where((tag) => tag.contains(normalized)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).newPost,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                minLines: 3,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: _isQuestion
                      ? S.of(context).questionPrompt
                      : S.of(context).content,
                  hintText: _isQuestion
                      ? S.of(context).questionHint
                      : S.of(context).postHint,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tagsController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addTagFromInput(),
                onChanged: (value) {
                  if (value.contains(',')) {
                    _addTagFromInput();
                    return;
                  }
                  setState(() {});
                },
                decoration: InputDecoration(
                  labelText: S.of(context).tags,
                  hintText: S.of(context).tagsHint,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: S.of(context).addTag,
                    onPressed: _addTagFromInput,
                  ),
                ),
              ),
              if (_selectedTags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedTags
                      .map(
                        (tag) => InputChip(
                          label: Text(displayTag(tag)),
                          onDeleted: () => _removeTag(tag),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                S.of(context).suggestedTags,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).hintColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _filteredSuggestions(_tagsController.text)
                    .map(
                      (tag) => ActionChip(
                        label: Text(displayTag(tag)),
                        onPressed: () => _addTag(tag),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _isQuestion,
                title: Text(S.of(context).postAsQuestion),
                onChanged: (value) => setState(() => _isQuestion = value),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _publish,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(_loading
                      ? S.of(context).publishing
                      : S.of(context).publish),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
