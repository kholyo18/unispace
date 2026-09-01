import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/branding.dart';

class _UniSpaceBottomTabItem {
  const _UniSpaceBottomTabItem({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

class ModernUniSpaceBottomBar extends StatefulWidget {
  const ModernUniSpaceBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  static  List<_UniSpaceBottomTabItem> _items = [
    _UniSpaceBottomTabItem(
      label: 'المجتمع',
      icon: Icons.groups_rounded,
      color: Color(0xFF8B5CF6),
    ),

    _UniSpaceBottomTabItem(
      label: 'الدردشة',
      icon: Icons.chat_bubble_rounded,
      color: AppTeal.chat,
    ),
    _UniSpaceBottomTabItem(
      label: 'الرئيسية',
      icon: Icons.home_rounded,
      color: Color(0xFF2563EB),
    ),
  ];

  @override
  State<ModernUniSpaceBottomBar> createState() =>
      _ModernUniSpaceBottomBarState();
}

class _ModernUniSpaceBottomBarState extends State<ModernUniSpaceBottomBar> {
  bool _dragging = false;
  int? _hoverIndex;

  int get _visualIndex => _hoverIndex ?? widget.selectedIndex;

  int _indexFromLocalX(double localX, double width) {
    if (width <= 0) return widget.selectedIndex;
    final i = (localX / (width / ModernUniSpaceBottomBar._items.length)).floor();
    return i.clamp(0, ModernUniSpaceBottomBar._items.length - 1);
  }

  void _commit(int index) {
    if (index != widget.selectedIndex) {
      widget.onTabSelected(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final items = ModernUniSpaceBottomBar._items;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 15),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final tabW = constraints.maxWidth / items.length;

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (d) {
                        _commit(_indexFromLocalX(d.localPosition.dx, constraints.maxWidth));
                      },
                      onLongPressStart: (d) {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          _dragging = true;
                          _hoverIndex = _indexFromLocalX(
                            d.localPosition.dx,
                            constraints.maxWidth,
                          );
                        });
                      },
                      onLongPressMoveUpdate: (d) {
                        final next = _indexFromLocalX(
                          d.localPosition.dx,
                          constraints.maxWidth,
                        );
                        if (next != _hoverIndex) {
                          HapticFeedback.selectionClick();
                          setState(() => _hoverIndex = next);
                          _commit(next); // يغيّر الواجهة أثناء السحب
                        }
                      },
                      onLongPressEnd: (_) {
                        final i = _hoverIndex ?? widget.selectedIndex;
                        _commit(i);
                        setState(() {
                          _dragging = false;
                          _hoverIndex = null;
                        });
                      },
                      onLongPressCancel: () {
                        setState(() {
                          _dragging = false;
                          _hoverIndex = null;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        height: _dragging ? 50 : 45,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                              Colors.white.withValues(alpha: 0.22),
                              Colors.white.withValues(alpha: 0.18),
                            ]
                                : [
                              Colors.white.withValues(alpha: 0.16),
                              Colors.white.withValues(alpha: 0.45),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.16)
                                : Colors.white.withValues(alpha: 0.6),
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.32 : 0.10),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // مؤشر ينزاح مع التبويب
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              left: _visualIndex * tabW,
                              top: 0,
                              bottom: 0,
                              width: tabW,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 3, vertical: 1),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: items[_visualIndex]
                                        .color
                                        .withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: List.generate(items.length, (index) {
                                final item = items[index];
                                final selected = _visualIndex == index;
                                return Expanded(
                                  child: Center(
                                    child: AnimatedScale(
                                      scale: selected ? 1.12 : 1.0,
                                      duration:
                                      const Duration(milliseconds: 180),
                                      curve: Curves.easeOutCubic,
                                      child: Icon(
                                        item.icon,
                                        size: 20,
                                        color: selected
                                            ? item.color
                                            : theme.colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.55),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
