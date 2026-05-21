import 'package:flutter/material.dart';

import 'package:trocado/src/domain/models/user_model.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class CoupleScanPartnerPreviewWidget extends StatelessWidget {
  final UserModel partner;

  const CoupleScanPartnerPreviewWidget({super.key, required this.partner});

  @override
  Widget build(BuildContext context) => Container(
    padding: const .all(16.0),
    decoration: BoxDecoration(
      borderRadius: .circular(16.0),
      color: context.colors.surfaceContainer,
    ),
    child: Row(
      spacing: 16.0,
      children: [
        CircleAvatar(
          radius: 28.0,
          backgroundColor: context.colors.primary,
          child: Text(
            _initial(partner.name),
            style: context.typography.titleMedium?.copyWith(
              color: context.colors.onPrimary,
            ),
          ),
        ),
        Expanded(
          child: Column(
            spacing: 4.0,
            crossAxisAlignment: .start,
            children: [
              Text(partner.name, style: context.typography.titleSmall),
              Text(
                partner.email,
                style: context.typography.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  String _initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
  }
}
