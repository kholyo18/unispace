class MediaUploadValidation implements Exception {
  const MediaUploadValidation(this.message);
  final String message;
  @override
  String toString() => message;
}

void validateMediaUploadSize(int size, {required bool video}) {
  final limit = video ? 200 : 20;
  if (size <= 0 || size > limit * 1024 * 1024) {
    throw MediaUploadValidation('الملف فارغ أو يتجاوز الحد المسموح: ' + limit.toString() + ' ميغابايت');
  }
}

String postVideoContentType(String extension) {
  const types = {'mp4':'video/mp4','mov':'video/quicktime','m4v':'video/x-m4v',
    'webm':'video/webm','mkv':'video/x-matroska','3gp':'video/3gpp'};
  final type = types[extension.toLowerCase()];
  if (type == null) throw const MediaUploadValidation('صيغة الفيديو غير مدعومة');
  return type;
}
