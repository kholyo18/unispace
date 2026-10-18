import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:url_launcher/url_launcher.dart';
import '../../../services/chat_location_point.dart';
export '../../../services/chat_location_point.dart';

/// Narrow platform seam: tests exercise permission and confirmation behavior
/// without requesting real device permissions or coordinates.
abstract class ChatLocationProvider {
  Future<bool> servicesEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<ChatLocationPoint> currentPosition();
  Future<bool> openAppSettings();
  Future<bool> openLocationSettings();
}

class DeviceChatLocationProvider implements ChatLocationProvider {
  @override
  Future<bool> servicesEnabled() => Geolocator.isLocationServiceEnabled();
  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();
  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();
  @override
  Future<ChatLocationPoint> currentPosition() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return ChatLocationPoint(position.latitude, position.longitude,
        accuracy: position.accuracy);
  }

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();
  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}

/// Returns a Maps link only after the user explicitly confirms the preview.
/// The caller must recheck the active account/conversation before sending it.
Future<String?> showChatLocationSheet(
  BuildContext context, {
  ChatLocationProvider? provider,
  Future<bool> Function(Uri)? openMap,
}) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ChatLocationSheet(
          provider: provider ?? DeviceChatLocationProvider(), openMap: openMap),
    );

class ChatLocationSheet extends StatefulWidget {
  const ChatLocationSheet({super.key, required this.provider, this.openMap});
  final Future<bool> Function(Uri)? openMap;
  final ChatLocationProvider provider;
  @override
  State<ChatLocationSheet> createState() => _ChatLocationSheetState();
}

class _ChatLocationSheetState extends State<ChatLocationSheet>
    with WidgetsBindingObserver {
  bool _waitingSettings = false,
      _settingsAway = false,
      _refreshAfterSettings = false;
  bool _openingMap = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_waitingSettings) return;
    if (state != AppLifecycleState.resumed) {
      _settingsAway = true;
    } else if (_settingsAway) {
      _waitingSettings = false;
      if (_busy) {
        _refreshAfterSettings = true;
      } else {
        unawaited(_locate());
      }
    }
  }

  Future<void> _openMap() async {
    if (_point == null || _openingMap) return;
    setState(() => _openingMap = true);
    try {
      final uri = Uri.parse(_point!.mapsLink);
      final opened = await (widget.openMap?.call(uri) ??
          launchUrl(uri, mode: LaunchMode.externalApplication));
      if (!opened && mounted) setState(() => _error = 'mapFailed');
    } catch (_) {
      if (mounted) setState(() => _error = 'mapFailed');
    } finally {
      if (mounted) setState(() => _openingMap = false);
    }
  }

  bool _busy = false;
  ChatLocationPoint? _point;
  String? _error;
  bool _appSettings = false;
  bool _locationSettings = false;

  Future<void> _locate() async {
    if (_busy) return;
    _waitingSettings = false;
    _refreshAfterSettings = false;
    setState(() {
      _busy = true;
      _point = null;
      _error = null;
      _appSettings = false;
      _locationSettings = false;
    });
    try {
      final enabled = await widget.provider.servicesEnabled();
      if (!mounted) return;
      if (!enabled) {
        setState(() {
          _error = 'off';
          _locationSettings = true;
        });
        return;
      }
      var permission = await widget.provider.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        permission = await widget.provider.requestPermission();
        if (!mounted) return;
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        setState(() {
          _appSettings = permission == LocationPermission.deniedForever;
          _error = _appSettings ? 'forever' : 'denied';
        });
        return;
      }
      final point = await widget.provider
          .currentPosition()
          .timeout(const Duration(seconds: 22));
      if (!mounted) return;
      if (!point.isValid) throw StateError('Invalid coordinates');
      setState(() => _point = point);
    } on TimeoutException {
      if (mounted) setState(() => _error = 'timeout');
    } on LocationServiceDisabledException {
      if (mounted)
        setState(() {
          _error = 'off';
          _locationSettings = true;
        });
    } on PermissionDeniedException {
      if (mounted)
        setState(() {
          _error = 'denied';
          _appSettings = true;
        });
    } catch (_) {
      if (mounted) setState(() => _error = 'failed');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _settings() async {
    if (_busy) return;
    setState(() => _busy = true);
    _waitingSettings = true;
    _settingsAway = false;
    try {
      final opened = await (_appSettings
          ? widget.provider.openAppSettings()
          : widget.provider.openLocationSettings());
      if (!opened) {
        _waitingSettings = false;
        if (mounted) setState(() => _error = 'settingsFailed');
      }
    } catch (_) {
      _waitingSettings = false;
      if (mounted) setState(() => _error = 'settingsFailed');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        if (_refreshAfterSettings) {
          _refreshAfterSettings = false;
          unawaited(_locate());
        }
      }
    }
  }

  String _text(String key) {
    final language = Localizations.localeOf(context).languageCode;
    return _strings[key]![language == 'ar'
        ? 0
        : language == 'fr'
            ? 1
            : 2];
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _text('title'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: _text('close'),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(_text('explain')),
            const SizedBox(height: 16),
            if (_busy) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
              Text(_text('loading'), textAlign: TextAlign.center),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _text(_error!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_point != null) ...[
              const Icon(Icons.location_on_outlined, size: 36),
              Text(_text('preview'), textAlign: TextAlign.center),
              if (_point!.hasAccuracy)
                Text(
                    _text('accuracy').replaceAll(
                        '{meters}', _point!.accuracy!.ceil().toString()),
                    textAlign: TextAlign.center),
              SelectableText(
                _point!.coordinates,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
              ),
              TextButton.icon(
                key: const ValueKey('previewLocation'),
                onPressed: _busy || _openingMap ? null : _openMap,
                icon: const Icon(Icons.open_in_new),
                label: Text(_text('openMap')),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const ValueKey('confirmLocation'),
                onPressed: _busy
                    ? null
                    : () => Navigator.pop(context, _point!.mapsLink),
                icon: const Icon(Icons.send),
                label: Text(_text('send')),
              ),
            ],
            if (_appSettings || _locationSettings)
              TextButton(
                onPressed: _busy ? null : _settings,
                child: Text(_text('settings')),
              ),
            OutlinedButton.icon(
              key: const ValueKey('locate'),
              onPressed: _busy ? null : _locate,
              icon: const Icon(Icons.my_location),
              label: Text(
                _text(
                  _point != null
                      ? 'refresh'
                      : _error == null
                          ? 'locate'
                          : 'retry',
                ),
              ),
            ),
          ],
        ),
      );

  static const _strings = <String, List<String>>{
    'title': ['مشاركة الموقع', 'Partager la position', 'Share location'],
    'accuracy': [
      'دقة تقديرية: ضمن {meters} متر',
      'Précision estimée : rayon de {meters} m',
      'Estimated accuracy: within {meters} m'
    ],
    'openMap': ['معاينة في الخرائط', 'Aperçu sur la carte', 'Preview in Maps'],
    'mapFailed': [
      'تعذر فتح الخريطة. أعد المحاولة.',
      'Impossible d’ouvrir la carte. Réessayez.',
      'Could not open the map. Try again.'
    ],
    'close': ['إغلاق', 'Fermer', 'Close'],
    'explain': [
      'سنحدد موقعك الحالي بعد موافقتك. راجع الإحداثيات ثم اضغط إرسال لمشاركة رابط الخريطة. لا تتم مشاركة موقعك مباشرة أو في الخلفية.',
      'Autorisez la localisation, puis vérifiez les coordonnées avant d’envoyer le lien de la carte. Aucun suivi en direct ou en arrière-plan.',
      'Allow location access, then review the coordinates before sending the map link. Your location is not tracked live or in the background.',
    ],
    'loading': [
      'جارٍ تحديد الموقع…',
      'Localisation en cours…',
      'Getting location…',
    ],
    'preview': [
      'الإحداثيات التي ستتم مشاركتها',
      'Coordonnées à partager',
      'Coordinates to share',
    ],
    'send': ['إرسال الموقع', 'Envoyer la position', 'Send location'],
    'locate': ['تحديد موقعي الحالي', 'Obtenir ma position', 'Get my location'],
    'refresh': ['تحديث الموقع', 'Actualiser la position', 'Refresh location'],
    'retry': ['إعادة المحاولة', 'Réessayer', 'Try again'],
    'settings': ['فتح الإعدادات', 'Ouvrir les paramètres', 'Open settings'],
    'off': [
      'خدمة الموقع معطلة. فعّلها من الإعدادات ثم أعد المحاولة.',
      'La localisation est désactivée. Activez-la dans les paramètres, puis réessayez.',
      'Location services are off. Enable them in settings, then try again.',
    ],
    'denied': [
      'لم يُسمح بالوصول إلى الموقع. يمكنك إعادة المحاولة أو إغلاق النافذة.',
      'L’accès à la position a été refusé. Réessayez ou fermez cette fenêtre.',
      'Location permission was denied. You can retry or close this sheet.',
    ],
    'forever': [
      'السماح بالموقع معطل لهذا التطبيق. فعّله من إعدادات التطبيق ثم أعد المحاولة.',
      'L’accès est bloqué pour cette application. Autorisez-le dans les paramètres, puis réessayez.',
      'Location access is blocked for this app. Allow it in app settings, then try again.',
    ],
    'timeout': [
      'استغرق تحديد الموقع وقتًا طويلًا. انتقل إلى مكان بإشارة أفضل ثم أعد المحاولة.',
      'La localisation a pris trop de temps. Déplacez-vous vers un endroit avec un meilleur signal, puis réessayez.',
      'Finding your location timed out. Move somewhere with a better signal, then try again.',
    ],
    'failed': [
      'تعذر تحديد الموقع. أعد المحاولة.',
      'Impossible d’obtenir la position. Réessayez.',
      'Could not get your location. Try again.',
    ],
    'settingsFailed': [
      'تعذر فتح الإعدادات. افتح إعدادات الموقع من الهاتف ثم أعد المحاولة.',
      'Impossible d’ouvrir les paramètres. Ouvrez les paramètres de localisation sur votre téléphone, puis réessayez.',
      'Could not open settings. Open your phone’s location settings, then try again.',
    ],
  };
}
