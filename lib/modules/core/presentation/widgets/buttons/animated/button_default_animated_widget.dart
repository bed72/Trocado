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
          child: dto.initialWidget,
          onTap: dto.initialOnTap,
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
        ),

        FailureState: _buildProperties(
          context: context,
          width: 54.0,
          isFailure: true,
          state: 'Failure',
          onTap: dto.failureOnTap,
          child: dto.failureWidget,
        ),
      },
    );
  }

  ButtonAnimatedProperties _buildProperties({
    required BuildContext context,
    required String state,
    required double width,
    required Widget child,
    bool? isFailure,
    VoidCallback? onTap,
  }) {
    Color color = context.colors.primary;

    if (context.isDark) color = context.colors.onPrimary;
    if (isFailure ?? false) color = context.colors.errorContainer;

    return ButtonAnimatedProperties(
      state: state,
      child: child,
      onTap: onTap ?? () {},
      size: Size(width, 54.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.all(Radius.circular(16.0)),
      ),
    );
  }
}
