import 'package:flutter/material.dart';

class Skeleton extends StatelessWidget {
  final double? height;
  final double? width;
  final BorderRadiusGeometry? borderRadius;

  const Skeleton({
    super.key,
    this.height,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.grey.shade200,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
    );
  }
}

class SkeletonPost extends StatelessWidget {
  const SkeletonPost({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Skeleton(width: 40, height: 40, borderRadius: BorderRadius.all(Radius.circular(20))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(height: 12, width: 80),
                    const SizedBox(height: 4),
                    Skeleton(height: 10, width: 60),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Skeleton(height: 14, width: 200),
          const SizedBox(height: 8),
          Skeleton(height: 12),
          const SizedBox(height: 4),
          Skeleton(height: 12, width: 150),
          const SizedBox(height: 16),
          Skeleton(height: 150, borderRadius: BorderRadius.circular(12)),
        ],
      ),
    );
  }
}