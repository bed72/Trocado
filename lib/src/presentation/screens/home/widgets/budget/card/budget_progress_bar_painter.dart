import 'dart:math';

import 'package:flutter/material.dart';

class BudgetProgressBarPainter extends CustomPainter {
  final Color fillColor;
  final Color trackColor;
  final Color thumbColor;
  final double percentage;

  const BudgetProgressBarPainter({
    required this.fillColor,
    required this.trackColor,
    required this.thumbColor,
    required this.percentage,
  });

  final double _thumbWidth = 6.0;
  final double _thumbHeight = 22.0;
  final double _trackHeight = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final trackTop = centerY - _trackHeight / 2;
    final trackBottom = centerY + _trackHeight / 2;
    const roundedEnd = Radius.circular(2);
    final roundedStart = Radius.circular(_trackHeight / 2);

    canvas.drawRRect(
      RRect.fromLTRBR(0, trackTop, size.width, trackBottom, roundedStart),
      Paint()..color = trackColor,
    );

    final fillWidth = size.width * percentage;
    final isComplete = percentage >= 1.0;
    if (fillWidth > 0) {
      canvas.drawRRect(
        RRect.fromLTRBAndCorners(
          0,
          trackTop,
          isComplete ? size.width : max(fillWidth, _trackHeight) - 4,
          trackBottom,
          topLeft: roundedStart,
          topRight: isComplete ? roundedStart : roundedEnd,
          bottomRight: isComplete ? roundedStart : roundedEnd,
          bottomLeft: roundedStart,
        ),
        Paint()..color = fillColor,
      );
    }

    if (percentage > 0.04 && percentage < 0.99) {
      final thumbX = fillWidth.clamp(0.0, size.width);
      canvas.drawRRect(
        RRect.fromLTRBR(
          thumbX - _thumbWidth / 2,
          centerY - _thumbHeight / 2,
          thumbX + _thumbWidth / 2,
          centerY + _thumbHeight / 2,
          .circular(_thumbWidth / 2),
        ),
        Paint()..color = thumbColor,
      );
    }
  }

  @override
  bool shouldRepaint(BudgetProgressBarPainter old) =>
      old.percentage != percentage || old.fillColor != fillColor;
}
