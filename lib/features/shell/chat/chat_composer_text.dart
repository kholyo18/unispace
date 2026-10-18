import 'package:flutter/services.dart';

/// Inserts a picker result using the same UTF-16 selection offsets as Flutter.
/// An unfocused field may have no selection; append in that case.
TextEditingValue insertChatComposerText(TextEditingValue value, String text) {
  if (text.isEmpty) return value;
  final selection = value.selection;
  final valid = selection.isValid && selection.end <= value.text.length;
  final start = valid ? selection.start : value.text.length;
  final end = valid ? selection.end : value.text.length;
  return TextEditingValue(
    text: value.text.replaceRange(start, end, text),
    selection: TextSelection.collapsed(offset: start + text.length),
    composing: TextRange.empty,
  );
}
