import 'package:flutter/material.dart';

import 'package:trocado/modules/core/presentation/extensions/context_extension.dart';

import 'package:trocado/modules/core/presentation/widgets/buttons/animated/button_animated_state.dart';
import 'package:trocado/modules/core/presentation/widgets/buttons/animated/button_animated_widget.dart';
import 'package:trocado/modules/core/presentation/widgets/buttons/dtos/button_default_animated_dto.dart';
import 'package:trocado/modules/core/presentation/widgets/buttons/animated/button_animated_properties.dart';

class ButtonDefaultAnimatednWidget extends StatelessWidget {
  final ButtonDefaultAnimatedDto dto;

  const ButtonDefaultAnimatednWidget({super.key, required this.dto});

  @override
  Widget build(BuildContext context) {
    return ButtonAnimatedWidget(
      controller: dto.controller,
      states: {
        InitialState: _buildProperties(
          context: context,
          state: 'Initial',
          width: dto.initialWidth,
          onTap: dto.initialOnTap,
          child: dto.initialWidget,
        ),

        LoadingState: _buildProperties(
          context: context,
          width: 54.0,
          state: 'Loading',
          child: dto.loadingWidget,
        ),

        SuccessState: _buildProperties(
          context: context,
          width: 54.0,
          state: 'Success',
          onTap: dto.successOnTap,
          child: dto.successWidget,
          onAnimationEnd: dto.onAnimationSuccessEnd,
        ),

        FailureState: _buildProperties(
          context: context,
          width: 54.0,
          state: 'Failure',
          onTap: dto.failureOnTap,
          child: dto.failureWidget,
          onAnimationEnd: dto.onAnimationFailureEnd,
        ),
      },
    );
  }

  ButtonAnimatedProperties _buildProperties({
    required BuildContext context,
    required String state,
    required double width,
    required Widget child,
    VoidCallback? onTap,
    VoidCallback? onAnimationEnd,
  }) => ButtonAnimatedProperties(
    state: state,
    child: child,
    onTap: onTap ?? () {},
    size: Size(width, 54.0),
    onAnimationEnd: onAnimationEnd,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(16.0)),
      color: context.isDark
          ? context.colors.surfaceContainer.withValues(alpha: .98)
          : context.colors.primary,
    ),
  );
}
