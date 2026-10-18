import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/chat_view_once_service.dart';

String _text(BuildContext c, String ar, String en, String fr) =>
    switch (Localizations.localeOf(c).languageCode) {
      'ar' => ar,
      'fr' => fr,
      _ => en
    };

class ChatViewOncePage extends StatefulWidget {
  const ChatViewOncePage(
      {super.key,
      required this.chatId,
      required this.messageId,
      this.load,
      this.protect});
  final String chatId, messageId;
  @visibleForTesting
  final Future<Uint8List> Function()? load;
  @visibleForTesting
  final Future<void> Function(bool)? protect;
  @override
  State<ChatViewOncePage> createState() => _ChatViewOncePageState();
}

class _ChatViewOncePageState extends State<ChatViewOncePage>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('unispace/private_media');
  ui.Image? _image;
  bool _error = false, _protected = false, _closed = false;
  StreamSubscription<User?>? _auth;
  String? _uid;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_open());
  }

  Future<void> _protect(bool value) async {
    if (widget.protect != null) {
      await widget.protect!(value);
      return;
    }
    if (!Platform.isAndroid)
      throw UnsupportedError('Protected viewer unavailable');
    await _channel.invokeMethod<void>('setSecure', value);
  }

  Future<void> _open() async {
    try {
      await _protect(true);
      _protected = true;
      if (!mounted || _closed) {
        await _protect(false);
        _protected = false;
        return;
      }
      if (widget.load == null) {
        _uid = FirebaseAuth.instance.currentUser?.uid;
        _auth = FirebaseAuth.instance.authStateChanges().listen((u) {
          if (u?.uid != _uid) _close();
        });
      }
      final bytes = await (widget.load?.call() ??
          ChatViewOnceService.consume(
              chatId: widget.chatId, messageId: widget.messageId));
      if (!mounted || _closed) {
        bytes.fillRange(0, bytes.length, 0);
        return;
      }
      ui.Codec? codec;
      ui.ImmutableBuffer? buffer;
      ui.ImageDescriptor? descriptor;
      try {
        buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
        descriptor = await ui.ImageDescriptor.encoded(buffer);
        final scale =
            math.min(1.0, 2048 / math.max(descriptor.width, descriptor.height));
        codec = await descriptor.instantiateCodec(
            targetWidth: math.max(1, (descriptor.width * scale).round()),
            targetHeight: math.max(1, (descriptor.height * scale).round()));
        final frame = await codec.getNextFrame();
        if (!mounted || _closed) {
          frame.image.dispose();
          return;
        }
        setState(() => _image = frame.image);
      } finally {
        codec?.dispose();
        descriptor?.dispose();
        buffer?.dispose();
        bytes.fillRange(0, bytes.length, 0);
      }
    } catch (_) {
      if (mounted && !_closed) setState(() => _error = true);
    }
  }

  void _close() {
    if (_closed) return;
    _closed = true;
    _image?.dispose();
    _image = null;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _close();
  }

  @override
  void dispose() {
    _closed = true;
    WidgetsBinding.instance.removeObserver(this);
    _auth?.cancel();
    _image?.dispose();
    _image = null;
    if (_protected) unawaited(_protect(false).catchError((Object _) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title:
                Text(_text(c, 'العرض مرة واحدة', 'View once', 'Vue unique'))),
        body: Center(
            child: _error
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                        _text(
                            c,
                            'الصورة غير متاحة أو تم فتحها بالفعل. إذا انقطع الاتصال بعد فتحها، فلا يمكن فتحها مجددًا.',
                            'Photo unavailable or already opened. A connection lost after opening cannot be retried.',
                            'Photo indisponible ou déjà ouverte. Une interruption après ouverture ne permet pas de réessayer.'),
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center))
                : _image == null
                    ? const CircularProgressIndicator()
                    : InteractiveViewer(
                        child: RawImage(image: _image, fit: BoxFit.contain))),
        bottomNavigationBar: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                    _text(
                        c,
                        'بعد إغلاق الصورة لا يمكنك فتحها مجددًا.',
                        'You cannot reopen this photo after closing.',
                        'Vous ne pourrez plus ouvrir cette photo après fermeture.'),
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center))),
      );
}
