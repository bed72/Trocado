import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

class SettingsLogoutWidget extends StatelessWidget {
  final VoidCallback onTap;

  const SettingsLogoutWidget({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    width: .infinity,
    padding: const .only(top: 16.0),
    child: ButtonWidget.outlined(
      onTap: onTap,
      label: 'Logout',
      child: const Icon(Icons.logout, size: 20.0),
    ),
  );
}
