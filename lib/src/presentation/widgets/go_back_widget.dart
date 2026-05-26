import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/buttons/icon_button_widget.dart';

class GoBackWidget extends StatelessWidget {
  final VoidCallback? onPress;

  const GoBackWidget({super.key, this.onPress});

  @override
  Widget build(BuildContext context) {
    return IconButtonWidget(
      width: 36.0,
      height: 36.0,
      iconSize: 24.0,
      icon: Icons.chevron_left,
      onPress: onPress ?? context.pop,
    );
  }
}
