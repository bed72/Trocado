import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class PremiumBadgeWidget extends StatelessWidget {
  const PremiumBadgeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const .symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        borderRadius: .circular(12.0),
        border: .all(color: context.colors.primary),
      ),
      child: Text(
        'PREMIUM',
        style: context.typography.labelSmall?.copyWith(
          fontWeight: .w600,
          color: context.colors.primary,
        ),
      ),
    );
  }
}
