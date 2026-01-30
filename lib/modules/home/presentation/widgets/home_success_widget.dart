import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/home/domain/models/home_model.dart';
import 'package:trocado/modules/home/domain/models/balance_model.dart';

import 'package:trocado/modules/home/presentation/widgets/home_empty_widget.dart';
import 'package:trocado/modules/home/presentation/widgets/balance/balance_widget.dart';
import 'package:trocado/modules/home/presentation/widgets/transaction/transaction_widget.dart';

class HomeTransactionSuccessWidget extends StatelessWidget {
  final HomeModel data;
  final bool isLoadingMore;
  final bool hasReachedEnd;
  final VoidCallback onLoadMore;
  final TransactionTypeModel? type;
  final ValueChanged<int> onDelete;
  final ValueChanged<int?> onPress;
  final String Function(double value) format;
  final TransactionDto Function(TransactionModel) toDto;

  const HomeTransactionSuccessWidget({
    super.key,
    required this.data,
    required this.toDto,
    required this.format,
    required this.onPress,
    required this.onDelete,
    required this.onLoadMore,
    this.type,
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const .symmetric(horizontal: 16.0),
      sliver: data.transactions.isEmpty
          ? _buildEmpty()
          : SliverList(
              delegate: SliverChildBuilderDelegate(
                childCount: data.transactions.length + (hasReachedEnd ? 0 : 1),
                (_, index) {
                  if (index >= data.transactions.length) {
                    if (!isLoadingMore) addPostFrameCallback(onLoadMore);
                    return _buildLoading();
                  }

                  return TransactionWidget(
                    format: format,
                    onPress: onPress,
                    onDelete: onDelete,
                    dto: toDto(data.transactions[index]),
                  );
                },
              ),
            ),
    );
  }

  Padding _buildLoading() => const Padding(
    padding: .symmetric(vertical: 16.0),
    child: CircularProgressIndicatorWidget(),
  );

  SliverFillRemaining _buildEmpty() => SliverFillRemaining(
    hasScrollBody: false,
    child: HomeEmptyWidget(type: type),
  );
}

class HomeBalaceSuccessWidget extends StatelessWidget {
  final BalanceModel model;
  final TransactionTypeModel? type;
  final ValueChanged<TransactionTypeModel?> onPress;

  const HomeBalaceSuccessWidget({
    super.key,
    required this.type,
    required this.model,
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
          dto: .total(amount: model.total),
        ),
        Row(
          spacing: 16.0,
          children: [
            Expanded(
              child: BalanceWidget(
                onPress: onPress,
                isSelected: type == .income,
                dto: .income(amount: model.income),
              ),
            ),
            Expanded(
              child: BalanceWidget(
                onPress: onPress,
                isSelected: type == .expense,
                dto: .expense(amount: model.expense),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
