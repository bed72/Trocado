import 'package:flutter/material.dart';

class FadeSwitchAnimation extends StatelessWidget {
  final Curve curve;
  final Widget child;
  final Duration duration;

  const FadeSwitchAnimation({
    super.key,
    required this.child,
    this.curve = Curves.easeOutCubic,
    this.duration = const Duration(milliseconds: 260),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      transitionBuilder: (Widget child, Animation<double> animation) =>
          FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              filterQuality: FilterQuality.high,
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(animation),
              child: child,
            ),
          ),
      child: child,
    );
  }
}
