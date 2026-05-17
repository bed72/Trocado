import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class CoupleInviteHeroWidget extends StatelessWidget {
  const CoupleInviteHeroWidget({super.key});

  @override
  Widget build(BuildContext context) => Column(
    spacing: 12.0,
    crossAxisAlignment: .center,
    children: [
      Text(
        'Trocado fica melhor a dois',
        textAlign: .center,
        style: context.typography.titleLarge?.copyWith(fontWeight: .bold),
      ),
      Text(
        'Compartilhem orçamentos, vejam quem gastou o quê sem precisar perguntar.',
        textAlign: .center,
        style: context.typography.bodyMedium?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    ],
  );
}
