import 'dart:async';
import 'package:flutter/material.dart';
import 'firebase_legal_eligibility_client.dart';
import 'legal_consent_models.dart';
import 'legal_eligibility_client.dart';
import 'legal_eligibility_models.dart';

/// Development preview only; never use a build flag as server authorization.
const legalEligibilityPreviewEnabled = bool.fromEnvironment(
  'UNISPACE_LEGAL_ELIGIBILITY_PREVIEW', defaultValue: false,
);

class LegalEligibilityGate extends StatefulWidget {
  const LegalEligibilityGate({super.key, required this.child, this.client,
    this.timeout = const Duration(seconds: 20)});
  final Widget child;
  final LegalEligibilityClient? client;
  final Duration timeout;
  @override
  State<LegalEligibilityGate> createState() => _LegalEligibilityGateState();
}

class _LegalEligibilityGateState extends State<LegalEligibilityGate>
    with WidgetsBindingObserver {
  late LegalEligibilityClient _client;
  StreamSubscription<String?>? _subscription;
  final _day = TextEditingController();
  final _month = TextEditingController();
  final _year = TextEditingController();
  final _scroll = ScrollController(keepScrollOffset: false);
  LegalEligibilityStatus? _status;
  String? _uid;
  LegalDocument? _document;
  String? _error;
  bool _loading = true;
  bool _busy = false;
  bool _suspended = false;
  bool _disposed = false;
  bool _accurate = false;
  bool _terms = false;
  bool _community = false;
  bool _privacy = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _connect();
  }

  void _clear() {
    _status = null;
    _document = null;
    _error = null;
    _accurate = _terms = _community = _privacy = false;
    _day.clear(); _month.clear(); _year.clear();
  }

  void _connect() {
    final client = widget.client ?? FirebaseLegalEligibilityClient();
    _client = client;
    _uid = client.currentUserId;
    _subscription = client.userChanges.listen((uid) {
      if (_disposed || !identical(client, _client) || uid == _uid) return;
      _uid = uid;
      unawaited(_load());
    }, onError: (Object error) {
      if (_disposed || !identical(client, _client)) return;
      ++_generation;
      setState(() {
        _clear(); _loading = _busy = false;
        _error = 'تعذر التحقق من الحساب. أعد المحاولة أو سجّل الخروج.';
      });
    });
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant LegalEligibilityGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.client != widget.client) {
      ++_generation;
      unawaited(_subscription?.cancel());
      _connect();
    }
  }

  bool _current(int generation, String uid) => !_disposed && mounted &&
      !_suspended && generation == _generation && uid == _uid &&
      uid == _client.currentUserId;

  Future<void> _load() async {
    if (_disposed) return;
    final generation = ++_generation;
    final uid = _client.currentUserId;
    _uid = uid;
    setState(() { _clear(); _busy = false; _loading = uid != null; });
    if (_suspended || uid == null) return;
    try {
      final status = await _client.readStatus(uid).timeout(widget.timeout);
      if (!_current(generation, uid)) return;
      if (status.uid != uid) throw const LegalEligibilityReloadRequired();
      setState(() { _status = status; _loading = false; });
    } catch (_) {
      if (!_current(generation, uid)) return;
      setState(() {
        _loading = false;
        _error = 'تعذر تحميل حالة الأهلية. تحقق من الاتصال ثم أعد المحاولة.';
      });
    }
  }

  Future<void> _write(Future<void> Function() action, {bool birthDate = false}) async {
    final status = _status;
    if (_busy || _loading || _suspended || status == null ||
        status.uid != _client.currentUserId) return;
    final generation = _generation;
    setState(() { _busy = true; _error = null; });
    try {
      await action().timeout(widget.timeout);
      if (_current(generation, status.uid)) await _load();
    } on LegalBirthDateRejected {
      if (!_current(generation, status.uid)) return;
      setState(() {
        _busy = false; _accurate = false;
        _error = 'لم يقبل الخادم هذا التاريخ. تحقق من صحته وأنه ليس في المستقبل.';
      });
    } catch (error) {
      if (!_current(generation, status.uid)) return;
      // A timed-out write may have committed. Do not grant access or let a user
      // edit/resubmit a different birth date until a fresh status read succeeds.
      setState(() {
        _clear(); _busy = _loading = false;
        _error = error is LegalEligibilityReloadRequired
            ? 'تغيرت الحالة أو الوثائق، أو يتطلب التاريخ مراجعة. أعد التحقق؛ وللتصحيح تواصل مع الدعم.'
            : birthDate
                ? 'تعذر تأكيد حفظ التاريخ. أعد التحقق من الحالة قبل المحاولة مجددًا.'
                : 'تعذر تأكيد الموافقة. أعد التحقق؛ لا يُفتح الحساب بناءً على محاولة حفظ فقط.';
      });
    }
  }

  Future<void> _declare() async {
    final status = _status;
    if (status?.step != LegalEligibilityStep.birthDateRequired || !_accurate || _busy) return;
    final date = legalBirthDateFromFields(year: _year.text, month: _month.text, day: _day.text);
    if (date == null) {
      setState(() => _error = 'أدخل تاريخًا ميلاديًا صحيحًا: يوم، شهر، وسنة من أربعة أرقام.');
      return;
    }
    FocusScope.of(context).unfocus();
    await _write(() => _client.declareBirthDate(status!, date, accuracyConfirmed: true), birthDate: true);
  }

  Future<void> _accept() async {
    final status = _status;
    if (status == null || !status.needsPersonalAcceptance || !_terms || !_community || !_privacy || _busy) return;
    await _write(() => _client.accept(status, termsAccepted: true,
      communityAccepted: true, privacyAcknowledged: true));
  }

  Future<void> _signOut() async {
    if (_busy) return;
    final generation = ++_generation;
    setState(() { _clear(); _busy = true; _loading = false; });
    try {
      await _client.signOut().timeout(widget.timeout);
      if (!_disposed && generation == _generation) {
        if (_client.currentUserId != null) throw const LegalEligibilityReloadRequired();
        await _load();
      }
    } catch (_) {
      if (_disposed || generation != _generation) return;
      setState(() { _busy = false; _error = 'تعذر تسجيل الخروج. حاول مجددًا.'; });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;
    if (state == AppLifecycleState.resumed) {
      _suspended = false;
      unawaited(_load());
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _suspended = true;
      ++_generation;
      setState(() { _clear(); _busy = false; _loading = true; });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    _day.dispose(); _month.dispose(); _year.dispose(); _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status?.uid == _client.currentUserId ? _status : null;
    if (!_loading && !_busy && !_suspended && status?.canProceed == true) return widget.child;
    final policy = status?.policy;
    final document = policy == null ? null : _document;
    return Directionality(textDirection: TextDirection.rtl, child: PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false,
          title: Text(document?.title ?? 'الأهلية وشروط الاستخدام'),
          leading: document == null ? null : IconButton(
            key: const ValueKey('eligibility-document-back'), tooltip: 'العودة',
            onPressed: () => setState(() => _document = null), icon: const Icon(Icons.arrow_back)),
        ),
        body: SafeArea(child: Align(alignment: Alignment.topCenter, child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: Scrollbar(controller: _scroll, child: SingleChildScrollView(
              key: ValueKey('eligibility-page:$_generation:${document?.id ?? 'state'}'),
              controller: _scroll, primary: false,
              padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 32),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('معاينة تقنية — غير مفعّلة للمستخدمين', textAlign: TextAlign.center),
                const SizedBox(height: 20),
                if (document != null) ...[
                  Text(document.title, style: Theme.of(context).textTheme.headlineSmall),
                  Text('الإصدار: ${document.version}'),
                  const SizedBox(height: 16),
                  SelectableText(document.body, style: const TextStyle(height: 1.7)),
                ] else ...[
                  if (_loading) const Center(child: CircularProgressIndicator())
                  else if (_uid == null) const Text('يلزم تسجيل الدخول للمتابعة. لا توجد موافقة محفوظة بهذه الشاشة.')
                  else if (status != null) ...[
                    ..._stepContent(status),
                    if (policy != null) ...[
                      const SizedBox(height: 20),
                      Text('الجهة المشغلة: ${policy.operatorName}'),
                      Text('تاريخ النشر: ${policy.publishedAt.toIso8601String().split('T').first}'),
                      for (final doc in policy.documents) Card(child: ListTile(
                        key: ValueKey('eligibility-open-${doc.id}'),
                        title: Text(doc.title), subtitle: Text('الإصدار: ${doc.version}'),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: _busy ? null : () => setState(() => _document = doc),
                      )),
                    ],
                    if (status.step == LegalEligibilityStep.birthDateRequired) ..._birthFields(),
                    if (status.needsPersonalAcceptance) ..._consentFields(),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Semantics(liveRegion: true, child: Text(_error!, key: const ValueKey('eligibility-error'))),
                  ],
                  if (!_loading && _uid != null) TextButton(
                    key: const ValueKey('eligibility-refresh'), onPressed: _busy ? null : _load,
                    child: const Text('إعادة التحقق من الحالة')),
                  if (_uid != null) TextButton(
                    key: const ValueKey('eligibility-signout'), onPressed: _busy ? null : _signOut,
                    child: const Text('عدم المتابعة وتسجيل الخروج')),
                ],
                const SizedBox(height: 20),
                const Text('للدعم أو تصحيح تاريخ سبق حفظه أو طلب حقوقك وحذف الحساب دون الموافقة، راسل البريد التالي. لا ترسل كلمات مرور أو رموز دخول أو وثائق هوية كاملة.'),
                const SizedBox(height: 8),
                const SelectableText('unispace.0.1.0@gmail.com', textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center, key: ValueKey('eligibility-support')),
              ]),
            )),
          ),
        ))),
      ),
    ));
  }

  List<Widget> _stepContent(LegalEligibilityStatus status) {
    String title;
    String message;
    switch (status.step) {
      case LegalEligibilityStep.notConfigured:
        title = 'المسار غير جاهز بعد';
        message = 'لم يفعّل الخادم وثائق الأهلية. لا يمكن تجاوز هذه الخطوة أو احتسابها موافقة.';
        break;
      case LegalEligibilityStep.birthDateRequired:
        title = 'تأكيد تاريخ الميلاد';
        message = 'نحتاج التاريخ لتحديد مسار الأهلية. راجع الوثائق أدناه قبل إرساله. هذا إقرار ذاتي وليس تحققًا من الهوية.';
        break;
      case LegalEligibilityStep.underMinimumAge:
        title = 'الحد الأدنى للاستخدام 18 سنة';
        message = 'التاريخ المسجل لا يستوفي الحد الأدنى الحالي. لا يمكن المتابعة بهذا المسار. لتصحيح خطأ في التاريخ، تواصل مع الدعم للمراجعة.';
        break;
      case LegalEligibilityStep.personalConsentRequired:
        title = 'موافقتك الشخصية مطلوبة';
        message = 'بحسب التاريخ المسجل، يشمل مسارك موافقتك وموافقة ممثلك القانوني بعد التحقق منها. موافقتك وحدها لا تفتح التطبيق.';
        break;
      case LegalEligibilityStep.independentConsentRequired:
        title = 'موافقة شخصية مستقلة';
        message = 'يتطلب مسارك الحالي قبولك الشخصي للوثائق. وقد يُطلب قبول جديد عند بلوغ 19 سنة أو تغيير الوثائق. لا نعيد استخدام موافقة ممثل بدل موافقتك.';
        break;
      case LegalEligibilityStep.representativeRequired:
        title = 'موافقة الممثل لم تُستوفَ بعد';
        message = 'سُجّلت موافقتك الشخصية، لكن الخادم لم يؤكد موافقة ممثل سارية ومراجعة على هذه الوثائق. هذه الشاشة لا ترسل دعوة ولا تتحقق من صفة الممثل. تواصل مع الدعم لمعرفة حالة المراجعة.';
        break;
      case LegalEligibilityStep.ready:
        title = 'جارٍ التحقق';
        message = 'لا يتم الدخول إلا بعد تأكيد الحالة من الخادم.';
        break;
    }
    return [Semantics(header: true, child: Text(title,
      key: ValueKey('eligibility-step-${status.step.name}'),
      style: Theme.of(context).textTheme.headlineSmall)),
      const SizedBox(height: 12), Text(message, style: const TextStyle(height: 1.6))];
  }

  List<Widget> _birthFields() => [
    const SizedBox(height: 20),
    Wrap(spacing: 12, runSpacing: 12, children: [
      _dateField('اليوم', 'day', _day, 2, 110),
      _dateField('الشهر', 'month', _month, 2, 110),
      _dateField('السنة', 'year', _year, 4, 150),
    ]),
    const Text('راجع التاريخ قبل التأكيد. تصحيح تاريخ محفوظ يحتاج مراجعة؛ لا يُستبدل تلقائيًا من الملف الشخصي.'),
    CheckboxListTile(key: const ValueKey('eligibility-accuracy'), contentPadding: EdgeInsets.zero,
      value: _accurate, title: const Text('أؤكد أن هذا هو تاريخ ميلادي الصحيح.'),
      onChanged: _busy ? null : (value) => setState(() => _accurate = value ?? false)),
    FilledButton(key: const ValueKey('eligibility-save-date'),
      onPressed: _busy || !_accurate ? null : _declare,
      child: Text(_busy ? 'جارٍ التحقق...' : 'تأكيد التاريخ والمتابعة')),
  ];

  Widget _dateField(String label, String id, TextEditingController controller, int length, double width) =>
      SizedBox(width: width, child: TextField(
        key: ValueKey('eligibility-$id'), controller: controller,
        enabled: !_busy, keyboardType: TextInputType.number, textDirection: TextDirection.ltr,
        maxLength: length, autocorrect: false, enableSuggestions: false,
        decoration: InputDecoration(labelText: label, counterText: '', border: const OutlineInputBorder()),
        onChanged: (_) => setState(() { _accurate = false; _error = null; }),
      ));

  List<Widget> _consentFields() => [
    const SizedBox(height: 16),
    const Text('فتح الوثيقة لا يُسجّل موافقة. اختر كل بند بنفسك بعد الاطلاع عليه.'),
    CheckboxListTile(key: const ValueKey('eligibility-terms'), contentPadding: EdgeInsets.zero,
      value: _terms, title: const Text('أوافق على شروط استخدام UniSpace.'),
      onChanged: _busy ? null : (value) => setState(() => _terms = value ?? false)),
    CheckboxListTile(key: const ValueKey('eligibility-community'), contentPadding: EdgeInsets.zero,
      value: _community, title: const Text('أوافق على قواعد المجتمع.'),
      onChanged: _busy ? null : (value) => setState(() => _community = value ?? false)),
    CheckboxListTile(key: const ValueKey('eligibility-privacy'), contentPadding: EdgeInsets.zero,
      value: _privacy, title: const Text('اطلعت على سياسة الخصوصية والبيانات اللازمة للخدمة وحقوقي.'),
      onChanged: _busy ? null : (value) => setState(() => _privacy = value ?? false)),
    const Text('هذا الإقرار لا يمنح إذنًا لتدريب الذكاء الاصطناعي أو للتسويق أو لأي اشتراك مدفوع.'),
    const SizedBox(height: 16),
    FilledButton(key: const ValueKey('eligibility-accept'),
      onPressed: _busy || !_terms || !_community || !_privacy ? null : _accept,
      child: Text(_busy ? 'جارٍ تأكيد الموافقة...' : 'تسجيل موافقتي والمتابعة')),
  ];
}
