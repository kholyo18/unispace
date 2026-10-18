import 'package:flutter/material.dart';

String pollSliderEmoji(double value) {
  if (value < 20) return '😣';
  if (value < 40) return '😕';
  if (value < 60) return '😐';
  if (value < 80) return '🙂';
  return '😍';
}

Color pollSliderColor(double value) {
  if (value < 25) return Colors.redAccent;
  if (value < 50) return Colors.orangeAccent;
  if (value < 75) return const Color(0xFF26A69A);
  return const Color(0xFF00BFA5);
}

/// Result scales use the midpoint for a single answer, unlike builder previews.
List<String> pollScaleEmojis(int requestedSize, {bool alternate = false}) {
  const faces = ['😠', '😞', '😕', '😑', '😐', '🙂', '😊', '😄', '😃', '😁'];
  const alternateFaces = ['😭', '😢', '😐', '🙂', '😄'];
  final source = alternate ? alternateFaces : faces;
  final size = requestedSize.clamp(1, 10);
  return List.generate(size, (index) {
    if (size == 1) return source[source.length ~/ 2];
    return source[((index / (size - 1)) * (source.length - 1)).round()];
  });
}

/// Preserve the callable's existing answer schema, including nested grid values.
Object? serializePollAnswer(dynamic value) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  if (value is DateTime) return value.toIso8601String();
  if (value is TimeOfDay) return {'hour': value.hour, 'minute': value.minute};
  if (value is Set) return value.map(serializePollAnswer).toList();
  if (value is List) return value.map(serializePollAnswer).toList();
  if (value is Map) {
    return value.map(
        (key, answer) => MapEntry(key.toString(), serializePollAnswer(answer)));
  }
  return value.toString();
}
