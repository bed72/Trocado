import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/home/domain/models/home_model.dart';
import 'package:trocado/modules/home/presentation/widgets/transaction/transaction_widget.dart';

class HomeSuccessWidget extends StatelessWidget {
  final HomeModel data;
  final ValueChanged<int> onDelete;
  final ValueChanged<TransactionDto> onPress;
  final TransactionDto Function(TransactionModel) toDto;

  const HomeSuccessWidget({
    super.key,
    required this.data,
    required this.toDto,
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
