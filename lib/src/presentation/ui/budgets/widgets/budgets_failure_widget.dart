import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/icons/background_icon_widget.dart';

class BudgetsFailureWidget extends StatelessWidget {
  final VoidCallback onRetry;

  const BudgetsFailureWidget({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const .all(24.0),
    child: Column(
      spacing: 12.0,
      mainAxisSize: .min,
      mainAxisAlignment: .center,
      crossAxisAlignment: .center,
      children: [
        BackgroundIconWidget(
          icon: Icons.error_outline,
          color: context.colors.error,
        ),
        Text(
          'Não foi possível carregar os orçamentos.',
          textAlign: .center,
          style: context.typography.titleMedium?.copyWith(
            fontWeight: .w600,
            color: context.colors.onSurface,
          ),
        ),
        ButtonWidget.text(onTap: onRetry, label: 'Tentar novamente'),
      ],
    ),
  );
}
