import 'package:flutter/material.dart';
import '../../features/legal/legal_consent_gate.dart';

/// Failure to read a security requirement must never grant access.
class AuthSecurityCheck extends StatefulWidget {
  const AuthSecurityCheck({super.key, required this.check, required this.challengeBuilder,
    required this.child, this.timeout = const Duration(seconds: 10)});
  final Future<bool> Function() check;
  final WidgetBuilder challengeBuilder;
  final Widget child;
  final Duration timeout;
  @override
  State<AuthSecurityCheck> createState() => _AuthSecurityCheckState();
}

class _AuthSecurityCheckState extends State<AuthSecurityCheck> {
  late Future<bool> _result;
  @override
  void initState() { super.initState(); _result = _check(); }
  Future<bool> _check() => Future<bool>.sync(widget.check).timeout(widget.timeout);
  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _result,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError || !snapshot.hasData) {
        return Scaffold(body: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.shield_outlined, size: 40),
            const SizedBox(height: 16),
            const Text('تعذر التحقق من متطلبات الأمان. تحقق من الاتصال ثم حاول مجددًا.', textAlign: TextAlign.center),
            TextButton(onPressed: () => setState(() { _result = _check(); }), child: const Text('إعادة المحاولة')),
          ]),
        )));
      }
      if (snapshot.data!) return widget.challengeBuilder(context);
      return legalConsentPreviewEnabled
          ? LegalConsentGate(child: widget.child)
          : widget.child;
    },
  );
}
