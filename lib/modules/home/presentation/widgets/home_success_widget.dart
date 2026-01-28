import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/home/domain/models/home_model.dart';
import 'package:trocado/modules/home/domain/models/balance_model.dart';

import 'package:trocado/modules/home/presentation/widgets/balance/balance_widget.dart';
import 'package:trocado/modules/home/presentation/widgets/transaction/transaction_widget.dart';

class HomeTransactionSuccessWidget extends StatelessWidget {
  final HomeModel data;
  final ValueChanged<int> onDelete;
  final String Function(double value) format;
  final ValueChanged<TransactionDto> onPress;
  final TransactionDto Function(TransactionModel) toDto;

  const HomeTransactionSuccessWidget({
    super.key,
    required this.data,
    required this.toDto,
    required this.format,
    required this.onPress,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const .symmetric(horizontal: 16.0),
      sliver: data.transactions.isEmpty
          ? _buildEmpty(context)
          : SliverList(
              delegate: SliverChildBuilderDelegate(
                childCount: data.transactions.length,
                (_, index) => TransactionWidget(
                  format: format,
                  onPress: onPress,
                  onDelete: onDelete,
                  dto: toDto(data.transactions[index]),
                ),
              ),
            ),
    );
  }

  Widget _buildEmpty(BuildContext context) => SliverFillRemaining(
    hasScrollBody: false,
    child: Center(
      child: Column(
        spacing: 8.0,
        mainAxisSize: .min,
        children: [
          ImageWidget(height: 220.0, source: AssetsConstant.empty.source),
          Text(
            'Nenhuma transação por aqui 👀',
            textAlign: .center,
            style: context.typography.titleMedium?.copyWith(
              fontWeight: .w800,
              color: context.colors.onSurface.withValues(alpha: 0.8),
            ),
          ),
          Text(
            'Comece adicionando suas receitas ou despesasque elas vão aparecer aqui rapidinho.',
            textAlign: .center,
            style: context.typography.bodyMedium?.copyWith(
              fontWeight: .w600,
              color: context.colors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    ),
  );
}

class HomeBalaceSuccessWidget extends StatelessWidget {
  final BalanceModel model;
  final TransactionTypeDto? type;
  final String Function(double value) format;
  final ValueChanged<TransactionTypeDto?> onPress;

  const HomeBalaceSuccessWidget({
    super.key,
    required this.type,
    required this.model,
    required this.format,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 16.0,
      children: [
        BalanceWidget(
          onPress: onPress,
          isSelected: type == null,
          dto: .total(value: model.total, format: format),
        ),
        Row(
          spacing: 16.0,
          children: [
            Expanded(
              child: BalanceWidget(
                onPress: onPress,
                isSelected: type == .income,
                dto: .income(value: model.income, format: format),
              ),
            ),
            Expanded(
              child: BalanceWidget(
                onPress: onPress,
                isSelected: type == .expense,
                dto: .expense(value: model.expense, format: format),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
