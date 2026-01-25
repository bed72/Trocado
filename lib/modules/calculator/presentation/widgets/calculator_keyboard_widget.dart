import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class CalculatorKeyboard extends StatelessWidget {
  final void Function(String) onKeyTap;

  const CalculatorKeyboard({super.key, required this.onKeyTap});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = context.colors.secondaryContainer;

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 1.2,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _key(context, '7'),
        _key(context, '8'),
        _key(context, '9'),

        _key(context, '4'),
        _key(context, '5'),
        _key(context, '6'),

        _key(context, '1'),
        _key(context, '2'),
        _key(context, '3'),

        _key(context, '0'),
        _key(context, ','),
        _key(context, ''),

        _key(context, 'AC', backgroundColor),
        _key(context, 'DEL', backgroundColor),
        _key(context, '✓', backgroundColor),
      ],
    );
  }

  BounceWidget _key(
    BuildContext context,
    String label, [
    Color? backgroundColor,
  ]) => BounceWidget.withTap(
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
