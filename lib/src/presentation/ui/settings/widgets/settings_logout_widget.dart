import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

class SettingsLogoutWidget extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;

  const SettingsLogoutWidget({
    super.key,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: .infinity,
    padding: const .only(top: 16.0),
    child: ButtonWidget.elevated(
      label: 'Sair',
      isLoading: isLoading,
      onTap: isLoading ? null : onTap,
      child: const Icon(Icons.logout, size: 20.0),
    ),
  );
}
