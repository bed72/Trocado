import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

class ProfileDeleteAccountWidget extends StatelessWidget {
  final VoidCallback onTap;

  const ProfileDeleteAccountWidget({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: .infinity,
      padding: const .only(top: 16.0),
      child: ButtonWidget.elevated(
        onTap: onTap,
        label: 'Apagar conta',
        child: const Icon(Icons.delete_outline, size: 20.0),
      ),
    );
  }
}
