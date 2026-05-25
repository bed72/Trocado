import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/icons/background_icon_widget.dart';

class ChatEmptyWidget extends StatelessWidget {
  const ChatEmptyWidget({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const .symmetric(horizontal: 32.0),
      child: Column(
        spacing: 8.0,
        mainAxisSize: .min,
        children: [
          BackgroundIconWidget(
            width: 64.0,
            height: 64.0,
            iconSize: 30.0,
            icon: Icons.chat_outlined,
            color: context.colors.primary,
          ),
          const SizedBox(height: 8.0),
          Text(
            'Olá! Sou seu assistente financeiro.',
            textAlign: .center,
            style: context.typography.titleMedium?.copyWith(
              color: context.colors.onSurface,
            ),
          ),
          Text(
            'Pergunte sobre seus gastos, orçamentos ou qualquer dúvida financeira.',
            textAlign: .center,
            style: context.typography.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}
