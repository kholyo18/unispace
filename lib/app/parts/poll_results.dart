part of '../../main.dart';

class PollResponsesScreen extends StatefulWidget {
  final _Post post;
  const PollResponsesScreen({super.key, required this.post});
  @override
  State<PollResponsesScreen> createState() => _PollResponsesScreenState();
}

class _PollResponsesScreenState extends State<PollResponsesScreen> {
  final List<Map<String, dynamic>> _responses = [];
  _Post? _post;
  Map<String, dynamic>? _cursor;
  String? _error, _uid;
  bool _loading = false, _more = true;
  int _generation = 0;
  StreamSubscription<User?>? _auth;
  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted || user?.uid == _uid) return;
      _uid = user?.uid; _refresh();
    });
    moderationRevision.addListener(_refresh);
    blockedListRevision.addListener(_refresh);
    _refresh();
  }
  void _refresh() { if (mounted) _load(reset: true); }
  Future<void> _load({bool reset = false}) async {
    if (!mounted || (!reset && (_loading || !_more))) return;
    final generation = reset ? ++_generation : _generation;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    bool current() => mounted && generation == _generation && uid == FirebaseAuth.instance.currentUser?.uid;
    setState(() {
      _loading = true; _error = null;
      if (reset) { _responses.clear(); _post = null; _cursor = null; _more = true; }
    });
    try {
      final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('readOwnPollResponses', options: HttpsCallableOptions(timeout: const Duration(seconds: 120)))
          .call<Map<String, dynamic>>(
              {'postId': widget.post.id, 'cursor': _cursor});
      if (!current()) return;
      final page = result.data, rawPost = page['post'];
      if (rawPost is! Map || rawPost['id'] != widget.post.id || rawPost['data'] is! Map ||
          page[mainText(context, "responses")] is! List || page['exhausted'] is! bool ||
          (page['cursor'] != null && page['cursor'] is! Map) ||
          (page['exhausted'] == false && page['cursor'] == null)) throw StateError('Invalid results page');
      final post = _Post.fromData(widget.post.id!, Map<String, dynamic>.from(rawPost['data'] as Map));
      if (post.authorId != uid) throw StateError('Not the owner');
      final incoming = (page[mainText(context, "responses")] as List).map((row) {
        if (row is! Map || row['id'] is! String || row['answers'] is! Map) throw StateError('Invalid response');
        final data = Map<String, dynamic>.from(row);
        final date = DateTime.tryParse(data['submittedAt']?.toString() ?? '');
        data['submittedAt'] = date == null ? null : Timestamp.fromDate(date);
        return data;
      }).toList();
      setState(() {
        _post = post;
        for (final row in incoming) {
          _responses.removeWhere((old) => old['id'] == row['id']);
          _responses.add(row);
        }
        _cursor = page['cursor'] == null ? null : Map<String, dynamic>.from(page['cursor'] as Map);
        _more = page['exhausted'] == false; _loading = false;
      });
    } catch (_) {
      if (!current()) return;
      setState(() { _loading = false; _responses.clear(); _post = null; _error = mainText(context, "تعذر عرض النتائج أو ليست لديك صلاحية الوصول"); });
    }
  }
  @override
  void dispose() {
    _generation++; _auth?.cancel();
    moderationRevision.removeListener(_refresh);
    blockedListRevision.removeListener(_refresh);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.ltr,
    child: Scaffold(
      appBar: AppBar(title:  Text(mainText(context, "Poll responses")), actions: [
        IconButton(onPressed: _loading ? null : _refresh, icon: const Icon(Icons.refresh), tooltip: mainText(context, "تحديث")),
      ]),
      body: _error != null ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error!), TextButton(onPressed: _refresh, child:  Text(mainText(context, "إعادة المحاولة"))),
      ])) : _post == null ? const Center(child: CircularProgressIndicator()) : DefaultTabController(
        length: 2, child: Column(children: [
          Padding(padding: const EdgeInsets.all(12), child: Text(
            _responses.length.toString() + (_more ? mainText(context, " إجابة محمّلة — الملخص جزئي") : mainText(context, " إجابة محمّلة")),
          )),
           TabBar(tabs: [Tab(text: mainText(context, "Summary")), Tab(text: mainText(context, "Individual"))
                        ]),
                        Expanded(child: TabBarView(children: [
            _SummaryTab(polls: _post!.pollDataList, responses: _responses),
            _IndividualTab(polls: _post!.pollDataList, responses: _responses),
          ])),
          if (_more) TextButton(onPressed: _loading ? null : () => _load(),
            child: Text(_loading ? mainText(context, "جارٍ التحميل...") : mainText(context, "تحميل المزيد"))),
        ]),
      ),
    ),
  );
}

class _SummaryTab extends StatelessWidget {
  final List<PollData> polls;
  final List<Map<String, dynamic>> responses;

  const _SummaryTab({required this.polls, required this.responses});

  Map<String, dynamic>? _answersOf(Map<String, dynamic> r) {
    final a = r['answers'];
    if (a is Map) return Map<String, dynamic>.from(a);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (responses.isEmpty) return const _EmptyResponsesState();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: polls.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        final poll = polls[i];
        final key = '$i';
        final timeKey = '${i + 100000}';
        final values = <dynamic>[];
        for (final r in responses) {
          final answers = _answersOf(r);
          if (answers == null) continue;
          if (answers.containsKey(key)) {
            var v = answers[key];
            // NEW: دمج الوقت المخزّن على حدا (لو كاين) مع التاريخ
            if (poll.type == PollQuestionType.date && answers.containsKey(timeKey)) {
              v = _mergeDateTimeAnswer(v, answers[timeKey]);
            }
            values.add(v);
          }
        }
        return _QuestionSummaryCard(index: i, poll: poll, values: values);
      },
    );
  }
}

DateTime? _coerceDateTime(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  try {
    final dynamic dyn = v;
    final result = dyn.toDate();
    if (result is DateTime) return result;
  } catch (_) {}
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) return DateTime.tryParse(v);
  if (v is Map) {
    final hour = v['hour'];
    final minute = v['minute'];
    if (hour is num && minute is num) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour.toInt(), minute.toInt());
    }
  }
  return null;
}

String _two(int n) => n.toString().padLeft(2, '0');
dynamic _mergeDateTimeAnswer(dynamic dateVal, dynamic timeVal) {
  if (timeVal is! Map) return dateVal;
  final h = timeVal['hour'];
  final m = timeVal['minute'];
  if (h is! num || m is! num) return dateVal;

  DateTime? merge(dynamic single) {
    DateTime? d;
    if (single is String) d = DateTime.tryParse(single);
    if (single is DateTime) d = single;
    if (d == null) return null;
    return DateTime(d.year, d.month, d.day, h.toInt(), m.toInt());
  }

  if (dateVal is List) {
    return dateVal.map((e) {
      final merged = merge(e);
      return merged?.toIso8601String() ?? e;
    }).toList();
  }

  final merged = merge(dateVal);
  return merged?.toIso8601String() ?? dateVal;
}

class _IndividualTab extends StatelessWidget {
  final List<PollData> polls;
  final List<Map<String, dynamic>> responses;

  const _IndividualTab({required this.polls, required this.responses});

  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatDateTime(DateTime d, PollQuestionType type) {
    if (type == PollQuestionType.time) {
      return '${_two(d.hour)}:${_two(d.minute)}';
    }
    final datePart = '${_two(d.day)}/${_two(d.month)}/${d.year}';
    final hasTime = d.hour != 0 || d.minute != 0;
    return hasTime
        ? '$datePart  •  ${_two(d.hour)}:${_two(d.minute)}'
        : datePart;
  }

  String _formatAnswer(PollData poll, dynamic value) {
    if (value == null) return '—';

    if (poll.type == PollQuestionType.date ||
        poll.type == PollQuestionType.time) {
      if (value is List && value.isNotEmpty) {
        return value.map((e) {
          final dt = e is String
              ? DateTime.tryParse(e)
              : (e is DateTime ? e : null);
          return dt == null ? e.toString() : _formatDateTime(dt, poll.type);
        }).join(mainTextCurrent("، "));
      }
      final dt = value is String
          ? DateTime.tryParse(value)
          : (value is DateTime ? value : null);
      if (dt != null) return _formatDateTime(dt, poll.type);
    }

    if (value is num &&
        value.toInt() >= 0 &&
        value.toInt() < poll.options.length) {
      return poll.options[value.toInt()];
    }

    if (value is List) {
      return value.map((e) {
        if (e is num &&
            e.toInt() >= 0 &&
            e.toInt() < poll.options.length) {
          return poll.options[e.toInt()];
        }
        return e.toString();
      }).join(' • ');
    }

    return value.toString();
  }

  String? _submittedLabel(Map<String, dynamic> r) {
    final raw = r['submittedAt'];
    DateTime? d;
    if (raw is DateTime) {
      d = raw;
    } else {
      try {
        final result = raw.toDate();
        if (result is DateTime) d = result;
      } catch (_) {}
    }
    if (d == null) return null;
    return '${_two(d.day)}/${_two(d.month)}/${d.year}  ${_two(d.hour)}:${_two(d.minute)}';
  }

  Widget _buildAnswerWidget(PollData poll, dynamic rawValue, Map<String, dynamic> answers, int index) {
    dynamic value = rawValue;

    if (poll.type == PollQuestionType.date) {
      value = _mergeDateTimeAnswer(
        answers['$index'],
        answers['${index + 100000}'],
      );
    }

    switch (poll.type) {
      case PollQuestionType.date:
        return _DateAnswersList(
          values: value == null ? const [] : [value],
        );

      case PollQuestionType.time:
        return _TimeAnswersList(
          values: value == null ? const [] : [value],
        );

      case PollQuestionType.linearScale:
        if (poll.scaleStyle == LinearScaleStyle.slider) {
          return _SingleSliderAnswer(poll: poll, value: value);
        }
        return _SingleScaleAnswer(poll: poll, value: value);

      case PollQuestionType.grid:
      case PollQuestionType.checkboxGrid:
        return _GridSummary(
          poll: poll,
          values: value == null ? const [] : [value],
        );

      default:
        final text = _formatAnswer(poll, value);
        final isEmpty = text.trim().isEmpty || text == '—';
        return Text(
          isEmpty ? mainTextCurrent("No answer") : text,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            height: 1.35,
            color: isEmpty
                ? ThemeData.light().hintColor
                : null,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (responses.isEmpty) return const _EmptyResponsesState();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: responses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final r = responses[index];
        final answers = r['answers'] is Map
            ? Map<String, dynamic>.from(r['answers'] as Map)
            : <String, dynamic>{};
        final badgeColor = _chartPalette[index % _chartPalette.length];
        final submitted = _submittedLabel(r);
        final respondent = () {
          final name = r['respondentName']?.toString().trim();
          if (name != null && name.isNotEmpty) return name;
          // احتياطي للإجابات القديمة
          final id = r['respondentId']?.toString();
          if (id == null || id.isEmpty) return null;
          return id.length > 10 ? '${id.substring(0, 8)}…' : id;
        }();

        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              leading: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: badgeColor,
                  ),
                ),
              ),
              title: Text(
                mainText(context, "Response {0}", <Object?>[index + 1]),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    if (respondent != null)
                      Flexible(
                        child: Text(
                          respondent,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.hintColor,
                          ),
                        ),
                      ),

                    if (submitted != null && respondent != null)
                      Text('  •  ',
                          style: TextStyle(color: theme.hintColor)),
                    if (submitted != null) ...[
                      Icon(Icons.schedule_rounded,
                          size: 13, color: theme.hintColor),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          submitted,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: theme.hintColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              children: [
                for (int i = 0; i < polls.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _IndividualQuestionBlock(
                    index: i + 1,
                    question: polls[i].question.isEmpty
                        ? mainText(context, "Question {0}", <Object?>[i + 1])
                        : polls[i].question,
                    accent: badgeColor,
                    child: _buildAnswerWidget(
                      polls[i],
                      answers['$i'],
                      answers,
                      i,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _IndividualQuestionBlock extends StatelessWidget {
  final int index;
  final String question;
  final Widget child;
  final Color? accent;

  const _IndividualQuestionBlock({
    required this.index,
    required this.question,
    required this.child,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accent ?? theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '$index',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: theme.hintColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _SingleScaleAnswer extends StatelessWidget {
  final PollData poll;
  final dynamic value;

  const _SingleScaleAnswer({required this.poll, required this.value});

  List<String> _emojis() => pollScaleEmojis(poll.scaleSize ?? 5, alternate: poll.scaleStyle == LinearScaleStyle.emoji1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = (poll.scaleSize ?? 5).clamp(1, 10);
    final n = value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '');

    if (n == null || n < 0 || n >= size) {
      return Text('—', style: TextStyle(color: theme.hintColor));
    }

    final style = poll.scaleStyle;
    final isStars = style == LinearScaleStyle.stars;
    final isEmoji =
        style == LinearScaleStyle.emoji || style == LinearScaleStyle.emoji1;
    final isLine = style == LinearScaleStyle.line;
    final isSlider = style == LinearScaleStyle.slider;

    // ===== نجوم =====
    if (isStars) {
      return Row(
        children: List.generate(
          size,
              (i) => Icon(
            i <= n ? Icons.star_rounded : Icons.star_border_rounded,
            size: 26,
            color: const Color(0xFFFFC107),
          ),
        ),
      );
    }

    // ===== إيموجي =====
    if (isEmoji) {
      final faces = _emojis();
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(size, (i) {
          final selected = i == n;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: selected ? 44 : 36,
            height: selected ? 44 : 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.14)
                  : Colors.transparent,
              border: selected
                  ? Border.all(
                color: theme.colorScheme.primary,
                width: 2,
              )
                  : null,
            ),
            child: Opacity(
              opacity: selected ? 1 : 0.35,
              child: Text(
                faces[i],
                style: TextStyle(fontSize: selected ? 24 : 18),
              ),
            ),
          );
        }),
      );
    }

    if (isLine) {
      final low =
      poll.scaleMinLabel.trim().isNotEmpty ? poll.scaleMinLabel.trim() : mainText(context, "Low");
      final high =
      poll.scaleMaxLabel.trim().isNotEmpty ? poll.scaleMaxLabel.trim() : mainText(context, "High");

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(size, (i) {
              final selected = i == n;
              final filled = i <= n;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: i == size - 1 ? 0 : 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: filled
                        ? theme.colorScheme.primary
                        : theme.dividerColor.withValues(alpha: 0.25),
                  ),
                  child: selected
                      ? Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  )
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  low,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.hintColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${n + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  high,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.hintColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // افتراضي
    return Text(
      '${n + 1} / $size',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

class _SingleSliderAnswer extends StatelessWidget {
  final PollData poll;
  final dynamic value;

  const _SingleSliderAnswer({required this.poll, required this.value});

  double? _parsePercent() {
    if (value == null) return null;

    // قائمة (احتياطي)
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      return _toPercent(first);
    }

    return _toPercent(value);
  }

  double? _toPercent(dynamic v) {
    if (v == null) return null;

    if (v is num) {
      final n = v.toDouble();
      // 0..100
      if (n >= 0 && n <= 100) return n;
      // 0..1
      if (n >= 0 && n <= 1) return n * 100;
    }

    final d = double.tryParse(v.toString());
    if (d == null) return null;
    if (d >= 0 && d <= 100) return d;
    if (d >= 0 && d <= 1) return d * 100;
    return null;
  }

  

  

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = _parsePercent();

    if (percent == null) {
      return Text(
        mainText(context, "No answer"),
        style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.w600),
      );
    }

    final accent = pollSliderColor(percent);
    final emoji = pollSliderEmoji(percent);

    return Column(
      children: [
        // رأس: إيموجي + نسبة
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Text(
              '${percent.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // شريط السلايدر للعرض فقط — بدون منحنى
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            activeTrackColor: accent,
            inactiveTrackColor: accent.withValues(alpha: 0.18),
            disabledActiveTrackColor: accent,
            disabledInactiveTrackColor: accent.withValues(alpha: 0.18),
            disabledThumbColor: accent,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Slider(
            value: percent.clamp(0, 100),
            min: 0,
            max: 100,
            onChanged: null,
          ),
        ),
      ],
    );
  }
}







class _DonutPainter extends CustomPainter {
  final List<double> ratios;
  final List<Color> colors;
  final double progress;
  final double strokeWidth;

  _DonutPainter({
    required this.ratios,
    required this.colors,
    required this.progress,
    this.strokeWidth = 22,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -pi / 2;
    const gap = 0.02; // فاصل بسيط بين القطاعات لإحساس أنظف
    for (var i = 0; i < ratios.length; i++) {
      final sweep = ratios[i] * 2 * pi * progress;
      if (sweep <= 0.001) continue;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, max(0.0, sweep - gap), false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.ratios != ratios;
}

class _PollDonutChart extends StatelessWidget {
  final List<int> counts;
  final List<Color> colors;
  final int total;

  const _PollDonutChart(
      {required this.counts, required this.colors, required this.total});

  @override
  Widget build(BuildContext context) {
    final safeTotal = total == 0 ? 1 : total;
    final ratios = counts.map((c) => c / safeTotal).toList();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: 148,
          height: 148,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(148, 148),
                painter: _DonutPainter(ratios: ratios, colors: colors, progress: value),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$total', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  Text(
                    total == 1 ? mainText(context, "response") : mainText(context, "responses"),
                    style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
class _PollBarRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _PollBarRow(
      {required this.label, required this.count, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : count / total;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text('$count', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: color)),
              const SizedBox(width: 4),
              Text('(${(ratio * 100).toStringAsFixed(0)}%)',
                  style: TextStyle(fontSize: 11.5, color: theme.hintColor)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 750),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 9,
                backgroundColor: theme.dividerColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _CurvePainter extends CustomPainter {
  final List<double> ratios;
  final Color color;
  final double progress;
  final double? averageIndex; // 0 .. n-1 (يمكن كسر)

  _CurvePainter({
    required this.ratios,
    required this.color,
    required this.progress,
    this.averageIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (ratios.isEmpty) return;

    final n = ratios.length;
    final padX = 12.0;
    final padY = 16.0;
    final w = size.width - padX * 2;
    final h = size.height - padY * 2;

    Offset pointAt(double i) {
      final t = n == 1 ? 0.5 : i / (n - 1);
      final x = padX + w * t;
      final idx = i.round().clamp(0, n - 1);
      // ارتفاع تقريبي عند المتوسط: استيفاء خطي بين نقطتين
      double r;
      if (i <= 0) {
        r = ratios.first;
      } else if (i >= n - 1) {
        r = ratios.last;
      } else {
        final lo = i.floor();
        final hi = i.ceil();
        final f = i - lo;
        r = ratios[lo] * (1 - f) + ratios[hi] * f;
      }
      final y = padY + h * (1 - r.clamp(0.0, 1.0) * progress);
      return Offset(x, y);
    }

    final path = Path();
    final pts = List.generate(n, (i) => pointAt(i.toDouble()));

    path.moveTo(pts.first.dx, pts.first.dy);
    if (n == 2) {
      path.lineTo(pts[1].dx, pts[1].dy);
    } else if (n > 2) {
      for (int i = 0; i < n - 1; i++) {
        final p0 = pts[i == 0 ? 0 : i - 1];
        final p1 = pts[i];
        final p2 = pts[i + 1];
        final p3 = pts[i + 2 < n ? i + 2 : n - 1];
        final c1 = Offset(
          p1.dx + (p2.dx - p0.dx) / 6,
          p1.dy + (p2.dy - p0.dy) / 6,
        );
        final c2 = Offset(
          p2.dx - (p3.dx - p1.dx) / 6,
          p2.dy - (p3.dy - p1.dy) / 6,
        );
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
      }
    }

    final fill = Path.from(path)
      ..lineTo(pts.last.dx, size.height - padY)
      ..lineTo(pts.first.dx, size.height - padY)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0.02),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (final p in pts) {
      canvas.drawCircle(p, 4.5, Paint()..color = color);
      canvas.drawCircle(p, 2.2, Paint()..color = Colors.white);
    }

    // ===== نقطة الثقل (المتوسط) =====
    if (averageIndex != null && progress > 0.2) {
      final avgPt = pointAt(averageIndex!);

      // خط عمودي خفيف
      canvas.drawLine(
        Offset(avgPt.dx, padY),
        Offset(avgPt.dx, size.height - padY),
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke,
      );

      // حلقة خارجية
      canvas.drawCircle(
        avgPt,
        9,
        Paint()
          ..color = color.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        avgPt,
        7,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
      canvas.drawCircle(
        avgPt,
        3.5,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CurvePainter old) =>
      old.progress != progress ||
          old.ratios != ratios ||
          old.color != color ||
          old.averageIndex != averageIndex;
}

class _PollCurveChart extends StatefulWidget {
  final List<int> counts;
  final int total;
  final Color color;
  final List<String>? labels;

  const _PollCurveChart({
    required this.counts,
    required this.total,
    required this.color,
    this.labels,
  });

  @override
  State<_PollCurveChart> createState() => _PollCurveChartState();
}

class _PollCurveChartState extends State<_PollCurveChart> {
  bool _showAvgLabel = false;

  double? get _averageIndex {
    if (widget.counts.isEmpty || widget.total <= 0) return null;
    double sum = 0;
    for (int i = 0; i < widget.counts.length; i++) {
      sum += i * widget.counts[i];
    }
    return sum / widget.total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counts = widget.counts;
    final maxC = counts.isEmpty ? 1 : counts.reduce(max).clamp(1, 1 << 30);
    final ratios = counts.map((c) => c / maxC).toList();
    final avg = _averageIndex;
    final n = counts.length;

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            const height = 140.0;
            const padX = 12.0;
            const padY = 16.0;
            final w = width - padX * 2;
            final h = height - padY * 2;

            Offset? avgOffset;
            if (avg != null && n > 0) {
              final t = n == 1 ? 0.5 : avg / (n - 1);
              // ارتفاع تقريبي
              double r;
              if (avg <= 0) {
                r = ratios.first;
              } else if (avg >= n - 1) {
                r = ratios.last;
              } else {
                final lo = avg.floor();
                final hi = avg.ceil();
                final f = avg - lo;
                r = ratios[lo] * (1 - f) + ratios[hi] * f;
              }
              avgOffset = Offset(
                padX + w * t,
                padY + h * (1 - r.clamp(0.0, 1.0)),
              );
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                if (avgOffset == null) return;
                final d = (details.localPosition - avgOffset).distance;
                if (d <= 28) {
                  setState(() => _showAvgLabel = !_showAvgLabel);
                } else {
                  setState(() => _showAvgLabel = false);
                }
              },
              child: SizedBox(
                height: height,
                width: width,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 750),
                      curve: Curves.easeOutCubic,
                      builder: (context, t, _) {
                        return CustomPaint(
                          size: Size(width, height),
                          painter: _CurvePainter(
                            ratios: ratios,
                            color: widget.color,
                            progress: t,
                            averageIndex: avg,
                          ),
                        );
                      },
                    ),
                    if (_showAvgLabel && avg != null && avgOffset != null)
                      Positioned(
                        left: (avgOffset.dx - 48).clamp(0.0, width - 96),
                        top: (avgOffset.dy - 36).clamp(0.0, height - 28),
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.inverseSurface,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              mainText(context, "Average {0}", <Object?>[(avg + 1).toStringAsFixed(1)]),
                              style: TextStyle(
                                color: theme.colorScheme.onInverseSurface,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        if (widget.labels != null && widget.labels!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: List.generate(widget.labels!.length, (i) {
              return Expanded(
                child: Text(
                  widget.labels![i],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: theme.hintColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
class _Legend extends StatelessWidget {
  final List<String> options;
  final Map<int, int> counts;
  final List<Color> colors;
  final int total;

  const _Legend(
      {required this.options, required this.counts, required this.colors, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeTotal = total == 0 ? 1 : total;

    return Column(
      children: List.generate(options.length, (i) {
        final c = counts[i] ?? 0;
        final pct = (c / safeTotal * 100).toStringAsFixed(0);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(options[i],
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Text('$c', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
              const SizedBox(width: 4),
              Text('($pct%)', style: TextStyle(fontSize: 11, color: theme.hintColor)),
            ],
          ),
        );
      }),
    );
  }
}
enum _ChartView { donut, bar ,curve }

class _ChartToggle extends StatelessWidget {
  final _ChartView value;
  final ValueChanged<_ChartView> onChanged;
  final Set<_ChartView> allowed;

  const _ChartToggle({
    required this.value,
    required this.onChanged,
    this.allowed = const {
      _ChartView.donut,
      _ChartView.bar,
      _ChartView.curve,
    },
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget button(_ChartView v, IconData icon) {
      if (!allowed.contains(v)) return const SizedBox.shrink();
      final selected = value == v;
      return InkWell(
        onTap: () => onChanged(v),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: selected
                ? scheme.primary
                : scheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(_ChartView.donut, Icons.pie_chart_rounded),
          button(_ChartView.bar, Icons.bar_chart_rounded),
          button(_ChartView.curve, Icons.show_chart_rounded),
        ],
      ),
    );
  }
}
class _ScaleDistribution extends StatelessWidget {
  final PollData poll;
  final List<dynamic> values;
  final List<String>? labels;
  final bool starMode;

  const _ScaleDistribution({
    required this.poll,
    required this.values,
    this.labels,
    this.starMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = poll.scaleSize ?? 5;
    final bottomLabels = labels ?? List.generate(size, (i) => '${i + 1}');
    final isEmojiLabels = labels != null &&
        labels!.isNotEmpty &&
        labels!.first.length > 1; // تقريباً إيموجي

    final nums = values
        .map((v) => v is num ? v.toInt() : int.tryParse(v.toString()))
        .whereType<int>()
        .toList();

    if (nums.isEmpty) {
      return Text(mainText(context, "No numeric answers"),
          style: TextStyle(color: theme.hintColor));
    }

    final counts = List<int>.filled(size, 0);
    for (final n in nums) {
      if (n >= 0 && n < size) counts[n]++;
    }
    final maxCount = counts.reduce(max).clamp(1, 1 << 30);
    final avg = nums.reduce((a, b) => a + b) / nums.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up_rounded,
                size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              mainText(context, "Average: {0} / {1}", <Object?>[(avg + 1).toStringAsFixed(1), size]),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 115,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(size, (i) {
              final ratio = counts[i] / maxCount;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${counts[i]}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: ratio),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => Container(
                          height: 70 * value.clamp(0.04, 1.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                _chartPalette[0],
                                _chartPalette[0].withValues(alpha: 0.55),
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (starMode)
                        Text(
                          bottomLabels[i.clamp(0, bottomLabels.length - 1)],
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFFC107),
                          ),
                        )
                      else
                      Text(
                        bottomLabels[i.clamp(0, bottomLabels.length - 1)],
                        style: TextStyle(
                          fontSize: isEmojiLabels ? 15 : 11,
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
class _SliderScaleSummary extends StatelessWidget {
  final PollData poll;
  final List<dynamic> values;

  const _SliderScaleSummary({required this.poll, required this.values});

  List<int> _bucketCounts({int buckets = 10}) {
    final counts = List<int>.filled(buckets, 0);
    for (final v in values) {
      final n = v is num ? v.toDouble() : double.tryParse(v.toString());
      if (n == null) continue;
      final x = n.clamp(0.0, 100.0);
      final i = (x / 100 * (buckets - 1)).round().clamp(0, buckets - 1);
      counts[i]++;
    }
    return counts;
  }

  List<double> _numericValues() {
    return values
        .map((v) => v is num ? v.toDouble() : double.tryParse(v.toString()))
        .whereType<double>()
        .map((v) => v.clamp(0.0, 100.0))
        .toList();
  }

  

  

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nums = _numericValues();
    if (nums.isEmpty) {
      return Text(mainText(context, "No answers yet"), style: TextStyle(color: theme.hintColor));
    }

    final avg = nums.reduce((a, b) => a + b) / nums.length;
    final accent = pollSliderColor(avg);
    final emoji = pollSliderEmoji(avg);
    final buckets = _bucketCounts(buckets: 10);
    final maxC = buckets.reduce(max).clamp(1, 1 << 30);
    final ratios = buckets.map((c) => c / maxC).toList();

    // فهرس المتوسط على 0..9 للمنحنى
    final avgIndex = (avg / 100 * (buckets.length - 1));

    return Column(
      children: [
        // رأس: إيموجي + متوسط %
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Text(
              '${avg.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          mainText(context, "{0} response{1}  ·  avg", <Object?>[nums.length, nums.length == 1 ? '' : 's']),
          style: TextStyle(fontSize: 12, color: theme.hintColor),
        ),
        const SizedBox(height: 16),

        // منحنى التوزيع على 0–100
        SizedBox(
          height: 140,
          width: double.infinity,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 750),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) {
              return CustomPaint(
                painter: _CurvePainter(
                  ratios: ratios,
                  color: accent,
                  progress: t,
                  averageIndex: avgIndex,
                ),
              );
            },
          ),
        ),

        // تسميات 0% — 50% — 100%
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                poll.scaleMinLabel.isNotEmpty ? poll.scaleMinLabel : '0%',
                style: TextStyle(fontSize: 11, color: theme.hintColor),
              ),
              Text('50%', style: TextStyle(fontSize: 11, color: theme.hintColor)),
              Text(
                poll.scaleMaxLabel.isNotEmpty ? poll.scaleMaxLabel : '100%',
                style: TextStyle(fontSize: 11, color: theme.hintColor),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // شريط متوسط يشبه السلايدر (للقراءة فقط)
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            activeTrackColor: accent,
            inactiveTrackColor: accent.withValues(alpha: 0.18),
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Slider(
            value: avg.clamp(0, 100),
            min: 0,
            max: 100,
            onChanged: null, // للعرض فقط
          ),
        ),
      ],
    );
  }
}
class _LineScaleSummary extends StatelessWidget {
  final PollData poll;
  final List<dynamic> values;
  final bool useCurve;

  const _LineScaleSummary({
    required this.poll,
    required this.values,
    this.useCurve = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = poll.scaleSize ?? 5;
    final nums = values
        .map((v) => v is num ? v.toInt() : int.tryParse(v.toString()))
        .whereType<int>()
        .where((n) => n >= 0 && n < size)
        .toList();

    if (nums.isEmpty) {
      return Text(mainText(context, "No answers yet"), style: TextStyle(color: theme.hintColor));
    }

    final counts = List<int>.filled(size, 0);
    for (final n in nums) {
      counts[n]++;
    }
    final total = nums.length;
    final maxC = counts.reduce(max).clamp(1, 1 << 30);
    final avg = nums.reduce((a, b) => a + b) / nums.length;
    final primary = theme.colorScheme.primary;

    if (useCurve) {
      return Column(
        children: [
          _avgHeader(theme, avg, size, primary),
          const SizedBox(height: 12),
          _PollCurveChart(
            counts: counts,
            total: total,
            color: primary,
            labels: null, // بلا أرقام تحت المنحنى
          ),
          const SizedBox(height: 8),
          _endLabels(theme),
        ],
      );
    }

    // ===== شريط نقاط مثل واجهة الإجابة (بدون أعمدة) =====
    return Column(
      children: [
        _avgHeader(theme, avg, size, primary),
        const SizedBox(height: 22),
        SizedBox(
          height: 40,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth - 20;
              final avgT = size <= 1 ? 0.0 : (avg / (size - 1)).clamp(0.0, 1.0);

              return Stack(
                alignment: Alignment.center,
                children: [
                  // الخط الرمادي
                  Positioned(
                    left: 10,
                    right: 10,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // تعبئة حتى المتوسط
                  Positioned(
                    left: 10,
                    child: Container(
                      width: trackWidth * avgT,
                      height: 3,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // النقاط
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(size, (i) {
                        final c = counts[i];
                        final intensity = c / maxC;
                        final isAvg = avg.round().clamp(0, size - 1) == i;
                        final base = c == 0 ? 12.0 : 14.0 + 8.0 * intensity;

                        return Tooltip(
                          message: '$c response${c == 1 ? '' : 's'}',
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            width: isAvg ? base + 4 : base,
                            height: isAvg ? base + 4 : base,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c == 0
                                  ? theme.colorScheme.surface
                                  : primary.withValues(
                                alpha: 0.22 + 0.78 * intensity,
                              ),
                              border: Border.all(
                                color: c == 0 ? theme.dividerColor : primary,
                                width: isAvg ? 2.5 : 2,
                              ),
                              boxShadow: isAvg
                                  ? [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                ),
                              ]
                                  : null,
                            ),
                            child: c > 0
                                ? Text(
                              '$c',
                              style: TextStyle(
                                fontSize: base > 18 ? 10 : 8,
                                fontWeight: FontWeight.w800,
                                color: intensity > 0.45
                                    ? Colors.white
                                    : primary,
                              ),
                            )
                                : null,
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _endLabels(theme),
      ],
    );
  }

  Widget _avgHeader(ThemeData theme, double avg, int size, Color primary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.linear_scale, size: 16, color: primary),
        const SizedBox(width: 6),
        Text(
          mainTextCurrent("Average step {0} / {1}", <Object?>[(avg + 1).toStringAsFixed(1), size]),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: primary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _endLabels(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          poll.scaleMinLabel.isNotEmpty ? poll.scaleMinLabel : mainTextCurrent("Low"),
          style: TextStyle(fontSize: 11, color: theme.hintColor),
        ),
        Text(mainTextCurrent("Neutral"),
            style: TextStyle(fontSize: 11, color: theme.hintColor)),
        Text(
          poll.scaleMaxLabel.isNotEmpty ? poll.scaleMaxLabel : mainTextCurrent("High"),
          style: TextStyle(fontSize: 11, color: theme.hintColor),
        ),
      ],
    );
  }
}
class _TextAnswersList extends StatelessWidget {
  final List<dynamic> values;
  const _TextAnswersList({required this.values});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (values.isEmpty) return Text(mainText(context, "No text answers yet"), style: TextStyle(color: theme.hintColor));

    return Column(
      children: values.take(20).map((v) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.format_quote_rounded, size: 16, color: theme.hintColor),
              const SizedBox(width: 8),
              Expanded(child: Text(v.toString(), style: const TextStyle(fontSize: 13.5, height: 1.4))),
            ],
          ),
        );
      }).toList(),
    );
  }
}
class _DateAnswerEntry {
  final DateTime date;
  int count;
  _DateAnswerEntry({required this.date, this.count = 1});
}

class _DateAnswersList extends StatelessWidget {
  final List<dynamic> values;
  const _DateAnswersList({required this.values});

  List<_DateAnswerEntry> _group() {
    final flat = <dynamic>[];
    for (final v in values) {
      if (v is List) {
        flat.addAll(v);
      } else {
        flat.add(v);
      }
    }
    final map = <String, _DateAnswerEntry>{};
    for (final raw in flat) {
      final d = _coerceDateTime(raw);
      if (d == null) continue;
      final hasTime = d.hour != 0 || d.minute != 0;
      final key = hasTime
          ? '${d.year}-${d.month}-${d.day}_${d.hour}:${d.minute}'
          : '${d.year}-${d.month}-${d.day}';
      if (map.containsKey(key)) {
        map[key]!.count++;
      } else {
        map[key] = _DateAnswerEntry(date: d);
      }
    }
    final list = map.values.toList()
      ..sort((a, b) {
        final byCount = b.count.compareTo(a.count);
        return byCount != 0 ? byCount : a.date.compareTo(b.date);
      });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = _group();
    if (entries.isEmpty) {
      return Text(mainText(context, "No answers yet"), style: TextStyle(color: theme.hintColor));
    }

    return Column(
      children: entries.map((e) {
        final d = e.date;
        final hasTime = d.hour != 0 || d.minute != 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient:  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTeal.main, AppTeal.accent],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${d.day}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, height: 1)),
                    Text(DateFormat.MMM(Localizations.localeOf(context).languageCode).format(d),
                        style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat.yMMMEd(Localizations.localeOf(context).languageCode).format(d),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                    if (hasTime) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time_rounded, size: 13, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${_two(d.hour)}:${_two(d.minute)}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (e.count > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('×${e.count}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TimeAnswersList extends StatelessWidget {
  final List<dynamic> values;
  const _TimeAnswersList({required this.values});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flat = <dynamic>[];
    for (final v in values) {
      if (v is List) {
        flat.addAll(v);
      } else {
        flat.add(v);
      }
    }
    final grouped = <String, int>{};
    for (final raw in flat) {
      final d = _coerceDateTime(raw);
      if (d == null) continue;
      final key = '${_two(d.hour)}:${_two(d.minute)}';
      grouped[key] = (grouped[key] ?? 0) + 1;
    }
    if (grouped.isEmpty) return Text(mainText(context, "No answers yet"), style: TextStyle(color: theme.hintColor));
    final sorted = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sorted.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              theme.colorScheme.primary.withValues(alpha: 0.10),
              theme.colorScheme.primary.withValues(alpha: 0.04),
            ]),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time_rounded, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(e.key, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
              if (e.value > 1) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('${e.value}',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
class _GridSummary extends StatelessWidget {
  final PollData poll;
  final List<dynamic> values;

  const _GridSummary({required this.poll, required this.values});

  Map<int, Map<int, int>> _parseCounts() {
    final rows = poll.gridRows.length;
    final cols = poll.gridColumns.length;
    final counts = <int, Map<int, int>>{
      for (var r = 0; r < rows; r++) r: {for (var c = 0; c < cols; c++) c: 0},
    };

    void addCell(int r, int c) {
      if (r < 0 || r >= rows || c < 0 || c >= cols) return;
      counts[r]![c] = (counts[r]![c] ?? 0) + 1;
    }

    int? resolveCol(dynamic raw) {
      if (raw is num) return raw.toInt();
      if (raw is String) {
        final asInt = int.tryParse(raw);
        if (asInt != null) return asInt;
        final idx = poll.gridColumns.indexOf(raw);
        return idx >= 0 ? idx : null;
      }
      return null;
    }

    for (final v in values) {
      if (v is Map) {
        // شكل شائع: { "0": 2, "1": [0,2] } → مفتاح = فهرس الصف
        v.forEach((rowKey, colVal) {
          final r = int.tryParse(rowKey.toString());
          if (r == null) return;
          if (colVal is List) {
            for (final cv in colVal) {
              final c = resolveCol(cv);
              if (c != null) addCell(r, c);
            }
          } else {
            final c = resolveCol(colVal);
            if (c != null) addCell(r, c);
          }
        });
      } else if (v is List) {
        // شكل بديل: قائمة موقعها = فهرس الصف
        for (var r = 0; r < v.length && r < rows; r++) {
          final colVal = v[r];
          if (colVal is List) {
            for (final cv in colVal) {
              final c = resolveCol(cv);
              if (c != null) addCell(r, c);
            }
          } else if (colVal != null) {
            final c = resolveCol(colVal);
            if (c != null) addCell(r, c);
          }
        }
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (poll.gridRows.isEmpty || poll.gridColumns.isEmpty) {
      return Text(mainText(context, "No grid data"), style: TextStyle(color: theme.hintColor));
    }

    final counts = _parseCounts();
    final maxCount = counts.values.expand((row) => row.values)
        .fold<int>(1, (a, b) => max(a, b));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Table(
          defaultColumnWidth: const FixedColumnWidth(64),
          border: TableBorder.all(color: theme.dividerColor.withValues(alpha: 0.25)),
          children: [
            TableRow(
              decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
              children: [
                const _GridHeaderCell(text: ''),
                for (final col in poll.gridColumns) _GridHeaderCell(text: col),
              ],
            ),
            for (var r = 0; r < poll.gridRows.length; r++)
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      poll.gridRows[r],
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                  for (var c = 0; c < poll.gridColumns.length; c++)
                    _GridCell(count: counts[r]?[c] ?? 0, maxCount: maxCount),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _GridHeaderCell extends StatelessWidget {
  final String text;
  const _GridHeaderCell({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _GridCell extends StatelessWidget {
  final int count;
  final int maxCount;
  const _GridCell({required this.count, required this.maxCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final intensity = maxCount == 0 ? 0.0 : count / maxCount;
    final color = _chartPalette0;
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: count == 0 ? Colors.transparent : color.withValues(alpha: 0.12 + intensity * 0.55),
      child: Text(
        count == 0 ? '—' : '$count',
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: intensity > 0.55 ? Colors.white : theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

 Color _chartPalette0 = AppTeal.main;

class _EmptyResponsesState extends StatelessWidget {
  const _EmptyResponsesState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.poll_outlined, size: 44, color: theme.hintColor.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(mainText(context, "No responses yet"), style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
class _QuestionSummaryCard extends StatefulWidget {
  final int index;
  final PollData poll;
  final List<dynamic> values;

  const _QuestionSummaryCard(
      {required this.index, required this.poll, required this.values});

  @override
  State<_QuestionSummaryCard> createState() => _QuestionSummaryCardState();
}
class _QuestionSummaryCardState extends State<_QuestionSummaryCard> {
  _ChartView _view = _ChartView.donut;

  bool get _isChoiceType =>
      widget.poll.type == PollQuestionType.singelOptin ||
          widget.poll.type == PollQuestionType.dropdown ||
          widget.poll.type == PollQuestionType.checkbox;

  bool get _isScaleType => widget.poll.type == PollQuestionType.linearScale;
  bool get _isSliderScale =>
      widget.poll.type == PollQuestionType.linearScale &&
          widget.poll.scaleStyle == LinearScaleStyle.slider;
  bool get _isLineScale =>
      widget.poll.type == PollQuestionType.linearScale &&
          widget.poll.scaleStyle == LinearScaleStyle.line;
  bool get _supportsToggle =>
      (_isChoiceType && widget.poll.options.isNotEmpty) ||
          (_isScaleType && !_isSliderScale);

  IconData get _typeIcon {
    switch (widget.poll.type) {
      case PollQuestionType.singelOptin:
        return Icons.radio_button_checked_rounded;
      case PollQuestionType.dropdown:
        return Icons.arrow_drop_down_circle_rounded;
      case PollQuestionType.checkbox:
        return Icons.check_box_rounded;
      case PollQuestionType.linearScale:
        return Icons.linear_scale_rounded;
      case PollQuestionType.shortText:
      case PollQuestionType.longText:
        return Icons.short_text_rounded;
      case PollQuestionType.date:
        return Icons.calendar_today_rounded;
      case PollQuestionType.time:
        return Icons.access_time_rounded;
      case PollQuestionType.grid:
      case PollQuestionType.checkboxGrid:
        return Icons.grid_on_rounded;
    }
  }
  @override
  void initState() {
    super.initState();
    if (_isLineScale) {
      _view = _ChartView.bar; // لا تبدأ بالدائرة
    }
  }
  List<String> _scaleEmojis(PollData poll) => pollScaleEmojis(poll.scaleSize ?? 5, alternate: poll.scaleStyle == LinearScaleStyle.emoji1);
  Map<int, int> _optionCounts() {
    final counts = <int, int>{for (var i = 0; i < widget.poll.options.length; i++) i: 0};
    for (final v in widget.values) {
      if (v is num) {
        final i = v.toInt();
        if (counts.containsKey(i)) counts[i] = counts[i]! + 1;
      } else if (v is String) {
        final i = widget.poll.options.indexOf(v);
        if (i >= 0) counts[i] = (counts[i] ?? 0) + 1;
      } else if (v is List) {
        for (final e in v) {
          final i = e is num ? e.toInt() : widget.poll.options.indexOf(e.toString());
          if (i >= 0) counts[i] = (counts[i] ?? 0) + 1;
        }
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final poll = widget.poll;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 14, offset: const Offset(0, 6))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16,16,16,16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.only(left: 0, top: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(_typeIcon, size: 16, color: theme.colorScheme.primary),
              ),SizedBox(width: 10,
              ),
              Expanded(
                child: Text(
                  poll.question.isEmpty ? mainText(context, "Question {0}", <Object?>[widget.index + 1]) : poll.question,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              if (_supportsToggle)
                _ChartToggle(
                  value: _view,
                  onChanged: (v) {
                    if (_isLineScale && v == _ChartView.donut) return;
                    setState(() => _view = v);
                  },
                  allowed: _isLineScale
                      ? const {_ChartView.bar, _ChartView.curve}
                      : const {_ChartView.donut, _ChartView.bar, _ChartView.curve},
                ),
            ],
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Text(
              mainText(context, "{0} answer{1}", <Object?>[widget.values.length, widget.values.length == 1 ? '' : 's']),
              style: TextStyle(fontSize: 12, color: theme.hintColor),
            ),
          ),
          const SizedBox(height: 14),
          _buildBody(theme),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final poll = widget.poll;
    switch (poll.type) {
      case PollQuestionType.singelOptin:
      case PollQuestionType.dropdown:
      case PollQuestionType.checkbox:
        return _buildChoiceBody(theme);
      case PollQuestionType.linearScale:
        if (poll.scaleStyle == LinearScaleStyle.slider) {
          return _SliderScaleSummary(poll: poll, values: widget.values);
        }
        return _buildScaleBody(theme);
      case PollQuestionType.shortText:
      case PollQuestionType.longText:
        return _TextAnswersList(values: widget.values);
      case PollQuestionType.date:
        return _DateAnswersList(values: widget.values);
      case PollQuestionType.time:
        return _TimeAnswersList(values: widget.values);
      case PollQuestionType.grid:
      case PollQuestionType.checkboxGrid:
        return _GridSummary(poll: poll, values: widget.values);
    }
  }

  Widget _buildChoiceBody(ThemeData theme) {
    final poll = widget.poll;
    if (poll.options.isEmpty) {
      return Text(mainText(context, "No options"), style: TextStyle(color: theme.hintColor));
    }

    final counts = _optionCounts();
    final total = widget.values.length;
    final colors = List.generate(
      poll.options.length,
          (i) => _chartPalette[i % _chartPalette.length],
    );
    final countList = List.generate(poll.options.length, (i) => counts[i] ?? 0);

    if (_view == _ChartView.donut) {
      return Column(
        children: [
          Center(
            child: _PollDonutChart(
              counts: countList,
              colors: colors,
              total: total,
            ),
          ),
          const SizedBox(height: 16),
          _Legend(
            options: poll.options,
            counts: counts,
            colors: colors,
            total: total,
          ),
        ],
      );
    }

    if (_view == _ChartView.curve) {
      return Column(
        children: [
          _PollCurveChart(
            counts: countList,
            total: total,
            color: colors.first,
            labels: poll.options,
          ),
          const SizedBox(height: 12),
          _Legend(
            options: poll.options,
            counts: counts,
            colors: colors,
            total: total,
          ),
        ],
      );
    }

    // bar
    return Column(
      children: List.generate(
        poll.options.length,
            (i) => _PollBarRow(
          label: poll.options[i],
          count: counts[i] ?? 0,
          total: total,
          color: colors[i],
        ),
      ),
    );
  }

  Widget _buildScaleBody(ThemeData theme) {
    final size = widget.poll.scaleSize ?? 5;
    final style = widget.poll.scaleStyle;
    if (style == LinearScaleStyle.line) {
      return _LineScaleSummary(
        poll: widget.poll,
        values: widget.values,
        useCurve: _view == _ChartView.curve,
      );
    }
    final isEmoji = style == LinearScaleStyle.emoji ||
        style == LinearScaleStyle.emoji1;
    final isStars = style == LinearScaleStyle.stars;

    final List<String> labels;
    if (isEmoji) {
      labels = _scaleEmojis(widget.poll);
    } else if (isStars) {
      labels = List.generate(size, (i) => '★${i + 1}');
    } else {
      labels = List.generate(size, (i) => '${i + 1}');
    }

    final counts = <int, int>{for (var i = 0; i < size; i++) i: 0};
    for (final v in widget.values) {
      final n = v is num ? v.toInt() : int.tryParse(v.toString());
      if (n != null && n >= 0 && n < size) {
        counts[n] = counts[n]! + 1;
      }
    }

    final total = widget.values.length;
    final colors = isStars
        ? List.generate(size, (i) {
      final t = size <= 1 ? 1.0 : i / (size - 1);
      return Color.lerp(
        const Color(0xFFFFE082), // فاتح
        const Color(0xFFFF8F00), // غامق
        t,
      )!;
    })
        : List.generate(size, (i) => _chartPalette[i % _chartPalette.length]);
    final countList = List.generate(size, (i) => counts[i] ?? 0);

    final nums = widget.values
        .map((v) => v is num ? v.toDouble() : double.tryParse(v.toString()))
        .whereType<double>()
        .toList();

    if (_view == _ChartView.bar) {
      return _ScaleDistribution(
        poll: widget.poll,
        values: widget.values,
        labels: labels,
        starMode: isStars,
      );
    }

    if (_view == _ChartView.curve) {
      return _PollCurveChart(
        counts: countList,
        total: total,
        color: isStars ? const Color(0xFFFFC107) : _chartPalette[0],
        labels: labels,
      );
    }

    // donut
    return Column(
      children: [
        if (nums.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isStars ? Icons.star_rounded : Icons.trending_up_rounded,
                  size: 16,
                  color: isStars
                      ? const Color(0xFFFFC107)
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  mainText(context, "Average: {0} / {1}", <Object?>[(nums.reduce((a, b) => a + b) / nums.length + 1).toStringAsFixed(1), size]),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isStars
                        ? const Color(0xFFFFC107)
                        : theme.colorScheme.primary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        Center(
          child: _PollDonutChart(
            counts: countList,
            colors: colors,
            total: total,
          ),
        ),
        const SizedBox(height: 16),
        _Legend(
          options: isStars
              ? List.generate(size, (i) => '★${i + 1}')
              : labels,
          counts: counts,
          colors: colors,
          total: total,
        ),
      ],
    );
  }
}
//==============================================================================================
 List<Color> _chartPalette = [
  AppTeal.main, // teal (العلامة التجارية)
  Color(0xFF6366F1), // indigo
  Color(0xFFF59E0B), // amber
  Color(0xFFEC4899), // pink
  Color(0xFF10B981), // green
  Color(0xFF8B5CF6), // violet
  Color(0xFFEF4444), // red
  Color(0xFF06B6D4), // cyan
  Color(0xFFF97316), // orange
  Color(0xFF64748B), // slate
];
// شريحة موحدة تحافظ على الترتيب
