import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class StepBoxDecorationWidget extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;

  const StepBoxDecorationWidget({
    super.key,
    required this.child,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerAnimation(
      pause: Duration(seconds: 6),
      duration: Duration(seconds: 4),
      radius: context.radius.cornerRadiusFull,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          shape: .circle,
          color: context.colors.inverseSurface.withValues(alpha: 0.10),
        ),
        child: Center(child: child),
      ),
    );
  }
}
