import 'package:flutter/material.dart';

class IndicatorWidget extends Decoration {
  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _IndicatorBox();
}

class _IndicatorBox extends BoxPainter {
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF717971), Color(0xFF717971)],
      ).createShader(.fromCircle(center: offset, radius: 50))
      ..strokeWidth = 2
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.butt;

    canvas.drawLine(
      Offset(offset.dx, 0.5),
      Offset(configuration.size!.width + offset.dx, 0.5),
      paint,
    );
  }
}
