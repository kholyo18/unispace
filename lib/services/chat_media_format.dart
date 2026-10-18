/// Upload metadata for the original media bytes; this does not transcode or
/// fully validate that the file can be decoded on a particular device.
class ChatMediaFormat {
  const ChatMediaFormat(this.extension, this.contentType);

  final String extension;
  final String contentType;
  bool get isGif => contentType == 'image/gif';
}

const _jpeg = ChatMediaFormat('jpg', 'image/jpeg');
const _png = ChatMediaFormat('png', 'image/png');
const _gif = ChatMediaFormat('gif', 'image/gif');
const _webp = ChatMediaFormat('webp', 'image/webp');
const _bmp = ChatMediaFormat('bmp', 'image/bmp');
const _heic = ChatMediaFormat('heic', 'image/heic');
const _heif = ChatMediaFormat('heif', 'image/heif');
const _avif = ChatMediaFormat('avif', 'image/avif');

const _imageExtensions = <String, ChatMediaFormat>{
  'jpg': _jpeg,
  'jpeg': _jpeg,
  'png': _png,
  'gif': _gif,
  'webp': _webp,
  'bmp': _bmp,
  'heic': _heic,
  'heif': _heif,
  'avif': _avif,
};

const _videoExtensions = <String, ChatMediaFormat>{
  'mp4': ChatMediaFormat('mp4', 'video/mp4'),
  'mov': ChatMediaFormat('mov', 'video/quicktime'),
  'm4v': ChatMediaFormat('m4v', 'video/x-m4v'),
  'webm': ChatMediaFormat('webm', 'video/webm'),
  'mkv': ChatMediaFormat('mkv', 'video/x-matroska'),
  '3gp': ChatMediaFormat('3gp', 'video/3gpp'),
};

String _extension(String path) {
  final basename = path.replaceAll('\\', '/').split('/').last;
  final dot = basename.lastIndexOf('.');
  return dot < 0 ? '' : basename.substring(dot + 1).toLowerCase();
}

bool _matches(List<int> bytes, List<int> magic, [int offset = 0]) {
  if (bytes.length < offset + magic.length) return false;
  for (var i = 0; i < magic.length; i++) {
    if (bytes[offset + i] != magic[i]) return false;
  }
  return true;
}

ChatMediaFormat? _isoImageFormat(List<int> bytes) {
  if (bytes.length < 16 || !_matches(bytes, 'ftyp'.codeUnits, 4)) {
    return null;
  }
  final boxSize = (bytes[0] << 24) |
      (bytes[1] << 16) |
      (bytes[2] << 8) |
      bytes[3];
  if (boxSize < 16) return null;
  final end = boxSize < bytes.length ? boxSize : bytes.length;
  final brands = <String>{String.fromCharCodes(bytes.sublist(8, 12))};
  // Offset 12 is the minor version, not another brand.
  for (var offset = 16; offset + 4 <= end; offset += 4) {
    brands.add(String.fromCharCodes(bytes.sublist(offset, offset + 4)));
  }
  if (brands.contains('avif') || brands.contains('avis')) return _avif;
  if (brands.contains('heic') || brands.contains('heix') ||
      brands.contains('hevc') || brands.contains('hevx')) {
    return _heic;
  }
  if (brands.contains('mif1') || brands.contains('msf1')) return _heif;
  return null;
}

/// Prefer recognizable bytes to a misleading picker filename. If no supported
/// signature is available, only an explicitly supported extension is accepted.
/// Throws [FormatException] rather than silently relabeling unknown bytes JPEG.
ChatMediaFormat detectChatImageFormat(List<int> bytes, String path) {
  if (_matches(bytes, const [0x89, 0x50, 0x4e, 0x47, 13, 10, 26, 10])) {
    return _png;
  }
  if (_matches(bytes, 'GIF87a'.codeUnits) ||
      _matches(bytes, 'GIF89a'.codeUnits)) {
    return _gif;
  }
  if (_matches(bytes, const [0xff, 0xd8, 0xff])) return _jpeg;
  if (_matches(bytes, 'RIFF'.codeUnits) &&
      _matches(bytes, 'WEBP'.codeUnits, 8)) {
    return _webp;
  }
  if (_matches(bytes, 'BM'.codeUnits)) return _bmp;
  final iso = _isoImageFormat(bytes);
  if (iso != null) return iso;
  final fallback = _imageExtensions[_extension(path)];
  if (fallback != null) return fallback;
  throw const FormatException('Unsupported chat image format');
}

/// Preserves the known container type. Changing the filename cannot transcode
/// a MOV/WebM recording into MP4.
ChatMediaFormat detectChatVideoFormat(String path) {
  final format = _videoExtensions[_extension(path)];
  if (format != null) return format;
  throw const FormatException('Unsupported chat video format');
}
