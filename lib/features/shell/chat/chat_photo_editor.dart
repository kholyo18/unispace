import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'photo_edit_model.dart';
export 'photo_edit_model.dart' show prepareChatPhoto;

class ChatPhotoEditorPage extends StatefulWidget {
  const ChatPhotoEditorPage({super.key, required this.file, this.hd = true});
  final File file;
  final bool hd;
  @override
  State<ChatPhotoEditorPage> createState() => _ChatPhotoEditorPageState();
}

class _ChatPhotoEditorPageState extends State<ChatPhotoEditorPage> {
  late final PhotoHistory _history;
  ui.Image? _image;
  String? _loadedPath;
  PhotoEdit? _draft;
  final Set<String> _ownedFiles = {};
  String? _returnedPath;
  bool _disposed = false;

  File _own(File file) {
    if (file.path == widget.file.path) return file;
    _ownedFiles.add(file.path);
    if (_disposed) unawaited(_removeOwned(file.path));
    return file;
  }

  Future<void> _removeOwned(String path) async {
    if (path == widget.file.path || path == _returnedPath) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
      _ownedFiles.remove(path);
    } on FileSystemException {
      // A failed deletion remains owned and can be retried at page disposal.
    }
  }

  bool _busy = true, _gif = false, _draw = false;
  Color _color = Colors.white;
  double _width = 0.012, _textSize = 0.075;
  int? _selected;
  int _generation = 0;
  String? _error;
  PhotoEdit get _edit => _draft ?? _history.current;
  String t(String ar, String en, String fr) {
    final code = Localizations.localeOf(context).languageCode;
    return code == 'ar'
        ? ar
        : code == 'fr'
            ? fr
            : en;
  }

  @override
  void initState() {
    super.initState();
    _history = PhotoHistory(PhotoEdit(path: widget.file.path));
    _load();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _image?.dispose();
    for (final path in _ownedFiles.toList()) {
      unawaited(_removeOwned(path));
    }
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = File(_history.current.path);
      final stream = await file.open();
      late List<int> header;
      try {
        header = await stream.read(6);
      } finally {
        await stream.close();
      }
      final gif = header.length == 6 &&
          header[0] == 71 &&
          header[1] == 73 &&
          header[2] == 70;
      final image = await decodePhoto(file, maxEdge: widget.hd ? 2560 : 1600);
      if (!mounted || generation != _generation) {
        image.dispose();
        return;
      }
      _image?.dispose();
      setState(() {
        _image = image;
        _loadedPath = file.path;
        _gif = gif;
        _busy = false;
      });
    } catch (e) {
      if (mounted && generation == _generation)
        setState(() {
          _error = e is PhotoSourceTooLarge
              ? t(
                  'حجم الصورة يتجاوز 80 ميغابايت.',
                  'Image exceeds 80 MiB.',
                  'L’image dépasse 80 Mio.',
                )
              : t(
                  'تعذر فتح الصورة. أعد المحاولة.',
                  'Could not open image. Try again.',
                  'Impossible d’ouvrir l’image. Réessayez.',
                );
          _busy = false;
        });
    }
  }

  void _push(PhotoEdit edit) {
    setState(() {
      _history.push(edit);
      _draft = null;
    });
  }

  void _step(bool redo) {
    setState(() {
      _draft = null;
      _selected = null;
      redo ? _history.redo() : _history.undo();
    });
    if (_loadedPath != _history.current.path) _load();
  }

  Future<File> _export() async {
    if (_image == null) throw StateError('Image unavailable');
    final bytes = await renderPhoto(
      _image!,
      _edit,
      direction: Directionality.of(context),
    );
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/chat_photo_${DateTime.now().microsecondsSinceEpoch}.png',
    );
    try {
      await file.writeAsBytes(bytes, flush: true);
      return _own(file);
    } catch (_) {
      _own(file);
      await _removeOwned(file.path);
      rethrow;
    }
  }

  Future<void> _finish() async {
    if (_busy || _image == null) return;
    if (_gif || (!_edit.hasOverlays && _edit.path == widget.file.path)) {
      Navigator.pop(context, widget.file);
      return;
    }
    setState(() => _busy = true);
    try {
      final raw = _edit.hasOverlays ? await _export() : File(_edit.path);
      final result = _own(await prepareChatPhoto(raw, hd: widget.hd));
      if (_edit.hasOverlays) await _removeOwned(raw.path);
      if (mounted) {
        _returnedPath = result.path;
        Navigator.pop(context, result);
      } else {
        await _removeOwned(result.path);
      }
    } catch (_) {
      _showError();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError() {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              'تعذر حفظ التعديل. احتفظنا بالتعديلات، حاول مجددًا.',
              'Could not save. Your edits are retained; try again.',
              'Impossible d’enregistrer. Vos modifications sont conservées.',
            ),
          ),
        ),
      );
  }

  Future<void> _crop() async {
    if (_busy || _gif) return;
    setState(() => _busy = true);
    File? composed;
    try {
      composed = await _export();
      if (!mounted) return;
      final result = await ImageCropper().cropImage(
        sourcePath: composed.path,
        compressFormat: ImageCompressFormat.png,
        compressQuality: widget.hd ? 95 : 88,
        maxWidth: widget.hd ? 2560 : 1600,
        maxHeight: widget.hd ? 2560 : 1600,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: t(
              'قص وتدوير',
              'Crop and rotate',
              'Recadrer et pivoter',
            ),
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: t('قص وتدوير', 'Crop and rotate', 'Recadrer et pivoter'),
            aspectRatioLockEnabled: false,
          ),
        ],
      );
      if (result == null) return;
      _own(File(result.path));
      if (!mounted) return;
      _push(PhotoEdit(path: result.path));
      _selected = null;
      await _load();
    } catch (_) {
      _showError();
    } finally {
      if (composed != null) await _removeOwned(composed.path);
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _text() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('نص أو إيموجي', 'Text or emoji', 'Texte ou emoji')),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 240,
          maxLines: 3,
          style: const TextStyle(fontFamilyFallback: ['NotoColorEmoji']),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('إلغاء', 'Cancel', 'Annuler')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(t('إضافة', 'Add', 'Ajouter')),
          ),
        ],
      ),
    );
    // The dialog route keeps the controller while its closing transition runs.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    if (!mounted || text == null || text.isEmpty) return;
    _push(
      _edit.copy(
        texts: [
          ..._edit.texts,
          PhotoText(text, const Offset(.5, .5), _color, _textSize),
        ],
      ),
    );
    setState(() {
      _selected = _edit.texts.length - 1;
      _draw = false;
    });
  }

  Offset _point(Offset p, Size size) {
    return photoSourcePoint(
      Offset((p.dx / size.width).clamp(0, 1), (p.dy / size.height).clamp(0, 1)),
      _edit.turns,
    );
  }

  void _start(Offset p, Size size) {
    if (_busy || _gif) return;
    final point = _point(p, size);
    if (_draw) {
      setState(
        () => _draft = _history.current.copy(
          strokes: [
            ..._history.current.strokes,
            PhotoStroke([point], _color, _width),
          ],
        ),
      );
    } else if (_edit.texts.isNotEmpty) {
      var index = 0;
      var distance = double.infinity;
      for (var i = 0; i < _edit.texts.length; i++) {
        final d = (_edit.texts[i].position - point).distance;
        if (d < distance) {
          index = i;
          distance = d;
        }
      }
      setState(() => _selected = distance < .25 ? index : null);
    }
  }

  void _move(Offset p, Size size) {
    if (_busy || _gif) return;
    final point = _point(p, size);
    if (_draw && _draft != null) {
      final strokes = [..._draft!.strokes];
      final previous = strokes.removeLast();
      strokes.add(
        PhotoStroke(
          [...previous.points, point],
          previous.color,
          previous.width,
        ),
      );
      setState(() => _draft = _draft!.copy(strokes: strokes));
    } else if (!_draw && _selected != null) {
      final texts = [..._edit.texts];
      texts[_selected!] = texts[_selected!].copy(position: point);
      setState(() => _draft = _edit.copy(texts: texts));
    }
  }

  void _end() {
    if (_draft != null) _push(_draft!);
  }

  Widget _button(
    IconData icon,
    String label,
    VoidCallback action, {
    bool enabled = true,
    bool active = false,
  }) =>
      IconButton(
        tooltip: label,
        onPressed: !_busy && !_gif && enabled ? action : null,
        icon: Icon(icon, color: active ? Colors.greenAccent : null),
      );
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(t('تعديل الصورة', 'Edit photo', 'Modifier la photo')),
          actions: [
            TextButton(
              onPressed: _busy || _image == null ? null : _finish,
              child: Text(t('تم', 'Done', 'Terminé')),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (_gif)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    t(
                      'تُحفظ صور GIF كما هي للحفاظ على الحركة؛ تعديلها غير متاح.',
                      'GIF files stay unchanged to preserve animation; editing is unavailable.',
                      'Les GIF restent inchangés pour préserver l’animation ; la modification est indisponible.',
                    ),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    if (_error != null)
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.white),
                            ),
                            TextButton(
                              onPressed: _load,
                              child: Text(
                                t('إعادة المحاولة', 'Retry', 'Réessayer'),
                              ),
                            ),
                          ],
                        ),
                      );
                    if (_image == null || _busy)
                      return const Center(child: CircularProgressIndicator());
                    final imageSize = photoSize(_image!, _edit);
                    final scale = math.min(
                      box.maxWidth / imageSize.width,
                      box.maxHeight / imageSize.height,
                    );
                    final size = imageSize * scale;
                    return Center(
                      child: SizedBox(
                        width: size.width,
                        height: size.height,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanStart: (d) => _start(d.localPosition, size),
                          onPanUpdate: (d) => _move(d.localPosition, size),
                          onPanEnd: (_) => _end(),
                          onPanCancel: () => setState(() => _draft = null),
                          onTapUp: (d) {
                            _start(d.localPosition, size);
                            if (_draw) _end();
                          },
                          child: ClipRect(
                            child: CustomPaint(
                              painter: _PhotoPainter(
                                _image!,
                                _edit,
                                Directionality.of(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (!_gif)
                Theme(
                  data: ThemeData.dark(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _button(
                              Icons.crop_rotate,
                              t('قص', 'Crop', 'Recadrer'),
                              _crop,
                            ),
                            _button(
                              Icons.rotate_right,
                              t('تدوير', 'Rotate', 'Pivoter'),
                              () => _push(
                                _edit.copy(turns: (_edit.turns + 1) % 4),
                              ),
                            ),
                            _button(
                              Icons.draw,
                              t('رسم', 'Draw', 'Dessiner'),
                              () => setState(() => _draw = !_draw),
                              active: _draw,
                            ),
                            _button(
                              Icons.text_fields,
                              t(
                                'نص أو إيموجي',
                                'Text or emoji',
                                'Texte ou emoji',
                              ),
                              _text,
                            ),
                            _button(
                              Icons.filter_b_and_w,
                              t('فلتر', 'Filter', 'Filtre'),
                              () => _push(
                                _edit.copy(
                                  filter:
                                      (_edit.filter + 1) % photoFilters.length,
                                ),
                              ),
                            ),
                            _button(
                              Icons.undo,
                              t('تراجع', 'Undo', 'Annuler'),
                              () => _step(false),
                              enabled: _history.canUndo,
                            ),
                            _button(
                              Icons.redo,
                              t('إعادة', 'Redo', 'Rétablir'),
                              () => _step(true),
                              enabled: _history.canRedo,
                            ),
                            _button(
                              Icons.delete_outline,
                              t(
                                'حذف النص المحدد',
                                'Delete selected text',
                                'Supprimer le texte sélectionné',
                              ),
                              () {
                                final texts = [..._edit.texts]
                                  ..removeAt(_selected!);
                                _selected = null;
                                _push(_edit.copy(texts: texts));
                              },
                              enabled: _selected != null,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final color in [
                            Colors.white,
                            Colors.black,
                            Colors.red,
                            Colors.yellow,
                            Colors.green,
                            Colors.blue,
                          ])
                            Padding(
                              padding: const EdgeInsets.all(5),
                              child: Semantics(
                                label: t(
                                  'لون الرسم والنص',
                                  'Drawing and text color',
                                  'Couleur du dessin et du texte',
                                ),
                                button: true,
                                selected: _color == color,
                                child: InkWell(
                                  onTap: _busy
                                      ? null
                                      : () => setState(() => _color = color),
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: color,
                                      border: Border.all(
                                        color: _color == color
                                            ? Colors.greenAccent
                                            : Colors.white38,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (_draw)
                        Slider(
                          value: _width,
                          min: .003,
                          max: .04,
                          onChanged:
                              _busy ? null : (v) => setState(() => _width = v),
                        ),
                      if (!_draw && _selected != null)
                        Slider(
                          value: _edit.texts[_selected!].size.clamp(.025, .2),
                          min: .025,
                          max: .2,
                          onChanged: _busy
                              ? null
                              : (value) {
                                  final texts = [..._edit.texts];
                                  texts[_selected!] = texts[_selected!].copy(
                                    size: value,
                                  );
                                  setState(
                                    () => _draft = _edit.copy(texts: texts),
                                  );
                                },
                          onChangeEnd: (_) => _end(),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _draw
                              ? t(
                                  'ارسم بإصبعك؛ التراجع يمحو آخر خط',
                                  'Draw with your finger; undo removes the last stroke',
                                  'Dessinez avec le doigt ; annuler efface le dernier trait',
                                )
                              : t(
                                  'اسحب النص لتحريكه؛ حدده لتغيير حجمه أو حذفه',
                                  'Drag text to move it; select it to resize or delete',
                                  'Glissez le texte ; sélectionnez-le pour le redimensionner ou supprimer',
                                ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPainter extends CustomPainter {
  _PhotoPainter(this.image, this.edit, this.direction);
  final ui.Image image;
  final PhotoEdit edit;
  final TextDirection direction;
  @override
  void paint(Canvas canvas, Size size) =>
      paintPhoto(canvas, size, image, edit, direction: direction);
  @override
  bool shouldRepaint(covariant _PhotoPainter old) =>
      old.image != image || old.edit != edit || old.direction != direction;
}
