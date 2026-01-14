import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class CalculatorKeyboard extends StatelessWidget {
  final void Function(String) onKeyTap;

  const CalculatorKeyboard({super.key, required this.onKeyTap});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = context.isDark
        ? context.colors.secondaryContainer
        : context.colors.secondaryContainer;

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 4,
      mainAxisSpacing: 4.0,
      crossAxisSpacing: 4.0,
      childAspectRatio: 1.2,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildKey(
          label: 'AC',
          context: context,
          backgroundColor: backgroundColor,
        ),
        _buildKey(
          label: '÷',
          context: context,
          backgroundColor: backgroundColor,
        ),
        _buildKey(
          label: '×',
          context: context,
          backgroundColor: backgroundColor,
        ),
        _buildKey(
          label: 'DEL',
          context: context,
          backgroundColor: backgroundColor,
        ),

        _buildKey(context: context, label: '7'),
        _buildKey(context: context, label: '8'),
        _buildKey(context: context, label: '9'),
        _buildKey(context: context, label: '()'),

        _buildKey(context: context, label: '4'),
        _buildKey(context: context, label: '5'),
        _buildKey(context: context, label: '6'),
        _buildKey(context: context, label: '-'),

        _buildKey(context: context, label: '1'),
        _buildKey(context: context, label: '2'),
        _buildKey(context: context, label: '3'),
        _buildKey(context: context, label: '+'),

        _buildKey(context: context, label: '.'),
        _buildKey(context: context, label: '0'),
        _buildKey(context: context, label: '='),
        _buildKey(
          context: context,
          label: '✓',
          backgroundColor: backgroundColor,
        ),
      ],
    );
  }

  BounceWidget _buildKey({
    required BuildContext context,
    required String label,
    Color? backgroundColor,
  }) => BounceWidget.withTap(
    onTap: () => onKeyTap(label),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: context.radius.cornerRadius100,
        color: backgroundColor ?? context.colors.outlineVariant,
      ),
      child: Center(
        child: Text(
          label,
          style: context.typography.bodyLarge?.copyWith(
            fontWeight: .w800,
            color: context.colors.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
      ),
    ),
  );
}
