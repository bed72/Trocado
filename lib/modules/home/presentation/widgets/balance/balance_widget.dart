import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/home/data/dtos/balance_dto.dart';

class BalanceWidget extends StatelessWidget {
  final BalanceDto state;

  const BalanceWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final color = switch (state.type) {
      .income => context.colors.primary,
      .expense => context.colors.error,
      null => context.colors.onSurfaceVariant,
    };

    final icon = switch (state.type) {
      .expense => Icons.south_east,
      .income => Icons.arrow_outward,
      null => Icons.info,
    };

    return Card(
      elevation: 0.0,
      child: Container(
        margin: .all(8.0),
        padding: .all(16.0),
        child: Column(
          spacing: 16.0,
          mainAxisSize: .min,
          crossAxisAlignment: state.isTotal ? .center : .start,
          children: [
            Row(
              mainAxisAlignment: state.isTotal ? .center : .spaceBetween,
              children: [
                Text(
                  state.label.toUpperCase(),
                  style: state.isTotal
                      ? context.typography.titleMedium?.copyWith(
                          fontWeight: .w600,
                          color: context.colors.onSurfaceVariant.withValues(
                            alpha: 0.8,
                          ),
                        )
                      : context.typography.labelMedium?.copyWith(
                          fontWeight: .w600,
                          color: context.colors.onSurfaceVariant.withValues(
                            alpha: 0.8,
                          ),
                        ),
                ),
                if (!state.isTotal) _buildIcon(color: color, icon: icon),
              ],
            ),
            Text(
              state.amount,
              style: state.isTotal
                  ? context.typography.titleLarge?.copyWith(
                      fontWeight: state.isTotal ? .w600 : .bold,
                      color: context.colors.onSurfaceVariant,
                    )
                  : context.typography.titleMedium?.copyWith(
                      fontWeight: state.isTotal ? .w600 : .bold,
                      color: context.colors.onSurfaceVariant,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Container _buildIcon({required Color color, required IconData icon}) =>
      Container(
        width: 32.0,
        height: 32.0,
        decoration: BoxDecoration(
          shape: .circle,
          color: color.withValues(alpha: 0.2),
        ),
        child: IconWidget(name: icon, size: 16, color: color),
      );
}
