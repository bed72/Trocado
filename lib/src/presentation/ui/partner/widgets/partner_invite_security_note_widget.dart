import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class PartnerInviteSecurityNoteWidget extends StatelessWidget {
  const PartnerInviteSecurityNoteWidget({super.key});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: context.radius.cornerRadius100,
      color: context.colors.primary.withValues(alpha: 0.08),
    ),
    child: ListTile(
      minLeadingWidth: 0.0,
      horizontalTitleGap: 12.0,
      titleAlignment: .center,
      contentPadding: const .symmetric(horizontal: 12.0, vertical: 8.0),
      leading: Icon(
        Icons.shield_outlined,
        size: 24.0,
        color: context.colors.primary,
      ),
      title: Text(
        'Vocês compartilham orçamentos e despesas, mas senhas e dados de login são individuais.',
        style: context.typography.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    ),
  );
}
