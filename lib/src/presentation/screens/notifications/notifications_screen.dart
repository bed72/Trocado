import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldWidget(
    appBar: AppBarWidget(leading: GoBackWidget()),
    child: Padding(
      padding: const .all(16.0),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            'Notificações',
            style: context.typography.headlineMedium?.copyWith(
              fontWeight: .bold,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Acompanhe os alertas e avisos da sua conta.',
            style: context.typography.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24.0),
          const Expanded(child: Placeholder()),
        ],
      ),
    ),
  );
}
