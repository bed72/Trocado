import 'package:flutter/material.dart';

import 'package:trocado/modules/core/presentation/animation/switch_animation.dart';

import 'package:trocado/modules/core/presentation/extensions/context_extension.dart';

import 'package:trocado/modules/core/presentation/widgets/bounce_widget.dart';
import 'package:trocado/modules/core/presentation/widgets/buttons/animated/button_animated_state.dart';
import 'package:trocado/modules/core/presentation/widgets/buttons/animated/button_animated_controller.dart';
import 'package:trocado/modules/core/presentation/widgets/buttons/animated/button_animated_properties.dart';

class ButtonAnimatedWidget extends StatefulWidget {
  final int milliseconds;
  final Curve transitionCurve;
  final ButtonAnimatedController controller;
  final Map<Type, ButtonAnimatedProperties> states;

  const ButtonAnimatedWidget({
    super.key,
    required this.states,
    this.milliseconds = 600,
    required this.controller,
    this.transitionCurve = Curves.easeIn,
  });

  @override
  State<ButtonAnimatedWidget> createState() => _ButtonAnimatedWidgetState();
}

class _ButtonAnimatedWidgetState extends State<ButtonAnimatedWidget>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ButtonAnimatedState>(
      valueListenable: widget.controller,
      builder: (_, value, _) {
        final state = widget.states[value.runtimeType]!;

        return BounceWidget.withTap(
          onTap: state.onTap,
          child: AnimatedContainer(
            width: state.size?.width,
            height: state.size?.height,
            alignment: state.alignment,
            onEnd: state.onAnimationEnd,
            decoration: state.decoration,
            curve: widget.transitionCurve,
            clipBehavior: state.clipBehavior,
            transformAlignment: state.transformAlignment,
            foregroundDecoration: state.foregroundDecoration,
            duration: Duration(milliseconds: widget.milliseconds),
            child: AnimatedDefaultTextStyle(
              curve: widget.transitionCurve,
              duration: Duration(milliseconds: widget.milliseconds),
              style:
                  state.textStyle?.copyWith(inherit: true) ??
                  context.typography.bodyMedium!,
              child: SwitchAnimation(
                type: .fade,
                milliseconds: widget.milliseconds,
                child: KeyedSubtree(
                  key: ValueKey<String>(state.state),
                  child: state.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
