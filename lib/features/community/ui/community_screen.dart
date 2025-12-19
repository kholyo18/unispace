import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../generated/l10n.dart';
import '../../../ui/widgets/empty_state.dart';
import '../../../ui/widgets/app_scaffold.dart';
import '../data/community_repository.dart';
import '../models/post_model.dart';
import 'post_create_sheet.dart';
import 'post_details_screen.dart';
import 'widgets/community_skeleton.dart';
import 'widgets/post_card.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final CommunityRepository _repository = CommunityRepository();
  final TextEditingController _searchController = TextEditingController();
  CommunityFilter _filter = CommunityFilter.all;
  String? _university;
  String? _activeTag;

  @override
  void initState() {
    super.initState();
    _loadUniversity();
  }

  Future<void> _loadUniversity() async {
    final university = await _repository.getUserUniversity();
    if (mounted) {
      setState(() => _university = university);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateSheet() async {
    final created = await showModalBottomSheet<bool>(
      isScrollControlled: true,
      context: context,
      builder: (_) => PostCreateSheet(
        repository: _repository,
        university: _university,
      ),
    );
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).postPublished)),
      );
    }
  }

  void _openPost(PostModel post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailsScreen(
          repository: _repository,
          post: post,
        ),
      ),
    );
  }

  void _setTagFilter(String? tag) {
    setState(() => _activeTag = tag);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final hasActiveTag = _activeTag != null && _activeTag!.isNotEmpty;

    return AppScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              S.of(context).community,
              style: GoogleFonts.pacifico(
                textStyle: Theme.of(context).textTheme.displayLarge,
                fontSize: 28,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      padding: EdgeInsets.zero,
      floatingActionButton: user == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _openCreateSheet,
              icon: const Icon(Icons.edit_note),
              label: Text(S.of(context).createPost),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: S.of(context).searchPosts,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<CommunityFilter>(
                segments: [
                  ButtonSegment(
                    value: CommunityFilter.all,
                    label: Text(S.of(context).filterAll),
                  ),
                  ButtonSegment(
                    value: CommunityFilter.myUniversity,
                    label: Text(S.of(context).filterMyUniversity),
                  ),
                  ButtonSegment(
                    value: CommunityFilter.questions,
                    label: Text(S.of(context).filterQuestions),
                  ),
                  ButtonSegment(
                    value: CommunityFilter.unanswered,
                    label: Text(S.of(context).filterUnanswered),
                  ),
                  ButtonSegment(
                    value: CommunityFilter.trending,
                    label: Text(S.of(context).filterTrending),
                  ),
                  ButtonSegment(
                    value: CommunityFilter.saved,
                    label: Text(S.of(context).filterSaved),
                  ),
                ],
                selected: {_filter},
                onSelectionChanged: (selection) {
                  setState(() => _filter = selection.first);
                },
              ),
            ),
          ),
          if (hasActiveTag)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: InputChip(
                  label: Text('#${_activeTag!}'),
                  onDeleted: () => _setTagFilter(null),
                  deleteIcon: const Icon(Icons.close),
                ),
              ),
            ),
          Expanded(
            child: _buildFeed(context, user),
          ),
        ],
      ),
    );
  }

  Widget _buildFeed(BuildContext context, User? user) {
    final hasActiveTag = _activeTag != null && _activeTag!.isNotEmpty;
    final hasSearch = _searchController.text.trim().isNotEmpty;

    if (user == null) {
      return EmptyState(
        icon: Icons.lock_outline,
        title: S.of(context).loginRequired,
        subtitle: S.of(context).loginToContinue,
      );
    }

    if (_filter == CommunityFilter.myUniversity &&
        (_university == null || _university!.isEmpty)) {
      return EmptyState(
        icon: Icons.school_outlined,
        title: S.of(context).universityNotSet,
        subtitle: S.of(context).universityNotSetHint,
      );
    }

    return StreamBuilder<List<PostModel>>(
      stream: _repository.streamPosts(
        filter: _filter,
        query: _searchController.text,
        tagFilter: _activeTag,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CommunitySkeleton();
        }
        if (snapshot.hasError) {
          return Center(child: Text(S.of(context).somethingWentWrong));
        }
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          if (hasSearch || hasActiveTag) {
            return EmptyState(
              icon: Icons.search_off,
              title: S.of(context).noResultsTitle,
              subtitle: S.of(context).noSearchResults,
              action: TextButton.icon(
                onPressed: () {
                  _clearSearch();
                  _setTagFilter(null);
                },
                icon: const Icon(Icons.refresh),
                label: Text(S.of(context).clearSearch),
              ),
            );
          }
          return EmptyState(
            icon: Icons.public_outlined,
            title: S.of(context).noPostsYet,
            subtitle: S.of(context).startDiscussion,
            action: user == null
                ? null
                : FilledButton(
                    onPressed: _openCreateSheet,
                    child: Text(S.of(context).createFirstPost),
                  ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
          itemCount: posts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (_, index) => PostCard(
            post: posts[index],
            repository: _repository,
            onOpen: () => _openPost(posts[index]),
            onTagSelected: _setTagFilter,
          ),
        );
      },
    );
  }
}
