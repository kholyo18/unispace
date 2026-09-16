import 'dart:async';
import 'package:flutter/material.dart';
import 'legal_consent_models.dart';
import 'legal_consent_service.dart';

// Preview only. Existing builds never instantiate Firebase services for this gate.
// This client flag is NOT server-side authorization or an application-wide consent rule.
const legalConsentPreviewEnabled = bool.fromEnvironment('UNISPACE_LEGAL_CONSENT_PREVIEW', defaultValue: false);

class LegalConsentGate extends StatefulWidget {
  const LegalConsentGate({super.key, required this.child, this.client,
    this.timeout = const Duration(seconds: 20)});
  final Widget child;
  final LegalConsentClient? client;
  final Duration timeout;
  @override
  State<LegalConsentGate> createState() => _LegalConsentGateState();
}

class _LegalConsentGateState extends State<LegalConsentGate> with WidgetsBindingObserver {
  late LegalConsentClient _client;
  StreamSubscription<String?>? _subscription;
  String? _uid;
  LegalConsentStatus? _status;
  String? _documentId;
  String? _error;
  bool _loading = true;
  bool _busy = false;
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

  void _connect() {
    _client = widget.client ?? FirebaseLegalConsentClient();
    _uid = _client.currentUserId;
    _subscription = _client.userChanges.listen((uid) {
      if (_uid == uid) return;
      _uid = uid;
      unawaited(_load());
    }, onError: (Object error) {
      if (!mounted) return;
      _generation++;
      setState(() {
        _status = null; _documentId = null; _loading = false; _busy = false;
        _terms = _community = _privacy = false;
        _error = 'تعذر التحقق من الحساب. أعد المحاولة أو سجّل الخروج.';
      });
    });
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant LegalConsentGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.client != widget.client) {
      _generation++;
      unawaited(_subscription?.cancel());
      _connect();
    }
  }

  bool _current(int generation, String uid) => mounted && generation == _generation &&
      _uid == uid && _client.currentUserId == uid;

  Future<void> _load() async {
    if (!mounted) return;
    final generation = ++_generation;
    final uid = _client.currentUserId;
    _uid = uid;
    setState(() {
      _status = null; _documentId = null; _error = null; _loading = uid != null; _busy = false;
      _terms = _community = _privacy = false;
    });
    if (uid == null) return;
    try {
      final status = await _client.readStatus(uid).timeout(widget.timeout);
      if (!_current(generation, uid)) return;
      if (status.uid != uid) throw const LegalConsentReloadRequired();
      setState(() { _status = status; _loading = false; });
    } catch (_) {
      if (!_current(generation, uid)) return;
      setState(() {
        _loading = false;
        _error = 'تعذر تحميل مستندات الموافقة. تحقق من الاتصال ثم أعد المحاولة.';
      });
    }
  }

  Future<void> _accept() async {
    final status = _status;
    if (_busy || !_terms || !_community || !_privacy || status == null || !status.required ||
        status.uid != _client.currentUserId) return;
    final generation = _generation;
    setState(() { _busy = true; _error = null; });
    try {
      await _client.accept(status).timeout(widget.timeout);
      if (_current(generation, status.uid)) await _load(); // Re-read; a success response alone never opens the app.
    } on LegalConsentReloadRequired {
      if (_current(generation, status.uid)) await _load();
    } catch (_) {
      if (!_current(generation, status.uid)) return;
      setState(() {
        _busy = false;
        _error = 'تعذر تأكيد حفظ الموافقة. أعد المحاولة؛ لن تُسجَّل موافقة مكررة على النسخة نفسها.';
      });
    }
  }

  Future<void> _signOut() async {
    if (_busy) return;
    final generation = ++_generation;
    setState(() {
      _busy = true; _error = null; _status = null; _documentId = null; _loading = false;
      _terms = _community = _privacy = false;
    });
    try {
      await _client.signOut().timeout(widget.timeout);
      if (mounted && generation == _generation) await _load();
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() { _busy = false; _error = 'تعذر تسجيل الخروج. حاول مجددًا.'; });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(_load());
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _generation++;
      setState(() {
        _status = null; _documentId = null; _loading = true; _busy = false;
        _terms = _community = _privacy = false;
      });
    }
  }

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status?.uid == _client.currentUserId ? _status : null;
    if (!_loading && !_busy && status != null && status.uid == _client.currentUserId && !status.required) {
      return widget.child;
    }
    final policy = status?.policy;
    LegalDocument? document;
    if (policy != null) {
      for (final candidate in policy.documents) {
        if (candidate.id == _documentId) document = candidate;
      }
    }
    return Directionality(textDirection: TextDirection.rtl, child: PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false,
          title: Text(document?.title ?? 'الشروط والخصوصية'),
          leading: document == null ? null : IconButton(
            key: const ValueKey('legal-document-back'), tooltip: 'العودة إلى الموافقة',
            onPressed: () => setState(() => _documentId = null), icon: const Icon(Icons.arrow_back)),
        ),
        body: SafeArea(child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: document != null && policy != null ? _DocumentReader(key: ValueKey('${policy.fingerprint}:${document.id}'),
            document: document, operatorName: policy.operatorName) : SingleChildScrollView(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (_loading) ...[
                const Center(child: CircularProgressIndicator()), const SizedBox(height: 20),
                const Text('جارٍ التحقق من مستندات الموافقة...', textAlign: TextAlign.center),
              ] else if (_uid == null) ...[
                const Text('يلزم تسجيل الدخول لمراجعة الموافقة الخاصة بحسابك.', textAlign: TextAlign.center),
              ] else if (policy != null) ...[
                Text('راجع المستندات قبل المتابعة', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text('الجهة المشغلة: ${policy.operatorName}'),
                Text('تاريخ النشر: ${policy.publishedAt.toIso8601String().split('T').first}'),
                const SizedBox(height: 12),
                const Text('فتح المستند لا يُعد موافقة. اختر كل بند بنفسك بعد مراجعة محتواه.'),
                const SizedBox(height: 12),
                for (final doc in policy.documents) Card(child: ListTile(
                  title: Text(doc.title), subtitle: Text('الإصدار: ${doc.version}'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: _busy ? null : () => setState(() => _documentId = doc.id),
                  key: ValueKey('legal-open-${doc.id}'),
                )),
                const SizedBox(height: 12),
                CheckboxListTile(key: const ValueKey('legal-terms'), contentPadding: EdgeInsets.zero,
                  value: _terms, title: const Text('أوافق على شروط الاستخدام.'),
                  onChanged: _busy ? null : (value) => setState(() => _terms = value ?? false)),
                CheckboxListTile(key: const ValueKey('legal-community'), contentPadding: EdgeInsets.zero,
                  value: _community, title: const Text('أوافق على قواعد المجتمع.'),
                  onChanged: _busy ? null : (value) => setState(() => _community = value ?? false)),
                CheckboxListTile(key: const ValueKey('legal-privacy'), contentPadding: EdgeInsets.zero,
                  value: _privacy, title: const Text('أقرّ بأنني اطّلعت على إشعار الخصوصية.'),
                  onChanged: _busy ? null : (value) => setState(() => _privacy = value ?? false)),
                const SizedBox(height: 12),
                const Text('هذه الخطوة لا تطلب موافقة لتدريب نماذج الذكاء الاصطناعي أو للتسويق.'),
                const SizedBox(height: 20),
                FilledButton(key: const ValueKey('legal-accept'),
                  onPressed: _busy || !_terms || !_community || !_privacy ? null : _accept,
                  child: Text(_busy ? 'جارٍ حفظ الموافقة...' : 'أوافق وأتابع')),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Semantics(liveRegion: true, child: Text(_error!, textAlign: TextAlign.center)),
                TextButton(key: const ValueKey('legal-retry'), onPressed: _busy ? null : _load,
                  child: const Text('إعادة المحاولة')),
              ],
              if (_uid != null) ...[
                const SizedBox(height: 12),
                TextButton(key: const ValueKey('legal-signout'), onPressed: _busy ? null : _signOut,
                  child: const Text('عدم الموافقة وتسجيل الخروج')),
              ],
            ]),
          ),
        ))),
      ),
    ));
  }
}

class _DocumentReader extends StatefulWidget {
  const _DocumentReader({super.key, required this.document, required this.operatorName});
  final LegalDocument document;
  final String operatorName;
  @override
  State<_DocumentReader> createState() => _DocumentReaderState();
}

class _DocumentReaderState extends State<_DocumentReader> {
  final ScrollController _scroll = ScrollController();
  @override
  void dispose() { _scroll.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ScrollConfiguration(
    behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
    child: Scrollbar(controller: _scroll, child: SingleChildScrollView(
      controller: _scroll, padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Semantics(header: true, child: Text(widget.document.title, style: Theme.of(context).textTheme.headlineSmall)),
        const SizedBox(height: 12),
        Text('الإصدار: ${widget.document.version}'), Text('الجهة المشغلة: ${widget.operatorName}'),
        const SizedBox(height: 24), SelectableText(widget.document.body, style: const TextStyle(height: 1.7)),
      ]),
    )),
  );
}
