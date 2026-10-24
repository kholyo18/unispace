import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

/// Returns only an explicitly accepted crop. Cancellation never assigns a file.
Future<File?> cropImageForAssignment(BuildContext context, File source,
    {double? aspectRatio, bool circle = false}) async {
  final ratio = circle ? 1.0 : aspectRatio;
  if (ratio != null && (!ratio.isFinite || ratio <= 0)) {
    throw ArgumentError.value(ratio, 'aspectRatio');
  }
  final language = Localizations.localeOf(context).languageCode;
  final title = switch (language) {
    'ar' => 'حرّك الصورة وكبّرها للقص',
    'fr' => 'Déplacer et zoomer pour recadrer',
    _ => 'Move and zoom to crop',
  };
  final result = await ImageCropper().cropImage(
    sourcePath: source.path,
    maxWidth: 2560,
    maxHeight: 2560,
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: 92,
    aspectRatio:
        ratio == null ? null : CropAspectRatio(ratioX: ratio, ratioY: 1),
    uiSettings: [
      AndroidUiSettings(
          toolbarTitle: title,
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          backgroundColor: Colors.black,
          lockAspectRatio: ratio != null,
          cropStyle: circle ? CropStyle.circle : CropStyle.rectangle),
      IOSUiSettings(
          title: title,
          aspectRatioLockEnabled: ratio != null,
          resetAspectRatioEnabled: ratio == null,
          cropStyle: circle ? CropStyle.circle : CropStyle.rectangle),
    ],
  );
  return result == null ? null : File(result.path);
}
