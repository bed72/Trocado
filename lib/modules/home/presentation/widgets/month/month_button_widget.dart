import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class MonthButtonWidget extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPress;

  const MonthButtonWidget({
    super.key,
    required this.icon,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: .zero,
      onPressed: onPress,
      icon: IconWidget(name: icon),
      style: IconButton.styleFrom(
        backgroundColor: context.colors.surfaceContainerHighest,
      ),
    );
  }
}
