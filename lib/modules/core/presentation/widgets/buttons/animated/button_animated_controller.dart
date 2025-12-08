import 'package:flutter/material.dart';

import 'package:trocado/modules/core/presentation/widgets/buttons/animated/button_animated_state.dart';

final class ButtonAnimatedController
    extends ValueNotifier<ButtonAnimatedState> {
  ButtonAnimatedController() : super(const InitialState());

  void state(ButtonAnimatedState state) {
    value = state;
  }
}
