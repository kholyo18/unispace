part of '../../main.dart';

class PollQuestionSlideView extends StatefulWidget {
  final PollData poll;
  final int slideIndex;
  final Map<int, dynamic> answers;
  final void Function(int key, dynamic value)? onAnswer;

  const PollQuestionSlideView({
    super.key,
    required this.poll,
    required this.slideIndex,
    required this.answers,
    this.onAnswer,
  });

  @override
  State<PollQuestionSlideView> createState() => _PollQuestionSlideViewState();
}

class _PollQuestionSlideViewState extends State<PollQuestionSlideView> {
  final Map<int, TextEditingController> _pollTextControllers = {};
  int get key => widget.slideIndex;
  DateRestrictMode dateMode = DateRestrictMode.months;
  TextEditingController? rangesCtrl;

  void _setAnswer(dynamic value) {
    widget.onAnswer?.call(key, value);
    setState(() {}); // لإعادة رسم الاختيار
  }
  @override

  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final key = widget.slideIndex;


      return Directionality(
          textDirection: TextDirection.ltr,
          child:GestureDetector(
          onTap: () {}, // امتصاص
          behavior: HitTestBehavior.opaque,
          child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رأس النوع
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : const Color(0xFFF1F3F4),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(
                    _iconForPollType(widget.poll.type),
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _labelForPollType(widget.poll.type),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // المحتوى (الإجابة تُحفظ تلقائياً في _pollAnswers)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.poll.question.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.poll.question,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (widget.poll.isRequired)
                            const Text(
                              ' *',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // حيز الإجابة فقط في المنتصف

                    _buildGoogleStyleOptions(widget.poll, theme, key),

                  ],
                ),
              ),
            ),
          ],
        ),
      )));
  }

  Widget _buildGoogleStyleOptions(PollData poll, ThemeData theme, int key) {

    switch (poll.type) {
    // ==================== Short answer ====================

    case PollQuestionType.shortText:
        final ctrl = _pollTextControllers.putIfAbsent(
          key,
              () => TextEditingController(
                text: widget.answers[key] is String
                    ? widget.answers[key] as String
                    : '',
          ),
        );
        final selected = widget.answers[key] is String
            ? widget.answers[key] as String
            : null;
        return TextField(
          controller: ctrl,
          onChanged: (v) {
            widget.onAnswer?.call(key, v); setState(() {});
          },
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: mainText(context, "Your answer"),
            hintStyle: TextStyle(
              color: theme.hintColor.withValues(alpha: 0.45),
              fontSize: 15,
            ),


            isDense: true,
            contentPadding: const EdgeInsets.only(bottom: 40, top: 20),
          ),
        );

// ==================== Paragraph ====================
      case PollQuestionType.longText:
        final ctrl = _pollTextControllers.putIfAbsent(
          key,
              () => TextEditingController(
                text: widget.answers[key] is String
                    ? widget.answers[key] as String
                    : '',
          ),
        );
        final selected = widget.answers[key] is String
            ? widget.answers[key] as String
            : null;
        return TextField(
          controller: ctrl,
          maxLines: 8,
          minLines: 8,
          onChanged: (v) {
            widget.onAnswer?.call(key, v); setState(() {});
          },
          style: const TextStyle(fontSize: 15, height: 1.45),
          decoration: InputDecoration(
            hintText: mainText(context, "Your answer"),
            hintStyle: TextStyle(
              color: theme.hintColor.withValues(alpha: 0.45),
              fontSize: 15,
            ),

            isDense: true,
            contentPadding: const EdgeInsets.only(bottom: 10, top: 0),
          ),
        );

    // ==================== Dropdown ====================
      case PollQuestionType.dropdown:
        final selected = widget.answers[key] is String
            ? widget.answers[key] as String
            : null;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.45)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: poll.options.contains(selected) ? selected : null,
              hint: Text(
                mainText(context, "Choose"),
                style: TextStyle(color: theme.hintColor.withValues(alpha: 0.6)),
              ),
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: theme.colorScheme.primary),
              borderRadius: BorderRadius.circular(12),
              items: poll.options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  widget.onAnswer?.call(key, v);
                });

                setState(() {});
              },
            ),
          ),
        );

    // ==================== Singel optin ====================
      case PollQuestionType.singelOptin:
        final selected =
        widget.answers[key] is int ? widget.answers[key] as int : null;

        return Column(
          children: List.generate(poll.options.length, (i) {
            final isSelected = selected == i;
            return GestureDetector(
              onTap: () => _setAnswer(i), // int فقط
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.dividerColor.withValues(alpha: 0.35),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.hintColor,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.circle, size: 10, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        poll.options[i],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );

    // ==================== Checkboxes ====================
      case PollQuestionType.checkbox:
        final selected = widget.answers[key] is Set
            ? Set<int>.from(widget.answers[key] as Set)
            : <int>{};
        return Column(
          children: List.generate(poll.options.length, (i) {
            final isChecked = selected.contains(i);
            return GestureDetector(
              onTap: () {
                final set = Set<int>.from(selected);
                isChecked ? set.remove(i) : set.add(i);
                _setAnswer(set); // _setAnswer يستدعي setState داخلياً
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: isChecked
                      ? theme.colorScheme.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isChecked
                        ? theme.colorScheme.primary
                        : theme.dividerColor.withValues(alpha: 0.35),
                    width: isChecked ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: isChecked
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: isChecked
                              ? theme.colorScheme.primary
                              : theme.hintColor,
                          width: 2,
                        ),
                      ),
                      child: isChecked
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        poll.options[i],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                          isChecked ? FontWeight.w600 : FontWeight.normal,
                          color: isChecked
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );

    // ==================== Linear scale ====================

      case PollQuestionType.linearScale:
        final size = (poll.scaleSize ?? 5).clamp(1, 10);
        final selected = widget.answers[key] is int
            ? widget.answers[key] as int
            : null;
        final style = poll.scaleStyle ?? LinearScaleStyle.numbers;

        // ---------- Slider جذاب + إيموجي ----------
        if (style == LinearScaleStyle.slider) {
          final double value = (selected ?? 50).toDouble().clamp(0.0, 100.0).toDouble();

          

          

          final accent = pollSliderColor(value);
          final emoji = pollSliderEmoji(value);

          return  Column(
            children: [
              // النسبة فوق الشريط
              Text(
                '${value.round()}%',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
              const SizedBox(height: 8),

              // الشريط — الإيموجي هو نقطة التحريك
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
                  value: value,
                  min: 0,
                  max: 100,
                  onChanged: (v) => _setAnswer(v.round()),
                ),
              ),

              const SizedBox(height: 4),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(poll.scaleMinLabel,
                      style: TextStyle(fontSize: 12, color: theme.hintColor)),
                  Text(poll.scaleMaxLabel,
                      style: TextStyle(fontSize: 12, color: theme.hintColor)),
                ],
              ),
            ],
          );
        }

        // ---------- stars ----------
        if (style == LinearScaleStyle.stars) {
          final starCount = (poll.scaleSize ?? 5).clamp(1, 10);

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                // إذا أكثر من 7 نجوم → صف قابل للالتفاف
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 2,
                  runSpacing: 6,
                  children: List.generate(starCount, (i) {
                    final isFilled = selected != null && i <= selected;
                    return GestureDetector(
                      onTap: () => _setAnswer(i),
                      child: AnimatedScale(
                        scale: isFilled ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          isFilled
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: starCount > 7 ? 30 : 36,
                          color: isFilled
                              ? const Color(0xFFFFC107)
                              : theme.hintColor.withValues(alpha: 0.3),
                        ),
                      ),
                    );
                  }),
                ),
                if (selected != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${selected + 1} / $starCount',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFC107),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        // ---------- Emoji (Maze graphic scale) ----------
        if (style == LinearScaleStyle.emoji || style == LinearScaleStyle.emoji1) {
          // ألوان من أحمر → أخضر
          final colors = [
            const Color(0xFFE57373), // أحمر
            const Color(0xFFEF9A9A),
            const Color(0xFFFFB74D),
            const Color(0xFFFFCC80),
            const Color(0xFFFFF176), // أصفر
            const Color(0xFFFFF59D),
            const Color(0xFFAED581),
            const Color(0xFF81C784),
            const Color(0xFF66BB6A),
            const Color(0xFF26A69A), // أخضر
          ];

          final faces = [
            '😠', '😞', '😕', '😑', '😐',
            '🙂', '😊', '😄', '😃', '😁',
          ];

          final count = size.clamp(1, 10);

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                // صف الوجوه الملونة
                count > 7
                    ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(count, (i) => _mazeFace(
                        i: i,
                        count: count,
                        selected: selected,
                        answerKey: key,
                        theme: theme,
                        colors: colors,
                        faces: faces,
                                    ))),
                      )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(count, (i) {
                    return _mazeFace(
                      i: i,
                      count: count,
                      selected: selected,
                      answerKey: key,
                      theme: theme,
                      colors: colors,
                      faces: faces,
                    );
                  }),
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      poll.scaleMinLabel,
                      style: TextStyle(fontSize: 11, color: theme.hintColor),
                    ),
                    Text(
                      poll.scaleMaxLabel,
                      style: TextStyle(fontSize: 11, color: theme.hintColor),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
        // ---------- 4) Line + Dots (مثل الصورة الثالثة) ----------
        if (style == LinearScaleStyle.line) {
          return Column(
            children: [
              SizedBox(
                height: 36,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        // الخط
                        Positioned(
                          left: 12,
                          right: 12,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: theme.dividerColor.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // النقاط
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(size, (i) {
                            final isSelected = selected == i;
                            final isPassed =
                                selected != null && i <= selected;
                            return GestureDetector(
                              onTap: () => _setAnswer(i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: isSelected ? 22 : 16,
                                height: isSelected ? 22 : 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : isPassed
                                      ? theme.colorScheme.primary
                                      .withValues(alpha: 0.4)
                                      : theme.colorScheme.surface,
                                  border: Border.all(
                                    color: isPassed || isSelected
                                        ? theme.colorScheme.primary
                                        : theme.dividerColor,
                                    width: 2,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.35),
                                      blurRadius: 6,
                                    ),
                                  ]
                                      : null,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(poll.scaleMinLabel,
                      style: TextStyle(fontSize: 11, color: theme.hintColor)),
                  Text(mainText(context, "Neutral"),
                      style: TextStyle(fontSize: 11, color: theme.hintColor)),
                  Text(poll.scaleMaxLabel,
                      style: TextStyle(fontSize: 11, color: theme.hintColor)),
                ],
              ),
            ],
          );
        }

        // ---------- Numbers ----------
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(size, (i) {
                    final isSelected = selected == i;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _setAnswer(i),
                          borderRadius: BorderRadius.circular(8),
                          child: Ink(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surface,
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.dividerColor.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    poll.scaleMinLabel.isNotEmpty ? poll.scaleMinLabel : mainText(context, "Low"),
                    style: TextStyle(fontSize: 11, color: theme.hintColor),
                  ),
                  Text(mainText(context, "Neutral"),
                      style: TextStyle(fontSize: 11, color: theme.hintColor)),
                  Text(
                    poll.scaleMaxLabel.isNotEmpty ? poll.scaleMaxLabel : mainText(context, "High"),
                    style: TextStyle(fontSize: 11, color: theme.hintColor),
                  ),
                ],
              ),
            ],
          ),
        );

    // ==================== Date ====================
      case PollQuestionType.date:
        final timeKey = key + 100000;
        final multi =
            poll.multiSelect || (poll.dateConfig?.multiSelect ?? false);
        final timePicked = widget.answers[timeKey] is TimeOfDay
            ? widget.answers[timeKey] as TimeOfDay
            : null;
        final includeTime =
            poll.includeTime || (poll.dateConfig?.includeTime ?? false);
        final config = poll.dateConfig;

        // قراءة الإجابة: يوم واحد أو قائمة
        List<DateTime> selectedDays() {
          final raw = widget.answers[key];
          if (raw is DateTime) return [raw];
          if (raw is List) {
            return raw
                .map((e) {
              if (e is DateTime) return e;
              if (e is String) return DateTime.tryParse(e);
              return null;
            })
                .whereType<DateTime>()
                .toList();
          }
          return [];
        }

        Future<void> pick() async {
          final current = selectedDays();
          final initial = current.isNotEmpty ? current.last : DateTime.now();

          // أيام مسموحة صراحة
          final specific = config?.allowedDays ?? const <DateTime>[];
          final months = config?.months ?? const <int>[];
          final year = config?.year ?? DateTime.now().year;

          final date = await showDatePicker(
            context: context,
            initialDate: () {
              if (specific.isNotEmpty) {
                return specific.first;
              }
              if (months.isNotEmpty) {
                return DateTime(year, months.first, 1);
              }
              return initial;
            }(),
            firstDate: specific.isNotEmpty
                ? DateTime(specific.first.year, 1, 1)
                : (config == null ? DateTime(2000) : DateTime(year, 1, 1)),
            lastDate: specific.isNotEmpty
                ? DateTime(specific.last.year, 12, 31)
                : (config == null ? DateTime(2100) : DateTime(year, 12, 31)),
            selectableDayPredicate: (day) {
              if (specific.isNotEmpty) {
                return specific.any((d) =>
                d.year == day.year &&
                    d.month == day.month &&
                    d.day == day.day);
              }
              if (config == null) return true;
              if (months.isEmpty) return day.year == year;
              return day.year == year && months.contains(day.month);
            },
          );

          if (date == null) return;

          if (multi) {
            final list = List<DateTime>.from(selectedDays());
            final exists = list.any((d) =>
            d.year == date.year &&
                d.month == date.month &&
                d.day == date.day);
            if (exists) {
              list.removeWhere((d) =>
              d.year == date.year &&
                  d.month == date.month &&
                  d.day == date.day);
            } else {
              list.add(date);
            }
            list.sort();
            _setAnswer(list);
          } else {
            _setAnswer(date);
          }
        }

        String labelFor(List<DateTime> days) {
          if (days.isEmpty) {
            return multi ? mainText(context, "Select days") : 'Select date';
          }
          return days
              .map((d) => '${d.day}/${d.month}/${d.year}').join('  •  ');
        }

        final days = selectedDays();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (config != null) ...[
              Text(
                config.hasSpecificDays
                    ? mainText(context, "Allowed days: {0}", <Object?>[config.allowedDays.map((d) => '${d.day}/${d.month}').join(', ')])
                    : (config.months.isEmpty
                    ? mainText(context, "Year {0}", <Object?>[config.year])
                    : 'Allowed: ${config.months.map((m) => [
                              'Jan',
                              'Feb',
                              'Mar',
                              'Apr',
                              'May',
                              'Jun',
                              'Jul',
                              'Aug',
                              'Sep',
                              'Oct',
                              'Nov',
                              'Dec'
                            ][m - 1]).join(', ')} ${config.year}'),
                style: TextStyle(fontSize: 12, color: theme.hintColor),
              ),
              const SizedBox(height: 10),
            ],
            GestureDetector(
              onTap: pick,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.4),
                  ),
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.25),
                ),
                child: Row(
                  children: [
                    Icon(
                      multi ? Icons.event_note : Icons.calendar_today_outlined,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        labelFor(days),
                        style: TextStyle(
                          fontSize: 14,
                          color: days.isNotEmpty
                              ? theme.colorScheme.onSurface
                              : theme.hintColor.withValues(alpha: 0.7),
                          fontWeight:
                          days.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (multi && days.isNotEmpty)
                      Text(
                        '${days.length}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // شرائح الأيام المختارة (متعدد)
            if (multi && days.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: days.map((d) {
                  return InputChip(
                    label: Text('${d.day}/${d.month}/${d.year}'),
                    onDeleted: () {
                      final list = List<DateTime>.from(days)
                        ..removeWhere((x) =>
                        x.year == d.year &&
                            x.month == d.month &&
                            x.day == d.day);
                      _setAnswer(list);
                    },
                  );
                }).toList(),
              ),
            ],

            if (includeTime) ...[
              const SizedBox(height: 10),
              _buildTimePickerButton(theme, timeKey, timePicked),
            ],
          ],
        );
    // ==================== Time ====================
      case PollQuestionType.time:
        final picked = widget.answers[key] is TimeOfDay
            ? widget.answers[key] as TimeOfDay
            : null;
        return GestureDetector(
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: picked ?? TimeOfDay.now(),
            );
            if (time != null) _setAnswer(time);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.4),
              ),
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.25),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  picked != null ? picked.format(context) : mainText(context, "Select time"),
                  style: TextStyle(
                    fontSize: 14,
                    color: picked != null
                        ? theme.colorScheme.onSurface
                        : theme.hintColor.withValues(alpha: 0.7),
                    fontWeight:
                    picked != null ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );

    // ==================== Singel optin Grid ====================
      case PollQuestionType.grid:
        return _buildInteractiveGrid(
          poll: poll,
          theme: theme,
          multiSelect: false,
        );

    // ==================== Checkbox Grid ====================
      case PollQuestionType.checkboxGrid:
        return _buildInteractiveGrid(
          poll: poll,
          theme: theme,
          multiSelect: true,
        );
    }
  }
    IconData _iconForPollType(PollQuestionType type) {
      switch (type) {
        case PollQuestionType.shortText:
          return Icons.short_text;
        case PollQuestionType.longText:
          return Icons.notes;
        case PollQuestionType.dropdown:
          return Icons.arrow_drop_down_circle_outlined;
        case PollQuestionType.singelOptin:
          return Icons.radio_button_checked;
        case PollQuestionType.checkbox:
          return Icons.check_box_outlined;
        case PollQuestionType.linearScale:
          return Icons.linear_scale;
        case PollQuestionType.grid:
          return Icons.grid_on_outlined;
        case PollQuestionType.checkboxGrid:
          return Icons.grid_view;
        case PollQuestionType.date:
          return Icons.calendar_today_outlined;
        case PollQuestionType.time:
          return Icons.access_time;
      }
    }

    String _labelForPollType(PollQuestionType type) {
      switch (type) {
        case PollQuestionType.shortText:
          return mainText(context, "Short answer");
        case PollQuestionType.longText:
          return mainText(context, "Paragraph");
        case PollQuestionType.dropdown:
          return mainText(context, "Dropdown");
        case PollQuestionType.singelOptin:
          return mainText(context, "Singel optin");
        case PollQuestionType.checkbox:
          return mainText(context, "Checkboxes");
        case PollQuestionType.linearScale:
          return mainText(context, "Linear scale");
        case PollQuestionType.grid:
          return mainText(context, "Singel optin grid");
        case PollQuestionType.checkboxGrid:
          return mainText(context, "Checkbox grid");
        case PollQuestionType.date:
          return mainText(context, "Date");
        case PollQuestionType.time:
          return mainText(context, "Time");
      }
    }

  Widget _buildInteractiveGrid({required PollData poll,
    required ThemeData theme, required bool multiSelect,
  }) {
    final key = widget.slideIndex;
    final answers = widget.answers[key] is Map
        ? Map<int, Set<int>>.from(
      (widget.answers[key] as Map).map(
            (k, v) => MapEntry(
          k is int ? k : int.tryParse(k.toString()) ?? 0,
          v is Set ? Set<int>.from(v) : <int>{},
        ),
      ),
    )
        : <int, Set<int>>{};

    if (poll.gridRows.isEmpty || poll.gridColumns.isEmpty) {
      return Text(mainText(context, "No grid data"), style: TextStyle(color: theme.hintColor));
    }

    final needsHorizontalScroll = poll.gridColumns.length > 3;
    final needsVerticalScroll = poll.gridRows.length > 4;

    final bgColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainerHighest
        : Colors.white;

    // ارتفاع تقريبي: رأس + صفوف (حد أقصى 4 صفوف ظاهرة)
    final double? tableHeight = needsVerticalScroll ? 220.0 : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // مؤشر أفقي
        if (needsHorizontalScroll)
          Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.swipe, size: 13, color: theme.hintColor),
                const SizedBox(width: 4),
              ],
            ),
          ),

        // الجدول
        Stack(
          children: [
            SizedBox(
              height: tableHeight,
              child: SingleChildScrollView(
                // عمودي عند كثرة الصفوف
                child: SingleChildScrollView(
                  // أفقي عند كثرة الأعمدة
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 12,
                    headingRowHeight: 40,
                    dataRowMinHeight: 44,
                    dataRowMaxHeight: 48,
                    columns: [
                      const DataColumn(
                        label: SizedBox(width: 70, child: Text('')),
                      ),
                      ...poll.gridColumns.map(
                            (c) => DataColumn(
                          label: SizedBox(
                            width: 64,
                            child: Text(
                              c,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                    rows: List.generate(poll.gridRows.length, (rowIndex) {
                      final rowSelected = answers[rowIndex] ?? <int>{};

                      return DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 70,
                              child: Text(
                                poll.gridRows[rowIndex],
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          ...List.generate(poll.gridColumns.length, (colIndex) {
                            final isSelected = rowSelected.contains(colIndex);

                            return DataCell(
                              Center(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      final map =
                                      Map<int, Set<int>>.from(answers);
                                      map[rowIndex] =
                                      Set<int>.from(map[rowIndex] ?? {});

                                      if (multiSelect) {
                                        if (isSelected) {
                                          map[rowIndex]!.remove(colIndex);
                                        } else {
                                          map[rowIndex]!.add(colIndex);
                                        }
                                      } else {
                                        map[rowIndex] = {colIndex};
                                      }

                                      _setAnswer(map);
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: multiSelect
                                          ? BoxShape.rectangle
                                          : BoxShape.circle,
                                      borderRadius: multiSelect
                                          ? BorderRadius.circular(5)
                                          : null,
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : theme.hintColor,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Icon(
                                      multiSelect
                                          ? Icons.check
                                          : Icons.circle,
                                      size: multiSelect ? 14 : 8,
                                      color: theme.colorScheme.surface.withValues(alpha: 0.7),
                                    )
                                        : null,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),

            // تدرج يمين (أعمدة)
            if (needsHorizontalScroll)
              Positioned(
                right: 0,
                top: 0,
                bottom: needsVerticalScroll ? 20 : 0,
                child: IgnorePointer(
                  child: Container(
                    width: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          bgColor.withValues(alpha: 0),
                          bgColor.withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // تدرج أسفل (صفوف)
            if (needsVerticalScroll)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          (theme.brightness == Brightness.dark
                              ? theme.colorScheme.surfaceContainerHighest
                              : Colors.white)
                              .withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.keyboard_arrow_down,
                              size: 16, color: theme.hintColor),
                          Text(
                            mainText(context, "المزيد"),
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimePickerButton(
      ThemeData theme,
      int timeKey,
      TimeOfDay? timePicked,
      ) {
    return GestureDetector(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: timePicked ?? TimeOfDay.now(),
        );
        if (time != null) {
          widget.onAnswer?.call(timeKey, time);
          setState(() {});
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.4),
          ),
          color: theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.25),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time,
                size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              timePicked != null ? timePicked.format(context) : mainText(context, "Select time"),
              style: TextStyle(
                fontSize: 14,
                color: timePicked != null
                    ? theme.colorScheme.onSurface
                    : theme.hintColor.withValues(alpha: 0.7),
                fontWeight:
                timePicked != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mazeFace({
    required int i,
    required int count,
    required int? selected,
    required int answerKey,
    required ThemeData theme,
    required List<Color> colors,
    required List<String> faces,
  }) {
    final isSelected = selected == i;
    final colorIndex = count <= 1
        ? 0
        : ((i / (count - 1)) * (colors.length - 1))
            .round()
            .clamp(0, colors.length - 1);
    final faceIndex = count <= 1
        ? 0
        : ((i / (count - 1)) * (faces.length - 1))
            .round()
            .clamp(0, faces.length - 1);

    return GestureDetector(
      onTap: () => _setAnswer(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: isSelected ? 38 : 34,
        height: isSelected ? 38 : 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors[colorIndex],
          border: isSelected
              ? Border.all(color: theme.colorScheme.onSurface, width: 2.5)
              : null,
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: colors[colorIndex].withValues(alpha: 0.45),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ]
              : null,
        ),
        child: Text(
          faces[faceIndex],
          style: TextStyle(fontSize: isSelected ? 18 : 16),
        ),
      ),
    );
  }
}

Map<String, dynamic> _pollToMap(PollData poll) {
  return {
    'question': poll.question,
    'type': poll.type.name,
    'options': poll.options,
    'gridRows': poll.gridRows,
    'gridColumns': poll.gridColumns,
    'scaleStyle': poll.scaleStyle?.name,
    'scaleSize': poll.scaleSize,
    'isRequired': poll.isRequired,
    'includeTime': poll.includeTime,
    'scaleMinLabel': poll.scaleMinLabel,
    'scaleMaxLabel': poll.scaleMaxLabel,
    'multiSelect': poll.multiSelect,
    'dateConfig': poll.dateConfig == null
        ? null
        : {
      'year': poll.dateConfig!.year,
      'months': poll.dateConfig!.months,
      'includeTime': poll.dateConfig!.includeTime,

      'allowedDays': poll.dateConfig!.allowedDays
          .map((d) => d.toIso8601String())
          .toList(),
      'rangeStart': poll.dateConfig!.rangeStart?.toIso8601String(),
      'rangesText': poll.dateConfig!.rangesText,
      'rangeEnd': poll.dateConfig!.rangeEnd?.toIso8601String(),
    },
    'selectedTime': poll.selectedTime == null
        ? null
        : {
      'hour': poll.selectedTime!.hour,
      'minute': poll.selectedTime!.minute,
    },
  };
}

PollData _pollFromMap(Map<String, dynamic> map) {
  final typeName = map['type']?.toString();
  final type = PollQuestionType.values.firstWhere(
        (e) => e.name == typeName,
    orElse: () => PollQuestionType.shortText,
  );

  final scaleName = map['scaleStyle']?.toString();
  final scaleStyle = scaleName == null
      ? null
      : LinearScaleStyle.values.firstWhere(
        (e) => e.name == scaleName,
    orElse: () => LinearScaleStyle.numbers,
  );

  PollDateConfig? dateConfig;
  final rawDate = map['dateConfig'];
  if (rawDate is Map) {
    final date = Map<String, dynamic>.from(rawDate);

    final allowedDays = (date['allowedDays'] is List)
        ? (date['allowedDays'] as List)
        .map((e) => DateTime.tryParse(e.toString()))
        .whereType<DateTime>()
        .toList()
        : <DateTime>[];

    final months = (date['months'] is List)
        ? (date['months'] as List)
        .map((e) => (e is num) ? e.toInt() : int.tryParse(e.toString()))
        .whereType<int>()
        .toList()
        : <int>[];

    dateConfig = PollDateConfig(
      year: (date['year'] as num?)?.toInt() ?? DateTime.now().year,
      months: months,
      allowedDays: allowedDays,
      includeTime: date['includeTime'] == true || map['includeTime'] == true,
      multiSelect: date['multiSelect'] == true,
      rangesText: date['rangesText']?.toString(),
      rangeStart: date['rangeStart'] != null
          ? DateTime.tryParse(date['rangeStart'].toString())
          : null,
      rangeEnd: date['rangeEnd'] != null
          ? DateTime.tryParse(date['rangeEnd'].toString())
          : null,
    );
  }

  TimeOfDay? selectedTime;
  final rawTime = map['selectedTime'];
  if (rawTime is Map) {
    final time = Map<String, dynamic>.from(rawTime);
    selectedTime = TimeOfDay(
      hour: (time['hour'] as num?)?.toInt() ?? 0,
      minute: (time['minute'] as num?)?.toInt() ?? 0,
    );
  }

  return PollData(
    question: map['question'] as String? ?? '',
    type: type,
    isRequired: map['isRequired'] == true,
    includeTime: map['includeTime'] == true,
    options: _stringList(map['options']),
    gridRows: _stringList(map['gridRows']),
    gridColumns: _stringList(map['gridColumns']),
    scaleStyle: scaleStyle,
    scaleSize: (map['scaleSize'] as num?)?.toInt(),
    scaleMinLabel: map['scaleMinLabel'] as String? ?? 'Low',
    scaleMaxLabel: map['scaleMaxLabel'] as String? ?? 'High',
    multiSelect: map['multiSelect'] == true,
    dateConfig: dateConfig,
    selectedTime: selectedTime,
  );
}

