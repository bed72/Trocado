import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class CoupleNoteWidget extends StatelessWidget {
  final IconData icon;
  final String message;

  const CoupleNoteWidget({
    super.key,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: context.radius.cornerRadius100,
      color: context.colors.primary.withValues(alpha: 0.08),
    ),
    child: ListTile(
      minLeadingWidth: 0.0,
      titleAlignment: .center,
      horizontalTitleGap: 12.0,
      leading: Icon(icon, size: 24.0, color: context.colors.primary),
      contentPadding: const .symmetric(horizontal: 12.0, vertical: 8.0),
      title: Text(
        message,
        style: context.typography.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    ),
  );
}
