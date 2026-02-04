import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.onChanged,
    this.length = 6,
    this.enabled = true,
  });

  final int length;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleChanged(String value, int index) {
    if (!widget.enabled) return;
    if (value.length > 1) {
      _handlePaste(value);
      return;
    }
    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    widget.onChanged(_currentCode());
  }

  void _handlePaste(String value) {
    final sanitized = value.replaceAll(RegExp(r'\s+'), '');
    if (sanitized.length < 2) return;
    for (var i = 0; i < widget.length; i++) {
      final char = i < sanitized.length ? sanitized[i] : '';
      _controllers[i].text = char;
    }
    _focusNodes.last.requestFocus();
    widget.onChanged(_currentCode());
  }

  String _currentCode() {
    return _controllers.map((c) => c.text).join();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final maxWidth = constraints.maxWidth;
        final totalSpacing = spacing * (widget.length - 1);
        final rawWidth = (maxWidth - totalSpacing) / widget.length;
        final boxWidth = rawWidth.clamp(36.0, 52.0);
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.length, (index) {
              return Padding(
                padding: EdgeInsetsDirectional.only(
                  end: index == widget.length - 1 ? 0 : spacing,
                ),
                child: SizedBox(
                  width: boxWidth,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    enabled: widget.enabled,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    onChanged: (value) => _handleChanged(value, index),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
