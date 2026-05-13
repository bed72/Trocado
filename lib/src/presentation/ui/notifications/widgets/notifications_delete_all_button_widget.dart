import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/buttons/icon_button_widget.dart';

class NotificationsDeleteAllButtonWidget extends StatelessWidget {
  final VoidCallback onPress;

  const NotificationsDeleteAllButtonWidget({super.key, required this.onPress});

  @override
  Widget build(BuildContext context) => IconButtonWidget(
    width: 36.0,
    height: 36.0,
    iconSize: 18.0,
    onPress: onPress,
    icon: Icons.delete_sweep_outlined,
  );
}
