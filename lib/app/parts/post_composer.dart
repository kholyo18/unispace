part of '../../main.dart';

enum _PostMenuAction { pin,edit, delete, share, save,download, repost, report, block, copy, pollResponses }
enum DateSelectMode { monthsOnly, multiDays, range }


enum PostItemType { text, image, video, poll, tags, }

class PostItem {
  final PostItemType type;
  final String title;
  final List<Map<String, dynamic>>? pollSlides;
  final String? mediaPath;

  final Uint8List? imageBytes;

  final List<String>? pollOptions;

  final List<PollData>? pollDataList;

  final List<String>? tags;

  PostItem({
    required this.type,
    required this.title,
    this.mediaPath,
    this.imageBytes,
    this.pollOptions,
    this.pollDataList,
    this.tags,
    this.pollSlides,
  });
}

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key, this.editingPost});
  final _Post? editingPost;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tagController = TextEditingController();
  final Map<int, bool> _savedPollAnswers = {};

  bool get _isEditing => widget.editingPost != null;

  List<String> _existingImageUrls = [];
  List<String> _existingVideoUrls = [];
  List<Map<String, dynamic>> _keptPollSlides = [];

// وسائط خاصة بالبول
  List<Uint8List> _pollImages = [];
  List<File> _pollVideos = [];
  List<VideoPlayerController> _pollVideoControllers = [];
  int _currentPollSlide = 0;
  List<_PollSlide> _pollSlides = [];


  List<String> _tags = [];
  List<PostItem> _pollItems = [];
  List<PollData> _pollDataList = [];
  List<File> _pickedVideos = [];

  List<Uint8List> _pickedImages = [];
  int _currentMediaIndex = 0;

  final List<String> _suggestedTags = const [
    'أسئلة',
    'مواد',
    'امتحانات',
    'نصائح',
    'تخصصات',
    'نقاش جامعي',
  ];
  final Map<int, dynamic> _pollAnswers = {};
  final Map<int, TextEditingController> _pollTextControllers = {};

  @override
  void initState() {
    super.initState();
    final p = widget.editingPost;
    if (p == null) return;

    _titleController.text = p.title;
    _bodyController.text = p.body;
    _tags = List<String>.from(p.tags);
    _existingImageUrls = p.imagePaths
        .map((e) => e.trim())
        .where((e) => e.startsWith('http'))
        .toList();
    _existingVideoUrls = p.videoPaths
        .map((e) => e.trim())
        .where((e) => e.startsWith('http'))
        .toList();
    _pollDataList = List<PollData>.from(p.pollDataList);
    _keptPollSlides = p.pollSlides
        .map((e) => Map<String, dynamic>.from(e)).toList();
  }

  bool _hasAnswer(PollData poll, int key) {
    if (!_pollAnswers.containsKey(key)) return false;
    final answer = _pollAnswers[key];

    if (answer is String) return answer.trim().isNotEmpty;
    if (answer is Set) return answer.isNotEmpty;
    if (answer is Map) {
      return answer.values.any((v) => v is Set && v.isNotEmpty);
    }
    if (answer is int) return true;
    if (answer is double) return true;

    // تاريخ
    if (answer is DateTime) {
      if (poll.type == PollQuestionType.date &&
          poll.dateConfig?.includeTime == true) {
        final timeKey = key + 100000;
        return _pollAnswers.containsKey(timeKey);
      }
      return true;
    }

    if (answer is TimeOfDay) return true;

    return false;
  }

  List<PollData> get _requiredQuestions {
    return _pollSlides
        .where((s) => s.type == _PollSlideType.poll)
        .map((s) => s.poll!)
        .where((p) => p.isRequired)
        .toList();
  }
  bool _isPosting = false;

  bool get _canPost {
    return _titleController.text.trim().isNotEmpty ||
        _bodyController.text.trim().isNotEmpty ||
        _pickedImages.isNotEmpty ||
        _pickedVideos.isNotEmpty ||
        _existingImageUrls.isNotEmpty ||
        _existingVideoUrls.isNotEmpty ||
        _pollDataList.isNotEmpty ||
        _keptPollSlides.isNotEmpty;
  }
  int get _mediaCount =>
      _existingImageUrls.length +
          _pickedImages.length +
          _existingVideoUrls.length +
          _pickedVideos.length;

  void _addTag(String tag) {
    final t = tag.trim();
    if (t.isEmpty || _tags.contains(t)) return;
    setState(() => _tags.add(t));
  }

  void _removeTag(String tag) => setState(() => _tags.remove(tag));

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    for (final f in files) {
      final bytes = await f.readAsBytes();
      setState(() => _pickedImages.add(bytes));
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;

    // FIX: نخزنو غير الملف — بلا VideoPlayerController، بلا initialize()
    // هادشي كان السبب فـ OOM: كل فيديو مختار كان كيحجز decoder كامل فورًا
    setState(() {
      _pickedVideos.add(File(picked.path));
    });
  }

  void _submitPost() {
    if (!_canPost || _isPosting) return;

    final items = <PostItem>[];

    final title = _titleController.text.trim();
    if (title.isNotEmpty) {
      items.add(PostItem(type: PostItemType.text, title: title));
    }

    final body = _bodyController.text.trim();
    if (body.isNotEmpty) {
      items.add(PostItem(type: PostItemType.text, title: body));
    }

    // صور المنشور العادية
    for (final img in _pickedImages) {
      items.add(PostItem(type: PostItemType.image, title: '', imageBytes: img));
    }

    // فيديوهات المنشور العادية
    for (final vid in _pickedVideos) {
      items.add(PostItem(
        type: PostItemType.video,
        title: '',
        mediaPath: vid.path,
      ));
    }

    final pollSlideItems = <Map<String, dynamic>>[];
    int pollIndex = 0;

    for (final slide in _pollSlides) {
      switch (slide.type) {
        case _PollSlideType.text:
          final t = slide.text?.trim() ?? '';
          if (t.isNotEmpty) {
            pollSlideItems.add({'type': 'text', 'text': t});
          }
          break;

        case _PollSlideType.image:
          if (slide.imageBytes != null) {
            // فقط داخل الترتيب — بدون PostItem.image
            pollSlideItems.add({
              'type': 'image',
              'imageBytes': slide.imageBytes, // مؤقتاً للرفع في _newPost
            });
          }
          break;

        case _PollSlideType.video:
          if (slide.videoFile != null) {
            pollSlideItems.add({
              'type': 'video',
              'mediaPath': slide.videoFile!.path,
            });
          }
          break;

        case _PollSlideType.poll:
          pollSlideItems.add({
            'type': 'poll',
            'pollIndex': pollIndex,
          });
          pollIndex++;
          break;
      }
    }
    final ordered = <Map<String, dynamic>>[];
    for (final slide in _pollSlides) {
      if (slide.type == _PollSlideType.text) {
        final t = slide.text?.trim() ?? '';
        if (t.isNotEmpty) ordered.add({'type': 'text', 'text': t});
      } else if (slide.type == _PollSlideType.image && slide.imageBytes != null) {
        ordered.add({'type': 'image', 'imageBytes': slide.imageBytes});
      } else if (slide.type == _PollSlideType.video && slide.videoFile != null) {
        ordered.add({'type': 'video', 'mediaPath': slide.videoFile!.path});
      } else if (slide.type == _PollSlideType.poll) {
        ordered.add({'type': 'poll', 'pollIndex': pollIndex++});
      }
    }

    if (_pollDataList.isNotEmpty || pollSlideItems.isNotEmpty) {
      items.add(PostItem(
        type: PostItemType.poll,
        title: '',
        pollDataList: List.from(_pollDataList),
        pollSlides: pollSlideItems,
      ));
    }

    if (_tags.isNotEmpty) {
      items.add(PostItem(
        type: PostItemType.tags,
        title: '',
        tags: List.from(_tags),
      ));
    }
    for (final url in _existingImageUrls) {
      items.add(PostItem(type: PostItemType.image, title: '', mediaPath: url));
    }
    for (final url in _existingVideoUrls) {
      items.add(PostItem(type: PostItemType.video, title: '', mediaPath: url));
    }

    if ((_pollDataList.isNotEmpty || _keptPollSlides.isNotEmpty) &&
        _pollSlides.isEmpty) {
      items.add(PostItem(
        type: PostItemType.poll,
        title: '',
        pollDataList: List.from(_pollDataList),
        pollSlides: List.from(_keptPollSlides),
      ));
    }
    Navigator.pop(context, items);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagController.dispose();



    // تنظيف controllers إجابات النص
    for (final c in _pollTextControllers.values) {
      c.dispose();
    }

    for (final s in _pollSlides) {
      s.videoController?.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppGuide(id: 'post', steps: const [GuideStep('post.title', 'post.title'),GuideStep('post.body', 'post.body'),GuideStep('post.images', 'post.images'),GuideStep('post.video', 'post.video'),GuideStep('post.poll', 'post.poll'),GuideStep('post.tags', 'post.tags'),GuideStep('post.publish', 'post.publish')], child: Directionality(
        textDirection: TextDirection.ltr,
        child:Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              // ===== العنوان (يسار) =====
          Expanded(child: Text(_isEditing ? mainText(context, "تعديل منشور") : 'Create a post',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              )),



              // ===== أزرار الحذف + النشر (يمين) =====
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent.withValues(alpha: 0),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:  Theme.of(context)
                                .colorScheme.onSurface.withValues(alpha: 0.2),
                      ),
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurface,fontWeight: FontWeight(30),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // ===== حاوية النشر (أزرق) =====
                  Container(
                    decoration: BoxDecoration(
                      color: _canPost
                          ? Theme.of(context).colorScheme.primary          // أزرق غامق لما فيه محتوى
                          : Colors.white,                 // أبيض لما فاضي
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _canPost
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: GuideTarget(id: 'post.publish', child: TextButton(
                      onPressed: (_canPost && !_isPosting) ? _submitPost : null,
                      style: TextButton.styleFrom(
                        foregroundColor: _canPost ? Colors.white : Colors.grey,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: _isPosting
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Text(
                        _isEditing ? mainText(context, "تعديل") : mainText(context, "Post"),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: _canPost ? Colors.white : Colors.grey,
                        ),
                      ),
                    )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ========== العنوان ==========
                  GuideTarget(id: 'post.title', child: TextField(
                    controller: _titleController,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    cursorColor: Theme.of(context).colorScheme.primary,
                    cursorWidth: 2.5,
                    decoration: InputDecoration(
                      hintText: mainText(context, "Title"),
                      hintStyle: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context)
                                .hintColor.withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      filled: false,
                    ),
                  )),

                  const SizedBox(height: 20),

// ========== النص ==========
                  GuideTarget(id: 'post.body', child: TextField(
                    controller: _bodyController,
                    onChanged: (_) => setState(() {}),
                    maxLines: null,
                    minLines: 4,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.45,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    cursorColor: Theme.of(context).colorScheme.primary,
                    decoration: InputDecoration(
                      hintText: mainText(context, "Body ...What you think of?)"),
                      hintStyle: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context)
                                .hintColor.withValues(alpha: 0.55),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      filled: false,
                    ),
                  )),

                  const SizedBox(height: 20),

                  if (widget.editingPost?.isRepost == true &&
                      widget.editingPost?.repostOf != null) ...[
                    const SizedBox(height: 12),
                    IgnorePointer(
                      child: _RepostEmbedCard(
                        data: widget.editingPost!.repostOf!,
                      ),
                    ),
                  ],
                  if (_mediaCount > 0)
                    Container(
                      height: 260,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: isDark
                            ? theme.colorScheme.surfaceContainerHighest
                            : Colors.grey.shade100,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          children: [
                            PageView.builder(
                              itemCount: _mediaCount,
                              onPageChanged: (i) => setState(() => _currentMediaIndex = i),
                              itemBuilder: (context, index) {
                                var i = index;

                                if (i < _existingImageUrls.length) {
                                  final url = _existingImageUrls[i];
                                  return Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Uri.tryParse(url)?.host == 'firebasestorage.googleapis.com'
                                          ? _AuthorizedImageView(
                                              key: ValueKey(url),
                                              postId: widget.editingPost?.id ?? '',
                                              path: url, preview: true)
                                          : ProtectedImage.network(url, fit: BoxFit.cover),
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: _closeButton(() {
                                          setState(() => _existingImageUrls.removeAt(i));
                                        }),
                                      ),
                                    ],
                                  );
                                }
                                i -= _existingImageUrls.length;

                                if (i < _pickedImages.length) {
                                  return Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.memory(_pickedImages[i], fit: BoxFit.cover),
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: _closeButton(() {
                                          setState(() => _pickedImages.removeAt(i));
                                        }),
                                      ),
                                    ],
                                  );
                                }
                                i -= _pickedImages.length;

                                if (i < _existingVideoUrls.length) {
                                  return Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      const ColoredBox(
                                        color: Colors.black87,
                                        child: Center(
                                          child: Icon(Icons.videocam, size: 48, color: Colors.white),
                                        ),
                                      ),
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: _closeButton(() {
                                          setState(() => _existingVideoUrls.removeAt(i));
                                        }),
                                      ),
                                    ],
                                  );
                                }
                                i -= _existingVideoUrls.length;

                                return _PickedVideoTile(
                                  key: ValueKey(_pickedVideos[i].path),
                                  file: _pickedVideos[i],
                                  onDelete: () {
                                    setState(
                                            () => _pickedVideos.removeAt(i));
                                  },
                                );
                              },
                            ),
                            if (_mediaCount > 1)
                              Positioned(
                                bottom: 14,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    _mediaCount,
                                        (i) => Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      width: _currentMediaIndex == i ? 9 : 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: _currentMediaIndex == i
                                            ? Colors.white
                                            : Colors.white54,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  // ========== شرائح البول ==========
                  if (_pollSlides.isNotEmpty) ...[
                    const SizedBox(height: 16),

                    // رأس
                    Row(
                      children: [
                        const Icon(Icons.poll_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          mainText(context, "Poll"),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            final oldCtrls = List<TextEditingController>.from(_pollTextControllers.values);
                            final oldVideos = _pollSlides.map((s) => s.videoController)
                                    .whereType<VideoPlayerController>()
                                    .toList();

                            setState(() {
                              _pollTextControllers.clear();
                              _pollAnswers.clear();
                              _pollSlides.clear();
                              _pollDataList.clear();
                              _pollItems.clear();
                            });

                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              for (final c in oldCtrls) {
                                c.dispose();
                              }
                              for (final v in oldVideos) {
                                v.dispose();
                              }
                            });
                          },
                          child: Icon(Icons.close, size: 20, color: theme.hintColor),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // الشرائح
                    SizedBox(
                      height: 300,
                      child: PageView.builder(
                        itemCount: _pollSlides.length + 1, // +1 لشريحة التأكيد
                        onPageChanged: (i) => setState(() => _currentPollSlide = i),
                        itemBuilder: (context, index) {
                          if (index == _pollSlides.length) {
                            return _buildSubmitSlide(theme, isDark);
                          }
                          final slide = _pollSlides[index];
                          return _buildPollSlide(slide, theme, isDark, slideIndex: index);
                        },
                      ),
                    ),

                    // نقاط الصفحات
                    if (_pollSlides.length + 1 > 1) ...[
                      const SizedBox(height: 10),
                      Center(
                        child: _SlideDotsIndicator(
                          count: _pollSlides.length + 1,
                          currentIndex: _currentPollSlide,
                        ),
                      ),
                    ],
                  ],
// ========== الوسوم ==========
                  if (_tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags
                          .map((tag) => Chip(
                        label: Text('#${mainTagText(context, tag)}'),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _removeTag(tag),
                      ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ========== الشريط السفلي (أزرار الإضافة) ==========
          Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.35),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ===== حاوية أزرار الوسائط =====
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GuideTarget(id: 'post.images', child: IconButton(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.photo_library_outlined),
                          tooltip: mainText(context, "Pictures"),
                          visualDensity: VisualDensity.compact,
                        )),
                        GuideTarget(id: 'post.video', child: IconButton(
                          onPressed: _pickVideo,
                          icon: const Icon(Icons.videocam_outlined),
                          tooltip: mainText(context, "Videos"),
                          visualDensity: VisualDensity.compact,
                        )),
                        GuideTarget(id: 'post.poll', child: IconButton(
                          onPressed: () async {
                            final result = await Navigator.push<List<PostItem>>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PollBuilderScreen(initialItems: _pollItems),
                              ),
                            );

                            if (result == null || result.isEmpty || !mounted) return;

                            // تنظيف القديم
                            for (final s in _pollSlides) {
                              s.videoController?.dispose();
                            }

                            final newSlides = <_PollSlide>[];
                            final newPollData = <PollData>[];
                            final newPollItems = <PostItem>[];

                            for (final item in result) {
                              if (item.type != PostItemType.poll) continue;

                              newPollItems.add(item);
                              final polls = item.pollDataList ?? <PollData>[];
                              newPollData.addAll(polls);

                              final maps = item.pollSlides ?? <Map<String, dynamic>>[];

                              // إن وُجدت pollSlides مرتبة — اعتمدها
                              if (maps.isNotEmpty) {
                                for (final s in maps) {
                                  final type = s['type']?.toString();

                                  if (type == 'text') {
                                    final t = s['text']?.toString().trim() ?? '';
                                    if (t.isNotEmpty) {
                                      newSlides.add(_PollSlide.text(t));
                                    }
                                  } else if (type == 'image') {
                                    final path =
                                        s['mediaPath']?.toString() ?? s['path']?.toString();
                                    Uint8List? bytes = s['imageBytes'] is Uint8List
                                        ? s['imageBytes'] as Uint8List
                                        : null;

                                    if (bytes == null && path != null && path.isNotEmpty) {
                                      try {
                                        final file = File(path);
                                        if (await file.exists()) {
                                          bytes = await file.readAsBytes();
                                        }
                                      } catch (_) {}
                                    }
                                    if (bytes != null) {
                                      newSlides.add(_PollSlide.image(bytes));
                                    }
                                  } else if (type == 'video') {
                                    final path =
                                        s['mediaPath']?.toString() ?? s['path']?.toString();
                                    if (path != null && path.isNotEmpty) {
                                      try {
                                        final file = File(path);
                                        if (await file.exists()) {
                                          final controller = VideoPlayerController.file(file)
                                            ..setLooping(true);
                                          await controller.initialize();
                                          newSlides.add(_PollSlide.video(file, controller));
                                        }
                                      } catch (_) {}
                                    }
                                  } else if (type == 'poll') {
                                    final idx = (s['pollIndex'] as num?)?.toInt() ?? 0;
                                    if (idx >= 0 && idx < polls.length) {
                                      newSlides.add(_PollSlide.poll(polls[idx]));
                                    }
                                  }
                                }
                              } else {
                                // احتياطي: أسئلة فقط بدون ترتيب وسائط
                                for (final p in polls) {
                                  newSlides.add(_PollSlide.poll(p));
                                }
                              }
                            }

                            if (!mounted) return;
                            setState(() {
                              _pollSlides = newSlides;
                              _pollItems = newPollItems;
                              _pollDataList = newPollData;
                              _currentPollSlide = 0;
                            });
                          },
                          icon: const Icon(Icons.poll_outlined),
                          tooltip: mainText(context, "استطلاع"),
                          visualDensity: VisualDensity.compact,
                        )),
                      ],
                    ),
                  ),

                  // ===== حاوية الوسم =====
                  Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: GuideTarget(id: 'post.tags', child: TextButton.icon(
                        onPressed: _showTagSheet,
                        icon: const Icon(Icons.tag, size: 20),
                        label:  Text(mainText(context, "Tags")),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                        ),
                      ))),
                ],
              ),
            ),
          ),
        ],
      ),
    )));
  }

  Widget _closeButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, size: 16, color: Colors.white),
      ),
    );
  }

  void _showTagSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: mainText(context, "أضف وسمًا..."),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      _addTag(_tagController.text);
                      _tagController.clear();
                      Navigator.pop(context);
                    },
                  ),
                ),
                onSubmitted: (v) {
                  _addTag(v);
                  _tagController.clear();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestedTags
                    .map((tag) => ActionChip(
                  label: Text(tag),
                  onPressed: () {
                    _addTag(tag);
                    Navigator.pop(context);
                  },
                ))
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPollSlide(_PollSlide slide,
      ThemeData theme,
      bool isDark, {
        required int slideIndex,
      }) {
    switch (slide.type) {
    // ===== نص =====
      case _PollSlideType.text:
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surfaceContainerHighest
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              _slideHeader(theme, isDark, Icons.text_fields, mainText(context, "Text")),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Text(
                        slide.text ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

    // ===== صورة =====
      case _PollSlideType.image:
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surfaceContainerHighest
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              _slideHeader(theme, isDark, Icons.image_outlined, mainText(context, "Image")),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(14),
                  ),
                  child: Image.memory(
                    slide.imageBytes!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            ],
          ),
        );

    // ===== فيديو =====
      case _PollSlideType.video:
        final controller = slide.videoController!;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surfaceContainerHighest
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              _slideHeader(theme, isDark, Icons.videocam_outlined, mainText(context, "Video")),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(14),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (controller.value.isInitialized)
                        FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: controller.value.size.width,
                            height: controller.value.size.height,
                            child: VideoPlayer(controller),
                          ),
                        )
                      else
                        const Center(child: CircularProgressIndicator()),
                      Center(
                        child: IconButton(
                          iconSize: 52,
                          color: Colors.white,
                          icon: Icon(
                            controller.value.isPlaying
                                ? Icons.pause_circle
                                : Icons.play_circle,
                          ),
                          onPressed: () {
                            setState(() {
                              controller.value.isPlaying
                                  ? controller.pause()
                                  : controller.play();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

    // ===== سؤال بول (الجزء 3) =====
      case _PollSlideType.poll:
        return PollQuestionSlideView(
          poll: slide.poll!,
          slideIndex: slideIndex,
          answers: _pollAnswers,
          onAnswer: (key, value) {
            setState(() => _pollAnswers[key] = value);
          },
        );
    }
  }

  Widget _slideHeader(
      ThemeData theme,
      bool isDark,
      IconData icon,
      String label,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : UniSpaceColors.lightField,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitSlide(ThemeData theme, bool isDark) {
    final allEntries = <MapEntry<int, PollData>>[];
    final requiredEntries = <MapEntry<int, PollData>>[];

    for (int i = 0; i < _pollSlides.length; i++) {
      final s = _pollSlides[i];
      if (s.type != _PollSlideType.poll || s.poll == null) continue;

      allEntries.add(MapEntry(i, s.poll!));
      if (s.poll!.isRequired) {
        requiredEntries.add(MapEntry(i, s.poll!));
      }
    }

    final totalQuestions = allEntries.length;
    final answeredCount =
        allEntries.where((e) => _hasAnswer(e.value, e.key)).length;

    final totalRequired = requiredEntries.length;
    final answeredRequired =
        requiredEntries.where((e) => _hasAnswer(e.value, e.key)).length;
    final allRequiredAnswered =
        totalRequired == 0 || answeredRequired == totalRequired;


    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 52,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            mainText(context, "Submit answers"),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            totalRequired == 0
                ? 'No required questions'
                : '$answeredRequired / $totalRequired required answered',
          ),

          Text(
            mainText(context, "{0} / {1} answered", <Object?>[(answeredCount).clamp(0, totalQuestions), totalQuestions]),
            style: TextStyle(
              fontSize: 14,
              color: theme.hintColor,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (!allRequiredAnswered) {
                    ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(
                        content: Text(mainText(context, "يجب الإجابة على جميع الأسئلة الإلزامية أولاً")),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text(mainText(context, "تم إرسال الإجابات"))),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child:  Text(
                  mainText(context, "Confirm & Submit"),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



}

class _SlideDotsIndicator extends StatefulWidget {
  const _SlideDotsIndicator({
    required this.count,
    required this.currentIndex,
    this.maxWidth = 200,
  });

  final int count;
  final int currentIndex;
  final double maxWidth;

  @override
  State<_SlideDotsIndicator> createState() => _SlideDotsIndicatorState();
}

class _SlideDotsIndicatorState extends State<_SlideDotsIndicator> {
  final ScrollController _scrollController = ScrollController();

  static const double _activeWidth = 10;
  static const double _inactiveWidth = 6;
  static const double _dotHeight = 6;
  static const double _hMargin = 3;

  double _slotWidth(int index) =>
      (index == widget.currentIndex ? _activeWidth : _inactiveWidth) + _hMargin * 2;

  double _offsetForIndex(int index) {
    double offset = 0;
    for (var i = 0; i < index; i++) {
      offset += _slotWidth(i);
    }
    return offset;
  }

  void _scrollToCurrent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target = _offsetForIndex(widget.currentIndex) -
          widget.maxWidth / 2 +
          _slotWidth(widget.currentIndex) / 2;
      final clamped = target.clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollToCurrent();
  }

  @override
  void didUpdateWidget(covariant _SlideDotsIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex || oldWidget.count != widget.count) {
      _scrollToCurrent();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 1) return const SizedBox.shrink();

    final theme = Theme.of(context);

    // احسب العرض الحقيقي لكل النقاط
    double totalDotsWidth = 0;
    for (var i = 0; i < widget.count; i++) {
      totalDotsWidth += _slotWidth(i);
    }

    // إذا كانت أقصر من maxWidth نوسّطها، وإلا نبقي العرض الأقصى مع السكرول
    final boxWidth = totalDotsWidth < widget.maxWidth
        ? totalDotsWidth
        : widget.maxWidth;

    return SizedBox(
      width: boxWidth,
      height: 5,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.count,
        itemBuilder: (context, i) {
          final active = i == widget.currentIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: _hMargin),
            width: active ? _activeWidth : _inactiveWidth,
            height: _dotHeight,
            decoration: BoxDecoration(
              color: active
                  ? theme.colorScheme.primary
                  : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(10),
            ),
          );
        },
      ),
    );
  }
}
//=======================================================================
