import 'package:flutter/material.dart';
import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/core/presentation/animation/switch_animation.dart';

class SizeAnimation extends StatelessWidget {
  final Curve curve;
  final Widget child;
  final int milliseconds;

  const SizeAnimation({
    super.key,
    required this.child,
    this.milliseconds = 300,
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      curve: curve,
      duration: Duration(milliseconds: milliseconds),
      child: SwitchAnimation(
        curve: curve,
        milliseconds: milliseconds,
        child: child,
      ),
    );
  }
}
