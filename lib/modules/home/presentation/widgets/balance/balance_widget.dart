import 'package:flutter/material.dart';
import 'package:animated_digit/animated_digit.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/home/data/dtos/balance_dto.dart';

class BalanceWidget extends StatelessWidget {
  final BalanceDto dto;
  final bool isSelected;
  final ValueChanged<TransactionTypeModel?> onPress;

  const BalanceWidget({
    super.key,
    required this.dto,
    required this.onPress,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (dto.type) {
      .income => context.colors.primary,
      .expense => context.colors.error,
      null => context.colors.onSurfaceVariant,
    };

    final icon = switch (dto.type) {
      .income => Icons.trending_up,
      .expense => Icons.trending_down,
      null => Icons.info,
    };

    return BounceWidget.withOnPress(
      onPress: isSelected ? null : () => onPress(dto.type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: ShapeDecoration(
          color: isSelected
              ? color.withValues(alpha: .4)
              : context.colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: context.radius.cornerRadius300,
            side: isSelected
                ? BorderSide(width: 1.4, color: color.withValues(alpha: .2))
                : BorderSide.none,
          ),
        ),
        child: Card(
          margin: .zero,
          shape: RoundedRectangleBorder(
            borderRadius: context.radius.cornerRadius300,
          ),
          child: Padding(
            padding: const .all(16.0),
            child: Column(
              spacing: 16.0,
              mainAxisSize: .min,
              crossAxisAlignment: dto.isTotal ? .center : .start,
              children: [
                Row(
                  mainAxisAlignment: dto.isTotal ? .center : .spaceBetween,
                  children: [
                    _buildLabel(context),
                    if (!dto.isTotal) _buildIcon(color: color, icon: icon),
                  ],
                ),

                // Text(
                //   dto.amount,
                //   style: dto.isTotal
                //       ? context.typography.titleLarge?.copyWith(
                //           fontWeight: dto.isTotal ? .w600 : .bold,
                //           color: context.colors.onSurfaceVariant,
                //         )
                //       : context.typography.titleMedium?.copyWith(
                //           fontWeight: dto.isTotal ? .w600 : .bold,
                //           color: context.colors.onSurfaceVariant,
                //         ),
                // ),
                _buildValue(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BackgroundIconWidget _buildIcon({
    required Color color,
    required IconData icon,
  }) => BackgroundIconWidget(
    name: icon,
    color: color,
    width: 32.0,
    height: 32.0,
    iconSize: 16.0,
    borderRadius: .circular(12.0),
  );

  Text _buildLabel(BuildContext context) => Text(
    dto.label.toUpperCase(),
    style: dto.isTotal
        ? context.typography.titleMedium?.copyWith(
            fontWeight: .w600,
            color: context.colors.onSurfaceVariant.withValues(alpha: 0.8),
          )
        : context.typography.labelMedium?.copyWith(
            fontWeight: .w600,
            color: context.colors.onSurfaceVariant.withValues(alpha: 0.8),
          ),
  );

  AnimatedDigitWidget _buildValue(BuildContext context) => AnimatedDigitWidget(
    value: 2.000,
    prefix: 'R\$ ',
    fractionDigits: 2,
    separateSymbol: '.',
    decimalSeparator: ',',
    enableSeparator: true,
    duration: const Duration(milliseconds: 400),
    textStyle: dto.isTotal
        ? context.typography.titleLarge?.copyWith(
            fontWeight: .w600,
            color: context.colors.onSurfaceVariant,
          )
        : context.typography.titleMedium?.copyWith(
            fontWeight: .bold,
            color: context.colors.onSurfaceVariant,
          ),
  );
}
