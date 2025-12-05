import 'package:flutter/material.dart';
import 'package:trocado/modules/core/domain/constant/animation_constant.dart';

class FadeSwitchAnimation extends StatelessWidget {
  final Curve curve;
  final Widget child;
  final Duration duration;
  final AnimationConstant type;

  const FadeSwitchAnimation({
    super.key,
    required this.child,
    this.curve = Curves.easeOutCubic,
    this.type = AnimationConstant.scale,
    this.duration = const Duration(milliseconds: 260),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: switch (type) {
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
