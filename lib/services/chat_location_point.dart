/// A one-time position, never a live tracking subscription.
class ChatLocationPoint {
  const ChatLocationPoint(this.latitude, this.longitude, {this.accuracy});
  final double latitude, longitude;
  final double? accuracy;
  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180;
  bool get hasAccuracy =>
      accuracy != null && accuracy!.isFinite && accuracy! >= 0;
  String get coordinates =>
      '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';
  String get mapsLink =>
      'https://www.google.com/maps/search/?api=1&query=$coordinates';

  /// Recognize only coordinate links emitted by the location composer.
  /// Arbitrary URLs and place-name searches remain ordinary chat text.
  static ChatLocationPoint? fromMapsLink(String text) {
    try {
      final uri = Uri.tryParse(text.trim());
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host != 'www.google.com' ||
          uri.userInfo.isNotEmpty ||
          uri.hasPort ||
          uri.hasFragment ||
          uri.path != '/maps/search/' ||
          uri.queryParametersAll.length != 2 ||
          uri.queryParametersAll.values.any((values) => values.length != 1) ||
          uri.queryParameters['api'] != '1') return null;
      final values = uri.queryParameters['query']?.split(',');
      if (values == null || values.length != 2) return null;
      final latitude = double.tryParse(values[0]);
      final longitude = double.tryParse(values[1]);
      if (latitude == null || longitude == null) return null;
      final point = ChatLocationPoint(latitude, longitude);
      return point.isValid ? point : null;
    } on FormatException {
      return null;
    }
  }
}
