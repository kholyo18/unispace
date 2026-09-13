import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

/// The enrollment URI contains a secret. Encoding and painting stay on this device.
class PrivateTotpQr extends StatelessWidget {
  const PrivateTotpQr({super.key, required this.data});
  final String data;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'رمز إعداد تطبيق المصادقة. يمكن استخدام المفتاح النصي أسفله.',
    child: CustomPaint(
      size: const Size.square(220),
      painter: _QrPainter(QrImage(QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M))),
    ),
  );
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.image);
  final QrImage image;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final scale = size.shortestSide / (image.moduleCount + 8);
    final paint = Paint()..color = Colors.black..isAntiAlias = false;
    for (var row = 0; row < image.moduleCount; row++) {
      for (var col = 0; col < image.moduleCount; col++) {
        if (image.isDark(row, col)) {
          canvas.drawRect(Rect.fromLTWH((col + 4) * scale, (row + 4) * scale, scale, scale), paint);
        }
      }
    }
  }
  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) => oldDelegate.image != image;
}
