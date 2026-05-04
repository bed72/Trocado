import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

class ProfileDeleteAccountWidget extends StatelessWidget {
  final VoidCallback onTap;

  const ProfileDeleteAccountWidget({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: .infinity,
      padding: const .only(top: 16.0),
      child: Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(primary: context.colors.error),
        ),
        child: ButtonWidget.outlined(
          label: 'Apagar conta',
          onTap: onTap,
          child: const Icon(Icons.delete_outline, size: 20.0),
        ),
      ),
    );
  }
}
