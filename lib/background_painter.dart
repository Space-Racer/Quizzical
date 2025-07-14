// background_painter.dart
import 'package:flutter/material.dart';

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1) // Subtle white circles
      ..style = PaintingStyle.fill;

    // Draw a few circles for background effect
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.2), 80, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.1), 120, paint);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.9), 100, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.7), 90, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 150, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false; // No need to repaint unless size changes
  }
}
