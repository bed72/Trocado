import 'package:flutter/material.dart';
import 'package:trocado/modules/core/core.dart';

final class ButtonDefaultAnimatedDto {
  final double initialWidth;
  final VoidCallback initialOnTap;

  final Widget initialWidget;

  final Widget loadingWidget;

  final Widget successWidget;
  final VoidCallback successOnTap;

  final Widget failureWidget;
  final VoidCallback failureOnTap;

  final ButtonAnimatedController controller;

  ButtonDefaultAnimatedDto({
    required this.controller,
    required this.initialWidth,
    required this.initialOnTap,
    required this.initialWidget,
    required this.loadingWidget,
    required this.successWidget,
    required this.successOnTap,
    required this.failureWidget,
    required this.failureOnTap,
  });
}
