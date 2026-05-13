import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String description,
  bool isDestructive = true,
  String denyLabel = 'Cancelar',
  String confirmLabel = 'Confirmar',
}) async {
  final data = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (_) => ConfirmDialogWidget(
      title: title,
      denyLabel: denyLabel,
      description: description,
      confirmLabel: confirmLabel,
      isDestructive: isDestructive,
    ),
  );

  return data ?? false;
}

class ConfirmDialogWidget extends StatelessWidget {
  final String title;
  final String denyLabel;
  final String description;
  final bool isDestructive;
  final String confirmLabel;

  const ConfirmDialogWidget({
    super.key,
    required this.title,
    required this.description,
    this.isDestructive = true,
    this.denyLabel = 'Cancelar',
    this.confirmLabel = 'Confirmar',
  });

  @override
  Widget build(BuildContext context) => AlertDialog(
    elevation: 0.0,
    backgroundColor: context.colors.surface,
    titlePadding: const .fromLTRB(24.0, 24.0, 24.0, 8.0),
    contentPadding: const .fromLTRB(24.0, 0.0, 24.0, 24.0),
    actionsPadding: const .fromLTRB(24.0, 0.0, 24.0, 24.0),
    insetPadding: const .symmetric(horizontal: 24.0, vertical: 24.0),
    title: Text(
      title,
      style: context.typography.titleLarge?.copyWith(fontWeight: .bold),
    ),
    content: Text(
      description,
      style: context.typography.bodyMedium?.copyWith(
        color: context.colors.onSurfaceVariant,
      ),
    ),
    actions: [
      Row(
        spacing: 12.0,
        children: [
          Expanded(
            child: ButtonWidget.outlined(
              label: denyLabel,
              onTap: () => context.pop(false),
            ),
          ),

          Expanded(
            child: isDestructive
                ? ButtonWidget.danger(
                    label: confirmLabel,
                    onTap: () => context.pop(true),
                  )
                : ButtonWidget.elevated(
                    label: confirmLabel,
                    onTap: () => context.pop(true),
                  ),
          ),
        ],
      ),
    ],
  );
}
