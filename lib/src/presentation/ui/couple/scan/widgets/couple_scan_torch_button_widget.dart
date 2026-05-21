import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class CoupleScanTorchButtonWidget extends StatelessWidget {
  final bool isOn;
  final VoidCallback onPressed;

  const CoupleScanTorchButtonWidget({
    super.key,
    required this.isOn,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => FloatingActionButton.small(
    onPressed: onPressed,
    backgroundColor: context.colors.surface,
    foregroundColor: context.colors.onSurface,
    child: Icon(isOn ? Icons.flash_off : Icons.flash_on),
  );
}
