part of '../../main.dart';

class RedditStyleAiSearchScreen extends StatefulWidget {
  const RedditStyleAiSearchScreen({super.key});

  @override
  State<RedditStyleAiSearchScreen> createState() =>
      _RedditStyleAiSearchScreenState();
}

enum _ResultTab { all, people, posts, comments }

class _RedditStyleAiSearchScreenState extends State<RedditStyleAiSearchScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  late final AnimationController _aiPulseController;
  List<_SearchPerson> _people = [];
  List<_CommentSearchHit> _commentHits = [];
  bool _isAiMode = false;
  bool _isLoading = false;
  bool _peopleLoaded = false;
  String? _error;
  String? _peopleNotice;
  String? _contentNotice;
  int _searchGeneration = 0;

  List<_Post> _results = [];
  String? _aiAnswer;
  String? _lastQuery;

  // NEW: التبويب النشط لعرض النتائج
  _ResultTab _tab = _ResultTab.all;

  StreamSubscription<User?>? _historySubscription;
  List<String> _recentSearches = [];
  late final String? _historyUid = FirebaseAuth.instance.currentUser?.uid;

  static const List<_ExploreItem> _exploreItems = [
    _ExploreItem(category: 'دراسة', label: 'امتحانات', activity: '٢٤٠+ منشور', icon: Icons.edit_note_rounded, color: Color(0xFFEF6C57)),
    _ExploreItem(category: 'فرص', label: 'منح دراسية', activity: '١٨٠+ منشور', icon: Icons.school_rounded, color: Color(0xFF4FA6D9)),
    _ExploreItem(category: 'دراسة', label: 'مذاكرة', activity: '٣١٠+ منشور', icon: Icons.menu_book_rounded, color: Color(0xFF57B894)),
    _ExploreItem(category: 'حياة جامعية', label: 'سكن جامعي', activity: '٩٠+ منشور', icon: Icons.apartment_rounded, color: Color(0xFFE0A340)),
    _ExploreItem(category: 'توجيه', label: 'تخصصات', activity: '١٤٠+ منشور', icon: Icons.workspace_premium_rounded, color: Color(0xFF9B7BE0)),
    _ExploreItem(category: 'مجتمع', label: 'أنشطة طلابية', activity: '٧٥+ منشور', icon: Icons.groups_rounded, color: Color(0xFFE06BA6)),
  ];

  @override
  void initState() {
    super.initState();
    _aiPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _loadRecentSearches();
    _historySubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted && user?.uid != _historyUid) {
        setState(() => _recentSearches = []);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _historySubscription?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _aiPulseController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final saved = await AccountSearchHistory.load(_historyUid);
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != _historyUid) return;
      setState(() => _recentSearches = saved);
    } catch (e) {
      debugPrint('load recent searches failed: $e');
    }
  }

  Future<void> _saveRecentSearches() async {
    try {
      if (FirebaseAuth.instance.currentUser?.uid != _historyUid) return;
      await AccountSearchHistory.save(_historyUid, _recentSearches);
    } catch (e) {
      debugPrint('save recent searches failed: $e');
    }
  }

  Future<void> _performSearch() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    final generation = ++_searchGeneration;
    final searchUserId = FirebaseAuth.instance.currentUser?.uid;

    setState(() {
      _isLoading = true;
      _peopleLoaded = false;
      _error = null;
      _peopleNotice = null;
      _contentNotice = null;
      _aiAnswer = null;
      _results = [];
      _people = [];
      _commentHits = [];
      _lastQuery = q;
      _tab = _ResultTab.all;
    });

    FocusScope.of(context).unfocus();

    if (!_recentSearches.contains(q)) {
      setState(() {
        _recentSearches.insert(0, q);
        if (_recentSearches.length > 10) _recentSearches.removeLast();
      });
      unawaited(_saveRecentSearches());
    }

    try {
      final tokens = _queryTokens(q);
      var people = <_SearchPerson>[];
      String? peopleNotice;
      try {
        final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
            .httpsCallable('searchPeople')
                .call<Map<String, dynamic>>({'query': q});
        if (!mounted || generation != _searchGeneration ||
            FirebaseAuth.instance.currentUser?.uid != searchUserId) return;
        final rows = response.data['people'];
        if (rows is! List) throw const FormatException('Invalid search response');
        people = rows.map((row) {
          if (row is! Map || row['id'] is! String || row['name'] is! String) {
            throw const FormatException('Invalid search person');
          }
          return _SearchPerson(id: row['id'] as String, name: row['name'] as String,
              username: row['username'] as String?, photoUrl: row['photoUrl'] as String?);
        }).toList();
        if (response.data['truncated'] == true) {
          peopleNotice = mainText(context, "نتائج الحسابات محدودة حاليًا؛ قد لا تشمل كل الحسابات المطابقة.");
        }
      } on FirebaseFunctionsException catch (e) {
        if (!mounted || generation != _searchGeneration ||
            FirebaseAuth.instance.currentUser?.uid != searchUserId) return;
        debugPrint('[Search] people failed: ${e.code}');
        peopleNotice = e.code == 'unauthenticated'
            ? mainText(context, "انتهت الجلسة. سجّل الدخول ثم أعد المحاولة.")
            : e.code == 'resource-exhausted'
            ? mainText(context, "بحثت مرات كثيرة. انتظر دقيقة ثم أعد البحث عن الحسابات.")
            : mainText(context, "تعذر البحث عن الحسابات. حاول مرة أخرى.");
      } catch (_) {
        if (!mounted || generation != _searchGeneration ||
            FirebaseAuth.instance.currentUser?.uid != searchUserId) return;
        peopleNotice = mainText(context, "تعذر البحث عن الحسابات. حاول مرة أخرى.");
      }

      if (!mounted || generation != _searchGeneration ||
          FirebaseAuth.instance.currentUser?.uid != searchUserId) return;
      // People results must not wait for, or depend on, the content scan.
      setState(() {
        _people = people;
        _peopleNotice = peopleNotice;
        _peopleLoaded = true;
      });
      final blocked = await loadBlockedUserIds();
      final hidden = await loadHiddenPostIds();
      if (!mounted || generation != _searchGeneration ||
          FirebaseAuth.instance.currentUser?.uid != searchUserId) return;

      bool accept(_Post post) {
        if (tokens.isEmpty) return false;
        final r = post.repostOf;
        final repostHit = r != null &&
            _allTokensIn(
              '${r['title'] ?? ''} ${r['body'] ?? ''} ${r['commentText'] ?? ''}',
              tokens,
            );
        final contentHit = _allTokensIn(
          '${post.title} ${post.body} ${post.tags.join(' ')}',
          tokens,
        );
        return contentHit || repostHit;

      }

      Future<void> walkComments(_Post post, List<_Comment> list, List<_CommentSearchHit> out) async {
        for (final c in list) {
          if (generation != _searchGeneration || !mounted) return;
          if (blocked.contains(c.authorId ?? '')) continue;
          if (_allTokensIn(c.text, tokens)) {
            out.add(_CommentSearchHit(post: post, comment: c));
          }
          if (c.replies.isNotEmpty) await walkComments(post, c.replies, out);
        }
      }

      final seen = <String>{};
      final filtered = <_Post>[];
      final commentHits = <_CommentSearchHit>[];


      Future<void> addResult(Map<String, dynamic> row) async {
        final id = row['id'];
        final raw = row['data'];
        if (id is! String || raw is! Map) throw const FormatException('Invalid content result');
        if (seen.contains(id) || generation != _searchGeneration || !mounted) return;
        seen.add(id);
        if (hidden.contains(id)) return;
        final post = _Post.fromData(id, Map<String, dynamic>.from(raw));
        if (isBlockedPost(post, blocked)) return;
        await walkComments(post, post.comments, commentHits);
        if (accept(post)) filtered.add(post);
      }

      final indexToken = tokens.isNotEmpty ? tokens.first : null;
      Future<bool> loadPage(int page) async {
        if (!mounted || generation != _searchGeneration) return true;
        final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
            .httpsCallable('readContentSearchPage', options: HttpsCallableOptions(timeout: const Duration(seconds: 120)))
            .call<Map<String, dynamic>>({'page': page, 'token': indexToken});
        final rows = response.data['posts'];
        if (rows is! List || response.data['exhausted'] is! bool) {
          throw const FormatException('Invalid content page');
        }
        for (final row in rows) {
          await addResult(Map<String, dynamic>.from(row as Map));
        }
        return response.data['exhausted'] == true;
      }
      final scan = await scanContentSearch(
        indexed: indexToken != null,
        loadPage: loadPage,
        current: () => mounted && generation == _searchGeneration &&
            FirebaseAuth.instance.currentUser?.uid == searchUserId,
      );
      if (!mounted || generation != _searchGeneration ||
          FirebaseAuth.instance.currentUser?.uid != searchUserId) return;
      final contentNotice = scan.incomplete
          ? mainText(context, "تعذر تحميل بعض نتائج المنشورات. أعد البحث للمحاولة مجددًا.")
          : scan.truncated ? mainText(context, "النتائج محدودة؛ قد لا تشمل المنشورات الأقدم.") : null;
      commentHits.sort((a, b) => b.comment.createdAt.compareTo(a.comment.createdAt));
      filtered.sort((a, b) {
        int score(_Post p) {
          var s = 0;
          if (_allTokensIn(p.title, tokens)) s += 100;
          if (_allTokensIn(p.body, tokens)) s += 40;
          if (_allTokensIn(p.tags.join(' '), tokens)) s += 30;
          if (p.repostOf != null &&
              _allTokensIn(
                '${p.repostOf!['title'] ?? ''} ${p.repostOf!['body'] ?? ''} ${p.repostOf!['commentText'] ?? ''}',
                tokens,
              )) s += 50;
          return s;
        }
        final c = score(b).compareTo(score(a));
        if (c != 0) return c;
        return b.createdAt.compareTo(a.createdAt);
      });
      final limitedCommentHits = commentHits.take(20).toList();

      if (!mounted || generation != _searchGeneration ||
          FirebaseAuth.instance.currentUser?.uid != searchUserId) return;

      if (_isAiMode) {
        final buf = StringBuffer();
        if (filtered.isEmpty) {
          buf.write(contentNotice ?? mainText(context, "لم أجد منشورات في المجتمع حول \"{0}\".", <Object?>[q]));
        } else {
          if (contentNotice != null) buf.writeln(contentNotice);
          buf.writeln(mainText(context, "ملخص من منشورات المجتمع حول \"{0}\":\n", <Object?>[q]));
          for (final p in filtered.take(6)) {
            final t = p.title.trim();
            final b = p.body.trim();
            if (t.isNotEmpty) buf.writeln('• $t');
            if (b.isNotEmpty) buf.writeln(t.isEmpty ? '• $b' : '  $b');
            buf.writeln();
          }
        }
        setState(() {
          _people = people;
          _peopleNotice = peopleNotice;
          _contentNotice = contentNotice;
          _results = filtered;
          _commentHits = limitedCommentHits;
          _aiAnswer = buf.toString().trim();
          _isLoading = false;
        });
      } else {
        setState(() {
          _people = people;
          _peopleNotice = peopleNotice;
          _contentNotice = contentNotice;
          _results = filtered;
          _commentHits = limitedCommentHits;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted || generation != _searchGeneration ||
          FirebaseAuth.instance.currentUser?.uid != searchUserId) return;
      setState(() {
        _contentNotice = mainText(context, "تعذر تحميل بعض نتائج المنشورات. أعد البحث للمحاولة مجددًا.");
        _isLoading = false;
      });
    }
  }

  void _clearSearch() {
    ++_searchGeneration;
    _controller.clear();
    _isLoading = false;
    _peopleLoaded = false;
    _peopleNotice = null;
      _contentNotice = null;
    setState(() {
      _results = [];
      _people = [];
      _commentHits = [];
      _aiAnswer = null;
      _lastQuery = null;
      _error = null;
    });
    _focusNode.requestFocus();
  }

  static final _normalColor = AppTeal.main;
  static const _aiColor = UniSpaceColors.emerald;

  Color get _accent => _isAiMode ? _aiColor : _normalColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? UniSpaceColors.darkBackground : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(theme, isDark),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildBody(theme, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        border: Border(
          bottom: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            splashRadius: 20,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _performSearch(),
              onChanged: (_) => setState(() {}),
              onTap: () => setState(() {}),
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15),
              decoration: InputDecoration(
                hintText: _isAiMode ? mainText(context, "اسأل الذكاء الاصطناعي...") : mainText(context, "ابحث"),
                hintStyle: TextStyle(color: theme.hintColor, fontSize: 15),
                filled: true,
                fillColor: isDark ? UniSpaceColors.darkSurface : UniSpaceColors.lightField,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(21), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(21), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(21),
                  borderSide: BorderSide(color: _accent, width: 1.5),
                ),
                prefixIcon: Icon(Icons.search_rounded, size: 19, color: _focusNode.hasFocus ? _accent : theme.hintColor),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_controller.text.isNotEmpty)
                      GestureDetector(
                        onTap: _clearSearch,
                        child: Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(color: theme.hintColor.withValues(alpha: 0.25), shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
                        ),
                      ),
                    Container(height: 20, width: 1, color: theme.hintColor.withValues(alpha: 0.2), margin: const EdgeInsets.symmetric(horizontal: 4)),
                    _AiToggleButton(
                      isActive: _isAiMode,
                      accent: _aiColor,
                      pulse: _aiPulseController,
                      onTap: () {
                        setState(() {
                          _isAiMode = !_isAiMode;
                          _results = [];
                          _aiAnswer = null;
                        });
                      },
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    if (_isLoading && (!_peopleLoaded || _isAiMode)) {
      return Center(
        key: const ValueKey('loading'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 3, color: _accent)),
            const SizedBox(height: 12),
            Text(_isAiMode ? mainText(context, "الذكاء الاصطناعي يفكر...") : mainText(context, "جاري البحث..."), style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        key: const ValueKey('error'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 44, color: theme.colorScheme.error),
              const SizedBox(height: 10),
              Text(mainText(context, "حدث خطأ أثناء البحث\n{0}", <Object?>[_error]), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    if (_isAiMode && _aiAnswer != null) {
      return ListView(
        key: const ValueKey('ai-answer'),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _aiColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(16), bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
              ),
              child: Text(_lastQuery ?? '', style: const TextStyle(color: Colors.white, fontSize: 14.5)),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? UniSpaceColors.darkSurface : UniSpaceColors.lightField,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(4), bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 14, color: _aiColor),
                      const SizedBox(width: 6),
                      Text(mainText(context, "AI"), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _aiColor)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_aiAnswer!, style: theme.textTheme.bodyMedium?.copyWith(height: 1.55)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_lastQuery != null && !_isAiMode) {
      if (!_isLoading && _results.isEmpty && _people.isEmpty && _commentHits.isEmpty) {
        return Center(
          key: const ValueKey('empty-results'),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 42, color: theme.hintColor.withValues(alpha: 0.5)),
              const SizedBox(height: 14),
              Text(_peopleNotice ?? _contentNotice ?? mainText(context, "لا توجد نتائج لـ \"{0}\"", <Object?>[_lastQuery]), style: theme.textTheme.titleSmall),
            ],
          ),
        );
      }

      // ===== NEW: تبويبات النتائج =====
      return Column(
        key: const ValueKey('results'),
        children: [
          if (_isLoading) LinearProgressIndicator(color: _accent),
          if (_contentNotice != null)
            Padding(padding: const EdgeInsets.all(12), child: Text(_contentNotice!, textAlign: TextAlign.center)),
          if (_peopleNotice != null)
            Padding(padding: const EdgeInsets.all(12), child: Text(_peopleNotice!, textAlign: TextAlign.center)),
          _ResultTabsBar(
            tab: _tab,
            onChanged: (v) => setState(() => _tab = v),
            peopleCount: _people.length,
            postsCount: _results.length,
            commentsCount: _commentHits.length,
            accent: _normalColor,
          ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
              children: [
                if ((_tab == _ResultTab.all || _tab == _ResultTab.people) && _people.isNotEmpty) ...[
                  if (_tab == _ResultTab.all)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                      child: Text(mainText(context, "حسابات"), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                  ..._people.map((p) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: PublicProfilePhoto(userId: p.id, fallbackUrl: p.photoUrl, size: 44, radius: 22, iconSize: 22),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: (p.username == null || p.username!.isEmpty) ? null : Text('@${p.username}'),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: p.id, initialName: p.name, initialPhotoUrl: p.photoUrl)));
                    },
                  )),
                  if (_tab == _ResultTab.all) const SizedBox(height: 10),
                ],
                if ((_tab == _ResultTab.all || _tab == _ResultTab.posts) && _results.isNotEmpty) ...[
                  if (_tab == _ResultTab.all)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                      child: Text(mainText(context, "منشورات"), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                  ..._results.map((post) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RedditStylePostCard(post: post, accent: _normalColor),
                  )),
                ],
                if ((_tab == _ResultTab.all || _tab == _ResultTab.comments) && _commentHits.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  if (_tab == _ResultTab.all)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                      child: Text(mainText(context, "تعليقات"), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                  ..._commentHits.map((hit) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RedditStyleCommentTile(hit: hit, accent: _normalColor),
                  )),
                ],
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      key: const ValueKey('idle'),
      padding: EdgeInsets.zero,
      children: [
        if (_recentSearches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                Text(mainText(context, "الأخيرة"), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() => _recentSearches.clear());
                    unawaited(_saveRecentSearches());
                  },
                  child: Text(mainText(context, "مسح الكل"), style: TextStyle(fontSize: 13, color: _accent, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          ..._recentSearches.map((s) => _RecentSearchRow(
            label: s,
            onTap: () {
              _controller.text = s;
              _performSearch();
            },
            onDelete: () => setState(() => _recentSearches.remove(s)),
          )),
          Divider(height: 24, thickness: 6, color: isDark ? UniSpaceColors.darkBackground : UniSpaceColors.lightField),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          child: Text(mainText(context, "استكشف"), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        ),
        ..._exploreItems.map((item) => _ExploreRow(
          item: item,
          onTap: () {
            _controller.text = item.label;
            _performSearch();
          },
        )),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _ResultTabsBar extends StatelessWidget {
  final _ResultTab tab;
  final ValueChanged<_ResultTab> onChanged;
  final int peopleCount;
  final int postsCount;
  final int commentsCount;
  final Color accent;

  const _ResultTabsBar({
    required this.tab,
    required this.onChanged,
    required this.peopleCount,
    required this.postsCount,
    required this.commentsCount,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(.12),
            width: 1,
          ),
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [


              _RedditStyleTab(
                label: mainText(context, "الكل"),
                count: peopleCount + postsCount + commentsCount,
                selected: tab == _ResultTab.all,
                accent: accent,
                onTap: () => onChanged(_ResultTab.all),
              ),
              _RedditStyleTab(
                label: mainText(context, "الأشخاص"),
                count: peopleCount,
                selected: tab == _ResultTab.people,
                accent: accent,
                onTap: () => onChanged(_ResultTab.people),
              ),
              _RedditStyleTab(
                label: mainText(context, "المنشورات"),
                count: postsCount,
                selected: tab == _ResultTab.posts,
                accent: accent,
                onTap: () => onChanged(_ResultTab.posts),
              ),
              _RedditStyleTab(
                label: mainText(context, "التعليقات"),
                count: commentsCount,
                selected: tab == _ResultTab.comments,
                accent: accent,
                onTap: () => onChanged(_ResultTab.comments),
              ),

            ],
          ),
        ),
      ),
    );
  }
}

class _RedditStyleTab extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _RedditStyleTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 100,
          height: 48,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Center(
                child: Directionality(
                  textDirection: Directionality.of(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: selected
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface
                              .withOpacity(.55),
                        ),
                      ),

                      const SizedBox(width: 4),

                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? theme.colorScheme.onSurface
                              .withOpacity(.65)
                              : theme.colorScheme.onSurface
                              .withOpacity(.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: selected ? 70 : 0,
                height: selected ? 2 : 0,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}





final blockedListRevision = ValueNotifier<int>(0);
final hiddenListRevision = ValueNotifier<int>(0);
const kModeratorIds = <String>{
  'QYZAB7X4JyXYgMGGwzgV8U4Mu6f2',
};
const kAutoHideMinReporters = 3;
const kAutoHideScore = 8;
const kAutoHideRatio = 0.03;
const kAutoHideViralViews = 5000;
const kAutoHideViralMinRatio = 0.004;

int scoreForSeverity(String severity) {
  switch (severity) {
    case 'P1':
      return 3;
    case 'P2':
      return 2;
    default:
      return 1;
  }
}

int _audienceSize(Map<String, dynamic> data) {
  final raw = data['uniqueViewers'] ?? data['viewsCount'];
  if (raw is num && raw.toInt() > 0) return raw.toInt();
  return 0;
}

bool isModerationCleared(Map<String, dynamic>? data) {
  final mod = data?['moderation'];
  return mod is Map && mod['status']?.toString() == 'cleared';
}

bool isAutoHiddenByReports(Map<String, dynamic>? data) {
  if (data == null || isModerationCleared(data)) return false;
  final reporters = (data['reportCount'] as num?)?.toInt() ?? 0;
  final score = (data['reportScore'] as num?)?.toInt() ?? 0;
  if (reporters < kAutoHideMinReporters) return false;

  final views = _audienceSize(data);
  if (views <= 0) {
    return score >= kAutoHideScore;
  }
  final ratio = reporters / views;
  if (views > kAutoHideViralViews && ratio < kAutoHideRatio) {
    return score >= kAutoHideScore && ratio >= kAutoHideViralMinRatio;
  }
  if (ratio >= kAutoHideRatio) return true;
  return score >= kAutoHideScore && ratio >= kAutoHideViralMinRatio;
}

String autoHideReason(Map<String, dynamic>? data) {
  if (!isAutoHiddenByReports(data)) return '';
  final reporters = (data?['reportCount'] as num?)?.toInt() ?? 0;
  final score = (data?['reportScore'] as num?)?.toInt() ?? 0;
  final views = data == null ? 0 : _audienceSize(data);
  if (views > 0) {
    final pct = (reporters / views * 100).toStringAsFixed(1);
    return mainTextCurrent("تلقائي: {0} مبلّغ · نقاط {1} · {2}٪ من المشاهدين", <Object?>[reporters, score, pct]);
  }
  return mainTextCurrent("تلقائي: {0} مبلّغ · نقاط {1}", <Object?>[reporters, score]);
}

Map<String, dynamic> moderationHistoryEntry(String action) {
  return {
    'action': action,
    'by': FirebaseAuth.instance.currentUser?.uid,
    'at': Timestamp.now(),
  };
}
bool isCommunityModerator([String? uid]) {
  final id = uid ?? FirebaseAuth.instance.currentUser?.uid;
  return id != null && kModeratorIds.contains(id);
}

String _searchNorm(String s) => normalizeCommunitySearch(s);
List<String> _queryTokens(String q) => communityQueryTokens(q);
bool _allTokensIn(String haystack, List<String> tokens) => communityTokensMatch(haystack, tokens);
bool isCommunityPostRemoved(Map<String, dynamic>? data) {
  if (data == null) return false;
  if (data['status']?.toString().trim().toLowerCase() == 'removed') {
    return true;
  }
  final mod = data['moderation'];
  if (mod is Map && mod['status']?.toString() == 'removed') return true;
  return isAutoHiddenByReports(data);
}


// بصمت لمعظم النصوص العربية.
List<String> buildSearchKeywords({
  required String title,
  required String body,
  List<String> tags = const [],
  String? author,
}) {
  final parts = <String>[
    ...title.split(RegExp(r'\s+')),
    ...body.split(RegExp(r'\s+')),
    ...tags,
    if (author != null) ...author.split(RegExp(r'\s+')),
  ];
  final out = <String>{};
  for (final w in parts) {
    final t = _searchNorm(w.trim());
    if (t.length >= 2) out.add(t);
    if (out.length >= 40) break;
  }
  return out.toList();
}

class _SearchPerson {
  const _SearchPerson(
      {required this.id, required this.name, this.username, this.photoUrl});
  final String id;
  final String name;
  final String? username;
  final String? photoUrl;
}

class _ExploreItem {
  final String category;
  final String label;
  final String activity;
  final IconData icon;
  final Color color;
  const _ExploreItem(
      {required this.category, required this.label, required this.activity, required this.icon, required this.color});
}

class _AiToggleButton extends StatelessWidget {
  final bool isActive;
  final Color accent;
  final AnimationController pulse;
  final VoidCallback onTap;

  const _AiToggleButton(
      {required this.isActive, required this.accent, required this.pulse, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, child) {
          final glow = isActive ? (0.15 + pulse.value * 0.15) : 0.0;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? accent : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isActive ? [BoxShadow(color: accent.withValues(alpha: glow), blurRadius: 10)
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 15, color: isActive ? Colors.white : Colors.grey),
                if (isActive) ...[
                  const SizedBox(width: 4),
                   Text(mainText(context, "AI"), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RecentSearchRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RecentSearchRow(
      {required this.label, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.history_rounded, size: 18, color: theme.hintColor),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            GestureDetector(onTap: onDelete, child: Icon(Icons.close_rounded, size: 17, color: theme.hintColor)),
          ],
        ),
      ),
    );
  }
}

class _ExploreRow extends StatelessWidget {
  final _ExploreItem item;
  final VoidCallback onTap;

  const _ExploreRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: item.color.withValues(alpha: 0.14), shape: BoxShape.circle),
              child: Icon(item.icon, size: 18, color: item.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mainText(context, item.category), style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor)),
                  const SizedBox(height: 2),
                  Text(mainText(context, item.label), style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(mainText(context, item.activity), style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor)),
                ],
              ),
            ),
            Icon(Icons.trending_up_rounded, size: 18, color: item.color.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}


