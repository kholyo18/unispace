import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'photo_edit_model.dart';

String _text(BuildContext context, String ar, String en, String fr) {
  return switch (Localizations.localeOf(context).languageCode) {
    'ar' => ar,
    'fr' => fr,
    _ => en,
  };
}

/// Returns a new immutable layer only after the user explicitly saves it.
Future<PhotoText?> showPhotoTextEditor(
  BuildContext context, {
  PhotoText? initial,
  required Color color,
}) {
  return showModalBottomSheet<PhotoText>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PhotoTextSheet(initial: initial, color: color),
  );
}

class _PhotoTextSheet extends StatefulWidget {
  const _PhotoTextSheet({required this.initial, required this.color});
  final PhotoText? initial;
  final Color color;

  @override
  State<_PhotoTextSheet> createState() => _PhotoTextSheetState();
}

class _PhotoTextSheetState extends State<_PhotoTextSheet> {
  late final TextEditingController _controller;
  late Color _color;
  late int _fontStyle;
  late TextAlign _align;
  late bool _background;
  late Color _backgroundColor;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial?.text ?? '');
    _color = widget.initial?.color ?? widget.color;
    _fontStyle = widget.initial?.fontStyle ?? 0;
    _align = widget.initial?.align ?? TextAlign.center;
    _background = widget.initial?.background != null;
    _backgroundColor = widget.initial?.background ?? _contrast;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _contrast =>
      _color.computeLuminance() > .45 ? Colors.black : Colors.white;

  void _save() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final original =
        widget.initial ?? PhotoText('', const Offset(.5, .5), _color, .075);
    Navigator.pop(
      context,
      original.copy(
        text: text,
        color: _color,
        fontStyle: _fontStyle,
        align: _align,
        background: _background ? _backgroundColor : null,
        clearBackground: !_background,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final available = MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom -
        MediaQuery.paddingOf(context).top;
    final palette = <Color>{
      Colors.white,
      Colors.black,
      widget.color,
      Colors.tealAccent,
      Colors.pinkAccent,
      Colors.orangeAccent
    };
    final style = TextStyle(
      fontFamily: _fontStyle == 1
          ? 'serif'
          : _fontStyle == 2
              ? 'monospace'
              : null,
      fontWeight: _fontStyle == 0 ? FontWeight.bold : FontWeight.normal,
      fontSize: 22,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: available.clamp(100, 640)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(
                    child: Text(
                  _text(
                      context, 'تعديل النص', 'Edit text', 'Modifier le texte'),
                  style: Theme.of(context).textTheme.titleLarge,
                )),
                IconButton(
                  tooltip: _text(context, 'إلغاء', 'Cancel', 'Annuler'),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ]),
              TextField(
                key: const ValueKey('photo-text-input'),
                controller: _controller,
                autofocus: true,
                minLines: 1,
                maxLines: 4,
                maxLength: 240,
                textAlign: _align,
                style: style,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: _text(
                      context, 'اكتب نصًا', 'Enter text', 'Saisir un texte'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                label: _text(
                    context, 'معاينة النص', 'Text preview', 'Aperçu du texte'),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _background
                        ? colors.surfaceContainerHighest
                        : _contrast.withValues(alpha: .9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Text(
                    _controller.text.isEmpty
                        ? _text(context, 'نص', 'Text', 'Texte')
                        : _controller.text,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    textAlign: _align,
                    style: style.copyWith(
                      color: _color,
                      backgroundColor: _background ? _backgroundColor : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final entry in [
                  _text(context, 'عريض', 'Bold', 'Gras'),
                  _text(context, 'كلاسيكي', 'Serif', 'Classique'),
                  _text(context, 'آلة كاتبة', 'Mono', 'Machine'),
                ].asMap().entries)
                  ChoiceChip(
                    key: ValueKey('photo-font-${entry.key}'),
                    label: Text(entry.value),
                    selected: _fontStyle == entry.key,
                    onSelected: (_) => setState(() => _fontStyle = entry.key),
                  ),
              ]),
              Wrap(spacing: 4, children: [
                for (final entry in <TextAlign, (IconData, String)>{
                  TextAlign.left: (
                    Icons.format_align_left,
                    _text(context, 'محاذاة لليسار', 'Align left',
                        'Aligner à gauche')
                  ),
                  TextAlign.center: (
                    Icons.format_align_center,
                    _text(context, 'توسيط', 'Center', 'Centrer')
                  ),
                  TextAlign.right: (
                    Icons.format_align_right,
                    _text(context, 'محاذاة لليمين', 'Align right',
                        'Aligner à droite')
                  ),
                }.entries)
                  IconButton(
                    key: ValueKey('photo-align-${entry.key.name}'),
                    tooltip: entry.value.$2,
                    isSelected: _align == entry.key,
                    color: _align == entry.key ? colors.primary : null,
                    onPressed: () => setState(() => _align = entry.key),
                    icon: Icon(entry.value.$1),
                  ),
              ]),
              Wrap(spacing: 4, runSpacing: 4, children: [
                for (final color in palette)
                  Semantics(
                    selected: _color == color,
                    child: IconButton(
                      key: ValueKey('photo-color-${color.toARGB32()}'),
                      tooltip: _colorName(context, color),
                      onPressed: () => setState(() {
                        _color = color;
                        _backgroundColor = _contrast;
                      }),
                      icon: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          border: Border.all(color: colors.outline, width: 1.5),
                        ),
                        child: _color == color
                            ? Icon(Icons.check,
                                size: 18,
                                color: color.computeLuminance() > .45
                                    ? Colors.black
                                    : Colors.white)
                            : null,
                      ),
                    ),
                  ),
              ]),
              SwitchListTile.adaptive(
                key: const ValueKey('photo-text-background'),
                contentPadding: EdgeInsets.zero,
                title: Text(_text(
                    context, 'خلفية النص', 'Text background', 'Fond du texte')),
                value: _background,
                onChanged: (value) => setState(() => _background = value),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const ValueKey('photo-text-save'),
                onPressed: _controller.text.trim().isEmpty ? null : _save,
                icon: const Icon(Icons.check),
                label: Text(_text(context, 'تم', 'Done', 'Terminé')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _colorName(BuildContext context, Color color) {
  if (color == Colors.white) {
    return _text(context, 'أبيض', 'White', 'Blanc');
  }
  if (color == Colors.black) {
    return _text(context, 'أسود', 'Black', 'Noir');
  }
  if (color == Colors.tealAccent) {
    return _text(context, 'فيروزي', 'Teal', 'Turquoise');
  }
  if (color == Colors.pinkAccent) {
    return _text(context, 'وردي', 'Pink', 'Rose');
  }
  if (color == Colors.orangeAccent) {
    return _text(context, 'برتقالي', 'Orange', 'Orange');
  }
  return _text(context, 'اللون المختار', 'Selected color', 'Couleur choisie');
}

/// All bundled emoji categories, skin tones and search; no remote sticker packs.
Future<String?> showPhotoStickerPicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      final colors = Theme.of(context).colorScheme;
      final height = ((MediaQuery.sizeOf(context).height -
                  MediaQuery.viewInsetsOf(context).bottom) *
              .6)
          .clamp(180.0, 420.0);
      final columns =
          (MediaQuery.sizeOf(context).width / 48).floor().clamp(4, 10);
      return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 16),
            child: Row(children: [
              Expanded(
                  child: Text(
                _text(context, 'الرموز والملصقات', 'Emoji stickers',
                    'Autocollants emoji'),
                style: Theme.of(context).textTheme.titleMedium,
              )),
              IconButton(
                tooltip: _text(context, 'إغلاق', 'Close', 'Fermer'),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ]),
          ),
          EmojiPicker(
            onEmojiSelected: (_, emoji) => Navigator.pop(context, emoji.emoji),
            config: Config(
              height: height,
              locale: Localizations.localeOf(context),
              checkPlatformCompatibility: false,
              emojiTextStyle:
                  const TextStyle(fontFamily: 'NotoColorEmoji', fontSize: 28),
              emojiViewConfig: EmojiViewConfig(
                columns: columns,
                emojiSizeMax: 32,
                backgroundColor: colors.surface,
                noRecents: Text(_text(context, 'لا توجد رموز حديثة',
                    'No recent emoji', 'Aucun emoji récent')),
              ),
              categoryViewConfig: CategoryViewConfig(
                initCategory: Category.SMILEYS,
                backgroundColor: colors.surface,
                iconColor: colors.onSurfaceVariant,
                iconColorSelected: colors.primary,
                indicatorColor: colors.primary,
              ),
              skinToneConfig: SkinToneConfig(
                enabled: true,
                dialogBackgroundColor: colors.surface,
                indicatorColor: colors.primary,
              ),
              bottomActionBarConfig: BottomActionBarConfig(
                backgroundColor: colors.surface,
                buttonColor: colors.primary,
                buttonIconColor: colors.onPrimary,
                showBackspaceButton: false,
                showSearchViewButton: true,
              ),
              searchViewConfig: SearchViewConfig(
                backgroundColor: colors.surface,
                buttonIconColor: colors.onSurface,
                hintText: _text(context, 'ابحث عن رمز', 'Search emoji',
                    'Rechercher un emoji'),
              ),
            ),
          ),
        ]),
      );
    },
  );
}
