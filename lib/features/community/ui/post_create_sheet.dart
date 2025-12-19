import 'package:flutter/material.dart';

import '../../../generated/l10n.dart';
import '../data/community_repository.dart';

class PostCreateSheet extends StatefulWidget {
  const PostCreateSheet({
    super.key,
    required this.repository,
    required this.university,
  });

  final CommunityRepository repository;
  final String? university;

  @override
  State<PostCreateSheet> createState() => _PostCreateSheetState();
}

class _PostCreateSheetState extends State<PostCreateSheet> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  bool _isQuestion = false;
  bool _loading = false;

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

    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    setState(() => _loading = true);
    try {
      await widget.repository.createPost(
        content: content,
        tags: tags,
        isQuestion: _isQuestion,
        university: widget.university,
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
                  labelText: S.of(context).content,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tagsController,
                decoration: InputDecoration(
                  labelText: S.of(context).tags,
                  hintText: S.of(context).tagsHint,
                ),
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
