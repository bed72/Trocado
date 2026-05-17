import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class CoupleDissolveHeroWidget extends StatelessWidget {
  const CoupleDissolveHeroWidget({super.key});

  @override
  Widget build(BuildContext context) => Column(
    spacing: 12.0,
    crossAxisAlignment: .center,
    children: [
      Text(
        'Cada um segue seu caminho',
        textAlign: .center,
        style: context.typography.titleLarge?.copyWith(fontWeight: .bold),
      ),
      Text(
        'Seus dados pessoais permanecem, mas vocês deixam de compartilhar despesas e orçamentos.',
        textAlign: .center,
        style: context.typography.bodyMedium?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    ],
  );
}
