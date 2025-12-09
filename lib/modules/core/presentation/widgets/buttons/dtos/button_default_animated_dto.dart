import 'package:flutter/material.dart';

import 'package:trocado/modules/core/presentation/widgets/buttons/animated/button_animated_controller.dart';

final class ButtonDefaultAnimatedDto {
  final double initialWidth;
  final VoidCallback? initialOnTap;

  final Widget initialWidget;

  final Widget loadingWidget;

  final Widget successWidget;
  final VoidCallback? successOnTap;
  final VoidCallback? onAnimationSuccessEnd;

  final Widget failureWidget;
  final VoidCallback? failureOnTap;
  final VoidCallback? onAnimationFailureEnd;

  final ButtonAnimatedController controller;

  ButtonDefaultAnimatedDto({
    required this.controller,
    required this.initialWidth,
    required this.initialWidget,
    required this.loadingWidget,
    required this.successWidget,
    required this.failureWidget,
    this.initialOnTap,
    this.successOnTap,
    this.failureOnTap,
    this.onAnimationSuccessEnd,
    this.onAnimationFailureEnd,
  });
}
