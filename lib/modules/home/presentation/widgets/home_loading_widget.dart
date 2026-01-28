import 'package:flutter/widgets.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/home/data/dtos/balance_dto.dart';

import 'package:trocado/modules/home/presentation/widgets/balance/balance_widget.dart';
import 'package:trocado/modules/home/presentation/widgets/transaction/transaction_widget.dart';

class HomeTransactionLoadingWidget extends StatelessWidget {
  const HomeTransactionLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SkeletonWidget(
        child: Column(
          children: .generate(
            10,
            (_) => TransactionWidget(
              dto: .empty(),
              onPress: (_) {},
              onDelete: (_) {},
              format: (_) => '',
            ),
          ),
        ),
      ),
    );
  }
}

class HomeBalanceLoadingWidget extends StatelessWidget {
  const HomeBalanceLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonWidget(
      child: Column(
        spacing: 16.0,
        children: [
          BalanceWidget(
            isSelected: false,
            onPress: (value) {},
            dto: BalanceDto.empty(label: 'Total', amount: 'R\$ 1.000,00'),
          ),
          Row(
            spacing: 16.0,
            children: [
              Expanded(
                child: BalanceWidget(
                  isSelected: false,
                  onPress: (value) {},
                  dto: BalanceDto.empty(
                    type: .income,
                    label: 'Receita',
                    amount: 'R\$ 10.000,00',
                  ),
                ),
              ),
              Expanded(
                child: BalanceWidget(
                  isSelected: false,
                  onPress: (value) {},
                  dto: BalanceDto.empty(
                    type: .expense,
                    label: 'Despesa',
                    amount: 'R\$ 1.000,00',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
