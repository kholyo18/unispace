import 'dart:io';

import 'package:path_provider/path_provider.dart';

class DownloadEntry {
  const DownloadEntry({
    required this.file,
    required this.lastModified,
  });

  final File file;
  final DateTime lastModified;

  String get name => file.uri.pathSegments.isNotEmpty
      ? file.uri.pathSegments.last
      : file.path;
}

class DownloadsRepository {
  DownloadsRepository._();

  static final DownloadsRepository instance = DownloadsRepository._();

  Future<Directory> _downloadsDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final directory = Directory('${docs.path}/downloads');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<List<DownloadEntry>> listDownloads() async {
    final directory = await _downloadsDir();
    final entities = directory.listSync();
    final files = entities.whereType<File>();
    final entries = <DownloadEntry>[];
    for (final file in files) {
      final modified = await file.lastModified();
      entries.add(DownloadEntry(file: file, lastModified: modified));
    }
    entries.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    return entries;
  }

  Future<void> clearDownloads() async {
    final directory = await _downloadsDir();
    if (!await directory.exists()) return;
    final entities = directory.listSync();
    for (final entity in entities) {
      try {
        await entity.delete(recursive: true);
      } catch (_) {}
    }
  }
}
