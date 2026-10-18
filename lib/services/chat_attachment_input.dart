import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

const chatDocumentMaxBytes = 20 * 1024 * 1024;

String chatDocumentName(String raw) {
  var name = raw
      .split(RegExp(r'[/\\]'))
      .last
      .replaceAll(RegExp(r'[\x00-\x1f\x7f:*?"<>|]'), '_')
      .trim();
  name = name.replaceAll(RegExp(r'[. ]+$'), '');
  if (name.isEmpty) name = 'document';
  if (RegExp(r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\.|$)',
          caseSensitive: false)
      .hasMatch(name)) {
    name = '_$name';
  }
  if (name.length > 180) name = name.substring(0, 180);
  return name;
}

Future<Uint8List> readBoundedChatAttachment(Stream<List<int>> source,
    {required int maxBytes, int? expectedBytes}) async {
  final bytes = BytesBuilder(copy: false);
  var length = 0;
  await for (final chunk in source.timeout(const Duration(seconds: 30))) {
    length += chunk.length;
    if (length > maxBytes) throw const FormatException('Attachment too large');
    bytes.add(chunk);
  }
  if (length == 0 || (expectedBytes != null && length != expectedBytes)) {
    throw const FormatException('Incomplete attachment');
  }
  return bytes.takeBytes();
}

Future<Uint8List> readChatDocument(PlatformFile file) async {
  if (file.size <= 0 || file.size > chatDocumentMaxBytes) {
    throw const FormatException(
        'Document size must be between 1 byte and 20 MB');
  }
  if (file.bytes != null) {
    if (file.bytes!.length != file.size)
      throw const FormatException('Document changed');
    return file.bytes!;
  }
  if (file.path != null) {
    final source = File(file.path!);
    if (await source.length() != file.size)
      throw const FormatException('Document changed');
    return readBoundedChatAttachment(source.openRead(),
        maxBytes: chatDocumentMaxBytes, expectedBytes: file.size);
  }
  if (file.readStream != null) {
    return readBoundedChatAttachment(file.readStream!,
        maxBytes: chatDocumentMaxBytes, expectedBytes: file.size);
  }
  throw const FormatException('Document is unavailable');
}

String? normalizeChatLink(String value) {
  var text = value.trim();
  if (text.isEmpty || text.length > 4096 || RegExp(r'\s').hasMatch(text))
    return null;
  if (!text.contains('://')) {
    if (RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(text)) return null;
    text = 'https://$text';
  }
  final uri = Uri.tryParse(text);
  if (uri == null ||
      !['https', 'http'].contains(uri.scheme) ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) return null;
  return uri.toString();
}
