import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class HomeGreetingWidget extends StatelessWidget {
  final String name;

  const HomeGreetingWidget({super.key, required this.name});

  String get _greeting => switch (DateTime.now().hour) {
    >= 5 && < 12 => 'Bom dia',
    >= 12 && < 18 => 'Boa tarde',
    >= 18 => 'Boa noite',
    _ => 'Isso são horas...',
  };

  @override
  Widget build(BuildContext context) => Column(
    spacing: 2.0,
    mainAxisSize: .min,
    crossAxisAlignment: .start,
    children: [
      Text(
        _greeting,
        style: context.typography.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
      Text(
        name,
        maxLines: 1,
        overflow: .ellipsis,
        style: context.typography.titleMedium?.copyWith(
          fontWeight: .w600,
          color: context.colors.onSurface,
        ),
      ),
    ],
  );
}
