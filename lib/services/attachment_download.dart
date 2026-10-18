import 'dart:io';

/// Saves an untrusted attachment name in its own fresh download directory.
/// Never use message metadata as a relative path or replace another download.
Future<File> saveDownloadedAttachment(
  Directory temporaryDirectory,
  String name,
  List<int> bytes,
) async {
  final invalidWindowsName = Platform.isWindows &&
      (name.endsWith('.') ||
          name.endsWith(' ') ||
          RegExp(r'[\\:*?"<>|]').hasMatch(name) ||
          RegExp(r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\.|$)',
                  caseSensitive: false)
              .hasMatch(name));
  if (name.isEmpty ||
      name == '.' ||
      name == '..' ||
      name.contains('/') ||
      name.contains('\u0000') ||
      invalidWindowsName) {
    throw const FormatException('Invalid attachment filename');
  }
  final download = await temporaryDirectory.createTemp('unispace-download-');
  try {
    return await File('${download.path}${Platform.pathSeparator}$name')
        .writeAsBytes(bytes, flush: true);
  } catch (_) {
    await download.delete(recursive: true);
    rethrow;
  }
}

/// Write each bounded chunk directly to disk; delete partial files on failure.
Future<File> streamDownloadedAttachment(
    Directory temporaryDirectory, String name, Stream<List<int>> source,
    {required int maxBytes,
    int? expectedBytes,
    void Function(int)? onProgress}) async {
  if (maxBytes <= 0 ||
      (expectedBytes != null &&
          (expectedBytes <= 0 || expectedBytes > maxBytes))) {
    throw const FormatException('Invalid attachment size');
  }
  final file =
      await saveDownloadedAttachment(temporaryDirectory, name, const []);
  RandomAccessFile? output;
  try {
    output = await file.open(mode: FileMode.write);
    var received = 0;
    await for (final chunk in source.timeout(const Duration(seconds: 30))) {
      received += chunk.length;
      if (received > maxBytes ||
          (expectedBytes != null && received > expectedBytes)) {
        throw const FormatException('Attachment too large');
      }
      await output.writeFrom(chunk);
      onProgress?.call(received);
    }
    if (received == 0 || (expectedBytes != null && received != expectedBytes)) {
      throw const FormatException('Incomplete attachment');
    }
    await output.close();
    output = null;
    return file;
  } catch (_) {
    await output?.close();
    await file.parent.delete(recursive: true);
    rethrow;
  }
}
