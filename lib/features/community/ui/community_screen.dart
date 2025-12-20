import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../generated/l10n.dart';
import '../../../ui/widgets/empty_state.dart';
import '../../../ui/widgets/app_scaffold.dart';
import '../data/community_repository.dart';
import '../models/post_model.dart';
import '../utils/saved_post_category.dart';
import '../utils/tag_utils.dart';
import 'post_create_sheet.dart';
import 'post_details_screen.dart';
import 'notifications_screen.dart';
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
  CommunityTab _tab = CommunityTab.all;
  Timer? _searchDebounce;
  String _searchQuery = '';
  bool _showUnanswered = false;
  bool _showTrending = false;
  bool _showSaved = false;
  SavedPostCategory? _savedCategoryFilter;
  String? _university;
  String? _universityId;
  String? _activeTag;
  static const Duration _searchDebounceDuration =
      Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _loadUniversity();
  }

  Future<void> _loadUniversity() async {
    final results = await Future.wait([
      _repository.getUserUniversity(),
      _repository.getUserUniversityId(),
    ]);
    final university = results[0] as String?;
    final universityId = results[1] as String?;
    if (mounted) {
      setState(() {
        _university = university;
        _universityId = universityId;
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
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
        universityId: _universityId,
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
    final normalized = normalizeTag(tag ?? '');
    if (_activeTag == normalized) return;
    setState(() => _activeTag = normalized);
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDuration, () {
      if (!mounted) return;
      setState(() => _searchQuery = value);
    });
  }

  void _commitSearchQuery() {
    _searchDebounce?.cancel();
    final value = _searchController.text;
    if (_searchQuery == value) return;
    setState(() => _searchQuery = value);
  }

  void _resetFilters() {
    setState(() {
      _tab = CommunityTab.all;
      _showSaved = false;
      _showTrending = false;
      _showUnanswered = false;
      _savedCategoryFilter = null;
    });
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
        actions: [
          if (user != null)
            StreamBuilder<int>(
              stream: _repository.unreadCountStream(user.uid),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return IconButton(
                  tooltip: S.of(context).notificationsTitle,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationsScreen(
                          repository: _repository,
                          userId: user.uid,
                        ),
                      ),
                    );
                  },
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_none),
                      if (count > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text(
                                count > 99 ? '99+' : count.toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
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
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, _) {
                return TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: S.of(context).searchPosts,
                    suffixIcon: value.text.trim().isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: S.of(context).clearSearch,
                            onPressed: _clearSearch,
                          ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<CommunityTab>(
                segments: [
                  ButtonSegment(
                    value: CommunityTab.all,
                    label: Text(S.of(context).filterAll),
                  ),
                  ButtonSegment(
                    value: CommunityTab.myUniversity,
                    label: Text(S.of(context).filterMyUniversity),
                  ),
                  ButtonSegment(
                    value: CommunityTab.questions,
                    label: Text(S.of(context).filterQuestions),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (selection) {
                  _commitSearchQuery();
                  setState(() => _tab = selection.first);
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: Text(S.of(context).filterSaved),
                  selected: _showSaved,
                  onSelected: (value) {
                    _commitSearchQuery();
                    setState(() {
                      _showSaved = value;
                      if (!value) {
                        _savedCategoryFilter = null;
                      }
                    });
                  },
                ),
                FilterChip(
                  label: Text(S.of(context).filterTrending),
                  selected: _showTrending,
                  onSelected: (value) {
                    _commitSearchQuery();
                    setState(() => _showTrending = value);
                  },
                ),
                FilterChip(
                  label: Text(S.of(context).filterUnanswered),
                  selected: _showUnanswered,
                  onSelected: (value) {
                    _commitSearchQuery();
                    setState(() => _showUnanswered = value);
                  },
                ),
                if (_showSaved)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: Text(S.of(context).savedCategoryLater),
                        selected:
                            _savedCategoryFilter == SavedPostCategory.later,
                        onSelected: (value) {
                          _commitSearchQuery();
                          setState(() {
                            _savedCategoryFilter = value
                                ? SavedPostCategory.later
                                : null;
                          });
                        },
                      ),
                      FilterChip(
                        label: Text(S.of(context).savedCategoryExams),
                        selected:
                            _savedCategoryFilter == SavedPostCategory.exams,
                        onSelected: (value) {
                          _commitSearchQuery();
                          setState(() {
                            _savedCategoryFilter = value
                                ? SavedPostCategory.exams
                                : null;
                          });
                        },
                      ),
                      FilterChip(
                        label: Text(S.of(context).savedCategoryAdvice),
                        selected:
                            _savedCategoryFilter == SavedPostCategory.advice,
                        onSelected: (value) {
                          _commitSearchQuery();
                          setState(() {
                            _savedCategoryFilter = value
                                ? SavedPostCategory.advice
                                : null;
                          });
                        },
                      ),
                    ],
                  ),
                if (hasActiveTag)
                  InputChip(
                    label: Text(displayTag(_activeTag!)),
                    onDeleted: () => _setTagFilter(null),
                    deleteIcon: const Icon(Icons.close),
                  ),
              ],
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
    final hasSearch = _searchQuery.trim().isNotEmpty;
    final hasActiveFilters = _tab != CommunityTab.all ||
        _showSaved ||
        _showTrending ||
        _showUnanswered;
    final actions = <Widget>[
      if (hasSearch)
        TextButton.icon(
          onPressed: _clearSearch,
          icon: const Icon(Icons.close),
          label: Text(S.of(context).clearSearch),
        ),
      if (hasActiveTag)
        TextButton.icon(
          onPressed: () => _setTagFilter(null),
          icon: const Icon(Icons.local_offer_outlined),
          label: Text(S.of(context).clearTags),
        ),
      if (hasActiveFilters)
        TextButton.icon(
          onPressed: _resetFilters,
          icon: const Icon(Icons.tune),
          label: Text(S.of(context).resetFilters),
        ),
    ];
    final emptyActions = actions.isEmpty
        ? null
        : Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: actions,
          );

    if (user == null) {
      return EmptyState(
        icon: Icons.lock_outline,
        title: S.of(context).loginRequired,
        subtitle: S.of(context).loginToContinue,
      );
    }

    if (_tab == CommunityTab.myUniversity &&
        (_universityId == null || _universityId!.isEmpty)) {
      return EmptyState(
        icon: Icons.school_outlined,
        title: S.of(context).universityNotSet,
        subtitle: S.of(context).universityNotSetHint,
        action: Builder(
          builder: (context) => FilledButton(
            onPressed: () => Scaffold.of(context).openEndDrawer(),
            child: Text(S.of(context).updateUniversity),
          ),
        ),
      );
    }

    return StreamBuilder<Map<String, SavedPostCategory>>(
      stream: _repository.streamSavedPostCategories(),
      builder: (context, savedSnapshot) {
        final savedCategoriesMap = savedSnapshot.data;
        return StreamBuilder<Set<String>>(
          stream: _repository.streamHiddenPostIds(user.uid),
          builder: (context, hiddenSnapshot) {
            final hiddenIds = hiddenSnapshot.data ?? <String>{};
            return StreamBuilder<Set<String>>(
              stream: _repository.streamBlockedUserIds(user.uid),
              builder: (context, blockedSnapshot) {
                final blockedIds = blockedSnapshot.data ?? <String>{};
                return StreamBuilder<List<PostModel>>(
                  stream: _repository.streamPosts(
                    tab: _tab,
                    query: _searchQuery,
                    tagFilter: _activeTag,
                    showSavedOnly: _showSaved,
                    showTrending: _showTrending,
                    showUnanswered: _showUnanswered,
                    savedCategoryFilter: _savedCategoryFilter,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const CommunitySkeleton();
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(S.of(context).somethingWentWrong),
                      );
                    }
                    final posts = (snapshot.data ?? [])
                        .where((post) =>
                            !hiddenIds.contains(post.id) &&
                            !blockedIds.contains(post.authorId))
                        .toList();
                    if (posts.isEmpty) {
                      if (hasSearch || hasActiveTag || hasActiveFilters) {
                        return EmptyState(
                          icon: Icons.search_off,
                          title: S.of(context).noResultsTitle,
                          subtitle: S.of(context).noSearchResults,
                          action: emptyActions,
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
                        key: ValueKey(posts[index].id),
                        post: posts[index],
                        repository: _repository,
                        onOpen: () => _openPost(posts[index]),
                        onTagSelected: _setTagFilter,
                        savedCategory: _showSaved
                            ? (savedCategoriesMap ?? {})[posts[index].id]
                            : null,
                        onSavedCategoryTap: _showSaved
                            ? () => _chooseSavedCategory(
                                  context,
                                  posts[index].id,
                                  (savedCategoriesMap ?? {})[posts[index].id] ??
                                      SavedPostCategory.later,
                                )
                            : null,
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _chooseSavedCategory(
    BuildContext context,
    String postId,
    SavedPostCategory currentCategory,
  ) async {
    final selected = await showModalBottomSheet<SavedPostCategory>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  S.of(context).chooseCategory,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              ...SavedPostCategory.values.map((category) {
                return ListTile(
                  title: Text(savedPostCategoryLabel(context, category)),
                  trailing: category == currentCategory
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.pop(context, category),
                );
              }),
            ],
          ),
        );
      },
    );
    if (selected == null || selected == currentCategory) return;
    try {
      await _repository.updateSavedCategory(postId, selected);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context)
                  .savedToCategory(savedPostCategoryLabel(context, selected)),
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).loginRequired)),
        );
      }
    }
  }
}
