import 'brand_launch.dart';
import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../services/release_policy.dart';

class RequiredUpdateGate extends StatefulWidget {
  const RequiredUpdateGate(
      {super.key,
      required this.child,
      this.readPolicy = ReleasePolicy.fetch,
      this.readBuild = ReleasePolicy.installedBuild,
      this.openStore = ReleasePolicy.openStore});
  final Widget child;
  final Future<ReleasePolicy> Function() readPolicy;
  final Future<int> Function() readBuild;
  final Future<bool> Function() openStore;

  @override
  State<RequiredUpdateGate> createState() => _RequiredUpdateGateState();
}

class _RequiredUpdateGateState extends State<RequiredUpdateGate>
    with WidgetsBindingObserver {
  bool _checking = false, _failed = false, _storeFailed = false;
  ReleasePolicy? _policy;
  int? _build;
  bool _configurationFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_check());
  }

  Future<void> _check() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final values = await Future.wait<Object>([
        widget.readPolicy(),
        widget.readBuild(),
      ]).timeout(const Duration(seconds: 10));
      final policy = values[0] as ReleasePolicy;
      final build = values[1] as int;
      if (!mounted) return;
      setState(() {
        _policy = policy;
        _build = build;
        _failed = false;
        _configurationFailed = false;
      });
    } catch (error) {
      final configurationFailed = error is FormatException ||
          (error is FirebaseFunctionsException &&
              const [
                'not-found',
                'permission-denied',
                'unauthenticated',
                'failed-precondition'
              ].contains(error.code));
      debugPrint(
          '[ReleasePolicy] check failed: ${error is FirebaseFunctionsException ? error.code : error.runtimeType}');
      if (mounted)
        setState(() {
          _failed = true;
          _configurationFailed = configurationFailed;
        });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _openStore() async {
    bool opened;
    try {
      opened = await widget.openStore();
    } catch (_) {
      opened = false;
    }
    if (mounted) setState(() => _storeFailed = !opened);
  }

  @override
  Widget build(BuildContext context) {
    if (!_failed &&
        _policy != null &&
        _build != null &&
        _policy!.allows(_build!)) {
      return widget.child;
    }
    final lang = Localizations.localeOf(context).languageCode;
    String text(String en, String ar, String fr) => lang == 'ar'
        ? ar
        : lang == 'fr'
            ? fr
            : en;
    final unknown = _policy == null || _failed;
    if (_checking && unknown) {
      return BrandLoadingScene(
          message: text('Checking for updates…', 'جارٍ التحقق من التحديثات…',
              'Vérification des mises à jour…'));
    }
    return Scaffold(
        body: SafeArea(
            child: Center(
                child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_checking && unknown) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(text('Checking for updates…', 'جارٍ التحقق من التحديثات…',
                'Vérification des mises à jour…')),
          ] else ...[
            Icon(unknown ? Icons.cloud_off : Icons.system_update, size: 48),
            const SizedBox(height: 20),
            Text(
                unknown
                    ? text(
                        'Unable to check for updates',
                        'تعذّر التحقق من التحديثات',
                        'Impossible de vérifier les mises à jour')
                    : text(
                        'Update UniSpace to continue',
                        'حدّث UniSpace للمتابعة',
                        'Mettez UniSpace à jour pour continuer'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
                unknown
                    ? text(
                        _configurationFailed
                            ? 'The update service is not configured correctly. Please try again later.'
                            : 'The update service did not respond. Please try again.',
                        _configurationFailed
                            ? 'خدمة التحديث غير مهيأة بشكل صحيح. أعد المحاولة لاحقًا.'
                            : 'لم تستجب خدمة التحديث. أعد المحاولة.',
                        _configurationFailed
                            ? 'Le service de mise à jour est mal configuré. Réessayez plus tard.'
                            : 'Le service de mise à jour ne répond pas. Réessayez.')
                    : text(
                        'Install the latest version from Google Play.',
                        'ثبّت أحدث إصدار من Google Play.',
                        'Installez la dernière version depuis Google Play.'),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            if (!unknown)
              FilledButton(
                  onPressed: _openStore,
                  child: Text(text('Update', 'تحديث', 'Mettre à jour'))),
            TextButton(
                onPressed: _checking ? null : _check,
                child: Text(text('Retry', 'إعادة المحاولة', 'Réessayer'))),
            if (_storeFailed)
              Text(
                  text(
                      'Could not open Google Play. Please try again.',
                      'تعذّر فتح Google Play. أعد المحاولة.',
                      'Impossible d’ouvrir Google Play. Réessayez.'),
                  textAlign: TextAlign.center),
          ],
        ]),
      ),
    ))));
  }
}
