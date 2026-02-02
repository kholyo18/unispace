import 'dart:io';

import 'package:path/path.dart' as p;

class DownloadItem {
  const DownloadItem({
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.modifiedAt,
    required this.extension,
  });

  final String name;
  final String path;
  final int sizeBytes;
  final DateTime modifiedAt;
  final String extension;

  bool get isImage => _imageExtensions.contains(extension);

  static const Set<String> _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'heic',
    'heif',
    'tiff',
    'svg',
  };

  static Future<DownloadItem> fromFile(File file) async {
    final stat = await file.stat();
    final fileName = p.basename(file.path);
    final ext = p.extension(file.path).replaceFirst('.', '').toLowerCase();
    return DownloadItem(
      name: fileName,
      path: file.path,
      sizeBytes: stat.size,
      modifiedAt: stat.modified,
      extension: ext,
    );
  }

  static String humanReadableBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double size = bytes.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return '${size.toStringAsFixed(size < 10 && unitIndex > 0 ? 1 : 0)} ${units[unitIndex]}';
  }
}
