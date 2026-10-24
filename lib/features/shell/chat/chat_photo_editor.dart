import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'photo_edit_model.dart';
import 'chat_photo_tools.dart';
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
  double _width = 0.012;
  bool _filters = false, _zoom = false;
  int _brush = 0;
  final _transform = TransformationController();
  PhotoEdit? _gestureBase;
  PhotoText? _gestureText;
  Offset? _gestureOrigin;
  int? _selected;
  int _generation = 0;
  String? _error;
  bool _allowExit = false;
  bool get _changed => _edit.hasOverlays || _edit.path != widget.file.path;
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
    _transform.dispose();
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
        setState(() => _allowExit = true);
        await WidgetsBinding.instance.endOfFrame;
        if (mounted) Navigator.pop(context, result);
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
    final index = _selected;
    final initial =
        index == null || _edit.texts[index].emoji ? null : _edit.texts[index];
    final result =
        await showPhotoTextEditor(context, initial: initial, color: _color);
    if (!mounted || result == null) return;
    final texts = [..._edit.texts];
    if (initial == null) {
      texts.add(result);
    } else {
      texts[index!] = result;
    }
    _push(_edit.copy(texts: texts));
    setState(() {
      _selected = initial == null ? texts.length - 1 : index;
      _draw = false;
      _zoom = false;
      _filters = false;
      _transform.value = Matrix4.identity();
    });
  }

  Future<void> _sticker() async {
    final emoji = await showPhotoStickerPicker(context);
    if (!mounted || emoji == null) return;
    _push(_edit.copy(texts: [
      ..._edit.texts,
      PhotoText(emoji, const Offset(.5, .5), Colors.white, .16, emoji: true)
    ]));
    setState(() {
      _selected = _edit.texts.length - 1;
      _draw = false;
      _zoom = false;
      _filters = false;
      _transform.value = Matrix4.identity();
    });
  }

  Offset _point(Offset p, Size size) => photoSourcePoint(
      Offset((p.dx / size.width).clamp(0, 1), (p.dy / size.height).clamp(0, 1)),
      _edit.turns,
      mirrored: _edit.mirrored);

  void _start(Offset p, Size size) {
    if (_busy || _gif || _zoom) return;
    final point = _point(p, size);
    _gestureBase = _history.current;
    _gestureOrigin = point;
    _gestureText = null;
    if (_draw) {
      setState(() => _draft = _history.current.copy(strokes: [
            ..._history.current.strokes,
            PhotoStroke([point], _color, _width,
                erase: _brush == 2, opacity: _brush == 1 ? .35 : 1),
          ]));
    } else {
      int? selected;
      for (var i = _edit.texts.length - 1; i >= 0; i--) {
        if (hitTestPhotoText(_edit.texts[i], point,
            Size(_image!.width.toDouble(), _image!.height.toDouble()),
            direction: Directionality.of(context), padding: 12)) {
          selected = i;
          break;
        }
      }
      setState(() => _selected = selected);
      if (selected != null) _gestureText = _edit.texts[selected];
    }
  }

  void _move(ScaleUpdateDetails d, Size size) {
    if (_busy || _gif || _zoom) return;
    final point = _point(d.localFocalPoint, size);
    if (_draw && _draft != null) {
      if (d.pointerCount > 1) return;
      final strokes = [..._draft!.strokes];
      final previous = strokes.removeLast();
      strokes.add(PhotoStroke(
          [...previous.points, point], previous.color, previous.width,
          erase: previous.erase, opacity: previous.opacity));
      setState(() => _draft = _draft!.copy(strokes: strokes));
    } else if (_selected != null && _gestureText != null) {
      final base = _gestureText!;
      final position = base.position + point - _gestureOrigin!;
      final texts = [..._gestureBase!.texts];
      texts[_selected!] = base.copy(
          position: Offset(position.dx.clamp(0, 1), position.dy.clamp(0, 1)),
          size: (base.size * d.scale).clamp(.025, .45),
          angle: base.angle + d.rotation * (_edit.mirrored ? -1 : 1));
      setState(() => _draft = _gestureBase!.copy(texts: texts));
    }
  }

  void _end() {
    if (_draft != null) _push(_draft!);
    _gestureBase = null;
    _gestureText = null;
    _gestureOrigin = null;
  }

  void _colorChange(Color color) {
    setState(() => _color = color);
    if (!_draw && _selected != null && !_edit.texts[_selected!].emoji) {
      final texts = [..._edit.texts];
      texts[_selected!] = texts[_selected!].copy(color: color);
      _push(_edit.copy(texts: texts));
    }
  }

  Widget _filterStrip() {
    final names = [
      t('أصلي', 'Original', 'Original'),
      t('أبيض وأسود', 'Mono', 'Mono'),
      t('دافئ', 'Warm', 'Chaud'),
      t('بارد', 'Cool', 'Froid'),
      t('بني', 'Sepia', 'Sépia'),
      t('زاهٍ', 'Vivid', 'Vif')
    ];
    return SizedBox(
        height: 82,
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: photoFilters.length,
            itemBuilder: (_, index) => Padding(
                padding: const EdgeInsets.all(4),
                child: Semantics(
                    selected: _edit.filter == index,
                    button: true,
                    child: InkWell(
                        onTap: _busy
                            ? null
                            : () => _push(_edit.copy(filter: index)),
                        child: Column(children: [
                          Container(
                              width: 64,
                              height: 48,
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: _edit.filter == index
                                          ? Colors.greenAccent
                                          : Colors.white24,
                                      width: 2)),
                              child: ClipRect(
                                  child: CustomPaint(
                                      painter: _PhotoPainter(
                                          _image!,
                                          _edit.copy(filter: index),
                                          Directionality.of(context))))),
                          Text(names[index],
                              style: const TextStyle(fontSize: 11)),
                        ]))))));
  }

  Future<void> _leave() async {
    if (_busy) return;
    final discard = !_changed ||
        await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                        title: Text(t('تجاهل التعديلات؟', 'Discard edits?',
                            'Abandonner les modifications ?')),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(t('متابعة التعديل', 'Keep editing',
                                  'Continuer'))),
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(t('تجاهل', 'Discard', 'Abandonner')))
                        ])) ==
            true;
    if (!mounted || !discard) return;
    setState(() => _allowExit = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context);
  }

  Widget _view(Widget child) => !_zoom
      ? child
      : InteractiveViewer(
          transformationController: _transform,
          minScale: 1,
          maxScale: 5,
          child: child);

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
      canPop: _allowExit || (!_busy && !_changed),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_busy) _leave();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          leading: IconButton(
              onPressed: _busy ? null : _leave, icon: const Icon(Icons.close)),
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
                          onScaleStart: _zoom
                              ? null
                              : (d) => _start(d.localFocalPoint, size),
                          onScaleUpdate: _zoom ? null : (d) => _move(d, size),
                          onScaleEnd: _zoom ? null : (_) => _end(),
                          onDoubleTap: _zoom || _draw
                              ? null
                              : () {
                                  if (_selected != null &&
                                      !_edit.texts[_selected!].emoji) _text();
                                },
                          onTapUp: (d) {
                            _start(d.localPosition, size);
                            if (_draw) _end();
                          },
                          child: _view(
                            ClipRect(
                                child: CustomPaint(
                              painter: _PhotoPainter(
                                _image!,
                                _edit,
                                Directionality.of(context),
                                selected: _draw || _zoom ? null : _selected,
                              ),
                            )),
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
                                Icons.flip,
                                t('عكس', 'Mirror', 'Miroir'),
                                () => _push(
                                    _edit.copy(mirrored: !_edit.mirrored))),
                            _button(
                                Icons.emoji_emotions_outlined,
                                t('ملصقات وإيموجي', 'Stickers and emoji',
                                    'Autocollants et emojis'),
                                _sticker),
                            _button(
                                Icons.zoom_in,
                                t('تكبير الصورة', 'Zoom photo', 'Zoom photo'),
                                () => setState(() {
                                      _zoom = !_zoom;
                                      _draw = false;
                                      _transform.value = Matrix4.identity();
                                    }),
                                active: _zoom),
                            _button(
                              Icons.draw,
                              t('رسم', 'Draw', 'Dessiner'),
                              () => setState(() {
                                _draw = !_draw;
                                _zoom = false;
                                _filters = false;
                                _selected = null;
                                _transform.value = Matrix4.identity();
                              }),
                              active: _draw,
                            ),
                            _button(
                              Icons.text_fields,
                              t(
                                'نص',
                                'Text',
                                'Texte',
                              ),
                              _text,
                            ),
                            _button(
                              Icons.auto_awesome,
                              t('فلتر', 'Filter', 'Filtre'),
                              () => setState(() {
                                _filters = !_filters;
                                _draw = false;
                              }),
                              active: _filters,
                            ),
                            _button(Icons.restart_alt,
                                t('إعادة ضبط', 'Reset', 'Réinitialiser'), () {
                              _selected = null;
                              _transform.value = Matrix4.identity();
                              _push(PhotoEdit(path: widget.file.path));
                              if (_loadedPath != widget.file.path) _load();
                            }, enabled: _changed),
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
                      if (_filters && _image != null) _filterStrip(),
                      if (_draw)
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _button(Icons.edit, t('قلم', 'Pen', 'Stylo'),
                                  () => setState(() => _brush = 0),
                                  active: _brush == 0),
                              _button(
                                  Icons.brush,
                                  t('تمييز', 'Highlighter', 'Surligneur'),
                                  () => setState(() => _brush = 1),
                                  active: _brush == 1),
                              _button(
                                  Icons.auto_fix_normal,
                                  t('ممحاة', 'Eraser', 'Gomme'),
                                  () => setState(() => _brush = 2),
                                  active: _brush == 2),
                            ]),
                      if (_draw || _selected != null)
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
                                        : () => _colorChange(color),
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
                                  'اسحب العنصر، وكبّره ودوّره بإصبعين؛ انقر مرتين لتعديل النص',
                                  'Drag to move; pinch and rotate with two fingers; double-tap to edit text',
                                  'Glissez, pincez et pivotez à deux doigts ; double-touchez pour modifier le texte',
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
  _PhotoPainter(this.image, this.edit, this.direction, {this.selected});
  final int? selected;
  final ui.Image image;
  final PhotoEdit edit;
  final TextDirection direction;
  @override
  void paint(Canvas canvas, Size size) {
    paintPhoto(canvas, size, image, edit, direction: direction);
    if (selected == null || selected! >= edit.texts.length) return;
    final text = edit.texts[selected!];
    final sourceSize = Size(image.width.toDouble(), image.height.toDouble());
    final bounds =
        photoTextBounds(text, sourceSize, direction: direction).inflate(6);
    Offset project(Offset p) {
      final delta = p - bounds.center;
      final rotated = bounds.center +
          Offset(
              delta.dx * math.cos(text.angle) - delta.dy * math.sin(text.angle),
              delta.dx * math.sin(text.angle) +
                  delta.dy * math.cos(text.angle));
      final normalized = photoDisplayPoint(
          Offset(rotated.dx / sourceSize.width, rotated.dy / sourceSize.height),
          edit.turns,
          mirrored: edit.mirrored);
      return Offset(normalized.dx * size.width, normalized.dy * size.height);
    }

    final points = [
      bounds.topLeft,
      bounds.topRight,
      bounds.bottomRight,
      bounds.bottomLeft
    ].map(project).toList();
    canvas.drawPath(
        Path()..addPolygon(points, true),
        Paint()
          ..color = Colors.white70
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant _PhotoPainter old) =>
      old.image != image ||
      old.edit != edit ||
      old.direction != direction ||
      old.selected != selected;
}
