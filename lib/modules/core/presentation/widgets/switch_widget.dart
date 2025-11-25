import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class SwitchWidget extends StatelessWidget {
  final bool value;
  final void Function(bool) onChanged;

  const SwitchWidget({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      splashRadius: 0.0,
      padding: .all(0.0),
      onChanged: onChanged,
      activeTrackColor: context.colors.surfaceContainerHigh,
      inactiveTrackColor: context.colors.surfaceContainerHigh,

      activeThumbColor: context.colors.inversePrimary,
      inactiveThumbColor: context.colors.inverseSurface.withAlpha(370),

      trackOutlineWidth: WidgetStateProperty.all(0.0),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    );
  }
}
