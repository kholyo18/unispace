import 'package:flutter/material.dart';

class ChatProfileAvatar extends StatelessWidget {
  const ChatProfileAvatar({super.key, required this.name, this.photoUrl});
  final String name;
  final String? photoUrl;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fallback = Center(
        child: Text(
            name.trim().isEmpty
                ? '?'
                : name.trim().characters.first.toUpperCase(),
            style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 20)));
    final url = photoUrl?.trim() ?? '';
    return ClipOval(
        child: SizedBox.square(
            dimension: 52,
            child: ColoredBox(
              color: colors.primary.withValues(alpha: .14),
              child: url.isEmpty
                  ? fallback
                  : Image.network(url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => fallback,
                      loadingBuilder: (_, child, progress) =>
                          progress == null ? child : fallback),
            )));
  }
}
