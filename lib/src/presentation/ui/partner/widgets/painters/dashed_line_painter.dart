import 'package:flutter/material.dart';

class DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashGap;
  final double dashLength;
  final double strokeWidth;

  const DashedLinePainter({
    required this.color,
    required this.dashGap,
    required this.dashLength,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = .round
      ..style = .stroke;

    final y = size.height / 2;
    double x = 0;

    while (x < size.width) {
      final next = (x + dashLength).clamp(0.0, size.width);
      canvas.drawLine(Offset(x, y), Offset(next, y), paint);
      x = next + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant DashedLinePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.dashGap != dashGap;
}
