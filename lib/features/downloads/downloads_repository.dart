import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'download_item.dart';

class DownloadsRepository {
  const DownloadsRepository();

  static const String _downloadsFolderName = 'downloads';
  static const String _cacheFolderName = 'unispace_cache';

  Future<Directory> _downloadsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory(p.join(appDir.path, _downloadsFolderName));
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    return downloadsDir;
  }

  Future<Directory> _cacheDirectory() async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory(p.join(tempDir.path, _cacheFolderName));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  Future<List<DownloadItem>> listDownloads() async {
    final dir = await _downloadsDirectory();
    final items = <DownloadItem>[];
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          items.add(await DownloadItem.fromFile(entity));
        } catch (_) {
          // Skip unreadable files but keep listing.
        }
      }
    }
    return items;
  }

  Future<int> computeDownloadsSizeBytes() async {
    final dir = await _downloadsDirectory();
    return _directorySizeBytes(dir);
  }

  Future<int> computeCacheSizeBytes() async {
    final dir = await _cacheDirectory();
    return _directorySizeBytes(dir);
  }

  Future<void> deleteDownload(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> clearCache() async {
    final dir = await _cacheDirectory();
    await _deleteDirectoryContents(dir);
  }

  Future<void> clearAllDownloads() async {
    final dir = await _downloadsDirectory();
    await _deleteDirectoryContents(dir);
  }

  Future<int> _directorySizeBytes(Directory dir) async {
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {
          // Skip unreadable files.
        }
      }
    }
    return total;
  }

  Future<void> _deleteDirectoryContents(Directory dir) async {
    if (!await dir.exists()) {
      return;
    }
    await for (final entity in dir.list(recursive: false, followLinks: false)) {
      try {
        await entity.delete(recursive: true);
      } catch (_) {
        // Best-effort deletion.
      }
    }
  }
}
