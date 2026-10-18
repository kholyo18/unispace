import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

String mediaText(BuildContext context, String ar, String en, String fr) =>
    switch (Localizations.localeOf(context).languageCode) {
      'ar' => ar,
      'fr' => fr,
      _ => en
    };

/// OS boundary: only images/videos that the user has granted access to.
class ChatGallerySource {
  const ChatGallerySource({this.imagesOnly = false});
  final bool imagesOnly;
  PermissionRequestOption get _permissionOptions => PermissionRequestOption(
        androidPermission: AndroidPermission(
            type: imagesOnly ? RequestType.image : RequestType.common,
            mediaLocation: false),
      );
  Future<PermissionState> access() =>
      PhotoManager.requestPermissionExtend(requestOption: _permissionOptions);
  Future<List<AssetEntity>> page(int page) => PhotoManager.getAssetListPaged(
        page: page,
        pageCount: 60,
        type: imagesOnly ? RequestType.image : RequestType.common,
        filterOption: FilterOptionGroup(orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false)
        ]),
      );
  Future<Uint8List?> thumbnail(AssetEntity asset) =>
      asset.thumbnailDataWithSize(const ThumbnailSize.square(240));
  Future<File?> file(AssetEntity asset) => asset.file;
  Future<void> settings() async {
    await PhotoManager.openSetting();
  }

  Future<void> limited() => PhotoManager.presentLimited(
      type: imagesOnly ? RequestType.image : RequestType.common);
}

Future<List<File>?> showChatMediaGallery(BuildContext context,
        {bool imagesOnly = false}) =>
    showModalBottomSheet<List<File>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SizedBox(
          height: MediaQuery.sizeOf(ctx).height * .9,
          child: ChatMediaGallery(
              maxSelection: imagesOnly ? 1 : 30,
              source: ChatGallerySource(imagesOnly: imagesOnly),
              onSelected: (files) async => Navigator.pop(ctx, files))),
    );

class ChatMediaGallery extends StatefulWidget {
  const ChatMediaGallery(
      {super.key,
      this.maxSelection = 30,
      this.header,
      this.controller,
      this.onCamera,
      required this.onSelected,
      this.source = const ChatGallerySource()});
  final int maxSelection;
  final Widget? header;
  final ScrollController? controller;
  final VoidCallback? onCamera;
  final Future<void> Function(List<File>) onSelected;
  final ChatGallerySource source;
  @override
  State<ChatMediaGallery> createState() => _ChatMediaGalleryState();
}

class _ChatMediaGalleryState extends State<ChatMediaGallery>
    with WidgetsBindingObserver {
  final _assets = <AssetEntity>[];
  final _selected = <String, AssetEntity>{};
  PermissionState? _permission;
  bool _loading = false, _preparing = false, _more = true, _failed = false;
  bool _returnFromSettings = false;
  int _page = 0;
  String t(String ar, String en, String fr) => mediaText(context, ar, en, fr);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load(reset: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _returnFromSettings) {
      _returnFromSettings = false;
      _load(reset: true);
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading || _preparing) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      if (reset) {
        final permission = await widget.source.access();
        if (!mounted) return;
        _permission = permission;
        _assets.clear();
        _selected.clear();
        _page = 0;
        _more = true;
      }
      if (_permission?.hasAccess != true) return;
      final items = await widget.source.page(_page);
      if (!mounted) return;
      final known = _assets.map((a) => a.id).toSet();
      _assets.addAll(items.where((a) => known.add(a.id)));
      _page++;
      _more = items.length == 60;
    } catch (_) {
      if (mounted) _failed = true;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _manage() async {
    try {
      if (_permission == PermissionState.limited) {
        await widget.source.limited();
        if (mounted) await _load(reset: true);
      } else {
        _returnFromSettings = true;
        await widget.source.settings();
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _review() async {
    if (_preparing || _selected.isEmpty) return;
    setState(() => _preparing = true);
    try {
      final files = <File>[];
      for (final asset in _selected.values.toList()) {
        final file = await widget.source.file(asset);
        if (!mounted) return;
        if (file == null) throw StateError('Media unavailable');
        files.add(file);
      }
      if (mounted) await widget.onSelected(files);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(t(
                'تعذر تجهيز الوسائط المحددة. أعد المحاولة.',
                'Could not prepare selected media. Try again.',
                'Impossible de préparer les médias. Réessayez.'))));
    } finally {
      if (mounted) setState(() => _preparing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraCount = widget.onCamera == null ? 0 : 1;
    final colors = Theme.of(context).colorScheme;
    return Material(
        color: colors.surface,
        child: SafeArea(
            top: false,
            child: Column(children: [
              Expanded(
                  child:
                      CustomScrollView(controller: widget.controller, slivers: [
                if (widget.header != null)
                  SliverToBoxAdapter(
                      child: AbsorbPointer(
                          absorbing: _preparing, child: widget.header)),
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(children: [
                          Expanded(
                              child: Text(
                                  widget.source.imagesOnly
                                      ? t('الصور', 'Photos', 'Photos')
                                      : t(
                                          'الصور والفيديوهات',
                                          'Photos and videos',
                                          'Photos et vidéos'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          color: colors.onSurface,
                                          fontWeight: FontWeight.w600))),
                          if (_permission == PermissionState.limited)
                            TextButton(
                                onPressed:
                                    _preparing || _loading ? null : _manage,
                                child: Text(t('إدارة الوصول', 'Manage access',
                                    'Gérer l’accès'))),
                        ]))),
                if (!_loading && _permission?.hasAccess != true)
                  SliverToBoxAdapter(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(children: [
                            Text(t(
                                'اسمح بالوصول إلى الصور لعرضها هنا.',
                                'Allow photo access to display your gallery here.',
                                'Autorisez l’accès aux photos pour afficher la galerie.')),
                            TextButton(
                                onPressed: _manage,
                                child: Text(t('فتح الإعدادات', 'Open settings',
                                    'Ouvrir les réglages'))),
                          ]))),
                SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 6,
                              mainAxisSpacing: 6),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index < cameraCount)
                          return Material(
                              color: colors.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                  key: const ValueKey('gallery-camera'),
                                  onTap: _preparing ? null : widget.onCamera,
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.photo_camera_outlined,
                                            color: colors.onSecondaryContainer,
                                            size: 36),
                                        Text(t('الكاميرا', 'Camera', 'Caméra'),
                                            style: TextStyle(
                                                color: colors
                                                    .onSecondaryContainer))
                                      ])));
                        final asset = _assets[index - cameraCount];
                        final order = _selected.keys.toList().indexOf(asset.id);
                        return _GalleryThumbnail(
                            key: ValueKey(asset.id),
                            source: widget.source,
                            asset: asset,
                            order: order,
                            onTap: _preparing
                                ? null
                                : () {
                                    if (order < 0 && widget.maxSelection == 1)
                                      _selected.clear();
                                    if (order < 0 &&
                                        _selected.length >=
                                            widget.maxSelection) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(t(
                                                  'يمكن اختيار 30 عنصرًا كحد أقصى.',
                                                  'Select up to 30 items.',
                                                  'Sélectionnez 30 éléments au maximum.'))));
                                      return;
                                    }
                                    setState(() {
                                      if (order >= 0) {
                                        _selected.remove(asset.id);
                                      } else {
                                        _selected[asset.id] = asset;
                                      }
                                    });
                                  });
                      }, childCount: _assets.length + cameraCount),
                    )),
                if (_loading)
                  const SliverToBoxAdapter(
                      child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()))),
                if (!_loading && _failed)
                  SliverToBoxAdapter(
                      child: TextButton(
                          onPressed: () => _load(reset: _permission == null),
                          child: Text(t(
                              'تعذر تحميل المعرض. أعد المحاولة',
                              'Gallery unavailable. Retry',
                              'Galerie indisponible. Réessayer')))),
                if (!_loading &&
                    !_failed &&
                    _permission?.hasAccess == true &&
                    _assets.isEmpty)
                  SliverToBoxAdapter(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(t(
                              'لا توجد صور أو فيديوهات متاحة.',
                              'No accessible photos or videos.',
                              'Aucune photo ou vidéo accessible.')))),
                if (!_loading &&
                    !_failed &&
                    _permission?.hasAccess == true &&
                    _more)
                  SliverToBoxAdapter(
                      child: TextButton(
                          onPressed: _preparing ? null : _load,
                          child: Text(
                              t('عرض المزيد', 'Load more', 'Afficher plus')))),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
              ])),
              if (_selected.isNotEmpty)
                Container(
                    decoration: BoxDecoration(
                        color: colors.surfaceContainerLow,
                        border: Border(
                            top: BorderSide(color: colors.outlineVariant))),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                            style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48)),
                            onPressed: _preparing ? null : _review,
                            child: _preparing
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colors.onSurfaceVariant))
                                : Text(
                                    '${t('التالي', 'Next', 'Suivant')} (${_selected.length})')))),
            ])));
  }
}

class _GalleryThumbnail extends StatefulWidget {
  const _GalleryThumbnail(
      {super.key,
      required this.source,
      required this.asset,
      required this.order,
      required this.onTap});
  final ChatGallerySource source;
  final AssetEntity asset;
  final int order;
  final VoidCallback? onTap;
  @override
  State<_GalleryThumbnail> createState() => _GalleryThumbnailState();
}

class _GalleryThumbnailState extends State<_GalleryThumbnail> {
  late final _thumbnail = widget.source.thumbnail(widget.asset);
  @override
  Widget build(BuildContext context) => Semantics(
        selected: widget.order >= 0,
        button: true,
        label: mediaText(
            context,
            widget.asset.type == AssetType.video ? 'فيديو' : 'صورة',
            widget.asset.type == AssetType.video ? 'Video' : 'Photo',
            widget.asset.type == AssetType.video ? 'Vidéo' : 'Photo'),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
                onTap: widget.onTap,
                child: Stack(fit: StackFit.expand, children: [
                  ColoredBox(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest),
                  FutureBuilder<Uint8List?>(
                      future: _thumbnail,
                      builder: (context, snapshot) => snapshot.data == null
                          ? const Icon(Icons.image_outlined)
                          : Image.memory(snapshot.data!,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image_outlined))),
                  if (widget.asset.type == AssetType.video)
                    Positioned(
                        bottom: 4,
                        left: 4,
                        child: DecoratedBox(
                            decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4)),
                            child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: Text(
                                    '▶ ${widget.asset.duration ~/ 60}:${(widget.asset.duration % 60).toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                        color: Colors.white))))),
                  Positioned(
                      top: 6,
                      right: 6,
                      child: CircleAvatar(
                          radius: 13,
                          backgroundColor: widget.order >= 0
                              ? Theme.of(context).colorScheme.primary
                              : Colors.black45,
                          child: widget.order >= 0
                              ? Text('${widget.order + 1}',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      fontSize: 12))
                              : const Icon(Icons.circle_outlined,
                                  color: Colors.white, size: 24))),
                ]))),
      );
}
