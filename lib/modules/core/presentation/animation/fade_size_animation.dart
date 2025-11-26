import 'package:flutter/material.dart';

import 'package:trocado/modules/core/presentation/animation/fade_switch_animation.dart';

class FadeSizeSwitcher extends StatelessWidget {
  final Curve curve;
  final Widget child;
  final Duration duration;

  const FadeSizeSwitcher({
    super.key,
    required this.child,
    this.curve = Curves.easeOutCubic,
    this.duration = const Duration(milliseconds: 260),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: duration,
      curve: curve,
      child: FadeSwitchAnimation(
        curve: curve,
        duration: duration,
        child: child,
      ),
    );
  }
}
