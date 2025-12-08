import 'package:flutter/material.dart';

final class ButtonAnimatedProperties {
  final Widget child;
  final String state;
  final Clip clipBehavior;
  final VoidCallback onTap;
  final BoxDecoration decoration;
  final AlignmentGeometry alignment;

  final Size? size;
  final TextStyle? textStyle;
  final VoidCallback? onAnimationEnd;
  final Decoration? foregroundDecoration;
  final AlignmentGeometry? transformAlignment;

  const ButtonAnimatedProperties({
    required this.state,
    required this.onTap,
    required this.decoration,
    this.size,
    this.textStyle,
    this.onAnimationEnd,
    this.transformAlignment,
    this.foregroundDecoration,
    this.clipBehavior = Clip.none,
    this.alignment = Alignment.center,
    this.child = const SizedBox.shrink(),
  });
}
