import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

class SettingsLogoutWidget extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const SettingsLogoutWidget({
    super.key,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: .infinity,
    padding: const .only(top: 16.0),
    child: ButtonWidget.danger(
      label: 'Sair',
      isLoading: isLoading,
      onTap: isLoading ? null : onTap,
    ),
  );
}
