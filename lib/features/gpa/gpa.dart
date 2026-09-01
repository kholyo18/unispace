import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';

import '../../core/branding.dart';
// الترجمة المولَّدة:
import '../../generated/l10n.dart'; // أو المسار الصحيح لـ S عندك
import '../../moduls3.dart';
import 'package:flutter/widgets.dart';
import '../../../ui/widgets/app_scaffold.dart';
import '../../core/translate_subject.dart';
import 'package:UniSpace/main.dart';


class QuickAverageScreen extends StatefulWidget {
  const QuickAverageScreen({super.key});

  @override
  State<QuickAverageScreen> createState() => _QuickAverageScreenState();
}

class _QuickAverageScreenState extends State<QuickAverageScreen> {
  static const String _quickCalcStorageKey = 'quick_calc_state_v1';
  static const double _dismissThreshold = 0.4;
  final List<NoteData> subjects = [];
  double threshold = 10;
  double avg = 0;
  double totalcred = 0;
  bool _hasSavedState = false;

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  void _add() => setState(() {
    subjects.add(NoteData(subject: ''));
  });

  void _calc() {
    double totalWeighted = 0;
    double totalCoef = 0;
    double totalCred = 0;

    for (final s in subjects) {
      final moy = s.moy;
      totalWeighted += moy * s.coef;
      totalCoef += s.coef;
      if (moy >= 10) {
        totalCred += s.cred;
      }
    }

    setState(() {
      avg = totalCoef == 0 ? 0 : totalWeighted / totalCoef;
      totalcred = totalCred;
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'threshold': threshold,
      'avg': avg,
      'totalcred': totalcred,
      'isSucceeded': avg >= threshold,
      'subjects': subjects
          .map(
            (s) => <String, dynamic>{
          'subject': s.subject,
          'coef': s.coef,
          'cred': s.cred,
          'td': s.td,
          'exam': s.exam,
          'tp': s.tp,
          'wtd': s.Wtd,
          'wexam': s.Wexam,
          'wtp': s.Wtp,
        },
      )
          .toList(),
    };
    await prefs.setString(_quickCalcStorageKey, jsonEncode(payload));
    _hasSavedState = true;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved ✅')),
    );
  }

  Future<void> _persistStateSilently() async {
    if (!_hasSavedState) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'threshold': threshold,
      'avg': avg,
      'totalcred': totalcred,
      'isSucceeded': avg >= threshold,
      'subjects': subjects
          .map(
            (s) => <String, dynamic>{
          'subject': s.subject,
          'coef': s.coef,
          'cred': s.cred,
          'td': s.td,
          'exam': s.exam,
          'tp': s.tp,
          'wtd': s.Wtd,
          'wexam': s.Wexam,
          'wtp': s.Wtp,
        },
      )
          .toList(),
    };
    await prefs.setString(_quickCalcStorageKey, jsonEncode(payload));
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_quickCalcStorageKey);
    if (raw == null || raw.isEmpty) {
      return;
    }
    _hasSavedState = true;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return;
    }
    final decodedSubjects = decoded['subjects'];
    final List<NoteData> loaded = [];
    if (decodedSubjects is List) {
      for (final entry in decodedSubjects) {
        if (entry is! Map) continue;
        loaded.add(
          NoteData(
            subject: entry['subject']?.toString() ?? '',
            coef: _toInt(entry['coef'], fallback: 1),
            cred: _toInt(entry['cred'], fallback: 1),
            td: _toDouble(entry['td'], fallback: 0),
            exam: _toDouble(entry['exam'], fallback: 0),
            tp: _toDouble(entry['tp'], fallback: 0),
            Wtd: _toDouble(entry['wtd'], fallback: 0.4),
            Wexam: _toDouble(entry['wexam'], fallback: 0.6),
            Wtp: _toDouble(entry['wtp'], fallback: 0),
          ),
        );
      }
    }
    if (!mounted) return;
    setState(() {
      subjects
        ..clear()
        ..addAll(loaded);
      threshold = _toDouble(decoded['threshold'], fallback: 10);
      avg = _toDouble(decoded['avg'], fallback: 0);
      totalcred = _toDouble(decoded['totalcred'], fallback: 0);
    });
  }

  Future<void> _clearSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_quickCalcStorageKey);
    _hasSavedState = false;
    if (!mounted) return;
    setState(() {
      subjects.clear();
      avg = 0;
      totalcred = 0;
      threshold = 10;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cleared ✅')),
    );
  }

  Future<void> _removeSubjectAt(int index) async {
    final removed = subjects.removeAt(index);
    setState(() {});
    await _persistStateSilently();
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            subjects.insert(index, removed);
            setState(() {});
            await _persistStateSilently();
          },
        ),
      ),
    );
  }

  double _toDouble(dynamic value, {required double fallback}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  int _toInt(dynamic value, {required int fallback}) {
    if (value == null) return fallback;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  Widget _quickCalcActionButton({
    required VoidCallback? onPressed,
    VoidCallback? onLongPress,
    required IconData icon,
    required String label,
    required double horizontalPadding,
  }) {
    return FilledButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      style: FilledButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).quickCalc),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ...subjects.asMap().entries.map((e) {
            final i = e.key;
            final s = e.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _QuickCalcDismissibleItem(
                data: s,
                index: i,
                threshold: _dismissThreshold,
                onRemove: _removeSubjectAt,
              ),
            );
          }),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 360 ? 8.0 : 12.0;
              return Row(
                children: [
                  Expanded(
                    child: _quickCalcActionButton(
                      onPressed: _add,
                      icon: Icons.add,
                      label: S.of(context).add,
                      horizontalPadding: horizontalPadding,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _quickCalcActionButton(
                      onPressed: _calc,
                      icon: Icons.calculate,
                      label: S.of(context).calculate,
                      horizontalPadding: horizontalPadding,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _quickCalcActionButton(
                      onPressed: _saveState,
                      onLongPress: _clearSavedState,
                      icon: Icons.save,
                      label: S.of(context).save,
                      horizontalPadding: horizontalPadding,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                textDirection: TextDirection.ltr,
                children: [
                  Expanded(
                    child: Text(
                      'Moy: ${avg.toStringAsFixed(2)}',
                      textDirection: TextDirection.ltr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      avg == 0
                          ? '___'
                          : (avg >= threshold ? "✅ Succeeded" : "❌ Failed"),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: avg == 0
                            ? Colors.grey
                            : (avg >= threshold ? Colors.green : Colors.red),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Cred: $totalcred',
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 18),
                  )),
            ],
          )
        ],
      ),
    );
  }
}

// -------------------------
// بيانات البطاقة
// -------------------------
class NoteData {
  String subject;
  int coef;
  int cred;
  double td;
  double exam;
  double tp;
  double Wtd;
  double Wexam;
  double Wtp;

  NoteData({
    this.subject = '',
    this.coef = 1,
    this.cred = 1,
    this.td = 0,
    this.exam = 0,
    this.tp = 0,
    this.Wtd = 0.4,
    this.Wexam = 0.6,
    this.Wtp = 0,
  });

  double get moy => (td * Wtd + exam * Wexam + tp * Wtp);
}

class _QuickCalcDismissibleItem extends StatefulWidget {
  const _QuickCalcDismissibleItem({
    required this.data,
    required this.index,
    required this.threshold,
    required this.onRemove,
  });

  final NoteData data;
  final int index;
  final double threshold;
  final Future<void> Function(int index) onRemove;

  @override
  State<_QuickCalcDismissibleItem> createState() =>
      _QuickCalcDismissibleItemState();
}

class _QuickCalcDismissibleItemState extends State<_QuickCalcDismissibleItem> {
  double _progress = 0;
  bool _hapticTriggered = false;

  void _handleUpdate(DismissUpdateDetails details) {
    final progress = details.progress.clamp(0.0, 1.0);
    if (progress >= widget.threshold && !_hapticTriggered) {
      HapticFeedback.lightImpact();
      _hapticTriggered = true;
    }
    if (progress < widget.threshold && _hapticTriggered) {
      _hapticTriggered = false;
    }
    if (_progress != progress) {
      setState(() {
        _progress = progress;
      });
    }
  }

  Future<bool> _confirmDismiss() async {
    return _progress >= widget.threshold;
  }

  @override
  Widget build(BuildContext context) {
    final ambientDirection = Directionality.of(context);
    final eased = Curves.easeOut.transform(_progress);
    final backgroundColor = Color.lerp(
      Colors.red.withValues(alpha: 0.08),
      Colors.red.shade600,
      eased,
    )!;
    final iconScale = 0.9 + (0.2 * eased);

    final dismissBackground = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              backgroundColor.withValues(alpha: 0.9),
              backgroundColor,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: iconScale,
              child: const Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'حذف',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Dismissible(
        key: ValueKey(widget.data),
        direction: DismissDirection.startToEnd,
        movementDuration: const Duration(milliseconds: 220),
        resizeDuration: const Duration(milliseconds: 200),
        dismissThresholds: {DismissDirection.startToEnd: widget.threshold},
        background: dismissBackground,
        confirmDismiss: (_) => _confirmDismiss(),
        onUpdate: _handleUpdate,
        onDismissed: (_) => widget.onRemove(widget.index),
        child: Directionality(
          textDirection: ambientDirection,
          child: NoteCardWidget(
            data: widget.data,
          ),
        ),
      ),
    );
  }
}

// -------------------------
// واجهة البطاقة
// -------------------------
class NoteCardWidget extends StatefulWidget {
  final NoteData data;

  const NoteCardWidget({
    super.key,
    required this.data,
  });

  @override
  State<NoteCardWidget> createState() => _NoteCardWidgetState();
}

class _NoteCardWidgetState extends State<NoteCardWidget> {
  late TextEditingController nameController;
  late TextEditingController coefController;
  late TextEditingController credController;
  late TextEditingController tdController;
  late TextEditingController tpController;
  late TextEditingController WtdController;
  late TextEditingController WtpController;
  late TextEditingController WexamController;
  late TextEditingController examController;

  bool expanded = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.data.subject);
    coefController = TextEditingController(text: widget.data.coef.toString());
    credController = TextEditingController(text: widget.data.cred.toString());
    tdController = TextEditingController(
        text: widget.data.td == 0 ? '' : widget.data.td.toString());
    examController = TextEditingController(
        text: widget.data.exam == 0 ? '' : widget.data.exam.toString());
    tpController = TextEditingController(
        text: widget.data.tp == 0 ? '' : widget.data.tp.toString());
    WexamController = TextEditingController(text: widget.data.Wexam.toString());
    WtdController = TextEditingController(text: widget.data.Wtd.toString());
    WtpController = TextEditingController(text: widget.data.Wtp.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 2,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      child: Column(
        children: [
          // Header: Delete, Subject Name, Moy
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: nameController,
                    onChanged: (v) {
                      widget.data.subject = v;
                      setState(() {});
                    },
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      contentPadding:
                      EdgeInsets.only(top: 2, bottom: 0, left: 0, right: 0),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.data.moy.toStringAsFixed(2),
                style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    expanded = !expanded;
                  });
                },
                icon: Icon(expanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down),
              )
            ],
          ),
          if (expanded)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Coef & Cred أولاً
                Flexible(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //coef
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          children: [
                            const Text("Coef"),
                            TextField(
                              controller: coefController,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 15),
                              decoration: const InputDecoration(
                                counterText: '',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              onChanged: (v) {
                                widget.data.coef = int.tryParse(v) ?? 1;
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      //cred
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          children: [
                            const Text("Cred"),
                            TextField(
                              controller: credController,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 15),
                              decoration: const InputDecoration(
                                counterText: '',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              onChanged: (v) {
                                widget.data.cred = int.tryParse(v) ?? 1;
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 180,
                  width: 1,
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: Row(
                    children: [
                      // wTD / wTP / wExam
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildScoreField("W.TD", WtdController, (v) {
                              widget.data.Wtd = double.tryParse(v) ?? 0;
                              setState(() {});
                            }),
                            const SizedBox(height: 5),
                            Container(
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1,
                              width: double.infinity,
                            ),
                            _buildScoreField("W.TP", WtpController, (v) {
                              widget.data.Wtp = double.tryParse(v) ?? 0;
                              setState(() {});
                            }),
                            const SizedBox(height: 5),
                            Container(
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1,
                              width: double.infinity,
                            ),
                            _buildScoreField("W.EX", WexamController, (v) {
                              widget.data.Wexam = double.tryParse(v) ?? 0;
                              setState(() {});
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // TD / TP / Exam
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildScoreField("TD", tdController, (v) {
                              widget.data.td = double.tryParse(v) ?? 0;
                              setState(() {});
                            }),
                            const SizedBox(height: 5),
                            Container(
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1,
                              width: double.infinity,
                            ),
                            _buildScoreField("TP", tpController, (v) {
                              widget.data.tp = double.tryParse(v) ?? 0;
                              setState(() {});
                            }),
                            const SizedBox(height: 5),
                            Container(
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1,
                              width: double.infinity,
                            ),
                            _buildScoreField("Exam", examController, (v) {
                              widget.data.exam = double.tryParse(v) ?? 0;
                              setState(() {});
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }

  Widget _buildScoreField(String label, TextEditingController controller,
      Function(String) onChange) {
    return Column(
      children: [
        Text(label),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            onChanged: (v) => onChange(v),
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              contentPadding:
              EdgeInsets.only(top: 2, bottom: 0, left: 0, right: 0),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

// ===================== GPA Table Data Model (public) ========================
class EvalWeight {
  final String label;
  final double weight;
  const EvalWeight({required this.label, required this.weight});
}

class ModuleSpec {
  final String id;
  final String name;
  final double coef;
  final double credits;
  final List<EvalWeight> evalWeights;
  const ModuleSpec({
    required this.id,
    required this.name,
    required this.coef,
    required this.credits,
    required this.evalWeights,
  });

  double get totalWeight =>
      evalWeights.fold<double>(0, (sum, item) => sum + item.weight);
}

class SemesterSpec {
  final String name;
  final List<ModuleSpec> modules;
  const SemesterSpec({required this.name, required this.modules});
}

List<SemesterSpec> createSemesterSpecsForTrack(ProgramTrack track) {
  return track.semesters.asMap().entries.map(
        (semEntry) {
      final semIndex = semEntry.key;
      final sem = semEntry.value;
      // جمع كل modules من كل الوحدات داخل السداسي
      final allModules =
      sem.unit.expand((u) => u.modules).toList(growable: false);

      return SemesterSpec(
        name: sem.label,
        modules: allModules
            .asMap()
            .entries
            .map(
              (moduleEntry) {
            final moduleIndex = moduleEntry.key;
            final module = moduleEntry.value;
            return ModuleSpec(
              id: 'sem${semIndex + 1}-module${moduleIndex + 1}',
              name: module.name,
              coef: module.coef.toDouble(),
              credits: module.credits.toDouble(),
              evalWeights: _normalizeEvalWeights(module.components),
            );
          },
        )
            .toList(growable: false),
      );
    },
  ).toList(growable: false);
}

List<SemesterSpec> demoL1GpaSpecs(BuildContext context) {
  final track = getDemoFaculties(context).first.majors.first.tracks.first;

  return createSemesterSpecsForTrack(track);
}

List<EvalWeight> _normalizeEvalWeights(List<ProgramComponent> components) {
  final Map<String, double> weights = {
    'TD': 0,
    'TP': 0,
    'EXAM': 0,
  };
  for (final c in components) {
    final key = c.label.toUpperCase();
    if (weights.containsKey(key)) {
      weights[key] = c.weight;
    }
  }
  return [
    EvalWeight(label: 'TD', weight: weights['TD']!),
    EvalWeight(label: 'TP', weight: weights['TP']!),
    EvalWeight(label: 'EXAM', weight: weights['EXAM']!),
  ];
}

String _slugifyModuleId(String value) {
  final slug = value
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (slug.isNotEmpty) {
    return slug;
  }
  final encoded = base64UrlEncode(utf8.encode(value));
  return encoded.replaceAll('=', '');
}

String _moduleIdForSemester(String semester, String moduleName) {
  final normalizedSemester = semester.trim().toUpperCase();
  final normalizedModule = moduleName.trim();
  return _slugifyModuleId('$normalizedSemester-$normalizedModule');
}

String buildAcademicStorageSignature({
  required SemesterSpec semester1,
  required SemesterSpec semester2,
  required String level,
}) {
  String moduleFingerprint(ModuleSpec module) {
    final weights = module.evalWeights
        .map((weight) => '${weight.label.toUpperCase()}:${weight.weight}')
        .join('|');
    return '${module.name.trim()}#${module.coef}#${module.credits}#$weights';
  }

  String semesterFingerprint(SemesterSpec semester) {
    final modules = semester.modules
        .map(moduleFingerprint)
        .join('||');
    return '${semester.name.trim().toUpperCase()}::${modules}';
  }

  final raw = [
    level.trim().toUpperCase(),
    semesterFingerprint(semester1),
    semesterFingerprint(semester2),
  ].join('###');

  return base64UrlEncode(utf8.encode(raw)).replaceAll('=', '');
}

class ModuleModel {
  ModuleModel({
    required this.id,
    required this.title,
    required num coef,
    required num credits,
    required double tdWeight,
    required double tpWeight,
    required double examWeight,
  })  : coef = coef.toDouble(),
        credits = credits.toDouble(),
        _hasTD = tdWeight > 0,
        _hasTP = tpWeight > 0,
        wTD = tdWeight / 100,
        wTP = tpWeight / 100,
        wEX = examWeight / 100,
        td = 0,
        tp = 0,
        exam = 0;

  final String id;
  final String title;
  double coef;
  double credits;
  final bool _hasTD;
  final bool _hasTP;
  double wTD;
  double wTP;
  double wEX;
  double? td;
  double? tp;
  double? exam;
  double? tdWeight = 0.4;
  double? tpWeight = 0;
  double? examWeight = 0.6;

  bool get hasTD => _hasTD;
  bool get hasTP => _hasTP;

  double get moy {
    final totalW = wTD + wTP + wEX; // مجموع الأوزان
    if (totalW <= 0) return 0;

    double normalize(double weight) => weight / totalW;

    final value = (td ?? 0) * normalize(wTD) +
        (tp ?? 0) * normalize(wTP) +
        (exam ?? 0) * normalize(wEX);

    return double.parse(value.toStringAsFixed(2));
  }
}

class SemesterModel {
  SemesterModel({
    required this.name,
    required this.modules,
    required VoidCallback onChanged,
  }) : _onChanged = onChanged;

  factory SemesterModel.fromSpec(
      SemesterSpec spec, {
        required VoidCallback onChanged,
      }) {
    final modules = spec.modules.map((module) {
      double weightFor(String label) {
        return module.evalWeights
            .firstWhere(
              (w) => w.label.toUpperCase() == label,
          orElse: () => const EvalWeight(label: 'TMP', weight: 0),
        )
            .weight;
      }

      return ModuleModel(
        id: module.id.trim().isNotEmpty
            ? module.id
            : _moduleIdForSemester(spec.name, module.name),
        title: module.name,
        coef: module.coef,
        credits: module.credits,
        tdWeight: weightFor('TD'),
        tpWeight: weightFor('TP'),
        examWeight: weightFor('EXAM'),
      );
    }).toList(growable: false);

    return SemesterModel(
        name: spec.name, modules: modules, onChanged: onChanged);
  }

  final String name;
  final List<ModuleModel> modules;
  final VoidCallback _onChanged;

  void recompute() => _onChanged();

  double moduleAverage(ModuleModel module) {
    return module.moy;
  }

  double moduleCreditsEarned(ModuleModel module) {
    final avg = moduleAverage(module);
    return avg >= 10 ? module.credits : 0;
  }

  double semesterAverage() {
    double weighted = 0;
    double coefs = 0;
    for (final module in modules) {
      weighted += moduleAverage(module) * module.coef;
      coefs += module.coef;
    }
    if (coefs == 0) {
      return 0;
    }
    final value = weighted / coefs;
    return double.parse(value.toStringAsFixed(2));
  }

  double creditsEarned() {
    return modules.fold<double>(
        0, (sum, module) => sum + moduleCreditsEarned(module));
  }

  SemesterModel convertProgramSemester(
      ProgramSemester ps,
      VoidCallback onChanged,
      ) {
    final allModules =
    ps.unit.expand((u) => u.modules).toList(growable: false);
    return SemesterModel(
      name: ps.label,
      onChanged: onChanged,
      modules: allModules.asMap().entries.map((entry) {
        final moduleIndex = entry.key;
        final m = entry.value;
        // تحويل ProgramComponent إلى أوزان TD/TP/EXAM
        double td = 0;
        double tp = 0;
        double exam = 0;

        for (var c in m.components) {
          if (c.label.toUpperCase() == 'TD') td = c.weight.toDouble();
          if (c.label.toUpperCase() == 'TP') tp = c.weight.toDouble();
          if (c.label.toUpperCase() == 'EXAM') exam = c.weight.toDouble();
        }

        return ModuleModel(
          id: 'sem${ps.label.trim().toUpperCase()}-module${moduleIndex + 1}',
          title: m.name,
          coef: m.coef,
          credits: m.credits,
          tdWeight: td,
          tpWeight: tp,
          examWeight: exam,
        );
      }).toList(),
    );
  }
}

// ---------- Table helpers ----------
class DecimalSanitizer extends TextInputFormatter {
  DecimalSanitizer({this.decimalPlaces = 2});

  final int decimalPlaces;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final sanitized = newValue.text.replaceAll(',', '.');
    final pattern = decimalPlaces > 0
        ? RegExp(r'^\d*([.]\d{0,' + decimalPlaces.toString() + r'})?$')
        : RegExp(r'^\d*$');
    if (sanitized.isEmpty || pattern.hasMatch(sanitized)) {
      return newValue.copyWith(text: sanitized);
    }
    return oldValue;
  }
}

class _NumField extends StatelessWidget {
  const _NumField({
    required this.value,
    required this.onChanged,
    this.width = 64,
    this.decimalPlaces = 2,
    this.inputRangePattern,
  });

  final double? value;
  final ValueChanged<double?> onChanged;
  final double width;
  final int decimalPlaces;
  final RegExp? inputRangePattern;

  @override
  Widget build(BuildContext context) {
    final initial = value == null ? '' : value!.toStringAsFixed(decimalPlaces);
    return SizedBox(
      width: width,
      child: TextFormField(
        textAlign: TextAlign.center,
        initialValue: initial,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        ),
        inputFormatters: [
          DecimalSanitizer(decimalPlaces: decimalPlaces),
          if (inputRangePattern != null)
            FilteringTextInputFormatter.allow(inputRangePattern!),
        ],
        onChanged: (s) {
          final sanitized = s.replaceAll(',', '.');
          if (sanitized.isEmpty) {
            onChanged(null);
            return;
          }
          final parsed = double.tryParse(sanitized);
          if (parsed == null) {
            return;
          }
          onChanged(parsed);
        },
      ),
    );
  }
}

// Compact text widget that never wraps:
Widget _cell(String s, {bool bold = false, bool center = false}) => Text(
  s,
  maxLines: 1,
  softWrap: false,
  overflow: TextOverflow.ellipsis,
  textAlign: center ? TextAlign.center : TextAlign.start,
  style: TextStyle(fontWeight: bold ? FontWeight.w600 : FontWeight.w400),
);
// -----------------------------------

SemesterSpec _pickSemester(List<SemesterSpec> specs, String label) {
  final normalizedLabel = label.toUpperCase();
  if (specs.isEmpty) {
    return const SemesterSpec(name: 'S?', modules: []);
  }
  return specs.firstWhere(
        (s) => s.name.toUpperCase() == normalizedLabel,
    orElse: () {
      if (normalizedLabel == 'S1') {
        return specs.first;
      }
      if (normalizedLabel == 'S2' && specs.length > 1) {
        return specs.last;
      }
      return specs.first;
    },
  );
}

// ================================ UI: Faculties ==============================
class FacultiesScreen extends StatelessWidget {
  final List<ProgramFaculty> faculties;
  const FacultiesScreen({super.key, required this.faculties});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return AppScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(S.of(context).faculties),
      ),
      padding: EdgeInsets.zero,
      body: ListView.separated(
        itemCount: faculties.length,
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) {
          final f = faculties[i];
          final theme = Theme.of(context);
          final majorsCount = f.majors.length;
          final subtitleText = majorsCount == 0
              ? S.of(context).noMajorsYet
              : majorsCount == 1
              ? S.of(context).oneMajor
              : '$majorsCount تخصصات';
          return Card(
            margin: EdgeInsets.zero,
            color: theme.colorScheme.surfaceVariant
                .withValues(alpha: theme.brightness == Brightness.dark ? .35 : .6),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => FacultyMajorsScreen(faculty: f)),
                );
              },
              child: ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: .12),
                  foregroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.apartment_rounded),
                ),
                title: Text(f.name),
                subtitle: Text(
                  subtitleText,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                trailing: Icon(Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================== UI: Majors =================================
class FacultyMajorsScreen extends StatelessWidget {
  final ProgramFaculty faculty;
  const FacultyMajorsScreen({super.key, required this.faculty});

  static  Color _primaryColor = AppTeal.main;
  static const Color _blueColor = Color(0xFF1565C0);
  static const Color _lightBackgroundColor = Color(0xFFEAF7F8);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textDirection = Directionality.of(context);
    final isRtl = textDirection == TextDirection.rtl;
    final majors = faculty.majors;

    return AppScaffold(
      //endDrawer: const AppEndDrawer(),
      padding: EdgeInsets.zero,
      background: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF6FBFC),
      body: Directionality(
        textDirection: textDirection,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                theme.colorScheme.surface,
                theme.scaffoldBackgroundColor,
              ]
                  : const [
                Color(0xFFEAF7F8),
                Color(0xFFF8FCFD),
              ],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            children: [
              _FacultyMajorsHeader(
                facultyName: faculty.name,
                isRtl: isRtl,
                onBack: () => Navigator.pop(context),
              ),
              const SizedBox(height: 22),
              if (majors.isEmpty)
                const _FacultyMajorsEmptyState()
              else
                ...List.generate(majors.length, (index) {
                  final major = majors[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == majors.length - 1 ? 0 : 14,
                    ),
                    child: _FacultyMajorCard(
                      major: major,
                      isRtl: isRtl,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MajorTracksScreen(
                              major: major,
                              faculty: faculty,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _FacultyMajorsHeader extends StatelessWidget {
  const _FacultyMajorsHeader({
    required this.facultyName,
    required this.isRtl,
    required this.onBack,
  });

  final String facultyName;
  final bool isRtl;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final foregroundColor = isDark ? Colors.white : const Color(0xFF083D43);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: isDark
              ? [
            theme.colorScheme.surfaceContainerHighest,
            theme.colorScheme.surface,
          ]
              : const [
            Colors.white,
            FacultyMajorsScreen._lightBackgroundColor,
          ],
        ),
        border: Border.all(
          color: (isDark ? Colors.white : FacultyMajorsScreen._primaryColor)
              .withValues(alpha: isDark ? .08 : .12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? .22 : .07),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _FacultyBackButton(isRtl: isRtl, onPressed: onBack),
              const SizedBox(width: 12),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: FacultyMajorsScreen._primaryColor.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child:  Icon(
                  Icons.apartment_rounded,
                  color: FacultyMajorsScreen._primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            facultyName,
            textAlign: TextAlign.start,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اختر القسم أو التخصص للمتابعة',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: foregroundColor.withValues(alpha: .68),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FacultyBackButton extends StatelessWidget {
  const _FacultyBackButton({required this.isRtl, required this.onPressed});

  final bool isRtl;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: .08)
          : Colors.white.withValues(alpha: .9),
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: .08),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isDark ? Colors.white : FacultyMajorsScreen._primaryColor)
                  .withValues(alpha: isDark ? .10 : .12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? .18 : .05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
            color: isDark ? Colors.white : FacultyMajorsScreen._primaryColor,
          ),
        ),
      ),
    );
  }
}

class _FacultyMajorCard extends StatelessWidget {
  const _FacultyMajorCard({
    required this.major,
    required this.isRtl,
    required this.onTap,
  });

  final ProgramMajor major;
  final bool isRtl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF083D43);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        splashColor: FacultyMajorsScreen._primaryColor.withValues(alpha: .08),
        highlightColor: FacultyMajorsScreen._primaryColor.withValues(alpha: .04),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: (isDark ? Colors.white : FacultyMajorsScreen._primaryColor)
                  .withValues(alpha: isDark ? .08 : .10),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? .20 : .06),
                blurRadius: 20,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient:  LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      FacultyMajorsScreen._primaryColor,
                      FacultyMajorsScreen._blueColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: FacultyMajorsScreen._primaryColor.withValues(alpha: .22),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  major.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: FacultyMajorsScreen._lightBackgroundColor,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: FacultyMajorsScreen._primaryColor.withValues(alpha: .10),
                  ),
                ),
                child: Icon(
                  isRtl
                      ? Icons.arrow_back_ios_new_rounded
                      : Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: FacultyMajorsScreen._primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FacultyMajorsEmptyState extends StatelessWidget {
  const _FacultyMajorsEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: FacultyMajorsScreen._primaryColor.withValues(alpha: .10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? .18 : .05),
            blurRadius: 20,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: FacultyMajorsScreen._lightBackgroundColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child:  Icon(
              Icons.school_rounded,
              color: FacultyMajorsScreen._primaryColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد أقسام متاحة حاليًا',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF083D43),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================== UI: Tracks =================================
class MajorTracksScreen extends StatelessWidget {
  final ProgramMajor major;
  final ProgramFaculty faculty;

  const MajorTracksScreen({
    super.key,
    required this.major,
    required this.faculty,
  });

  static final Color _primaryColor = FacultyMajorsScreen._primaryColor;
  static const Color _blueColor = FacultyMajorsScreen._blueColor;
  static const Color _lightBackgroundColor = FacultyMajorsScreen._lightBackgroundColor;

  @override
  Widget build(BuildContext context) {
    // تجميع التراكات حسب المستوى مع الحفاظ على ترتيب البيانات كما هو
    final Map<String, List<ProgramTrack>> tracksByLevel = {};
    for (var track in major.tracks) {
      tracksByLevel.putIfAbsent(track.level, () => []).add(track);
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textDirection = Directionality.of(context);
    final isRtl = textDirection == TextDirection.rtl;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF6FBFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFEAF7F8),
        surfaceTintColor: Colors.transparent,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsetsDirectional.only(start: 12),
          child: _TrackBackButton(
            isRtl: isRtl,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          major.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF083D43),
          ),
        ),
      ),
      body: Directionality(
        textDirection: textDirection,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                theme.colorScheme.surface,
                theme.scaffoldBackgroundColor,
              ]
                  : const [
                Color(0xFFEAF7F8),
                Color(0xFFF8FCFD),
              ],
            ),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
            itemCount: tracksByLevel.length,
            itemBuilder: (context, index) {
              final entry = tracksByLevel.entries.elementAt(index);
              return _TrackLevelSection(
                level: entry.key,
                tracks: entry.value,
                major: major,
                faculty: faculty,
                isRtl: isRtl,
                isLast: index == tracksByLevel.length - 1,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TrackBackButton extends StatelessWidget {
  const _TrackBackButton({required this.isRtl, required this.onPressed});

  final bool isRtl;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: .72)
                  : Colors.white.withValues(alpha: .94),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: MajorTracksScreen._primaryColor.withValues(alpha: isDark ? .18 : .12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? .18 : .05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
              size: 21,
              color: isDark ? Colors.white : MajorTracksScreen._primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackLevelSection extends StatelessWidget {
  const _TrackLevelSection({
    required this.level,
    required this.tracks,
    required this.major,
    required this.faculty,
    required this.isRtl,
    required this.isLast,
  });

  final String level;
  final List<ProgramTrack> tracks;
  final ProgramMajor major;
  final ProgramFaculty faculty;
  final bool isRtl;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TrackLevelHeader(level: level),
          const SizedBox(height: 10),
          ...List.generate(tracks.length, (index) {
            final track = tracks[index];
            return Padding(
              padding: EdgeInsets.only(bottom: index == tracks.length - 1 ? 0 : 10),
              child: _TrackSpecialtyCard(
                track: track,
                major: major,
                faculty: faculty,
                isRtl: isRtl,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TrackLevelHeader extends StatelessWidget {
  const _TrackLevelHeader({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final foregroundColor = isDark ? Colors.white : const Color(0xFF083D43);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient:  LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                MajorTracksScreen._primaryColor,
                MajorTracksScreen._blueColor,
              ],
            ),
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: MajorTracksScreen._primaryColor.withValues(alpha: isDark ? .18 : .14),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.school_rounded,
            size: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          level,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            color: foregroundColor,
            fontSize: 21,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 30,
          height: 4,
          decoration: BoxDecoration(
            color: MajorTracksScreen._primaryColor.withValues(alpha: .22),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

class _TrackSpecialtyCard extends StatelessWidget {
  const _TrackSpecialtyCard({
    required this.track,
    required this.major,
    required this.faculty,
    required this.isRtl,
  });

  final ProgramTrack track;
  final ProgramMajor major;
  final ProgramFaculty faculty;
  final bool isRtl;

  static const List<IconData> _specialtyIcons = [
    Icons.menu_book_rounded,
    Icons.auto_stories_rounded,
    Icons.library_books_rounded,
    Icons.school_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF083D43);
    final icon = _specialtyIcons[track.name.hashCode.abs() % _specialtyIcons.length];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final specs = createSemesterSpecsForTrack(track);
          final sem1 = _pickSemester(specs, 'S1');
          final sem2 = _pickSemester(specs, 'S2');

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudiesTableScreen(
                facultyName: track.name,
                programName: '${major.name} • ${track.name}',
                collegeId: faculty.name,
                departmentId: major.name,
                specialtyId: track.name,
                level: track.level,
                academicScopeId: buildAcademicStorageSignature(
                  semester1: sem1,
                  semester2: sem2,
                  level: track.level,
                ),
                semester1Modules: sem1,
                semester2Modules: sem2,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        splashColor: MajorTracksScreen._primaryColor.withValues(alpha: .08),
        highlightColor: MajorTracksScreen._primaryColor.withValues(alpha: .04),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: .78)
                  : Colors.white.withValues(alpha: .96),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isDark ? Colors.white : MajorTracksScreen._primaryColor)
                    .withValues(alpha: isDark ? .08 : .11),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? .18 : .045),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient:  LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        MajorTracksScreen._primaryColor,
                        MajorTracksScreen._blueColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: MajorTracksScreen._primaryColor.withValues(alpha: .18),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    track.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isDark
                        ? MajorTracksScreen._primaryColor.withValues(alpha: .14)
                        : MajorTracksScreen._lightBackgroundColor,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: MajorTracksScreen._primaryColor.withValues(alpha: .12),
                    ),
                  ),
                  child: Icon(
                    isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                    size: 24,
                    color: MajorTracksScreen._primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========================== UI: Studies GPA Table ============================
class StudiesTableScreen extends StatefulWidget {
  final String facultyName;
  final String programName;
  final String collegeId;
  final String departmentId;
  final String specialtyId;
  final String level;
  final String academicScopeId;
  final SemesterSpec semester1Modules;
  final SemesterSpec semester2Modules;

  const StudiesTableScreen({
    super.key,
    required this.facultyName,
    required this.programName,
    required this.collegeId,
    required this.departmentId,
    required this.specialtyId,
    required this.level,
    required this.academicScopeId,
    required this.semester1Modules,
    required this.semester2Modules,
  });

  @override
  State<StudiesTableScreen> createState() => _StudiesTableScreenState();
}

class _KeepAlive extends StatefulWidget {
  final Widget child;

  const _KeepAlive({required this.child});

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // مهم لمنع ضياع الحالة
    return widget.child;
  }
}

class _StudiesTableScreenState extends State<StudiesTableScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late SemesterModel _semester1;
  late SemesterModel _semester2;
  late GradesLocalStore _gradesStore;
  final Set<String> _loadedModuleStates = {};

  int currentIndex = 0; // ← هذا يمثل index الحالي

  @override
  void initState() {
    super.initState();
    _initializeGradesStore();
    _tabController = TabController(length: 2, vsync: this);
    _initSemesters();
    Future.microtask(() async {
      await loadSemesterNotes();
    });

    // الاستماع لتغييرات الـ index عند التمرير أو الضغط على الـ Tab
    _tabController.addListener(() {
      if (_tabController.index == currentIndex) return;
      setState(() {
        currentIndex = _tabController.index;
      });
      Future.microtask(() async {
        await loadSemesterNotes();
      });
    });
  }

  void _initializeGradesStore() {
    _gradesStore = GradesLocalStore(
      scope: GradesStorageScope(
        collegeId: widget.collegeId,
        departmentId: widget.departmentId,
        specialtyId: widget.specialtyId,
        level: widget.level,
        academicScopeId: widget.academicScopeId,
      ),
    );
  }


  void _initSemesters() {
    _semester1 = SemesterModel.fromSpec(
      widget.semester1Modules,
      onChanged: () => setState(() {}),
    );
    _semester2 = SemesterModel.fromSpec(
      widget.semester2Modules,
      onChanged: () => setState(() {}),
    );
  }
  // Regression checklist (manual):
  // 1) Edit grades/coef/cred/weights in Department A + Specialty X, then Save.
  // 2) Open Department B + Specialty Y (same level/semester/module names) => values must remain unchanged.
  // 3) Return to Department A + Specialty X => edited values must persist.
  // 4) First load with old global data migrates once into scoped storage, then reads scoped keys only.
  /// ==================== حفظ بيانات الفصل الحالي باستخدام SharedPreferences ====================
  Future<void> saveCurrentSemesterNotes() async {
    debugPrint('SAVE_CLICKED');
    FocusScope.of(context).unfocus(); // ← يفرض إنهاء تحرير أي TextField

    final currentSemester =
    _tabController.index == 0 ? _semester1 : _semester2;
    final semesterKey = currentSemester.name.trim().toUpperCase();
    for (final module in currentSemester.modules) {
      debugPrint(
        'SAVE_PAYLOAD semesterKey=$semesterKey moduleId=${module.id} '
            'cred=${module.credits} coef=${module.coef} td=${module.td} '
            'exam=${module.exam} tp=${module.tp} '
            'wTd=${module.wTD} wExam=${module.wEX} wTp=${module.wTP}',
      );
    }
    try {
      await _gradesStore.saveModuleStates(
        semesterKey,
        currentSemester.modules,
      );
      final readBack = await _gradesStore.loadModuleStates(semesterKey);
      debugPrint(
        'SAVE_READBACK semesterKey=$semesterKey data=${jsonEncode(readBack)}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Saved")),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('SAVE_ERROR semesterKey=$semesterKey error=$error');
      debugPrint('SAVE_STACK $stackTrace');
    }
  }

  /// ==================== تحميل بيانات الفصل الحالي من SharedPreferences ====================
  Future<void> loadSemesterNotes() async {
    final currentSemester =
    _tabController.index == 0 ? _semester1 : _semester2;
    final semesterKey = currentSemester.name.trim().toUpperCase();
    debugPrint('LOAD_START semesterKey=$semesterKey');
    final overrides = await _gradesStore.loadModuleStates(semesterKey);
    debugPrint(
      'LOAD_OVERRIDES semesterKey=$semesterKey data=${jsonEncode(overrides)}',
    );
    if (overrides.isEmpty) {
      debugPrint(
        'LOAD_DEFAULT semesterKey=$semesterKey reason=no_saved_data',
      );
    }

    var updated = false;
    if (!_loadedModuleStates.contains(semesterKey)) {
      for (final module in currentSemester.modules) {
        final moduleOverride = overrides[module.id];
        if (moduleOverride == null) {
          debugPrint(
            'LOAD_DEFAULT semesterKey=$semesterKey moduleId=${module.id} '
                'reason=missing_override',
          );
          continue;
        }
        module.coef = moduleOverride['coef']?.toDouble() ?? module.coef;
        module.credits = moduleOverride['cred']?.toDouble() ?? module.credits;
        module.td = moduleOverride['td'] ?? module.td;
        module.tp = moduleOverride['tp'] ?? module.tp;
        module.exam = moduleOverride['exam'] ?? module.exam;
        module.wTD = moduleOverride['wTD'] ?? module.wTD;
        module.wEX = moduleOverride['wEX'] ?? module.wEX;
        module.wTP = moduleOverride['wTP'] ?? module.wTP;
        updated = true;
      }
      _loadedModuleStates.add(semesterKey);
    }

    if (mounted && updated) setState(() {});
  }





  @override
  void didUpdateWidget(covariant StudiesTableScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final trackChanged = oldWidget.collegeId != widget.collegeId ||
        oldWidget.departmentId != widget.departmentId ||
        oldWidget.specialtyId != widget.specialtyId ||
        oldWidget.level != widget.level;
    final modulesChanged = oldWidget.semester1Modules != widget.semester1Modules ||
        oldWidget.semester2Modules != widget.semester2Modules;
    if (trackChanged || modulesChanged) {
      if (trackChanged) {
        _initializeGradesStore();
      }
      _initSemesters();
      _loadedModuleStates.clear();
      Future.microtask(() async {
        await loadSemesterNotes();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  Widget _buildSemesterTabContent(SemesterModel semester) {
    return Builder(
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        const summaryPadding = 220.0;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: SingleChildScrollView(
            //key: ValueKey('${semester.name}_${semester.modules.length}'),
            padding: EdgeInsets.fromLTRB(0, 8, 0, bottomInset),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // محتوى الجدول الخاص بالفصل
                buildSemesterTable(context, semester),

                const SizedBox(height: 16),

                // بطاقة الملخص السنوي داخل التمرير
                if (_tabController.index == 0)
                  _AnnualSummaryCard(
                    semester1: _semester1,
                    semester2: _semester2,
                    showS1: true,
                    showS2: false,
                    showAnnual: false,
                  ),
                if (_tabController.index == 1)
                  _AnnualSummaryCard(
                    semester1: _semester1,
                    semester2: _semester2,
                    showS1: false,
                    showS2: true,
                    showAnnual: true,
                  )
              ],
            ),
          ),
        );
      },
    );
  }





  @override
  Widget build(BuildContext context) {
    final sem1 = _semester1;
    final sem2 = _semester2;
    final canPop = Navigator.canPop(context);

    return AppScaffold(

        body:
        NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
                pinned: false,
                floating: true,
                snap: true,
                expandedHeight: 50,
                actionsIconTheme: IconThemeData(
                    color: Theme.of(context).colorScheme.onSurface
                    ,size: 15
                ),
                flexibleSpace:
                FlexibleSpaceBar(
                    background: Padding(
                        padding:  EdgeInsets.symmetric(horizontal: 0, vertical: 1),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(width: 45),
                              // النص طويل
                              Expanded(
                                child: Text(
                                  widget.facultyName+' :',
                                  style: TextStyle(fontSize: 20,
                                      color: Theme.of(context).colorScheme.onSurface),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // زر الحفظ
                              IconButton(
                                icon: Icon(Icons.save, color: Theme.of(context).colorScheme.onSurface ),
                                onPressed: saveCurrentSemesterNotes,
                                tooltip: "Save current semester",
                                iconSize:  25,
                              ),
                              IconButton(
                                icon:  Icon(Icons.insert_drive_file_rounded,
                                    color: Theme.of(context).colorScheme.onSurface),
                                iconSize: 25,
                                tooltip: "Download as PDF",
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ResultsScreen(
                                        semester1: _semester1,
                                        semester2: _semester2,
                                        programLabel: '${widget.programName}',
                                      ),
                                    ),
                                  );
                                },
                              )

                            ]
                        )
                    )
                )
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: TabBarDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'S1'),
                    Tab(text: 'S2'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _KeepAlive(child: _buildSemesterTabContent(sem1)),
              _KeepAlive(child: _buildSemesterTabContent(sem2)),
            ],
          ),
        )
    );
  }
}

class GradesStorageScope {
  const GradesStorageScope({
    required this.collegeId,
    required this.departmentId,
    required this.specialtyId,
    required this.level,
    required this.academicScopeId,
  });

  final String collegeId;
  final String departmentId;
  final String specialtyId;
  final String level;
  final String academicScopeId;

  String _sanitize(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return '';
    // Keep non-latin identifiers stable (e.g. Arabic) to avoid collisions
    // across tracks that would otherwise be reduced to empty/unknown values.
    return Uri.encodeComponent(normalized);
  }

  String get storageKey {
    final scope = _sanitize(academicScopeId);
    if (scope.isNotEmpty) {
      return 'scope__$scope';
    }

    // Fallback for safety in case the new scope id is missing unexpectedly.
    final lvl = _sanitize(level);
    return [
      'scope__legacy',
      if (lvl.isNotEmpty) lvl else 'unknown_level',
    ].join('__');
  }
}

class GradesLocalStore {
  static const bool _debugGradeStorageKeys = false;
  static const String _globalStorageKey = 'unispace_grades_v1';
  static const String _modulesStoragePrefix = 'modules_';
  static const String _scopedStoragePrefix = 'unispace_grades_v2_';

  GradesLocalStore({required this.scope});

  final GradesStorageScope scope;

  String get _storageKey => '$_scopedStoragePrefix${scope.storageKey}';

  String _normalizeSemesterKey(String semester) {
    return semester.trim().toUpperCase();
  }

  String _entryKey(String semester, String moduleId) {
    final normalizedSemester = _normalizeSemesterKey(semester);
    return '$normalizedSemester|$moduleId';
  }

  String _legacyModulesKey(String semester) {
    final normalizedSemester = _normalizeSemesterKey(semester).toLowerCase();
    return '$_modulesStoragePrefix$normalizedSemester';
  }

  String _modulesKey(String semester) {
    final normalizedSemester = _normalizeSemesterKey(semester).toLowerCase();
    return '$_modulesStoragePrefix${scope.storageKey}_$normalizedSemester';
  }

  Future<Map<String, dynamic>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (_debugGradeStorageKeys) {
      debugPrint('GRADES_LOAD_ALL key=$_storageKey');
    }
    if (raw == null || raw.isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> _loadLegacyGlobalAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_globalStorageKey);
    if (raw == null || raw.isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{};
  }

  Future<void> _saveAll(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    if (_debugGradeStorageKeys) {
      debugPrint('GRADES_SAVE_ALL key=$_storageKey entries=${data.length}');
    }
    try {
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (error, stackTrace) {
      debugPrint('SAVE_ALL_ERROR error=$error');
      debugPrint('SAVE_ALL_STACK $stackTrace');
      rethrow;
    }
  }


  Future<void> _migrateLegacyGradeEntryIfNeeded(
      String semester,
      String moduleId,
      ) async {
    final scoped = await _loadAll();
    final key = _entryKey(semester, moduleId);
    if (scoped.containsKey(key)) {
      return;
    }
    final legacy = await _loadLegacyGlobalAll();
    final legacyEntry = legacy[key];
    if (legacyEntry == null) {
      return;
    }
    scoped[key] = legacyEntry;
    await _saveAll(scoped);
  }

  Future<void> _migrateLegacyModulesIfNeeded(String semester) async {
    final prefs = await SharedPreferences.getInstance();
    final scopedKey = _modulesKey(semester);
    final scopedRaw = prefs.getString(scopedKey);
    if (scopedRaw != null && scopedRaw.isNotEmpty) {
      return;
    }

    final legacyKey = _legacyModulesKey(semester);
    final legacyRaw = prefs.getString(legacyKey);
    if (legacyRaw != null && legacyRaw.isNotEmpty) {
      await prefs.setString(scopedKey, legacyRaw);
      return;
    }

    final legacyGlobal = await _loadLegacyGlobalAll();
    final normalizedSemester = _normalizeSemesterKey(semester);
    final migratedPayload = <Map<String, dynamic>>[];
    for (final entry in legacyGlobal.entries) {
      final key = entry.key;
      if (!key.startsWith('$normalizedSemester|')) continue;
      final data = entry.value;
      if (data is! Map) continue;
      final moduleId = key.substring('$normalizedSemester|'.length);
      if (moduleId.isEmpty) continue;
      migratedPayload.add({
        'moduleId': moduleId,
        'moduleName': null,
        'semester': semester,
        'coef': data['coef'],
        'cred': data['cred'],
        'td': data['td'],
        'tp': data['tp'],
        'exam': data['exam'],
        'moy': data['moy'],
        'wTD': data['wTD'],
        'wEX': data['wEX'],
        'wTP': data['wTP'],
      });
    }
    if (migratedPayload.isNotEmpty) {
      await prefs.setString(scopedKey, jsonEncode(migratedPayload));
    }
  }

  Future<Map<String, double?>?> loadGrade(
      String semester,
      String moduleId,
      ) async {
    await _migrateLegacyGradeEntryIfNeeded(semester, moduleId);
    final all = await _loadAll();
    final entryKey = _entryKey(semester, moduleId);
    if (_debugGradeStorageKeys) {
      debugPrint('GRADES_LOAD_GRADE key=$_storageKey entry=$entryKey');
    }
    final entry = all[entryKey];
    if (entry is! Map) {
      return null;
    }
    double? toDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return {
      'td': toDouble(entry['td']),
      'exam': toDouble(entry['exam']),
      'tp': toDouble(entry['tp']),
      'moy': toDouble(entry['moy']),
      'coef': toDouble(entry['coef']),
      'cred': toDouble(entry['cred']),
      'wTD': toDouble(entry['wTD']),
      'wEX': toDouble(entry['wEX']),
      'wTP': toDouble(entry['wTP']),
    };

  }

  Future<void> saveGrade(
      String semester,
      String moduleId,
      double? td,
      double? exam,
      double? tp,
      double? moy,
      double coef,
      double cred,
      double wTD,
      double wEX,
      double wTP,
      ) async {
    final all = await _loadAll();

    final hasValues =
        td != null ||
            exam != null ||
            tp != null ||
            moy != null ||
            coef != 0 ||
            cred != 0;

    final key = _entryKey(semester, moduleId);
    if (_debugGradeStorageKeys) {
      debugPrint('GRADES_SAVE_GRADE key=$_storageKey entry=$key');
    }

    if (!hasValues) {
      all.remove(key);
      try {
        await _saveAll(all);
      } catch (error, stackTrace) {
        debugPrint('SAVE_GRADE_REMOVE_ERROR key=$key error=$error');
        debugPrint('SAVE_GRADE_REMOVE_STACK $stackTrace');
        rethrow;
      }
      return;
    }

    all[key] = <String, dynamic>{
      'td': td,
      'exam': exam,
      'tp': tp,
      'moy': moy,
      'coef': coef,
      'cred': cred,
      'wTD': wTD,
      'wEX': wEX,
      'wTP': wTP,
    };

    try {
      await _saveAll(all);
    } catch (error, stackTrace) {
      debugPrint('SAVE_GRADE_ERROR key=$key error=$error');
      debugPrint('SAVE_GRADE_STACK $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, Map<String, dynamic>>> loadModuleStates(
      String semester) async {
    double? toDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    final Map<String, Map<String, dynamic>> states = {};
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyModulesIfNeeded(semester);
    final modulesKey = _modulesKey(semester);
    final raw = prefs.getString(modulesKey);
    debugPrint('LOAD_MODULES_RAW key=$modulesKey raw=$raw');
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        debugPrint(
          'LOAD_MODULES_PARSED key=$modulesKey payload=${jsonEncode(decoded)}',
        );
        if (decoded is List) {
          for (final entry in decoded) {
            if (entry is! Map) continue;
            final id = entry['moduleId']?.toString() ?? entry['id']?.toString();
            if (id == null || id.isEmpty) continue;
            states[id] = {
              'moduleId': id,
              'moduleName': entry['moduleName']?.toString() ??
                  entry['name']?.toString(),
              'semester': entry['semester']?.toString() ?? semester,
              'coef': toDouble(entry['coef']),
              'cred': toDouble(entry['cred']),
              'td': toDouble(entry['td']),
              'tp': toDouble(entry['tp']),
              'exam': toDouble(entry['exam']),
              'moy': toDouble(entry['moy']),
              'wTD': toDouble(entry['wTD']),
              'wEX': toDouble(entry['wEX']),
              'wTP': toDouble(entry['wTP']),
            };
          }
        }
      } catch (error, stackTrace) {
        debugPrint('LOAD_MODULES_ERROR key=$modulesKey error=$error');
        debugPrint('LOAD_MODULES_STACK $stackTrace');
      }
    }

    return states;
  }

  Future<void> saveModuleStates(
      String semester, List<ModuleModel> modules) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = modules
        .map(
          (module) {
        final hasValues =
            module.td != null || module.tp != null || module.exam != null;
        final moy = hasValues ? module.moy : null;
        return <String, dynamic>{
          'moduleId': module.id,
          'moduleName': module.title,
          'semester': semester,
          'coef': module.coef,
          'cred': module.credits,
          'td': module.td,
          'tp': module.tp,
          'exam': module.exam,
          'moy': moy,
          'wTD': module.wTD,
          'wEX': module.wEX,
          'wTP': module.wTP,
        };
      },
    )
        .toList(growable: false);
    final modulesKey = _modulesKey(semester);
    debugPrint(
      'SAVE_MODULES key=$modulesKey payload=${jsonEncode(payload)}',
    );
    try {
      await prefs.setString(modulesKey, jsonEncode(payload));
    } catch (error, stackTrace) {
      debugPrint('SAVE_MODULES_ERROR key=$modulesKey error=$error');
      debugPrint('SAVE_MODULES_STACK $stackTrace');
      rethrow;
    }
    final readBack = prefs.getString(modulesKey);
    debugPrint('SAVE_MODULES_READBACK key=$modulesKey raw=$readBack');
  }

  Future<void> clearGrade(String semester, String moduleId) async {
    final all = await _loadAll();
    all.remove(_entryKey(semester, moduleId));
    await _saveAll(all);
  }
}

Widget buildSemesterTable(BuildContext context, SemesterModel sem) {
  return Padding(
    padding: const EdgeInsets.all(5),
    child: SingleChildScrollView(
      child: Column(
        children: sem.modules.map((module) {
          return Column(
            children: [
              NoteCard(
                coef: module.coef,
                cred: module.credits,
                subject: module.title,
                wTD: module.wTD,
                wEX: module.wEX,
                wTP: module.wTP,

                initialTd: module.td == 0 ? null : module.td,
                initialTp: module.tp == 0 ? null : module.tp,
                initialExam: module.exam == 0 ? null : module.exam,

                onChanged: (td, tp, exam, moy, coef, cred, wTD, wEX, wTP) {
                  module.td = td ?? 0;
                  module.tp = tp ?? 0;
                  module.exam = exam ?? 0;

                  module.coef = coef;
                  module.credits = cred;

                  module.wTD = wTD;
                  module.wEX = wEX;
                  module.wTP = wTP;

                  sem.recompute();
                  (context as Element).markNeedsBuild();
                },

              ),

              const SizedBox(height: 20),
            ],
          );
        }).toList(),
      ),
    ),
  );
}

/// بطاقة المادة NoteCard
class NoteCard extends StatefulWidget {
  final double coef;
  final double cred;
  final String subject;
  final double wTD;
  final double wEX;
  final double wTP;
  final double? initialTd;
  final double? initialTp;
  final double? initialExam;
  final Function(
      double? td,
      double? tp,
      double? exam,
      double moy,
      double coef,
      double cred,
      double wTD,
      double wEX,
      double wTP
      ) onChanged;




  const NoteCard({
    super.key,

    required this.coef,
    required this.cred,
    required this.subject,
    required this.onChanged,
    required this.wTD,
    required this.wEX,
    required this.wTP,
    this.initialTd,
    this.initialTp,
    this.initialExam,

  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}
class NoteResult {
  final double td;
  final double tp;
  final double exam;
  final double moy;
  final double coef;
  final double cred;

  NoteResult(
      this.td,
      this.tp,
      this.exam,
      this.moy,
      this.coef,
      this.cred);
}
class _NoteCardState extends State<NoteCard> {
  double? td;
  double? tp;
  double? exam;
  double moy = 0.0;

  late double coef;
  late double cred;
  late double wTD;
  late double wEX;
  late double wTP;
  late TextEditingController _tdController;
  late TextEditingController _tpController;
  late TextEditingController _examController;
  late TextEditingController _coefController;
  late TextEditingController _credController;

  String? translatedSubject;

  @override
  void initState() {
    super.initState();
    cred = widget.cred; // نهيئه بالقيمة الأصلية
    coef = widget.coef;
    wTD = widget.wTD;
    wEX = widget.wEX;
    wTP = widget.wTP;
    td = widget.initialTd;
    tp = widget.initialTp;
    exam = widget.initialExam;
    calculateMoy();
    _tdController = TextEditingController(text: _formatGrade(td));
    _tpController = TextEditingController(text: _formatGrade(tp));
    _examController = TextEditingController(text: _formatGrade(exam));
    _coefController = TextEditingController(text: coef.toStringAsFixed(0));
    _credController = TextEditingController(text: cred.toStringAsFixed(0));
    _loadTranslatedSubject();

  }
  void _loadTranslatedSubject() async {
    try {
      final result = await translateSubject(context, widget.subject);
      if (mounted) {
        setState(() {
          translatedSubject = result;
        });
      }
    } catch (_) {
      translatedSubject = widget.subject; // fallback عند الخطأ
    }
  }

  @override
  void didUpdateWidget(covariant NoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTd != td ||
        widget.initialTp != tp ||
        widget.initialExam != exam) {
      setState(() {
        td = widget.initialTd;
        tp = widget.initialTp;
        exam = widget.initialExam;
        calculateMoy();
        _tdController.text = _formatGrade(td);
        _tpController.text = _formatGrade(tp);
        _examController.text = _formatGrade(exam);
      });
    }
    if (widget.coef != coef || widget.cred != cred) {
      setState(() {
        coef = widget.coef;
        cred = widget.cred;
        _coefController.text = coef.toStringAsFixed(0);
        _credController.text = cred.toStringAsFixed(0);
      });
    }
    if (widget.wTD != wTD || widget.wEX != wEX || widget.wTP != wTP) {
      setState(() {
        wTD = widget.wTD;
        wEX = widget.wEX;
        wTP = widget.wTP;
        calculateMoy();
      });
    }
  }

  @override
  void dispose() {
    _tdController.dispose();
    _tpController.dispose();
    _examController.dispose();
    _coefController.dispose();
    _credController.dispose();
    super.dispose();
  }

  String _formatGrade(double? value) {
    if (value == null || value == 0) return '';
    return value.toString();
  }


  double? _parseGrade(String value) {
    final sanitized = value.replaceAll(',', '.').trim();
    if (sanitized.isEmpty) return null;
    return double.tryParse(sanitized);
  }

  int? _parseNonNegativeInt(String value) {
    final sanitized = value.trim();
    if (sanitized.isEmpty) return 0;
    final parsed = int.tryParse(sanitized);
    if (parsed == null || parsed < 0) return null;
    return parsed;
  }
  void onTDChanged(String v) {
    setState(() {
      td = _parseGrade(v);
      calculateMoy();
      notifyParent();
    });
  }
  void notifyParent() {
    widget.onChanged(td, tp, exam, moy, coef, cred, wTD, wEX, wTP);
  }

  void onExamChanged(String v) {
    setState(() {
      exam = _parseGrade(v);
      calculateMoy();
      notifyParent();
    });
  }
  void onTPChanged(String v) {
    setState(() {
      tp = _parseGrade(v);
      calculateMoy();
      notifyParent();
    });
  }
  void calculateMoy() {
    if (td == null && tp == null && exam == null) {
      moy = 0;
      return;
    }
// هنا معادلة حساب المعدل
    moy = ((td ?? 0) * wTD) + ((exam ?? 0) * wEX) + ((tp ?? 0) * wTP);
  }
  void updateCred(double newValue) {
    setState(() {
      cred = newValue;
      notifyParent();
    });
  }
  void updateCoef(double newValue) {
    setState(() {
      coef = newValue;
      notifyParent();
    });
  }
  void _showWeightsDialog() {
    TextEditingController wTDController = TextEditingController(text: wTD.toString());
    TextEditingController wEXController = TextEditingController(text: wEX.toString());
    TextEditingController wTPController = TextEditingController(text: wTP.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(S.of(context).editWeights),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              FutureBuilder<String>(
                future: translateSubject(context,widget.subject),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text('...'); // أثناء التحميل
                  } else if (snapshot.hasError) {
                    return Text(widget.subject); // fallback عند الخطأ
                  } else {
                    return Text(
                      textAlign: TextAlign.start,
                      snapshot.data!,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 15,),
              TextField(
                  controller: wTDController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: "W. TD"),
                  textAlign: TextAlign.center
              ),const SizedBox(height: 10,),
              TextField(
                controller: wEXController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "W. EXAM",),
                textAlign: TextAlign.center,
              ),const SizedBox(height: 10,),
              TextField(
                controller: wTPController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "W. TP"),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  wTD = double.tryParse(wTDController.text) ?? wTD;
                  wEX = double.tryParse(wEXController.text) ?? wEX;
                  wTP = double.tryParse(wTPController.text) ?? wTP;
                  calculateMoy();
                  notifyParent();
                });

                Navigator.pop(context);
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Container(width: double.infinity,height: 218,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        border:  Border.all(
          width: 3,
          color: moy == 0
              ? Theme.of(context).colorScheme.onSurface
              : moy < 10
              ? Colors.red.withValues(alpha: 0.7)
              : Colors.green.withValues(alpha: 0.7),
        ),

      ),
      child: Column(
        children: [
          //------------------ الصف العلوي --------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // اسم المادة
              Expanded(
                child:
                Column(
                  children: [

                    Text(
                      translatedSubject ?? widget.subject, // يظهر الاسم الثابت أو fallback أثناء التحميل
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Container(

                      child:
                      const SizedBox(width: 10, height: 15,),
                    ),
                  ],
                ),),
              Row(

                children: [
                  // Coef
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text("Coef", style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 2),
                      Container(
                        width: 60,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              width: 1,
                              color: Theme.of(context).colorScheme.onSurface,)
                        ),
                        child:

                        TextField(
                          controller: _coefController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final parsed = _parseNonNegativeInt(v);
                            if (parsed == null) return;
                            setState(() {
                              coef = parsed.toDouble();
                              notifyParent();
                            });
                          }
                          ,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(fontSize: 15),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.only(top: 2, bottom: 0, left: 0, right: 0),
                            border: InputBorder.none, // إزالة الحد الافتراضي إذا تريد
                          ),
                        ),



                      ),

                    ],
                  ),

                  const SizedBox(width: 5),

                  // Cred
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text("Cred", style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 2),
                      Container(
                          width: 60,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                width: 1,
                                color: Theme.of(context).colorScheme.onSurface,)
                          ),
                          child:
                          TextField(
                            controller: _credController,
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              final parsed = _parseNonNegativeInt(v);
                              if (parsed == null) return;
                              setState(() {
                                cred = parsed.toDouble();
                                notifyParent();
                              });
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(fontSize: 15),
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.only(top: 2, bottom: 0, left: 0, right: 0),
                              border: InputBorder.none, // إزالة الحد الافتراضي إذا تريد
                            ),
                          )


                      ),
                    ],
                  ),
                ],
              ),




            ],
          ),

          const SizedBox(height: 5),
          Container(height: 2,
            color: moy == 0
                ? Theme.of(context).colorScheme.onSurface
                : moy < 10
                ? Colors.red.withValues(alpha: 0.7)
                : Colors.green.withValues(alpha: 0.7),),

          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  S.of(context).notesTdTpExam,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,

                  ),),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
                  onPressed: () {
                    _showWeightsDialog();
                  },
                ),

              ]),

          const SizedBox(height: 0),

          //------------------ حقول TD + EXAM + MOY --------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              Row(children: [

                // EXAM
                if (wEX != 0)
                  Column(
                    children: [
                      const Text("EXAM"),
                      const SizedBox(height: 2),
                      Container(
                        width: 70,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: TextField(
                          controller: _examController,
                          textAlign: TextAlign.center,
                          maxLength: 5,
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            onExamChanged(v);
                          },
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.only(top: 50, bottom: 23, left: 0, right: 0),
                            border: InputBorder.none,
                            counterText: '',

                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(width: 5,),

                // TD
                if (wTD != 0)
                  Column(
                    children: [

                      const Text("TD"),
                      const SizedBox(height: 2),
                      Container(
                        width: 70,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(40),

                        ),
                        child: TextField(
                          controller: _tdController,
                          textAlign: TextAlign.center,
                          maxLength: 5,
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            onTDChanged(v);
                          },

                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.only(top: 50, bottom: 23, left: 0, right: 0),
                            border: InputBorder.none,
                            counterText: '',
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(width: 5,),
                //TP
                if (wTP != 0)
                  Column(
                    children: [

                      const Text("TP"),
                      const SizedBox(height: 2),
                      Container(
                        width: 70,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(40),

                        ),
                        child: TextField(
                          controller: _tpController,
                          textAlign: TextAlign.center,
                          maxLength: 5,
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            onTPChanged(v);
                          },

                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.only(top: 50, bottom: 23, left: 0, right: 0),
                            border: InputBorder.none,
                            counterText: '',
                          ),
                        ),
                      ),
                    ],
                  )

              ]),
              // MOY
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Moy:        ",
                      style: TextStyle(
                        fontSize: 15,

                      )),
                  Text(
                    moy.toStringAsFixed(2),
                    style:  TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: moy == 0
                          ? Theme.of(context).colorScheme.onSurface
                          : moy < 10
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }


}


class TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  TabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Material يعطي خلفية ورفع مناسب للـ TabBar
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant TabBarDelegate oldDelegate) {
    // عدّل إلى true لو أردت إعادة البناء عند تغيّر محتوى الـ TabBar
    return false;
  }
}
/// ------------------------ Résumé annuel -------------------------------
class _AnnualSummaryCard extends StatelessWidget {
  const _AnnualSummaryCard({
    Key? key,
    required this.semester1,
    required this.semester2,
    this.showAnnual = true,
    this.showS1 = true,
    this.showS2 = true,
  }) : super(key: key);

  final SemesterModel semester1;
  final SemesterModel semester2;

  final bool showAnnual; // عرض الملخص السنوي
  final bool showS1; // عرض بطاقة S1
  final bool showS2; // عرض بطاقة S2

  Widget buildInfoCard(
      String title, double value, IconData icon, BuildContext cx) {
    return Container(
      width: 140,
      height: 63,
      padding: const EdgeInsets.fromLTRB(15, 10, 5, 2),
      decoration: BoxDecoration(
        color: Theme.of(cx).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(width: 2, color: Theme.of(cx).colorScheme.onSurface),
      ),
      child: Column(
        children: [
          Row(children: [
            Icon(icon, size: 20),
            const SizedBox(
              width: 5,
            ),
            Text(title, style: const TextStyle(fontSize: 14)),
          ]),
          Text(
            value.toStringAsFixed(2),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final moy1 = semester1.semesterAverage();
    final moy2 = semester2.semesterAverage();
    final ann = ((moy1 + moy2) / 2);
    final creds = semester1.creditsEarned() + semester2.creditsEarned();
    final S1cred = semester1.creditsEarned();
    final S2cred = semester2.creditsEarned();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---------------------- قسم S1 ----------------------
        if (showS1)
          Directionality(
              textDirection:
              TextDirection.ltr, // ← يمنع الانعكاس داخل البطاقة فقط
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(
                      width: 3, color: Theme.of(context).colorScheme.onSurface),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text("S1 Résumé",
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 10),
                    Row(
                      textDirection: TextDirection.ltr,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        buildInfoCard(
                            "S1 Moyenne", moy1, Icons.filter_1, context),
                        buildInfoCard(
                            "S1 Credits", S1cred, Icons.auto_graph, context),
                      ],
                    ),
                  ],
                ),
              )),

        // ---------------------- قسم S2 ----------------------
        if (showS2)
          Directionality(
              textDirection:
              TextDirection.ltr, // ← يمنع الانعكاس داخل البطاقة فقط
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(
                      width: 3, color: Theme.of(context).colorScheme.onSurface),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text("S2 Résumé",
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 10),
                    Row(
                      textDirection: TextDirection.ltr,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        buildInfoCard(
                            "S2 Moyenne", moy2, Icons.filter_2, context),
                        buildInfoCard(
                            "S2 Credits", S2cred, Icons.auto_graph, context),
                      ],
                    ),
                  ],
                ),
              )),

        // ---------------------- الملخص السنوي ----------------------
        if (showAnnual)
          Directionality(
              textDirection:
              TextDirection.ltr, // ← يمنع الانعكاس داخل البطاقة فقط
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(
                      width: 3, color: Theme.of(context).colorScheme.onSurface),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Résumé Annual",
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 10),
                    Row(
                      textDirection: TextDirection.ltr,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        buildInfoCard("Année", ann, Icons.verified, context),
                        buildInfoCard(
                            "Total Credits", creds, Icons.auto_graph, context),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          width: 3,
                          color: ann == 0
                              ? Theme.of(context).colorScheme.onSurface
                              : ann < 10
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start, // Résultat: في البداية
                        children: [
                          Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Résultat:",
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              )),

                          const SizedBox(height: 0),

                          // النتيجة في الوسط
                          Center(
                            child: Text(
                              ann == 0
                                  ? '---'
                                  : (ann >= 10
                                  ? '✨u Succeeded✨'
                                  : 'u Failed ❌'),
                              style: GoogleFonts.dmMono(
                                  textStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                    color: ann == 0
                                        ? Theme.of(context).colorScheme.onSurface
                                        : ann < 10
                                        ? Colors.red
                                        : Colors.green,
                                  )),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              )),
      ],
    );
  }
}

Widget buildInfoCard(String title, double value, IconData icon) {
  return Card(
    //color:Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    )),
                Icon(
                  icon,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 0),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ));
}

extension SafeStringExt on String {
  String ellipsize(int max, {String ellipsis = '…'}) {
    if (length <= max) return this;
    if (max <= 0) return '';
    return substring(0, max) + ellipsis;
  }
}

// دالة تأخذك مباشرةً إلى واجهة “الدراسة”
void openStudiesNavigator(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
        builder: (_) => FacultiesScreen(faculties: getDemoFaculties(context))),
  );
}
/////////////////////////////////////////////////////////////////////////////
/////////////////////result screen///////////////////////////////
/////////////////////////////////////////////////////////////////////////////////

class ResultsScreen extends StatelessWidget {
  final SemesterModel semester1;
  final SemesterModel semester2;
  final String programLabel; // مثال: "Licence 2ème Année" (اختياري)

  const ResultsScreen({
    Key? key,
    required this.semester1,
    required this.semester2,
    this.programLabel = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // حسابات
    final double moy1 = semester1.semesterAverage();
    final double moy2 = semester2.semesterAverage();
    // إذا كان أحد الفصول فارغاً، إبقاء المتوسط = 0
    final double ann = _computeAnnual(moy1, moy2);
    final double cred1 = semester1.creditsEarned();
    final double cred2 = semester2.creditsEarned();
    final double totalCred = cred1 + cred2;

    final decisionColor = _decisionColor(context, ann);
    final decisionText = _decisionText(ann);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).studyResults),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final file = await PdfReportService.generateReport(
            faculty: programLabel, // مثال: يمكنك تمرير قيمة من parameters
            program: programLabel,
            semester1: semester1,
            semester2: semester2,
          );
          await OpenFilex.open(file.path);
        },
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('PDF'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- عنوان السنة / البرنامج ----------
            if (programLabel.isNotEmpty) ...[
              Text(
                programLabel,
                style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
            ],
            // ---------- العنوان العام + البطاقة العليا ----------
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: ann == 0
                    ? Theme.of(context).colorScheme.surface
                    : decisionColor.withValues(alpha: 0.10),
                border: Border.all(
                  color: ann == 0
                      ? Theme.of(context).colorScheme.outline
                      : decisionColor,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Decision :',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      )),
                  const SizedBox(height: 8),
                  Row(
                    textDirection: TextDirection.ltr,
                    children: [
                      // -------- بطاقة المعدل السنوي --------
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context).colorScheme.surface,
                            border: Border.all(
                              color:
                              Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Année',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color:
                                  Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 0),
                              Text(
                                ann == 0 ? '0.0' : ann.toStringAsFixed(2),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: ann == 0
                                      ? Theme.of(context).colorScheme.onSurface
                                      : decisionColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // -------- بطاقة الرصيد الإجمالي --------
                      Container(
                        width: 100,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context).colorScheme.surface,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Total Credits',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 0),
                            Text(
                              totalCred.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // -------- بطاقة النتيجة النهائية --------
                      Container(
                        width: 120,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: ann == 0
                              ? Theme.of(context).colorScheme.surface
                              : decisionColor,
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Résultat',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: ann == 0
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 0),
                            Text(
                              ann == 0 ? '---' : decisionText,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: ann == 0
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ---------- متوسط الفصل الأول و رصيده ----------
            _buildSemesterSummaryRow('S1', moy1, cred1, context),
            const SizedBox(height: 8),
            _buildSemesterSummaryRow('S2', moy2, cred2, context),
            const SizedBox(height: 12),

            const Divider(),

            // ---------- قوائم المواد: S1 ثم S2 ----------

            _buildModuleListSection(context, 'S1 Modules', semester1.modules),
            const SizedBox(height: 16),
            _buildModuleListSection(context, 'S2 Modules', semester2.modules),
          ],
        ),
      ),
    );
  }

  static double _computeAnnual(double moy1, double moy2) {
    // نعتبر 0 إن لم تكن هناك مواد؛ يمكن تعديل المنطق إذا كان مطلوباً غير ذلك
    if (moy1 == 0 && moy2 == 0) return 0.0;
    // لو أحدهم صفر ونريد حساب السنوي بناءً على الموجود فقط:
    if (moy1 == 0) return double.parse(moy2.toStringAsFixed(2));
    if (moy2 == 0) return double.parse(moy1.toStringAsFixed(2));
    return double.parse(((moy1 + moy2) / 2).toStringAsFixed(2));
  }

  static Color _decisionColor(BuildContext cx, double ann) {
    if (ann == 0) return Colors.grey.shade400;
    return ann < 10 ? Colors.red : Colors.green;
  }

  static String _decisionText(double ann) {
    if (ann == 0) return '---';
    return ann < 10 ? 'Failed' : 'Succeed';
  }

  Widget _buildSemesterSummaryRow(
      String label, double moy, double creds, BuildContext ctx) {
    final scheme = Theme.of(ctx).colorScheme;

    final Color color = moy == 0
        ? scheme.onSurface.withValues(alpha: 0.6)
        : (moy < 10 ? Colors.red : Colors.green);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
          ),
        ),
        Row(
          children: [
            // بطاقة المعدل
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color),
                color: scheme.surface,
              ),
              child: Text(
                'Moy: ${moy == 0 ? '---' : moy.toStringAsFixed(2)}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 10),

            // بطاقة الرصيد
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: scheme.outlineVariant),
                color: scheme.surface,
              ),
              child: Text(
                'Credits: ${creds.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModuleListSection(
      BuildContext context, String title, List<ModuleModel> modules) {
    final scheme = Theme.of(context).colorScheme;

    if (modules.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            S.of(context).noSubjectsThisSemester,
            style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7)),
          ),
        ],
      );
    }

    return Column(
      //crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
            alignment: Alignment.centerLeft,
            child: Text(
              textDirection: TextDirection.ltr,
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            )),
        const SizedBox(height: 8),
        ...modules.map((m) => _buildModuleRow(context, m)).toList(),
      ],
    );
  }

  Widget _buildModuleRow(BuildContext context, ModuleModel m) {
    final scheme = Theme.of(context).colorScheme;

    final grade = m.moy;
    final gradeColor = _getGradeColor(grade);

    return Card(
      color: scheme.surface,
      shadowColor: scheme.shadow,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        title: FutureBuilder<String>(
          future: translateSubject(context, m.title),
          builder: (context, snapshot) {
            return Text(
              snapshot.data ?? m.title,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            );
          },
        ),
        subtitle: Text(
          '${S.of(context).credits}: ${m.credits.toStringAsFixed(0)}  /  '
              '${S.of(context).coefficient}: ${m.coef.toStringAsFixed(0)}',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        trailing: SizedBox(
          width: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    grade.toStringAsFixed(2),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: gradeColor,
                    ),
                  ),
                  Text(
                    _gradeLabel(grade),
                    style: TextStyle(color: gradeColor),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(
                icon:
                Icon(Icons.info_outline, size: 20, color: scheme.onSurface),
                onPressed: () => _showModuleWeightsDialog(context, m),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showModuleWeightsDialog(BuildContext context, ModuleModel m) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: FutureBuilder<String>(
          future: translateSubject(context, m.title),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('...'); // أثناء التحميل
            } else if (snapshot.hasError) {
              return Text(m.title); // fallback عند الخطأ
            } else {
              return Text(
                snapshot.data!,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              );
            }
          },
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _infoRow('wTD', m.wTD),
            _infoRow('wTP', m.wTP),
            _infoRow('wEX', m.wEX),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(S.of(context).close)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value.toStringAsFixed(2)),
        ],
      ),
    );
  }

  Color _getGradeColor(double grade) {
    if (grade >= 10) return Colors.green;
    //if (grade >= 8) return Colors.orange;
    return Colors.red;
  }

  String _gradeLabel(double grade) {
    if (grade >= 10) return 'SUCCEED';
    //if (grade >= 8) return 'FAILED';
    return 'FAILED';
  }
}

class PdfReportService {
  static Future<File> generateReport({
    required String faculty,
    required String program,
    required SemesterModel semester1,
    required SemesterModel semester2,
  }) async {
    final generatedAt = DateTime.now();
    final pdf = pw.Document(
      title: 'Relevé des résultats UniSpace',
      author: 'UniSpace',
      subject: 'Relevé annuel des résultats',
      creator: 'UniSpace Flutter App',
      producer: 'UniSpace PDF Service',
    );

    // حساب المتوسطات
    final moy1 = semester1.semesterAverage();
    final moy2 = semester2.semesterAverage();
    final ann = (moy1 + moy2) / 2;

    final cred1 = semester1.creditsEarned();
    final cred2 = semester2.creditsEarned();
    final totalCred = cred1 + cred2;

    final decision = ann == 0 ? '---' : (ann >= 10 ? 'SUCCÈS' : 'AJOURNÉ');
    final regularFont =
    pw.Font.ttf(await rootBundle.load("assets/fonts/Tajawal-Regular.ttf"));
    final boldFont =
    pw.Font.ttf(await rootBundle.load("assets/fonts/Tajawal-Bold.ttf"));
    final user = FirebaseAuth.instance.currentUser;
    final fullName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : 'Étudiant UniSpace';
    final email = _maskEmail(user?.email);
    final docId = _buildDocumentId(generatedAt, semester1, semester2);
    final academicYear = _academicYear(generatedAt);

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        footer: (context) => _footer(context, generatedAt, docId),
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.ltr,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Université : Université UniSpace',
                    style: pw.TextStyle(font: boldFont, fontSize: 14)),
                pw.Text('Faculté : ${faculty.isEmpty ? 'Non renseignée' : faculty}'),
                pw.Text('Programme / Spécialité : ${program.isEmpty ? 'Non renseigné' : program}'),
                pw.Text('Année universitaire : $academicYear'),
                pw.Text('Nom & Prénom : $fullName'),
                pw.Text('Email : ${email ?? 'Non renseigné'}'),
                pw.SizedBox(height: 16),
                _sectionTitle('DÉCISION', font: boldFont),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(3),
                    1: pw.FlexColumnWidth(2),
                    2: pw.FlexColumnWidth(3),
                    3: pw.FlexColumnWidth(2),
                    4: pw.FlexColumnWidth(2),
                    5: pw.FlexColumnWidth(2),
                  },
                  children: [
                    _decisionHeaderRow(),
                    _decisionValueRow(
                      ann,
                      totalCred,
                      decision,
                      moy1,
                      moy2,
                      cred1,
                      cred2,
                    ),
                  ],
                ),
                pw.SizedBox(height: 14),
                _sectionTitle('SEMESTRE 1', font: boldFont),
                pw.SizedBox(height: 8),
                _modulesTable(semester1.modules),
                pw.SizedBox(height: 14),
                _sectionTitle('SEMESTRE 2', font: boldFont),
                pw.SizedBox(height: 8),
                _modulesTable(semester2.modules),
              ],
            ),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/results.pdf");
    return file.writeAsBytes(await pdf.save());
  }

  // ----------- Helpers -----------

  static pw.Widget _sectionTitle(String text, {required pw.Font font}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      color: PdfColors.grey300,
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 15,
          fontWeight: pw.FontWeight.bold,
          font: font, // استخدم الخط الممرر
        ),
      ),
    );
  }

  static pw.TableRow _decisionHeaderRow() {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        _tableCell('Année (moyenne générale)', bold: true),
        _tableCell('Total Crédits', bold: true),
        _tableCell('Résultat', bold: true),
        _tableCell('Moyenne S1', bold: true),
        _tableCell('Moyenne S2', bold: true),
        _tableCell('Crédits S1/S2', bold: true),
      ],
    );
  }

  static pw.TableRow _decisionValueRow(
      double ann,
      double totalCred,
      String decision,
      double moy1,
      double moy2,
      double cred1,
      double cred2,
      ) {
    return pw.TableRow(
      children: [
        _tableCell(ann.toStringAsFixed(2)),
        _tableCell(totalCred.toStringAsFixed(0)),
        _tableCell(decision),
        _tableCell(moy1.toStringAsFixed(2)),
        _tableCell(moy2.toStringAsFixed(2)),
        _tableCell('${cred1.toStringAsFixed(0)} / ${cred2.toStringAsFixed(0)}'),
      ],
    );
  }

  static pw.Widget _modulesTable(List<ModuleModel> modules) {
    final rows = modules
        .map((m) => [
      m.title.ellipsize(42),
      m.coef.toString(),
      m.credits.toString(),
      m.moy.toStringAsFixed(2),
    ])
        .toList();

    return pw.Table.fromTextArray(
      headers: const ['Module', 'Coef', 'Crédit', 'Moyenne'],
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.grey400),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      headerStyle:
      pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 10),
      columnWidths: const {
        0: pw.FixedColumnWidth(250),
        1: pw.FixedColumnWidth(55),
        2: pw.FixedColumnWidth(55),
        3: pw.FixedColumnWidth(70),
      },
      cellAlignments: const {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
      },
    );
  }

  static pw.Widget _footer(
      pw.Context context, DateTime generatedAt, String docId) {
    final generated = _formatDate(generatedAt);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.Text('Généré le : $generated', style: const pw.TextStyle(fontSize: 9)),
        pw.Text('Document ID : $docId', style: const pw.TextStyle(fontSize: 9)),
        pw.Text('Page ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9)),
        pw.Text(
          'Ce document est généré automatiquement par UniSpace et n’a pas de valeur administrative officielle.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static pw.Widget _tableCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static String _academicYear(DateTime now) {
    final startYear = now.month >= 9 ? now.year : now.year - 1;
    final endYear = startYear + 1;
    return '$startYear-$endYear';
  }

  static String? _maskEmail(String? email) {
    if (email == null || !email.contains('@')) return null;
    final parts = email.split('@');
    final local = parts.first;
    final domain = parts.last;
    if (local.length <= 2) return '$local@$domain';
    return '${local.substring(0, 2)}***@$domain';
  }

  static String _buildDocumentId(
      DateTime generatedAt,
      SemesterModel semester1,
      SemesterModel semester2,
      ) {
    final ts =
        '${generatedAt.year}${_two(generatedAt.month)}${_two(generatedAt.day)}-${_two(generatedAt.hour)}${_two(generatedAt.minute)}${_two(generatedAt.second)}';
    final hashSeed = [
      semester1.modules.length,
      semester2.modules.length,
      (semester1.semesterAverage() * 100).round(),
      (semester2.semesterAverage() * 100).round(),
    ].join('-');
    final shortHash = hashSeed.codeUnits.fold<int>(0, (a, b) => (a + b) % 99999);
    return 'US-$ts-${shortHash.toRadixString(16).padLeft(4, '0')}';
  }

  static String _formatDate(DateTime date) {
    return '${_two(date.day)}/${_two(date.month)}/${date.year} ${_two(date.hour)}:${_two(date.minute)}';
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}