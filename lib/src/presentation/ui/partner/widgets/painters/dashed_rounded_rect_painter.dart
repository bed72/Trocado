import 'package:flutter/material.dart';

class DashedRoundedRectPainter extends CustomPainter {
  final Color color;
  final Radius radius;
  final double dashGap;
  final double dashLength;
  final double strokeWidth;

  const DashedRoundedRectPainter({
    required this.color,
    required this.radius,
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

    final rect = Offset.zero & size;
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, radius));

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedRoundedRectPainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.dashGap != dashGap;
}
