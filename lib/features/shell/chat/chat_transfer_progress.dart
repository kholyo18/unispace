import 'package:flutter/material.dart';

/// Shared transfer feedback; unknown totals never display a false percentage.
class ChatTransferProgress extends StatelessWidget {
  const ChatTransferProgress(
      {super.key,
      required this.label,
      this.detail,
      this.progress,
      this.onCancel,
      this.downloading = false});
  final String label;
  final String? detail;
  final double? progress;
  final VoidCallback? onCancel;
  final bool downloading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final value = progress?.clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        Icon(downloading ? Icons.download_rounded : Icons.upload_rounded,
            color: colors.primary),
        const SizedBox(width: 10),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              Row(children: [
                Expanded(
                    child: Text(label,
                        style: TextStyle(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600))),
                if (value != null)
                  Text('${(value * 100).floor()}%',
                      style: TextStyle(color: colors.onSurfaceVariant))
              ]),
              if (detail != null)
                Text(detail!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: colors.onSurfaceVariant, fontSize: 12)),
              const SizedBox(height: 8),
              ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(value: value, minHeight: 4)),
            ])),
        if (onCancel != null)
          IconButton(
              tooltip: MaterialLocalizations.of(context).cancelButtonLabel,
              onPressed: onCancel,
              icon: Icon(Icons.close, color: colors.onSurfaceVariant)),
      ]),
    );
  }
}
