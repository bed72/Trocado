import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/home/presentation/states/transaction_state.dart';
import 'package:trocado/modules/home/presentation/widgets/transaction/transaction_widget.dart';

class TransactionsWidget extends StatelessWidget {
  final List<TransactionState> items;

  const TransactionsWidget({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 16.0,
      mainAxisSize: .max,
      crossAxisAlignment: .start,
      children: [
        Text(
          'Transações recentes',
          style: context.typography.bodyMedium?.copyWith(fontWeight: .w600),
        ),

        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (_, index) => TransactionWidget(state: items[index]),
          ),
        ),
      ],
    );
  }
}
