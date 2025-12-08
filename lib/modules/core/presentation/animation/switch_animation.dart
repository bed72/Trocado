import 'package:flutter/material.dart';
import 'package:trocado/modules/core/domain/constant/animation_constant.dart';

class SwitchAnimation extends StatelessWidget {
  final Curve curve;
  final Widget child;
  final int milliseconds;
  final AnimationConstant type;

  const SwitchAnimation({
    super.key,
    required this.child,
    this.milliseconds = 300,
    this.curve = Curves.easeOutCubic,
    this.type = AnimationConstant.scale,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      switchInCurve: curve,
      switchOutCurve: curve,
      duration: Duration(milliseconds: milliseconds),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: switch (type) {
          .fade => FadeTransition(opacity: animation, child: child),
          .size => SizeTransition(
            axisAlignment: -1.0,
            sizeFactor: animation,
            child: child,
          ),
          .scale => ScaleTransition(
            filterQuality: .high,
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(animation),
            child: child,
          ),
        },
      ),
      child: child,
    );
  }
}
