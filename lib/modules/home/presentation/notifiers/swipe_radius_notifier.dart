import 'package:flutter/material.dart';

final class SwipeRadiusNotifier {
  final double deadZone;
  final double maxRadius;
  final ValueNotifier<double> progress;

  SwipeRadiusNotifier({this.maxRadius = 20, this.deadZone = 0.04})
    : progress = ValueNotifier(0.0);

  void dispose() {
    progress.dispose();
  }

  void update(double value) {
    progress.value = value;
  }

  double get radius {
    final clamp = progress.value.clamp(0.0, 1.0);
    final adjusted = clamp < deadZone ? clamp / deadZone : 1.0;

    return maxRadius * (1 - adjusted);
  }
}
