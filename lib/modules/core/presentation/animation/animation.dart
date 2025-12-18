import 'package:flutter/widgets.dart';

const _duration = Duration(milliseconds: 300);

class SwitcherAnimation extends StatelessWidget {
  final Widget child;

  const SwitcherAnimation({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: _duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: child,
    );
  }
}

class SwicherSizeAnimation extends StatelessWidget {
  final Widget child;

  const SwicherSizeAnimation({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: _duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => SizeTransition(
        axisAlignment: -1.0,
        sizeFactor: animation,
        child: child,
      ),
      child: child,
    );
  }
}

class SlideAnimation extends StatelessWidget {
  final Widget child;
  final bool condition;

  const SlideAnimation({
    super.key,
    required this.child,
    required this.condition,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      curve: Curves.decelerate,
      duration: _duration,
      offset: condition ? const Offset(0, 1) : .zero,
      child: AnimatedOpacity(
        duration: _duration,
        opacity: condition ? 0 : 1,
        child: child,
      ),
    );
  }
}
