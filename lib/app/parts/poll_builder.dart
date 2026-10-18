part of '../../main.dart';

class PollBuilderScreen extends StatefulWidget {
  final List<PostItem>? initialItems;

  const PollBuilderScreen({
    Key? key,
    this.initialItems,
  }) : super(key: key);

  @override
  State<PollBuilderScreen> createState() => _PollBuilderScreenState();
}

class _PollBuilderScreenState extends State<PollBuilderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showFab = true;
  final List<PollQuestion> _pollQuestions = [];
  double previewSliderValue = 50;
  final List<_BuilderItem> _order = [];
  final ScrollController _scrollController = ScrollController();


  final TextEditingController titleCtrl = TextEditingController();
  final List<TextEditingController> options = [
    TextEditingController(),
    TextEditingController(),
  ];

  final List<PostBlock> _blocks = [];

  bool get _canSave {
    return _pollQuestions.isNotEmpty;
  }

  void _savePoll() {
    if (!_canSave) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "لا يمكن الحفظ بدون وجود سؤال بول"))),
      );
      return;
    }

    final pollSlideItems = <Map<String, dynamic>>[];
    final polls = <PollData>[];
    int pollIndex = 0;

    for (final item in _order) {
      if (item.isBlock && item.block != null) {
        final block = item.block!;

        if (block.type == BlockType.text) {
          final t = block.textController?.text.trim() ?? '';
          if (t.isNotEmpty) {
            pollSlideItems.add({'type': 'text', 'text': t});
          }
        }

        if (block.type == BlockType.image && block.image != null) {
          pollSlideItems.add({
            'type': 'image',
            'mediaPath': block.image!.path, // نفس مفتاح الفيديو
          });
        }

        if (block.type == BlockType.video && block.video != null) {
          pollSlideItems.add({
            'type': 'video',
            'mediaPath': block.video!.path,
          });
        }
      }

      if (item.poll != null) {
        final data = PollData.fromQuestion(item.poll!);
        debugPrint('SAVE isRequired=${data.isRequired} confirmed=${item.poll!.confirmed}');
        polls.add(data);
        pollSlideItems.add({
          'type': 'poll',
          'pollIndex': pollIndex,
        });
        pollIndex++;
      }
    }

    final result = <PostItem>[
      PostItem(
        type: PostItemType.poll,
        title: '',
        pollDataList: polls,
        pollSlides: pollSlideItems,
      ),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop(result);
    });
  }

  void _showNoPollWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:  Text(mainText(context, "لا يمكن الحفظ، أضف سؤالاً واحداً على الأقل")),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  List<DateTime> parseRangeText(String input, int year) {
    final result = <DateTime>{};
    // [شهر/يوم - شهر/يوم]  مثل [1/2-1/20] = من 2 يناير إلى 20 يناير
    final re = RegExp(r'\[(\d{1,2})/(\d{1,2})\s*-\s*(\d{1,2})/(\d{1,2})\]');
    for (final m in re.allMatches(input)) {
      final month1 = int.parse(m.group(1)!);
      final day1 = int.parse(m.group(2)!);
      final month2 = int.parse(m.group(3)!);
      final day2 = int.parse(m.group(4)!);

      if (month1 < 1 || month1 > 12 || month2 < 1 || month2 > 12) continue;

      final last1 = DateTime(year, month1 + 1, 0).day;
      final last2 = DateTime(year, month2 + 1, 0).day;

      var cur = DateTime(year, month1, day1.clamp(1, last1));
      final end = DateTime(year, month2, day2.clamp(1, last2));
      if (end.isBefore(cur)) continue;

      while (!cur.isAfter(end)) {
        result.add(DateTime(cur.year, cur.month, cur.day));
        cur = cur.add(const Duration(days: 1));
      }
    }
    return result.toList()..sort();
  }

  void _reorderOptions(PollQuestion q, int oldIndex, int newIndex) {
    setState(() {
      q.options = List<TextEditingController>.from(q.options);
      q.selectedOptions = List<bool>.from(q.selectedOptions);

      if (newIndex > oldIndex) newIndex -= 1;

      final item = q.options.removeAt(oldIndex);
      q.options.insert(newIndex, item);

      if (oldIndex < q.selectedOptions.length) {
        final sel = q.selectedOptions.removeAt(oldIndex);
        final insertAt = newIndex.clamp(0, q.selectedOptions.length);
        q.selectedOptions.insert(insertAt, sel);
      }
    });
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    if (widget.initialItems != null &&
        widget.initialItems!.isNotEmpty) {
      for (final item in widget.initialItems!) {
        switch (item.type) {
        // ==================== TEXT ====================
          case PostItemType.text:
            final block = PostBlock.text()..textController!.text = item.title;

            _blocks.add(block);

            // مهم جداً: أضفه إلى الترتيب العام
            _order.add(_BuilderItem.block(block));
            break;

        // ==================== IMAGE ====================
          case PostItemType.image:
            if (item.mediaPath != null) {
              final block = PostBlock.image()..image = File(item.mediaPath!);

              block.textController!.text = item.title;

              _blocks.add(block);

              // مهم جداً
              _order.add(_BuilderItem.block(block));
            }
            break;

        // ==================== VIDEO ====================
          case PostItemType.video:
            if (item.mediaPath != null) {
              final block = PostBlock.video()
                ..video = File(item.mediaPath!)
                ..textController!.text = item.title;

              final controller =
              VideoPlayerController.file(block.video!);

              block.videoController = controller;

              _blocks.add(block);

              // مهم جداً
              _order.add(_BuilderItem.block(block));

              controller.initialize().then((_) {
                if (!mounted) return;

                controller.setLooping(true);

                setState(() {});
              });
            }
            break;

        // ==================== POLL ====================
          case PostItemType.poll:
            final polls = item.pollDataList ?? <PollData>[];
            final slides = item.pollSlides ?? <Map<String, dynamic>>[];

            // ابنِ الأسئلة أولاً (مرجع بالفهرس)
            final questions = <PollQuestion>[];
            for (final data in polls) {
              final q = PollQuestion.fromPollData(data);
              questions.add(q);
              _pollQuestions.add(q);
            }

            if (slides.isNotEmpty) {
              // أعد الترتيب من pollSlides
              for (final s in slides) {
                final type = s['type']?.toString();

                if (type == 'text') {
                  final t = s['text']?.toString() ?? '';
                  final block = PostBlock.text()..textController!.text = t;
                  _blocks.add(block);
                  _order.add(_BuilderItem.block(block));
                } else if (type == 'image') {
                  final path =
                      s['mediaPath']?.toString() ?? s['path']?.toString();
                  if (path != null && path.isNotEmpty && File(path).existsSync()) {
                    final block = PostBlock.image()..image = File(path);
                    _blocks.add(block);
                    _order.add(_BuilderItem.block(block));
                  }
                } else if (type == 'video') {
                  final path =
                      s['mediaPath']?.toString() ?? s['path']?.toString();
                  if (path != null && path.isNotEmpty && File(path).existsSync()) {
                    final file = File(path);
                    final block = PostBlock.video()..video = file;
                    final controller = VideoPlayerController.file(file);
                    block.videoController = controller;
                    _blocks.add(block);
                    _order.add(_BuilderItem.block(block));
                    controller.initialize().then((_) {
                      if (!mounted) return;
                      controller.setLooping(true);
                      setState(() {});
                    });
                  }
                } else if (type == 'poll') {
                  final idx = (s['pollIndex'] as num?)?.toInt() ?? 0;
                  if (idx >= 0 && idx < questions.length) {
                    _order.add(_BuilderItem.poll(questions[idx]));
                  }
                }
              }
            } else {
              // احتياطي: أسئلة فقط بدون وسائط
              for (final q in questions) {
                _order.add(_BuilderItem.poll(q));
              }
            }
            break;

        // ==================== TAGS ====================
          case PostItemType.tags:
            break;
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose(); // ⬅️ مهم جدًا
    _scrollController.dispose();

    for (final q in _pollQuestions) {
      q.scaleMinCtrl.dispose();
      q.scaleMaxCtrl.dispose();
      q.questionCtrl.dispose();
      for (final c in q.options) {
        c.dispose();
      }
    }

    for (final block in _blocks) {
      block.videoController?.dispose();
      block.textController?.dispose();
      block.focusNode?.dispose();

    }
    super.dispose();
  }

  void _addTextBlock() {
    final block = PostBlock.text();
    setState(() {
      _blocks.add(block);
      _order.add(_BuilderItem.block(block));
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      block.focusNode?.requestFocus();
    });
  }

  void _addImageBlock() {
    final block = PostBlock.image();
    setState(() {
      _blocks.add(block);
      _order.add(_BuilderItem.block(block));
    });
  }

  void _moveOrder(int from, int delta) {
    final to = from + delta;
    if (to < 0 || to >= _order.length) return;
    setState(() {
      final item = _order.removeAt(from);
      _order.insert(to, item);
    });
  }

  void _deleteAtOrder(int orderIndex) {
    if (orderIndex < 0 || orderIndex >= _order.length) return;
    final item = _order[orderIndex];
    setState(() {
      _order.removeAt(orderIndex);
      if (item.block != null) {
        final b = item.block!;
        b.videoController?.dispose();
        b.textController?.dispose();
        b.focusNode?.dispose();
        _blocks.remove(b);
      } else if (item.poll != null) {
        final q = item.poll!;
        q.scaleMinCtrl.dispose();
        q.scaleMaxCtrl.dispose();
        q.questionCtrl.dispose();
        for (final c in q.options) {
          c.dispose();
        }
        _pollQuestions.remove(q);
      }
    });
  }

  void _openPollQuestionPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Text(
                    mainText(context, "choose a poll"),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _sectionLabel(mainText(context, "Text")),
                        _pollTypeTile(mainText(context, "Short text"), mainText(context, "One line answer"), PollQuestionType.shortText, Icons.short_text, Colors.blue),
                        _pollTypeTile(mainText(context, "Long text"), mainText(context, "Multi lines answer"), PollQuestionType.longText, Icons.notes, Colors.blue),

                        _sectionLabel(mainText(context, "Options")),
                        _pollTypeTile(mainText(context, "Singel option"), mainText(context, "Can choose only one answer"), PollQuestionType.singelOptin, Icons.radio_button_checked, Colors.deepPurple),
                        _pollTypeTile(mainText(context, "Checkbox"), mainText(context, "Can choose many answers"), PollQuestionType.checkbox, Icons.check_box_outlined, Colors.deepPurple),
                        _pollTypeTile(mainText(context, "Dropdowen"), mainText(context, "اChoose from the list"), PollQuestionType.dropdown, Icons.arrow_drop_down_circle_outlined, Colors.deepPurple),
                        _pollTypeTile(mainText(context, "lienear scale"), mainText(context, "Assessement on a graded scale"), PollQuestionType.linearScale, Icons.linear_scale, Colors.deepPurple),

                        _sectionLabel(mainText(context, "Grid")),
                        _pollTypeTile(mainText(context, "Grid"), mainText(context, "Row/Colams...can choose only one answer in a row"), PollQuestionType.grid, Icons.grid_view_outlined, AppTeal.main),
                        _pollTypeTile(mainText(context, "Checkbox grid"), mainText(context, "Row/Colams...can choose many answers in a row"), PollQuestionType.checkboxGrid, Icons.grid_on_outlined, AppTeal.main),

                        _sectionLabel('Date & Time'),
                        _pollTypeTile(mainText(context, "Date"), mainText(context, "Choose a day a month or a year"), PollQuestionType.date, Icons.calendar_today_outlined, Colors.orange),
                        _pollTypeTile(mainText(context, "Time"), mainText(context, "choose a specific time"), PollQuestionType.time, Icons.access_time, Colors.orange),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
          letterSpacing: 0.5,
        ),
      ),
    );
  }



  Future<void> _pickImageForBlock(PostBlock block) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        block.image = File(picked.path);
      });
    }
  }

  Future<List<DateTime>?> _pickMultiDays(
      BuildContext context, {
        required List<DateTime> initial,
        required int year,
        required List<int> months,
      }) async {
    final selected = Set<DateTime>.from(
      initial.map((d) => DateTime(d.year, d.month, d.day)),
    );

    return showDialog<List<DateTime>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title:  Text(mainText(ctx, "Select days")),
              content: SizedBox(
                width: 320,
                height: 360,
                child: CalendarDatePicker(
                  initialDate: selected.isNotEmpty
                      ? selected.first
                      : DateTime(year, months.isNotEmpty ? months.first : 1, 1),
                  firstDate: DateTime(year, 1, 1),
                  lastDate: DateTime(year, 12, 31),
                  selectableDayPredicate: (day) {
                    if (months.isEmpty) return true;
                    return months.contains(day.month);
                  },
                  onDateChanged: (day) {
                    final key = DateTime(day.year, day.month, day.day);
                    setLocal(() {
                      if (selected.contains(key)) {
                        selected.remove(key);
                      } else {
                        selected.add(key);
                      }
                    });
                  },
                ),
              ),
              // ملاحظة: CalendarDatePicker الافتراضي لا يلوّن عدة أيام.
              // للتمييز البصري استخدم table_calendar أو custom dayBuilder.
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child:  Text(mainText(ctx, "Cancel")),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pop(ctx, selected.toList()..sort()),
                  child: Text(mainText(ctx, "OK ({0})", <Object?>[selected.length])),
                ),
              ],
            );
          },
        );
      },
    );
  }
  Future<List<DateTime>?> _pickAllowedDays(
      BuildContext context, {
        required int year,
        required List<int> months,
        required List<DateTime> initial,
      }) async {
    final selected = <DateTime>{
      for (final d in initial) DateTime(d.year, d.month, d.day),
    };

    return showDialog<List<DateTime>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title:  Text(mainText(ctx, "الأيام المسموحة")),
              content: SizedBox(
                width: 320,
                height: 400,
                child: Column(
                  children: [
                    Text(
                      mainText(ctx, "اضغط يوماً لإضافته أو إزالته"),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(ctx).hintColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: CalendarDatePicker(
                        initialDate: selected.isNotEmpty
                            ? selected.first
                            : DateTime(
                          year,
                          months.isNotEmpty ? months.first : 1,
                          1,
                        ),
                        firstDate: DateTime(year, 1, 1),
                        lastDate: DateTime(year, 12, 31),
                        selectableDayPredicate: (day) {
                          if (months.isEmpty) return true;
                          return months.contains(day.month);
                        },
                        onDateChanged: (day) {
                          final key =
                          DateTime(day.year, day.month, day.day);
                          setLocal(() {
                            if (selected.contains(key)) {
                              selected.remove(key);
                            } else {
                              selected.add(key);
                            }
                          });
                        },
                      ),
                    ),
                    Text(mainText(ctx, "{0} يوم محدد", <Object?>[selected.length])),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child:  Text(mainText(ctx, "إلغاء")),
                ),
                TextButton(
                  onPressed: () {
                    final list = selected.toList()
                      ..sort((a, b) => a.compareTo(b));
                    Navigator.pop(ctx, list);
                  },
                  child:  Text(mainText(ctx, "تم")),
                ),
              ],
            );
          },
        );
      },
    );
  }
  Future<void> _openDaysPickerDialog(PollQuestion q, PollDateConfig cfg) async {
    var selected = Set<DateTime>.from(
      cfg.allowedDays.map((d) => DateTime(d.year, d.month, d.day)),
    );
    var month = selected.isNotEmpty ? selected.first.month : 1;
    final year = cfg.year;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final theme = Theme.of(ctx);
            final daysInMonth = DateTime(year, month + 1, 0).day;
            final firstWeekday = DateTime(year, month, 1).weekday % 7;

            bool isSel(int day) => selected.any(
                  (d) => d.year == year && d.month == month && d.day == day,
            );

            void toggle(int day) {
              final key = DateTime(year, month, day);
              setLocal(() {
                if (selected.contains(key)) {
                  selected.remove(key);
                } else {
                  selected.add(key);
                }
              });
            }

            return AlertDialog(
              title:  Text(mainText(ctx, "تحديد الأيام")),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: month > 1
                              ? () => setLocal(() => month--)
                              : null,
                        ),
                        Text(
                          DateFormat.yMMM(Localizations.localeOf(context).languageCode).format(DateTime(year, month)),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: month < 12
                              ? () => setLocal(() => month++)
                              : null,
                        ),
                      ],
                    ),
                    Row(
                      children: DateFormat.E(Localizations.localeOf(context).languageCode).dateSymbols.NARROWWEEKDAYS
                          .map((e) => Expanded(
                        child: Center(
                          child: Text(e,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: theme.hintColor)),
                        ),
                      ))
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                      ),
                      itemCount: firstWeekday + daysInMonth,
                      itemBuilder: (_, index) {
                        if (index < firstWeekday) {
                          return const SizedBox.shrink();
                        }
                        final day = index - firstWeekday + 1;
                        final sel = isSel(day);
                        return GestureDetector(
                          onTap: () => toggle(day),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: sel
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              border: Border.all(
                                color: sel
                                    ? theme.colorScheme.primary
                                    : theme.dividerColor
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              '$day',
                              style: TextStyle(
                                fontWeight:
                                sel ? FontWeight.w800 : FontWeight.w500,
                                color: sel
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mainText(ctx, "{0} يوم محدد", <Object?>[selected.length]),
                      style: TextStyle(fontSize: 12, color: theme.hintColor),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child:  Text(mainText(ctx, "إلغاء")),
                ),
                TextButton(
                  onPressed: () {
                    final list = selected.toList()..sort();
                    setState(() {
                      q.dateConfig = PollDateConfig(
                        year: year,
                        months: const [],
                        allowedDays: list,
                        multiSelect: cfg.multiSelect,
                        includeTime: q.includeTime,
                        rangesText: '',
                      );
                    });
                    Navigator.pop(ctx);
                  },
                  child:  Text(mainText(ctx, "تم")),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDaysToggleCalendar({
    required int year,
    required List<DateTime> selected,
    required ValueChanged<List<DateTime>> onChanged,
  }) {
    final theme = Theme.of(context);
    // شهر العرض: من أول يوم محدد أو يناير
    final focusMonth = selected.isNotEmpty
        ? DateTime(selected.first.year, selected.first.month)
        : DateTime(year, 1);

    return _DaysToggleCalendar(
      year: year,
      initialMonth: focusMonth.month,
      selected: selected,
      onChanged: onChanged,
      theme: theme,
    );
  }
  Widget _pollTypeTile(String title, String subtitle, PollQuestionType type, IconData icon, Color color) {
    bool isPressed = false;
    return StatefulBuilder(
      builder: (context, setInnerState) {
        return GestureDetector(
          onTapDown: (_) => setInnerState(() => isPressed = true),
          onTapCancel: () => setInnerState(() => isPressed = false),
          onTap: () {
            setInnerState(() => isPressed = true);
            Future.delayed(const Duration(milliseconds: 35), () {
              Navigator.pop(context);
              final q = PollQuestion(type);
              setState(() {
                _pollQuestions.add(q);
                _order.add(_BuilderItem.poll(q));
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                  );
                }
              });
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isPressed
                  ? color.withValues(alpha: 0.12)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isPressed
                    ? color
                    : Theme.of(context)
                        .colorScheme.onSurface.withValues(alpha: 0.08),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_left,
                  size: 20,
                  color: Theme.of(context)
                      .colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _fabIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
          message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onSurface,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppGuide(id: 'poll', steps: const [GuideStep('poll.add', 'poll.add'),GuideStep('poll.elements', 'poll.elements'),GuideStep('poll.save', 'poll.save')], child: Directionality(
        textDirection: TextDirection.ltr,
        child:Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          mainText(context, "Create a Poll"),
          style:TextStyle(fontSize: 17,
          fontWeight: FontWeight.w800,
              ),
            ),

        actions: [
      Container(
        height: 40,
      decoration: BoxDecoration(
      color: _canSave
        ? Colors.blue.shade700          // أزرق غامق لما فيه محتوى
            : Colors.white,                 // أبيض لما فاضي
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _canSave
              ? Colors.blue.shade700
              : Colors.grey.shade300,
        ),
      ),
      child: GuideTarget(id: 'poll.save', child: TextButton(
              onPressed: (_canSave) ? _savePoll : _showNoPollWarning,
              style: TextButton.styleFrom(
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              child: Text(mainText(context, "Save"),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: _canSave ? Colors.white : Colors.grey,
                    ),
                  ),
                )),
          ),
        ],
      ),
      floatingActionButton: _showFab
          ? Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context)
                        .colorScheme.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color:Theme.of(context).colorScheme.onSurface ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context)
                            .colorScheme.onSurface.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GuideTarget(id: 'poll.add', child: _fabIcon(
              icon: Icons.add_circle_outline,
               tooltip: mainText(context, "Poll"),
              onTap: _openPollQuestionPicker,
            )),
            GuideTarget(id: 'poll.elements', child: _fabIcon(
              icon: Icons.text_fields,
               tooltip: mainText(context, "Text"),
              onTap: _addTextBlock,
            )),
            _fabIcon(
              icon: Icons.add_photo_alternate_outlined,
               tooltip: mainText(context, "Picturs"),
              onTap: _addImageBlock,
            ),
            _fabIcon(
              icon: Icons.video_collection,
              tooltip: mainText(context, "Vedios"),
                onTap: () async {
                  final newBlock = PostBlock.video();
                  setState(() {
                    _blocks.add(newBlock);
                    _order.add(_BuilderItem.block(newBlock));
                  });

                  final picked = await ImagePicker()
                                .pickVideo(source: ImageSource.gallery);
                  if (picked != null) {
                    final file = File(picked.path);
                    final controller = VideoPlayerController.file(file);
                    await controller.initialize();
                    controller.setLooping(true);
                    setState(() {
                      newBlock.video = file;
                      newBlock.videoController = controller;
                    });

                // وضع التركيز على البلوك الأخير (اختياري)
                Future.delayed(const Duration(milliseconds: 100), () {
                  newBlock.focusNode?.requestFocus();
                              });
                            }
                          }),
                    ],
        ),
      )
          : null,
      body: _buildProperties(),
    )));
  }

  Widget _buildProperties() {
      return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListView.builder(
        controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _order.length,
      itemBuilder: (context, orderIndex) {
      final item = _order[orderIndex];
      final theme = Theme.of(context);

      // ---------- سؤال بول ----------
      if (!item.isBlock) {
      final q = item.poll!;
      final pollIndex = _pollQuestions.indexOf(q);
      return Container(
      key: ValueKey('poll_${q.hashCode}'),
      margin: const EdgeInsets.only(bottom: 16),
      child: _buildPollQuestionCard(
      q,
      pollIndex,
      orderIndex: orderIndex, // مرّره إن عدّلت التوقيع
      ),
      );
      }

      // ---------- بلوك ----------
      final block = item.block!;

      if (block.type == BlockType.text) {
      return Padding(
      key: ValueKey(block),
      padding: const EdgeInsets.only(bottom: 16),
      child: GoogleFormQuestionCard(
      typeLabel: mainText(context, "Text"),
      typeIcon: Icons.text_fields,
      questionField: null,
      onDelete: () => _deleteAtOrder(orderIndex),
      onMoveUp: () => _moveOrder(orderIndex, -1),
      onMoveDown: () => _moveOrder(orderIndex, 1),
      canMoveUp: orderIndex > 0,
      canMoveDown: orderIndex < _order.length - 1,
      body: TextField(
      controller: block.textController,
      focusNode: block.focusNode,
      maxLines: null,
      minLines: 5,
      style: TextStyle(
      fontSize: 16,
      height: 1.5,
      color: theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
      hintText: mainText(context, "Write your text..."),
      hintStyle: TextStyle(
      color: theme.hintColor.withValues(alpha: 0.55),
      ),
      border: InputBorder.none,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      ),
      ),
      ),
      );
      }

      if (block.type == BlockType.image) {
      return Padding(
      key: ValueKey(block),
      padding: const EdgeInsets.only(bottom: 16),
      child: GoogleFormQuestionCard(
      typeLabel: mainText(context, "Image"),
      typeIcon: Icons.image_outlined,
      questionField: null,
      onDelete: () => _deleteAtOrder(orderIndex),
      onMoveUp: () => _moveOrder(orderIndex, -1),
      onMoveDown: () => _moveOrder(orderIndex, 1),
      canMoveUp: orderIndex > 0,
      canMoveDown: orderIndex < _order.length - 1,
      body: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: GestureDetector(
                    onTap: () {
                      if (block.image != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullscreenImageViewer(
                              images: [block.image!.path],
                              initialIndex: 0,
                            ),
                          ),
                        );
                      } else {
                        _pickImageForBlock(block);
                      }
                    },
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.3),
                        ),
                        image: block.image != null
                            ? DecorationImage(
                          image: FileImage(block.image!),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: block.image == null
                          ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 36,
                              color: theme.hintColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              mainText(context, "Add image"),
                              style: TextStyle(color: theme.hintColor),
                            ),
                          ],
                        ),
                      )
                          : null,
                    ),
                  ),
                ),
              ),
            );
          }

      if (block.type == BlockType.video) {
      return Padding(
      key: ValueKey(block),
      padding: const EdgeInsets.only(bottom: 16),
      child: GoogleFormQuestionCard(
      typeLabel: mainText(context, "Video"),
      typeIcon: Icons.videocam_outlined,
      questionField: null,
      onDelete: () => _deleteAtOrder(orderIndex),
      onMoveUp: () => _moveOrder(orderIndex, -1),
      onMoveDown: () => _moveOrder(orderIndex, 1),
      canMoveUp: orderIndex > 0,
      canMoveDown: orderIndex < _order.length - 1,
      body: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: block.videoController == null
                      ? Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                      : Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullscreenVideoViewer(
                                controller: block.videoController!,
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 180,
                            width: double.infinity,
                            color: Colors.black,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (block.videoController!.value.isInitialized)
                                  FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      width: block.videoController!.value.size.width,
                                      height: block.videoController!.value.size.height,
                                      child: VideoPlayer(block.videoController!),
                                    ),
                                  ),
                                IconButton(
                                  iconSize: 52,
                                  color: Colors.white,
                                  icon: Icon(
                                    block.videoController!.value.isPlaying
                                        ? Icons.pause_circle
                                        : Icons.play_circle,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      block.videoController!.value.isPlaying
                                          ? block.videoController!.pause()
                                          : block.videoController!.play();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 6,
                        child: VideoProgressIndicator(
                          block.videoController!,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Colors.red,
                            bufferedColor: Colors.white38,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPollQuestionCard(PollQuestion q, int pollIndex, {
    required int orderIndex, }) {
    final theme = Theme.of(context);
    final orderIndex = _order.indexWhere((e) => e.poll == q);

    // حقل السؤال المشترك
    final questionField = TextField(
      controller: q.questionCtrl,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: mainText(context, "Question"),
        hintStyle: TextStyle(
          color: theme.hintColor.withValues(alpha: 0.6),
          fontSize: 16,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
    );

    // أزرار مشتركة
    void duplicate() {
      setState(() {
        final copy = PollQuestion.fromPollData(PollData.fromQuestion(q));
        final insertAt = orderIndex + 1;
        _pollQuestions.insert(pollIndex + 1, copy);
        _order.insert(insertAt, _BuilderItem.poll(copy));
      });
    }

    void delete() => _deleteAtOrder(orderIndex);

    switch (q.type) {
    // ==================== Short Answer ====================
      case PollQuestionType.shortText:
        return GoogleFormQuestionCard(
          typeLabel: mainText(context, "Short answer"),
          typeIcon: Icons.short_text,
          questionField: questionField,
          isRequired: q.confirmed,
          onRequiredChanged: (v) => setState(() => q.confirmed = v),
          onDuplicate: duplicate,
          onDelete: delete,
          body: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              mainText(context, "Short answer text"),
              style: TextStyle(
                color: theme.hintColor.withValues(alpha: 0.45),
                fontSize: 14,
              ),
            ),
          ),
          onMoveUp: () => _moveOrder(orderIndex, -1),
          onMoveDown: () => _moveOrder(orderIndex, 1),
          canMoveUp: orderIndex > 0,
          canMoveDown: orderIndex >= 0 && orderIndex < _order.length - 1,
        );

    // ==================== Paragraph ====================
      case PollQuestionType.longText:
        return GoogleFormQuestionCard(
          typeLabel: mainText(context, "Paragraph"),
          typeIcon: Icons.notes,
          questionField: questionField,
          isRequired: q.confirmed,
          onRequiredChanged: (v) => setState(() => q.confirmed = v),
          onDuplicate: duplicate,
          onDelete: delete,
          body: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              mainText(context, "Long answer text"),
              style: TextStyle(
                color: theme.hintColor.withValues(alpha: 0.45),
                fontSize: 14,
              ),
            ),
          ),
          onMoveUp: () => _moveOrder(orderIndex, -1),
          onMoveDown: () => _moveOrder(orderIndex, 1),
          canMoveUp: orderIndex > 0,
          canMoveDown: orderIndex >= 0 && orderIndex < _order.length - 1,
        );

    // ==================== Dropdown ====================
      case PollQuestionType.dropdown:
        return GoogleFormQuestionCard(
          typeLabel: mainText(context, "Dropdown"),
          typeIcon: Icons.arrow_drop_down_circle_outlined,
          questionField: questionField,
          isRequired: q.confirmed,
          onRequiredChanged: (v) => setState(() => q.confirmed = v),
          onDuplicate: duplicate,
          onDelete: delete,
          body:AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Column(
             key: ValueKey('opts_${q.options.length}_${identityHashCode(q)}'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: q.options.length,
                onReorder: (oldIndex, newIndex) => _reorderOptions(q, oldIndex, newIndex),
                proxyDecorator: (child, index, animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, _) {
                      final t = Curves.easeOut.transform(animation.value);
                      return Transform.scale(
                        scale: 1.0 + (0.04 * t),
                        child: Material(
                          elevation: 6 * t,
                          shadowColor: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context).colorScheme.surface,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            child: child,
                          ),
                        ),
                      );
                    },
                  );
                },
                itemBuilder: (context, i) {
                  return Container(
                    key: ValueKey(q.options[i]),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

                    child: Row(
                      children: [
                            ReorderableDragStartListener(
                          index: i,
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.drag_indicator, size: 22, color: Colors.grey),
                          ),
                        ),
                        Text(
                          '${i + 1}.',
                          style: TextStyle(color: theme.hintColor, fontSize: 14),
                        ),
                        const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: q.options[i],
                                decoration: InputDecoration(
                                  hintText: mainText(context, "Option"),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  hintStyle: TextStyle(
                                    color: theme.hintColor.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),
                        IconButton(
                          icon: Icon(Icons.close, size: 18, color: theme.hintColor),
                          onPressed: () {
                            setState(() {
                              q.options = List<TextEditingController>.from(q.options);
                              q.selectedOptions = List<bool>.from(q.selectedOptions);

                              q.options[i].dispose();
                              q.options.removeAt(i);
                              if (i < q.selectedOptions.length) {
                                q.selectedOptions.removeAt(i);
                              }
                            });
                          },
                        ),

                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    // حوّلها إلى قائمة قابلة للتمدد إن لزم
                    q.options = List<TextEditingController>.from(q.options);
                    q.selectedOptions = List<bool>.from(q.selectedOptions);

                    q.options.add(TextEditingController());
                    q.selectedOptions.add(false);
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label:  Text(mainText(context, "Add choice")),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          )),
            onMoveUp: () => _moveOrder(orderIndex, -1),
            onMoveDown: () => _moveOrder(orderIndex, 1),
            canMoveUp: orderIndex > 0,
            canMoveDown: orderIndex >= 0 && orderIndex < _order.length - 1,
        );

// ==================== Singel optin ====================
      case PollQuestionType.singelOptin:
        return GoogleFormQuestionCard(
          typeLabel: mainText(context, "Singel optin"),
          typeIcon: Icons.radio_button_checked,
          questionField: questionField,
          isRequired: q.confirmed,
          onRequiredChanged: (v) => setState(() => q.confirmed = v),
          onDuplicate: duplicate,
          onDelete: delete,
          body:AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child:  Column(
            key: ValueKey('opts_${q.options.length}_${q.hashCode}'), // ← مهم جداً
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: q.options.length,
                onReorder: (oldIndex, newIndex) => _reorderOptions(q, oldIndex, newIndex),
                proxyDecorator: (child, index, animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, _) {
                      final t = Curves.easeOut.transform(animation.value);
                      return Transform.scale(
                        scale: 1.0 + (0.04 * t),
                        child: Material(
                          elevation: 6 * t,
                          shadowColor: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context).colorScheme.surface,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            child: child,
                          ),
                        ),
                      );
                    },
                  );
                },
                itemBuilder: (context, i) {
                  return Container(
                    key: ValueKey(q.options[i]),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: i,
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.drag_indicator, size: 22, color: Colors.grey),
                          ),
                        ),
                        Icon(Icons.circle_outlined, size: 20, color: theme.hintColor),
                        const SizedBox(width: 5,
                            ),
                            Expanded(
                          child: TextField(
                            controller: q.options[i],
                            decoration: InputDecoration(
                              hintText: mainText(context, "Option"),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              hintStyle: TextStyle(
                                color: theme.hintColor.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 18, color: theme.hintColor),
                          onPressed: () {
                            setState(() {
                              q.options = List<TextEditingController>.from(q.options);
                              q.selectedOptions = List<bool>.from(q.selectedOptions);

                              q.options[i].dispose();
                              q.options.removeAt(i);
                              if (i < q.selectedOptions.length) {
                                q.selectedOptions.removeAt(i);
                              }
                            });
                          },
                        ),

                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    // حوّلها إلى قائمة قابلة للتمدد إن لزم
                    q.options = List<TextEditingController>.from(q.options);
                    q.selectedOptions = List<bool>.from(q.selectedOptions);

                    q.options.add(TextEditingController());
                    q.selectedOptions.add(false);
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label:  Text(mainText(context, "Add choice")),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          )),
          onMoveUp: () => _moveOrder(orderIndex, -1),
          onMoveDown: () => _moveOrder(orderIndex, 1),
          canMoveUp: orderIndex > 0,
          canMoveDown: orderIndex >= 0 && orderIndex < _order.length - 1,
        );

// ==================== Checkbox ====================
      case PollQuestionType.checkbox:
        return GoogleFormQuestionCard(
          typeLabel: mainText(context, "Checkboxes"),
          typeIcon: Icons.check_box_outlined,
          questionField: questionField,
          isRequired: q.confirmed,
          onRequiredChanged: (v) => setState(() => q.confirmed = v),
          onDuplicate: duplicate,
          onDelete: delete,
          body:AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Column(
            key: ValueKey('opts_${q.options.length}_${q.hashCode}'), // ← مهم جداً
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: q.options.length,
                onReorder: (oldIndex, newIndex) => _reorderOptions(q, oldIndex, newIndex),
                proxyDecorator: (child, index, animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, _) {
                      final t = Curves.easeOut.transform(animation.value);
                      return Transform.scale(
                        scale: 1.0 + (0.04 * t),
                        child: Material(
                          elevation: 6 * t,
                          shadowColor: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context).colorScheme.surface,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            child: child,
                          ),
                        ),
                      );
                    },
                  );
                },
                itemBuilder: (context, i) {
                  return Container(
                    key: ValueKey(q.options[i]),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: i,
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.drag_indicator, size: 22, color: Colors.grey),
                          ),
                        ),
                        Icon(Icons.check_box_outline_blank, size: 20, color: theme.hintColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: q.options[i],
                            decoration: InputDecoration(
                              hintText: mainText(context, "Option"),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              hintStyle: TextStyle(
                                color: theme.hintColor.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),

                        IconButton(
                          icon: Icon(Icons.close, size: 18, color: theme.hintColor),
                          onPressed: () {
                            setState(() {
                              q.options = List<TextEditingController>.from(q.options);
                              q.selectedOptions = List<bool>.from(q.selectedOptions);

                              q.options[i].dispose();
                              q.options.removeAt(i);
                              if (i < q.selectedOptions.length) {
                                q.selectedOptions.removeAt(i);
                              }
                            });
                          },
                        ),

                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    // حوّلها إلى قائمة قابلة للتمدد إن لزم
                    q.options = List<TextEditingController>.from(q.options);
                    q.selectedOptions = List<bool>.from(q.selectedOptions);

                    q.options.add(TextEditingController());
                    q.selectedOptions.add(false);
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label:  Text(mainText(context, "Add choice")),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          )),
          onMoveUp: () => _moveOrder(orderIndex, -1),
          onMoveDown: () => _moveOrder(orderIndex, 1),
          canMoveUp: orderIndex > 0,
          canMoveDown: orderIndex >= 0 && orderIndex < _order.length - 1,
        );

    // ==================== Singel optin Grid ====================
    case PollQuestionType.grid:
    return GoogleFormQuestionCard(
    typeLabel: mainText(context, "Singel optin grid"),
    typeIcon: Icons.grid_on_outlined,
    questionField: questionField,
    isRequired: q.confirmed,
    onRequiredChanged: (v) => setState(() => q.confirmed = v),
    onDuplicate: duplicate,
    onDelete: delete,
    body: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    // ===== Rows =====
    Text(mainText(context, "Rows"), style: TextStyle(color: theme.hintColor, fontSize: 13)),
    const SizedBox(height: 6),
    ReorderableListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: q.gridRows.length,
    onReorder: (oldIndex, newIndex) {
    setState(() {
    if (newIndex > oldIndex) newIndex--;
    final item = q.gridRows.removeAt(oldIndex);
    q.gridRows.insert(newIndex, item);
    q.initGrid();
    });
    },
    itemBuilder: (context, i) {
    return Padding(
    key: ValueKey('grid_row_$i${q.gridRows[i]}'),
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
    children: [
    Text('${i + 1}.', style: TextStyle(color: theme.hintColor)),
    const SizedBox(width: 8),
    Expanded(
    child: TextField(
    controller: TextEditingController(text: q.gridRows[i]),
    onChanged: (v) {
    q.gridRows[i] = v;
    },
    decoration: InputDecoration(
    hintText: mainText(context, "Row option"),
    border: InputBorder.none,
    isDense: true,
    contentPadding: EdgeInsets.zero,
    hintStyle: TextStyle(
    color: theme.hintColor.withValues(alpha: 0.5),
    ),
    ),
    ),
    ),
    IconButton(
    icon: Icon(Icons.close, size: 18, color: theme.hintColor),
    onPressed: () {
    setState(() {
    q.gridRows.removeAt(i);
    q.initGrid();
    });
    },
    ),
    const Icon(Icons.drag_handle, size: 20, color: Colors.grey),
    ],
    ),
    );
    },
    ),
    TextButton(
    onPressed: () {
    setState(() {
    q.gridRows.add('');
    q.initGrid();
    });
    },
    style: TextButton.styleFrom(
    foregroundColor: theme.colorScheme.primary,
    padding: EdgeInsets.zero,
    minimumSize: Size.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child:  Text(mainText(context, "Add row")),
    ),

    const SizedBox(height: 16),

    // ===== Columns =====
    Text(mainText(context, "Columns"), style: TextStyle(color: theme.hintColor, fontSize: 13)),
    const SizedBox(height: 6),
    ReorderableListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: q.gridColumns.length,
    onReorder: (oldIndex, newIndex) {
    setState(() {
    if (newIndex > oldIndex) newIndex--;
    final item = q.gridColumns.removeAt(oldIndex);
    q.gridColumns.insert(newIndex, item);
    q.initGrid();
    });
    },
    itemBuilder: (context, i) {
    return Padding(
    key: ValueKey('grid_col_$i${q.gridColumns[i]}'),
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
    children: [
    Text('${i + 1}.', style: TextStyle(color: theme.hintColor)),
    const SizedBox(width: 8),
    Expanded(
    child: TextField(
    controller: TextEditingController(text: q.gridColumns[i]),
    onChanged: (v) {
    q.gridColumns[i] = v;
    },
    decoration: InputDecoration(
    hintText: mainText(context, "Column option"),
    border: InputBorder.none,
    isDense: true,
    contentPadding: EdgeInsets.zero,
    hintStyle: TextStyle(
    color: theme.hintColor.withValues(alpha: 0.5),
    ),
    ),
    ),
    ),
    IconButton(
    icon: Icon(Icons.close, size: 18, color: theme.hintColor),
    onPressed: () {
    setState(() {
    q.gridColumns.removeAt(i);
    q.initGrid();
    });
    },
    ),
    const Icon(Icons.drag_handle, size: 20, color: Colors.grey),
    ],
    ),
    );
    },
    ),
    TextButton(
    onPressed: () {
    setState(() {
    q.gridColumns.add('');
    q.initGrid();
    });
    },
    style: TextButton.styleFrom(
    foregroundColor: theme.colorScheme.primary,
    padding: EdgeInsets.zero,
    minimumSize: Size.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child:  Text(mainText(context, "Add column")),
    ),
    ],
    ),
      onMoveUp: () => _moveOrder(orderIndex, -1),
      onMoveDown: () => _moveOrder(orderIndex, 1),
      canMoveUp: orderIndex > 0,
      canMoveDown: orderIndex >= 0 && orderIndex < _order.length - 1,
    );

// ==================== Checkbox Grid ====================
    case PollQuestionType.checkboxGrid:
    return GoogleFormQuestionCard(
    typeLabel: mainText(context, "Checkbox grid"),
    typeIcon: Icons.grid_view,
    questionField: questionField,
    isRequired: q.confirmed,
    onRequiredChanged: (v) => setState(() => q.confirmed = v),
    onDuplicate: duplicate,
    onDelete: delete,
    body: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    // ===== Rows =====
    Text(mainText(context, "Rows"), style: TextStyle(color: theme.hintColor, fontSize: 13)),
    const SizedBox(height: 6),
    ReorderableListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: q.gridRows.length,
    onReorder: (oldIndex, newIndex) {
    setState(() {
    if (newIndex > oldIndex) newIndex--;
    final item = q.gridRows.removeAt(oldIndex);
    q.gridRows.insert(newIndex, item);
    q.initGrid();
    });
    },
    itemBuilder: (context, i) {
    return Padding(
    key: ValueKey('cb_row_$i${q.gridRows[i]}'),
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
    children: [
    Text('${i + 1}.', style: TextStyle(color: theme.hintColor)),
    const SizedBox(width: 8),
    Expanded(
    child: TextField(
    controller: TextEditingController(text: q.gridRows[i]),
    onChanged: (v) {
    q.gridRows[i] = v;
    },
    decoration: InputDecoration(
    hintText: mainText(context, "Row option"),
    border: InputBorder.none,
    isDense: true,
    contentPadding: EdgeInsets.zero,
    hintStyle: TextStyle(
    color: theme.hintColor.withValues(alpha: 0.5),
    ),
    ),
    ),
    ),
    IconButton(
    icon: Icon(Icons.close, size: 18, color: theme.hintColor),
    onPressed: () {
    setState(() {
    q.gridRows.removeAt(i);
    q.initGrid();
    });
    },
    ),
    const Icon(Icons.drag_handle, size: 20, color: Colors.grey),
    ],
    ),
    );
    },
    ),
    TextButton(
    onPressed: () {
    setState(() {
    q.gridRows.add('');
    q.initGrid();
    });
    },
    style: TextButton.styleFrom(
    foregroundColor: theme.colorScheme.primary,
    padding: EdgeInsets.zero,
    minimumSize: Size.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child:  Text(mainText(context, "Add row")),
    ),

    const SizedBox(height: 16),

    // ===== Columns =====
    Text(mainText(context, "Columns"), style: TextStyle(color: theme.hintColor, fontSize: 13)),
    const SizedBox(height: 6),
    ReorderableListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: q.gridColumns.length,
    onReorder: (oldIndex, newIndex) {
    setState(() {
    if (newIndex > oldIndex) newIndex--;
    final item = q.gridColumns.removeAt(oldIndex);
    q.gridColumns.insert(newIndex, item);
    q.initGrid();
    });
    },
    itemBuilder: (context, i) {
    return Padding(
    key: ValueKey('cb_col_$i${q.gridColumns[i]}'),
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
    children: [
    Text('${i + 1}.', style: TextStyle(color: theme.hintColor)),
    const SizedBox(width: 8),
    Expanded(
    child: TextField(
    controller: TextEditingController(text: q.gridColumns[i]),
    onChanged: (v) {
    q.gridColumns[i] = v;
    },
    decoration: InputDecoration(
    hintText: mainText(context, "Column option"),
    border: InputBorder.none,
    isDense: true,
    contentPadding: EdgeInsets.zero,
    hintStyle: TextStyle(
    color: theme.hintColor.withValues(alpha: 0.5),
    ),
    ),
    ),
    ),
    IconButton(
    icon: Icon(Icons.close, size: 18, color: theme.hintColor),
    onPressed: () {
    setState(() {
    q.gridColumns.removeAt(i);
    q.initGrid();
    });
    },
    ),
    const Icon(Icons.drag_handle, size: 20, color: Colors.grey),
    ],
    ),
    );
    },
    ),
    TextButton(
    onPressed: () {
    setState(() {
    q.gridColumns.add('');
    q.initGrid();
    });
    },
    style: TextButton.styleFrom(
    foregroundColor: theme.colorScheme.primary,
    padding: EdgeInsets.zero,
    minimumSize: Size.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child:  Text(mainText(context, "Add column")),
    ),
    ],
    ),
      onMoveUp: () => _moveOrder(orderIndex, -1),
      onMoveDown: () => _moveOrder(orderIndex, 1),
      canMoveUp: orderIndex > 0,
      canMoveDown: orderIndex >= 0 && orderIndex < _order.length - 1,
    );

    // ==================== Linear Scale ====================
      case PollQuestionType.linearScale:
        return GoogleFormQuestionCard(
          typeLabel: mainText(context, "Linear scale"),
          typeIcon: Icons.linear_scale,
          questionField: questionField,
          isRequired: q.confirmed,
          onRequiredChanged: (v) => setState(() => q.confirmed = v),
          onDuplicate: duplicate,
          onDelete: delete,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ===== اختيار الشكل =====
              Text(mainText(context, "Style"), style: TextStyle(color: theme.hintColor, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    label:  Text(mainText(context, "Numbers")),
                    selected: q.scaleStyle == LinearScaleStyle.numbers,
                    onSelected: (_) =>
                        setState(() => q.scaleStyle = LinearScaleStyle.numbers),
                  ),
                  ChoiceChip(
                    label:  Text(mainText(context, "Line")),
                    selected: q.scaleStyle == LinearScaleStyle.line,
                    onSelected: (_) =>
                        setState(() => q.scaleStyle = LinearScaleStyle.line),
                  ),
                  ChoiceChip(
                    label:  Text(mainText(context, "Stars")),
                    selected: q.scaleStyle == LinearScaleStyle.stars,
                    onSelected: (_) =>
                        setState(() => q.scaleStyle = LinearScaleStyle.stars),
                  ),
                  ChoiceChip(
                    label:  Text(mainText(context, "Slider")),
                    selected: q.scaleStyle == LinearScaleStyle.slider,
                    onSelected: (_) =>
                        setState(() => q.scaleStyle = LinearScaleStyle.slider),
                  ),
                  ChoiceChip(
                    label:  Text(mainText(context, "Emoji")),
                    selected: q.scaleStyle == LinearScaleStyle.emoji,
                    onSelected: (_) =>
                        setState(() => q.scaleStyle = LinearScaleStyle.emoji),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ===== عدد المستويات =====
    if (q.scaleStyle != LinearScaleStyle.slider) ...[
              Row(
                children: [
                  Text(mainText(context, "Levels"), style: TextStyle(color: theme.hintColor)),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: q.scaleSize,
                    items: List.generate(9, (i) {
                      final val = i + 2; // 2 → 10
                      return DropdownMenuItem(value: val, child: Text('$val'));
                    }),
                    onChanged: (v) {
                      if (v != null) setState(() => q.scaleSize = v);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
              // ===== تسمية أقل / أعلى قيمة =====
              Text(mainText(context, "Labels"), style: TextStyle(color: theme.hintColor, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: q.scaleMinCtrl,
                      decoration: InputDecoration(
                        hintText: mainText(context, "Min label"),
                        labelText: 'Min',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: q.scaleMaxCtrl,
                      decoration: InputDecoration(
                        hintText: mainText(context, "Max label"),
                        labelText: 'Max',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ===== معاينة =====
              Text(mainText(context, "Preview"), style: TextStyle(color: theme.hintColor, fontSize: 13)),
              const SizedBox(height: 8),
              _buildScalePreview(q, theme),
            ],
          ),
          onMoveUp: () => _moveOrder(orderIndex, -1),
          onMoveDown: () => _moveOrder(orderIndex, 1),
          canMoveUp: orderIndex > 0,
          canMoveDown: orderIndex >= 0 && orderIndex < _order.length - 1,
        );

    // ==================== Date ====================
      case PollQuestionType.date:
        final cfg = q.dateConfig;
        final isRestricted = cfg != null;

        // وضع التقييد المحلي
        DateRestrictMode mode;
        if (!isRestricted) {
          mode = DateRestrictMode.months; // غير مستخدم في الواجهة
        } else if ((cfg!.rangesText?.trim().isNotEmpty ?? false)) {
          // أي نص مجال → Ranges
          mode = DateRestrictMode.ranges;
        } else if (cfg.months.isEmpty) {
          // months فارغة + ranges فارغ → Days (حتى لو allowedDays فارغة)
          mode = DateRestrictMode.days;
        } else {
          mode = DateRestrictMode.months;
        }

        return GoogleFormQuestionCard(
          typeLabel: mainText(context, "Date"),
          typeIcon: Icons.calendar_today_outlined,
          questionField: questionField,
          isRequired: q.confirmed,
          onRequiredChanged: (v) => setState(() => q.confirmed = v),
          onDuplicate: duplicate,
          onDelete: () => _deleteAtOrder(orderIndex),
          onMoveUp: () => _moveOrder(orderIndex, -1),
          onMoveDown: () => _moveOrder(orderIndex, 1),
          canMoveUp: orderIndex > 0,
          canMoveDown: orderIndex < _order.length - 1,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Free / Restricted
              Row(
                children: [
                  Expanded(
                    child: _DateModeChip(
                      label: mainText(context, "Free date"),
                      icon: Icons.event_available,
                      selected: !isRestricted,
                      onTap: () => setState(() => q.dateConfig = null),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DateModeChip(
                      label: mainText(context, "Restricted"),
                      icon: Icons.date_range,
                      selected: isRestricted,
                      onTap: () {
                        setState(() {
                          q.dateConfig ??= PollDateConfig(
                            year: DateTime.now().year,
                            months: [DateTime.now().month],
                            allowedDays: const [],
                            multiSelect: false,
                            rangesText: '',
                            includeTime: q.includeTime,
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _includeTimeRow(theme, q),

              // عدة أيام — Free
              if (!isRestricted)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title:  Text(mainText(context, "Allow multiple days")),
                  value: q.multiSelectDate,
                  onChanged: (v) => setState(() => q.multiSelectDate = v),
                ),

              if (!isRestricted) ...[
                const SizedBox(height: 8),
                _datePreviewBox(theme, mainText(context, "Month, day, year")),
              ],

              if (isRestricted) ...[
                const SizedBox(height: 12),
                Text(mainText(context, "Restrict by"), style: TextStyle(fontSize: 13, color: theme.hintColor)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label:  Text(mainText(context, "Months")),
                      selected: mode == DateRestrictMode.months,
                      onSelected: (_) {
                        setState(() {
                          q.dateConfig = PollDateConfig(
                            year: cfg!.year,
                            months: cfg.months.isEmpty ? [DateTime.now().month] : List.from(cfg.months),
                            allowedDays: const [],
                            multiSelect: cfg.multiSelect,
                            includeTime: q.includeTime,
                            rangesText: '',
                          );
                        });
                      },
                    ),
                    ChoiceChip(
                      label:  Text(mainText(context, "Specific days")),
                      selected: mode == DateRestrictMode.days,
                      onSelected: (_) {
                        setState(() {
                          q.dateConfig = PollDateConfig(
                            year: cfg!.year,
                            months: const [],
                            allowedDays: List.from(cfg.allowedDays),
                            multiSelect: cfg.multiSelect,
                            includeTime: q.includeTime,
                            rangesText: '',
                          );
                        });
                      },
                    ),
                    ChoiceChip(
                      label:  Text(mainText(context, "Ranges")),
                      selected: mode == DateRestrictMode.ranges,
                      onSelected: (_) {
                        setState(() {
                          final text = (cfg!.rangesText?.trim().isNotEmpty ?? false)
                              ? cfg.rangesText!
                              : '[1/1-1/15]';
                          q.rangesCtrl ??= TextEditingController(text: text);
                          q.rangesCtrl!.text = text;
                          q.dateConfig = PollDateConfig(
                            year: cfg!.year,
                            months: const [],
                            allowedDays: parseRangeText(text, cfg.year),
                            multiSelect: cfg.multiSelect,
                            includeTime: q.includeTime,
                            rangesText: text,
                          );
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                // السنة
                Row(
                  children: [
                    Text(
                      mainText(context, "Year"),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 96,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: TextField(
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: theme.colorScheme.onSurface,
                        ),
                        cursorColor: theme.colorScheme.primary,
                        decoration: InputDecoration(

                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          hintText: '2026',
                          hintStyle: TextStyle(
                            color: theme.hintColor.withValues(alpha: 0.4),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        controller: TextEditingController(text: '${cfg!.year}')
                          ..selection = TextSelection.collapsed(
                            offset: '${cfg.year}'.length,
                          ),
                        onSubmitted: (v) {
                          final y = int.tryParse(v) ?? cfg.year;
                          setState(() {
                            q.dateConfig = PollDateConfig(
                              year: y,
                              months: cfg.months,
                              allowedDays: cfg.allowedDays,
                              multiSelect: cfg.multiSelect,
                              includeTime: q.includeTime,
                              rangesText: cfg.rangesText,
                            );
                          });
                        },
                      ),
                    ),
                  ],
                ),

                // ----- Months -----
                if (mode == DateRestrictMode.months) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(12, (i) {
                      final month = i + 1;
                      final selected = cfg.months.contains(month);
                      return FilterChip(
                        label: Text(DateFormat.MMM(Localizations.localeOf(context).languageCode).format(DateTime(2000, i + 1))),
                        selected: selected,
                        onSelected: (v) {
                          setState(() {
                            final months = List<int>.from(cfg.months);
                            v ? months.add(month) : months.remove(month);
                            months.sort();
                            q.dateConfig = PollDateConfig(
                              year: cfg.year,
                              months: months,
                              allowedDays: const [],
                              multiSelect: cfg.multiSelect,
                              includeTime: q.includeTime,
                              rangesText: '',
                            );
                          });
                        },
                      );
                    }),
                  ),
                ],

                // ----- Specific days -----
                if (mode == DateRestrictMode.days) ...[
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: Text(
                      cfg.allowedDays.isEmpty
                          ? mainText(context, "Open calender")
                          : mainText(context, "{0} Days selected", <Object?>[cfg.allowedDays.length]),
                    ),
                    onPressed: () => _openDaysPickerDialog(q, cfg),
                  ),
                ],

                // ----- Ranges نصي -----
                if (mode == DateRestrictMode.ranges) ...[
                  const SizedBox(height: 12),
                  Text(
                    mainText(context, "مثال: [1/2-1/20] = من 2 يناير إلى 20 يناير"),
                    style: TextStyle(fontSize: 12, color: theme.hintColor),
                  ),
                  const SizedBox(height: 8),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: TextField(
                      controller: q.rangesCtrl ??=
                          TextEditingController(text: cfg.rangesText ?? ''),
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        hintText: '[1/2-1/20]',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) {
                        final days = parseRangeText(v, cfg.year);
                        q.dateConfig = PollDateConfig(
                          year: cfg.year,
                          months: const [],
                          allowedDays: days,
                          rangesText: v,
                          multiSelect: cfg.multiSelect,
                          includeTime: q.includeTime,
                        );
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mainText(context, "{0} يوم ضمن المجال", <Object?>[parseRangeText(q.dateConfig?.rangesText ?? '', cfg.year).length]),
                    style: TextStyle(fontSize: 12, color: theme.hintColor),
                  ),
                ],

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title:  Text(mainText(context, "Allow multiple days")),
                  value: cfg.multiSelect,
                  onChanged: (v) {
                    setState(() {
                      q.dateConfig = PollDateConfig(
                        year: cfg.year,
                        months: cfg.months,
                        allowedDays: cfg.allowedDays,
                        multiSelect: v,
                        includeTime: q.includeTime,
                        rangesText: cfg.rangesText,
                      );
                    });
                  },
                ),
              ],
            ],
          ),
        );

    // ==================== Time ====================
      case PollQuestionType.time:
        return GoogleFormQuestionCard(
          typeLabel: mainText(context, "Time"),
          typeIcon: Icons.access_time,
          questionField: questionField,
          isRequired: q.confirmed,
          onRequiredChanged: (v) => setState(() => q.confirmed = v),
          onDuplicate: duplicate,
          onDelete: delete,
          body: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    foregroundColor: theme.colorScheme.onSurface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                   onPressed: () async {
                  //   final picked = await showTimePicker(
                  //     context: context,
                  //     initialTime: q.selectedTime ?? TimeOfDay.now(),
                  //   );
                  //   if (picked != null) {
                  //     setState(() {
                  //       q.selectedTime = picked;
                  //       q.timeController?.text = picked.format(context);
                  //     });
                  //   }
                   },
                  icon: const Icon(Icons.access_time, size: 18),
                  label: Text(
                    q.selectedTime != null
                        ? q.selectedTime!.format(context)
                        : mainText(context, "Select time"),
                  ),
                ),
              ],
            ),
          ),
          onMoveUp: () => _moveOrder(orderIndex, -1),
          onMoveDown: () => _moveOrder(orderIndex, 1),
          canMoveUp: orderIndex > 0,
          canMoveDown: orderIndex >= 0 && orderIndex < _order.length - 1,
        );
    }
  }

  Widget _datePreviewBox(ThemeData theme, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined, size: 18, color: theme.hintColor),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: theme.hintColor.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _includeTimeRow(ThemeData theme, PollQuestion q) {
    return Row(
      children: [
         Expanded(child: Text(mainText(context, "Include time"), style: TextStyle(fontSize: 14))),
        Switch(
          value: q.includeTime,
          onChanged: (v) => setState(() => q.includeTime = v),
        ),
      ],
    );
  }

  Widget _buildScalePreview(PollQuestion q, ThemeData theme) {
    final size = q.scaleSize;

    switch (q.scaleStyle) {
      case LinearScaleStyle.numbers:
        return Column(
          children: [
            Row(
              children: List.generate(size, (i) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(q.scaleMinLabel,
                    style: TextStyle(fontSize: 11, color: theme.hintColor)),
                Text(q.scaleMaxLabel,
                    style: TextStyle(fontSize: 11, color: theme.hintColor)),
              ],
            ),
          ],
        );

      case LinearScaleStyle.stars:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(size, (i) {
            return Icon(Icons.star_outline_rounded,
                size: 28, color: theme.hintColor.withValues(alpha: 0.4));
          }),
        );

      case LinearScaleStyle.emoji:
        const faces = [
          '😠', '😞', '😕', '😑', '😐',
          '🙂', '😊', '😄', '😃', '😁',
        ];
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(size, (i) {
            final idx = size <= 1
                ? 0
                : ((i / (size - 1)) * (faces.length - 1)).round();
            return Text(faces[idx], style: const TextStyle(fontSize: 22));
          }),
        );

      case LinearScaleStyle.slider:
      // قيمة تجريبية للمعاينة
        final double value = q.previewSliderValue.clamp(0.0, 100.0);

        

        

        final accent = pollSliderColor(value);
        final emoji = pollSliderEmoji(value);

        return Column(
          children: [
            Text(
              '${value.round()}%',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: accent,
              ),
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 6,
                activeTrackColor: accent,
                inactiveTrackColor: accent.withValues(alpha: 0.18),
                overlayColor: accent.withValues(alpha: 0.12),
                thumbShape: _EmojiThumbShape(emoji: emoji, size: 40),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 28),
              ),
              child: Slider(
                value: q.previewSliderValue,
                min: 0,
                max: 100,
                onChanged: (v) => setState(() => q.previewSliderValue = v),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  q.scaleMinLabel.isNotEmpty ? q.scaleMinLabel : mainText(context, "Low"),
                  style: TextStyle(fontSize: 12, color: theme.hintColor),
                ),
                Text(
                  q.scaleMaxLabel.isNotEmpty ? q.scaleMaxLabel : mainText(context, "High"),
                  style: TextStyle(fontSize: 12, color: theme.hintColor),
                ),
              ],
            ),
          ],
        );



      case LinearScaleStyle.line:
        return Column(
          children: [
            Slider(
              value: (size / 2).toDouble(),
              min: 1,
              max: size.toDouble(),
              divisions: size - 1,
              onChanged: (_) {},
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(q.scaleMinLabel,
                    style: TextStyle(fontSize: 11, color: theme.hintColor)),
                Text(q.scaleMaxLabel,
                    style: TextStyle(fontSize: 11, color: theme.hintColor)),
              ],
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

class _DaysToggleCalendar extends StatefulWidget {
  final int year;
  final int initialMonth;
  final List<DateTime> selected;
  final ValueChanged<List<DateTime>> onChanged;
  final ThemeData theme;

  const _DaysToggleCalendar({
    required this.year,
    required this.initialMonth,
    required this.selected,
    required this.onChanged,
    required this.theme,
  });

  @override
  State<_DaysToggleCalendar> createState() => _DaysToggleCalendarState();
}

class _DaysToggleCalendarState extends State<_DaysToggleCalendar> {
  late int _month;

  @override
  void initState() {
    super.initState();
    _month = widget.initialMonth.clamp(1, 12);
  }

  bool _isSelected(int day) {
    return widget.selected.any((d) =>
    d.year == widget.year && d.month == _month && d.day == day);
  }

  void _toggle(int day) {
    final list = List<DateTime>.from(widget.selected);
    final exists = list.any((d) =>
    d.year == widget.year && d.month == _month && d.day == day);
    if (exists) {
      list.removeWhere(
          (d) =>
      d.year == widget.year && d.month == _month && d.day == day);
    } else {
      list.add(DateTime(widget.year, _month, day));
    }
    list.sort();
    widget.onChanged(list);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final daysInMonth = DateTime(widget.year, _month + 1, 0).day;
    final firstWeekday = DateTime(widget.year, _month, 1).weekday % 7; // أحد=0

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  if (_month > 1) {
                    _month--;
                  }
                });
              },
            ),
            Text(
              DateFormat.yMMM(Localizations.localeOf(context).languageCode).format(DateTime(widget.year, _month)),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  if (_month < 12) {
                    _month++;
                  }
                });
              },
            ),
          ],
        ),
        Row(
          children: DateFormat.E(Localizations.localeOf(context).languageCode).dateSymbols.NARROWWEEKDAYS
              .map((e) => Expanded(
            child: Center(
              child: Text(e,
                  style: TextStyle(
                      fontSize: 11, color: theme.hintColor)),
            ),
          ))
              .toList(),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: firstWeekday + daysInMonth,
          itemBuilder: (context, index) {
            if (index < firstWeekday) {
              return const SizedBox.shrink();
            }
            final day = index - firstWeekday + 1;
            final sel = _isSelected(day);
            return GestureDetector(
              onTap: () => _toggle(day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sel
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  border: Border.all(
                    color: sel
                        ? theme.colorScheme.primary
                        : theme.dividerColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                    color: sel
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

