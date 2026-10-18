part of '../../main.dart';

final moderationRevision = ValueNotifier<int>(0);

class CommunityReportsInboxScreen extends StatefulWidget {
  const CommunityReportsInboxScreen({super.key});

  @override
  State<CommunityReportsInboxScreen> createState() =>
      _CommunityReportsInboxScreenState();
}

class _ModerationInboxRow {
  const _ModerationInboxRow(this.id, this._data);
  final String id;
  final Map<String, dynamic> _data;
  Map<String, dynamic> data() => _data;
}

dynamic _decodeReportValue(dynamic value) {
  if (value is List) return value.map(_decodeReportValue).toList();
  if (value is Map) {
    if (value.length == 1 && value['__reportTime'] is num) {
      return Timestamp.fromMillisecondsSinceEpoch(
          (value['__reportTime'] as num).toInt());
    }
    return value.map((k,v) => MapEntry(k.toString(), _decodeReportValue(v)));
  }
  return value;
}

class _CommunityReportsInboxScreenState
    extends State<CommunityReportsInboxScreen> {
  String _filter = 'pending';
  String _search = '';
  final TextEditingController _searchCtrl = TextEditingController();

  // ===== عدّادات سريعة لكل حالة (لعرضها فالرأس) =====
  Map<String, int> _counts = {
    'pending': 0,
    'actioned': 0,
    'dismissed': 0,
    'restored': 0,
  };

  StreamSubscription<User?>? _authSub;
  final List<_ModerationInboxRow> _reports = [];
  bool _loading = false, _exhausted = false;
  String? _cursor, _loadError;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) => _loadReports());
    _loadReports();
  }

  @override
  void dispose() {
    _loadGeneration++;
    _authSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _selectFilter(String value) {
    setState(() => _filter = value);
    _loadReports();
  }

  Future<void> _loadReports({bool more = false}) async {
    if (more && (_loading || _exhausted)) return;
    final generation = ++_loadGeneration;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    setState(() {
      _loading = true; _loadError = null;
      if (!more) { _reports.clear(); _cursor = null; _exhausted = false; _counts.updateAll((_, __) => 0); }
    });
    try {
      if (uid == null) throw StateError('Signed out');
      final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('readModerationInbox')
          .call({'status': _filter, 'cursor': _cursor});
      if (!mounted || generation != _loadGeneration || FirebaseAuth.instance.currentUser?.uid != uid) return;
      final result = Map<String, dynamic>.from(response.data as Map);
      final rows = (result['reports'] as List).map((v) {
        final row = Map<String, dynamic>.from(v as Map);
        return _ModerationInboxRow(row['id'] as String,
            Map<String, dynamic>.from(_decodeReportValue(row['data']) as Map));
      }).toList();
      setState(() {
        for (final row in rows) {
          _reports.removeWhere((old) => old.id == row.id);
          _reports.add(row);
        }
        _counts = Map<String, dynamic>.from(result['counts'] as Map)
            .map((k,v) => MapEntry(k, (v as num).toInt()));
        _cursor = result['cursor'] as String?;
        _exhausted = result['exhausted'] == true;
      });
    } catch (_) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() { _reports.clear(); _counts.updateAll((_, __) => 0); _cursor = null;
        _loadError = mainText(context, "تعذر تحميل البلاغات أو لم تعد لديك صلاحية الوصول"); });
    } finally {
      if (mounted && generation == _loadGeneration) setState(() => _loading = false);
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'comment':
        return mainText(context, "تعليق");
      case 'user':
        return mainText(context, "حساب");
      default:
        return mainText(context, "منشور");
    }
  }

  String _reasonLabel(String id) {
    switch (id) {
      case 'academic/exam_leak':
        return mainText(context, "تسريب امتحان أو فرض");
      case 'academic/cheating':
        return mainText(context, "غش أو بيع حلول");
      case 'academic/misinfo':
        return mainText(context, "معلومات دراسية مضللة");
      case 'abuse':
        return mainText(context, "إساءة أو تنمّر");
      case 'sexual':
        return mainText(context, "محتوى غير لائق");
      case 'spam':
        return mainText(context, "إعلان أو سبام");
      case 'impersonation':
        return mainText(context, "انتحال شخصية");
      case 'hate':
        return mainText(context, "خطاب كراهية");
      case 'harassment':
        return mainText(context, "مضايقة");
      case 'fake':
        return mainText(context, "حساب وهمي");
      case 'inappropriate_profile':
        return mainText(context, "معلومات غير لائقة");
      case 'other':
        return mainText(context, "أخرى");
      default:
        return id;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'actioned':
        return mainText(context, "مخفي");
      case 'dismissed':
        return mainText(context, "مرفوض");
      case 'restored':
        return mainText(context, "مستعاد");
      default:
        return mainText(context, "معلّق");
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'actioned':
        return const Color(0xFFDC2626);
      case 'dismissed':
        return const Color(0xFF64748B);
      case 'restored':
        return const Color(0xFF16A34A);
      default:
        return AppTeal.main;
    }
  }

  Color _severityColor(String sev) {
    switch (sev) {
      case 'P1':
        return const Color(0xFFDC2626);
      case 'P2':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _emptyLabel() {
    switch (_filter) {
      case 'actioned':
        return mainText(context, "لا يوجد محتوى مخفي");
      case 'dismissed':
        return mainText(context, "لا توجد تبليغات مرفوضة");
      case 'restored':
        return mainText(context, "لا توجد محتويات مستعادة");
      default:
        return mainText(context, "لا توجد تبليغات معلّقة حاليًا 🎉");
    }
  }

  IconData _emptyIcon() {
    switch (_filter) {
      case 'actioned':
        return Icons.visibility_off_outlined;
      case 'dismissed':
        return Icons.block_flipped;
      case 'restored':
        return Icons.restore_rounded;
      default:
        return Icons.task_alt_rounded;
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(14),
      ),
    );
  }
  bool _moderationBusy = false;
  Future<void> _moderateReport(
      _ModerationInboxRow doc,
      String action, String successMessage) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (_moderationBusy || uid == null) return;
    _moderationBusy = true;
    try {
      await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('moderateCommunityReport')
          .call({
            'reportId': doc.id,
            'action': action,
            'expectedStatus': (doc.data()['status'] ?? 'pending').toString(),
          });
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) return;
      moderationRevision.value++;
      _toast(successMessage);
      await _loadReports();
    } catch (e) {
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) return;
      _toast(e is FirebaseFunctionsException && e.code == 'failed-precondition'
          ? mainText(context, "تغيّرت حالة البلاغ أو تعذر تنفيذ الإجراء؛ افتح البلاغ مجدداً")
          : mainText(context, "تعذر تنفيذ إجراء الإشراف"));
    } finally {
      _moderationBusy = false;
    }
  }

  Future<void> _reopen(_ModerationInboxRow doc) =>
      _moderateReport(doc, 'reopen', mainText(context, "أُعيد فتح التبليغ"));

  Future<void> _dismiss(_ModerationInboxRow doc) =>
      _moderateReport(doc, 'dismiss', mainText(context, "تم رفض التبليغ"));

  Future<void> _restore(_ModerationInboxRow doc) =>
      _moderateReport(doc, 'restore', mainText(context, "تمت استعادة المحتوى"));

  Future<void> _action(_ModerationInboxRow doc) =>
      _moderateReport(doc, 'hide', doc.data()['type'] == 'comment'
          ? mainText(context, "تم إخفاء التعليق للجميع") : mainText(context, "تم إخفاء المنشور للجميع"));

  Future<void> _openSheet(
      _ModerationInboxRow d,
      Map<String, dynamic> data,
      ) async {
    final type = data['type']?.toString() ?? 'post';
    final reason = data['reason']?.toString() ?? '';
    final owner = data['ownerName']?.toString() ?? '';
    final status = data['status']?.toString() ?? 'pending';
    final snapMap = data['snapshot'];
    String preview = '';
    if (snapMap is Map) {
      preview = (snapMap['body'] ??
          snapMap['text'] ??
          snapMap['title'] ??
          snapMap['displayName'] ??
          '')
          .toString();
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _StatusChip(label: _statusLabel(status), color: _statusColor(status)),
                    const SizedBox(width: 8),
                    Text(
                      _typeLabel(type),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _reasonLabel(reason),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                ),
                if (owner.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 16, color: Theme.of(ctx).hintColor),
                      const SizedBox(width: 4),
                      Text(mainText(ctx, "صاحب المحتوى: {0}", <Object?>[owner])),
                    ],
                  ),
                ],
                if ((data['details'] ?? '').toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx)
                          .colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(mainText(ctx, "تفاصيل المُبلِّغ: {0}", <Object?>[data['details']])),
                  ),
                ],
                if (preview.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    preview,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Theme.of(ctx).hintColor, height: 1.4),
                  ),
                ],
                const SizedBox(height: 20),
                if (status == 'pending' && (type == 'post' || type == 'comment'))
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(ctx, 'remove'),
                      icon: const Icon(Icons.visibility_off_rounded, size: 18),
                      label:  Text(mainText(ctx, "إخفاء للجميع")),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                if (status == 'pending') ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx, 'dismiss'),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label:  Text(mainText(ctx, "رفض التبليغ")),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
                if (status == 'actioned')
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(ctx, 'restore'),
                      icon: const Icon(Icons.restore_rounded, size: 18),
                      label:  Text(mainText(ctx, "استعادة المحتوى")),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                if (status == 'dismissed' || status == 'restored') ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx, 'reopen'),
                      icon: const Icon(Icons.replay_rounded, size: 18),
                      label:  Text(mainText(ctx, "تراجع: إعادة فتح التبليغ")),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );

    if (action == 'dismiss') {
      await _dismiss(d);
    } else if (action == 'remove') {
      await _action(d);
    } else if (action == 'restore') {
      await _restore(d);
    } else if (action == 'reopen') {
  await _reopen(d);
  }
  }

  @override
  Widget build(BuildContext context) {
    if (!isCommunityModerator()) {
      return  Scaffold(
        body: Center(child: Text(mainText(context, "غير مصرّح"))),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title:  Text(mainText(context, "مراجعة التبليغات"), style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [IconButton(onPressed: () => _loadReports(), tooltip: mainText(context, "تحديث"), icon: const Icon(Icons.refresh))
        ],
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: Column(
        children: [
          // ===== شريط إحصائيات سريعة =====
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Row(
              children: [
                _StatChip(
                  label: mainText(context, "معلّق"),
                  count: _counts['pending'] ?? 0,
                  color: AppTeal.main,
                  icon: Icons.hourglass_top_rounded,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: mainText(context, "مخفي"),
                  count: _counts['actioned'] ?? 0,
                  color: const Color(0xFFDC2626),
                  icon: Icons.visibility_off_rounded,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: mainText(context, "مرفوض"),
                  count: _counts['dismissed'] ?? 0,
                  color: const Color(0xFF64748B),
                  icon: Icons.block_flipped,
                ),
              ],
            ),
          ),

          // ===== فلاتر بشكل كبسولات =====
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterPill(
                    label: mainText(context, "معلّق"),
                    value: 'pending',
                    selected: _filter == 'pending',
                    count: _counts['pending'] ?? 0,
                    color: AppTeal.main,
                    onTap: () => _selectFilter('pending'),
                  ),
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: mainText(context, "مخفي"),
                    value: 'actioned',
                    selected: _filter == 'actioned',
                    count: _counts['actioned'] ?? 0,
                    color: const Color(0xFFDC2626),
                    onTap: () => _selectFilter('actioned'),
                  ),
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: mainText(context, "مرفوض"),
                    value: 'dismissed',
                    selected: _filter == 'dismissed',
                    count: _counts['dismissed'] ?? 0,
                    color: const Color(0xFF64748B),
                    onTap: () => _selectFilter('dismissed'),
                  ),
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: mainText(context, "مستعاد"),
                    value: 'restored',
                    selected: _filter == 'restored',
                    count: _counts['restored'] ?? 0,
                    color: const Color(0xFF16A34A),
                    onTap: () => _selectFilter('restored'),
                  ),
                ],
              ),
            ),
          ),

          // ===== حقل بحث بسيط باسم صاحب المحتوى =====
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
              style: const TextStyle(fontSize: 13.5),
              decoration: InputDecoration(
                hintText: mainText(context, "ابحث في البلاغات المحمّلة باسم صاحب المحتوى..."),
                hintStyle: TextStyle(fontSize: 13, color: theme.hintColor),
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: theme.hintColor),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _search = '');
                  },
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: Builder(
              builder: (context) {
                if (_loadError != null) {
                  return Center(child: TextButton(onPressed: () => _loadReports(), child: Text(_loadError! + mainText(context, " — إعادة المحاولة"))));
                }
                if (_loading && _reports.isEmpty) return const Center(child: CircularProgressIndicator());
                var docs = [..._reports];

                if (_search.isNotEmpty) {
                  docs = docs.where((d) {
                    final owner = (d.data()['ownerName'] ?? '').toString().toLowerCase();
                    return owner.contains(_search);
                  }).toList();
                }

                docs.sort((a, b) {
                  const order = {'P1': 0, 'P2': 1, 'P3': 2};
                  final sa = order[a.data()['severity']?.toString()] ?? 9;
                  final sb = order[b.data()['severity']?.toString()] ?? 9;
                  if (sa != sb) return sa.compareTo(sb);
                  final ta = a.data()['createdAt'];
                  final tb = b.data()['createdAt'];
                  if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
                  return 0;
                });

                if (docs.isEmpty) {
                  return _EmptyModerationState(
                    icon: _emptyIcon(),
                    label: _emptyLabel(),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final d = docs[i];
                    final data = d.data();
                    final type = data['type']?.toString() ?? 'post';
                    final reason = data['reason']?.toString() ?? '';
                    final status = data['status']?.toString() ?? 'pending';
                    final severity = data['severity']?.toString() ?? 'P3';

                    return _ModerationReportCard(
                      key: ValueKey(d.id),
                      reportId: d.id,
                      data: data,
                      severityColor: _severityColor(severity),
                      severityLabel: severity,
                      statusLabel: _statusLabel(status),
                      statusColor: _statusColor(status),
                      reasonLabel: _reasonLabel(reason),
                      typeLabel: _typeLabel(type),
                      onReview: () => _openSheet(d, data),
                      onQuickDismiss: status == 'pending' ? () => _dismiss(d) : null,
                      onQuickAction:
                      status == 'pending' && type != 'user' ? () => _action(d) : null,
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(children: [
               Text(mainText(context, "البحث وترتيب الأولوية ضمن البلاغات المحمّلة"), style: TextStyle(fontSize: 12)),
              if (!_exhausted && _loadError == null)
                TextButton(onPressed: _loading ? null : () => _loadReports(more: true),
                    child: Text(_loading ? mainText(context, "جارٍ التحميل...") : mainText(context, "تحميل المزيد"))),
            ]),
          ),
        ],
      ),
    );
  }
}

// ==================== شريط إحصائيات صغير أعلى الصفحة ====================
class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== كبسولة فلتر مع عداد ====================
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.value,
    required this.selected,
    required this.count,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final int count;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : color,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withValues(alpha: 0.25) : color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: selected ? Colors.white : color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==================== حالة فارغة عصرية ====================
class _EmptyModerationState extends StatelessWidget {
  const _EmptyModerationState({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTeal.main.withValues(alpha: 0.08),
              ),
              child: Icon(icon, size: 32, color: AppTeal.main),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== هيكل تحميل (Skeleton) ====================
class _ReportCardSkeleton extends StatefulWidget {
  const _ReportCardSkeleton();

  @override
  State<_ReportCardSkeleton> createState() => _ReportCardSkeletonState();
}

class _ReportCardSkeletonState extends State<_ReportCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.06);

    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_c),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 60, height: 18, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(20))),
              const Spacer(),
              Container(width: 40, height: 12, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(6))),
            ]),
            const SizedBox(height: 14),
            Container(width: double.infinity, height: 60, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(12))),
          ],
        ),
      ),
    );
  }
}

// ==================== شارة الحالة ====================
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ==================== بطاقة التبليغ الرئيسية (معاد تصميمها) ====================
class _ModerationReportCard extends StatefulWidget {
  const _ModerationReportCard({
    super.key,
    required this.reportId,
    required this.data,
    required this.severityColor,
    required this.severityLabel,
    required this.statusLabel,
    required this.statusColor,
    required this.reasonLabel,
    required this.typeLabel,
    required this.onReview,
    this.onQuickDismiss,
    this.onQuickAction,
  });

  final String reportId;
  final Map<String, dynamic> data;
  final Color severityColor;
  final String severityLabel;
  final String statusLabel;
  final Color statusColor;
  final String reasonLabel;
  final String typeLabel;
  final VoidCallback onReview;
  final VoidCallback? onQuickDismiss;
  final VoidCallback? onQuickAction;

  @override
  State<_ModerationReportCard> createState() => _ModerationReportCardState();
}

class _ModerationReportCardState extends State<_ModerationReportCard> {
  _Post? _post;
  _Comment? _comment;
  bool _loading = true;
  bool _expanded = false;
  int _previewGeneration = 0;
  StreamSubscription<User?>? _previewAuth;

  String get _type => widget.data['type']?.toString() ?? 'post';

  String get _postId {
    if (_type == 'comment') {
      return (widget.data['parentId'] ?? widget.data['postId'] ?? '')
          .toString()
          .trim();
    }
    return (widget.data['targetId'] ?? widget.data['postId'] ?? '')
        .toString()
        .trim();
  }

  String get _commentId =>
      (widget.data['commentId'] ?? widget.data['targetId'] ?? '')
          .toString()
          .trim();

  String get _timeAgo {
    final raw = widget.data['createdAt'];
    if (raw is! Timestamp) return '';
    final diff = DateTime.now().difference(raw.toDate());
    if (diff.inDays > 0) return mainText(context, "منذ {0}ي", <Object?>[diff.inDays]);
    if (diff.inHours > 0) return mainText(context, "منذ {0}س", <Object?>[diff.inHours]);
    if (diff.inMinutes > 0) return mainText(context, "منذ {0}د", <Object?>[diff.inMinutes]);
    return mainText(context, "الآن");
  }

  @override
  void initState() {
    super.initState();
    _previewAuth = FirebaseAuth.instance.authStateChanges().listen((_) => _load());
  }

  @override
  void dispose() {
    _previewGeneration++;
    _previewAuth?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ModerationReportCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data || oldWidget.reportId != widget.reportId) _load();
  }

  _Comment? _findComment(List<_Comment> list, String id) {
    for (final c in list) {
      if (c.id == id) return c;
      final nested = _findComment(c.replies, id);
      if (nested != null) return nested;
    }
    return null;
  }

  Future<void> _load() async {
    final generation = ++_previewGeneration;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    setState(() { _post = null; _comment = null; _loading = true; });
    try {
      if (uid == null || _type == 'user') return;
      final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('readModerationPreview')
              .call({'reportId': widget.reportId});
      if (!mounted || generation != _previewGeneration || FirebaseAuth.instance.currentUser?.uid != uid) return;
      final result = Map<String, dynamic>.from(response.data as Map);
      final raw = result['post'];
      if (raw == null) return;
      final row = Map<String, dynamic>.from(raw as Map);
      final post = _Post.fromData(row['id'] as String,
          Map<String, dynamic>.from(_decodeReportValue(row['data']) as Map));
      setState(() { _post = post; _comment = _type == 'comment' ? _findComment(post.comments, _commentId) : null; });
    } catch (_) {
      // Never fall back to cached historical content as a live preview.
    } finally {
      if (mounted && generation == _previewGeneration) setState(() => _loading = false);
    }
  }

  Future<void> _openPost() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    try {
      // The ordinary discussion screen retains ordinary content authorization.
      final data = await _readAuthorizedPostData(_postId);
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) return;
      final post = _Post.fromData(_postId, data);
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => CommentsScreen(
          post: post, initialCommentId: _type == 'comment' ? _commentId : null)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(mainText(context, "تعذر فتح المناقشة؛ استخدم معاينة البلاغ للمراجعة"))));
    }
  }

  Future<void> _confirmQuickAction() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: Directionality.of(context),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title:  Text(mainText(ctx, "إخفاء للجميع؟")),
          content: Text(_type == 'comment'
              ? mainText(ctx, "سيتم إخفاء هذا التعليق عن كل المستخدمين.")
              : mainText(ctx, "سيتم إخفاء هذا المنشور عن كل المستخدمين.")),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child:  Text(mainText(ctx, "إلغاء"))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              onPressed: () => Navigator.pop(ctx, true),
              child:  Text(mainText(ctx, "إخفاء")),
            ),
          ],
        ),
      ),
    );
    if (ok == true) widget.onQuickAction?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AppTeal.main;

    return Material(
      color: isDark ? const Color(0xFF16181C) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ===== شريط لون حسب الخطورة =====
              Container(width: 4, color: widget.severityColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ===== رأس البطاقة =====
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.severityColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.severityLabel,
                              style: TextStyle(
                                color: widget.severityColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _StatusChip(label: widget.statusLabel, color: widget.statusColor),
                          const SizedBox(width: 6),
                          Icon(
                            _type == 'comment'
                                ? Icons.mode_comment_outlined
                                : _type == 'user'
                                ? Icons.person_outline_rounded
                                : Icons.article_outlined,
                            size: 13,
                            color: accent,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            widget.typeLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                          ),
                          const Spacer(),
                          if (_timeAgo.isNotEmpty)
                            Text(
                              _timeAgo,
                              style: TextStyle(fontSize: 11, color: theme.hintColor),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.reasonLabel,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if ((widget.data['ownerName'] ?? '')
                          .toString()
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          mainText(context, "صاحب المحتوى: {0}", <Object?>[widget.data['ownerName']]),
                          style: TextStyle(fontSize: 12, color: theme.hintColor),
                        ),
                      ],

                      const SizedBox(height: 10),

                      // ===== معاينة المحتوى (قابلة للطي/الفتح لتوفير المساحة) =====
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      else
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() => _expanded = !_expanded),
                          child: AnimatedCrossFade(
                            duration: const Duration(milliseconds: 200),
                            crossFadeState:
                            _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                            firstChild: _CompactPreview(
                              type: _type,
                              post: _post,
                              comment: _comment,
                              theme: theme,
                            ),
                            secondChild: _type == 'post' && _post != null
                                ? _RedditStylePostCard(post: _post!, accent: accent)
                                : _type == 'comment' && _comment != null && _post != null
                                ? _RedditStyleCommentTile(
                              hit: _CommentSearchHit(post: _post!, comment: _comment!),
                              accent: accent,
                            )
                                : Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                _type == 'user' ? mainText(context, "تبليغ عن حساب") : mainText(context, "تعذر تحميل المحتوى"),
                                style: TextStyle(color: theme.hintColor),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 10),

                      // ===== أزرار الإجراء =====
                      Row(
                        children: [
                          if (_type != 'user')
                            _RoundIconAction(
                              icon: Icons.open_in_new_rounded,
                              tooltip: mainText(context, "فتح"),
                              onTap: _openPost,
                            ),
                          const SizedBox(width: 6),
                          if (widget.onQuickDismiss != null)
                            _RoundIconAction(
                              icon: Icons.close_rounded,
                              tooltip: mainText(context, "رفض"),
                              color: const Color(0xFF64748B),
                              onTap: widget.onQuickDismiss,
                            ),
                          const SizedBox(width: 6),
                          if (widget.onQuickAction != null)
                            _RoundIconAction(
                              icon: Icons.visibility_off_rounded,
                              tooltip: mainText(context, "إخفاء للجميع"),
                              color: const Color(0xFFDC2626),
                              onTap: _confirmQuickAction,
                            ),
                          const Spacer(),
                          TextButton(
                            onPressed: widget.onReview,
                            style: TextButton.styleFrom(
                              foregroundColor: accent,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child:  Text(
                              mainText(context, "التفاصيل الكاملة"),
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== معاينة مختصرة (سطر أو سطرين) قبل التوسيع ====================
class _CompactPreview extends StatelessWidget {
  const _CompactPreview({
    required this.type,
    required this.post,
    required this.comment,
    required this.theme,
  });

  final String type;
  final _Post? post;
  final _Comment? comment;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    String text = '';
    if (type == 'comment' && comment != null) {
      text = comment!.text.trim();
    } else if (post != null) {
      text = post!.title.trim().isNotEmpty ? post!.title.trim() : post!.body.trim();
    }
    if (text.isEmpty) text = mainText(context, "لا يوجد محتوى نصي");

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, height: 1.35, color: theme.colorScheme.onSurface),
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.expand_more_rounded, size: 18, color: theme.hintColor),
        ],
      ),
    );
  }
}

// ==================== زر إجراء دائري صغير ====================
class _RoundIconAction extends StatelessWidget {
  const _RoundIconAction({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: c.withValues(alpha: 0.08),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 17, color: c),
          ),
        ),
      ),
    );
  }
}
