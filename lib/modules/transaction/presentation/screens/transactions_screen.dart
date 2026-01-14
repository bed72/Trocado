import 'dart:async';

import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class TransactionsScreen extends StatefulWidget {
  final VoidCallback navigateToDate;
  final VoidCallback navigateToCategory;
  final VoidCallback navigateToCalculator;

  const TransactionsScreen({
    super.key,
    required this.navigateToDate,
    required this.navigateToCategory,
    required this.navigateToCalculator,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late final StreamSubscription _subscription;
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();

    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _subscription.cancel();
    _amountController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWidget(
      appBar: AppBarWidget(title: 'Transações'),
      child: Padding(
        padding: const .all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  spacing: 16.0,
                  crossAxisAlignment: .start,
                  children: [
                    TextFormFieldWidget(hint: 'Descrição'),

                    BounceWidget.withTap(
                      onTap: widget.navigateToCalculator,
                      child: TextFormFieldWidget(
                        hint: 'Valor',
                        readOnly: true,
                        absorbing: true,
                        controller: _amountController,
                      ),
                    ),

                    BounceWidget.withTap(
                      onTap: widget.navigateToCategory,
                      child: TextFormFieldWidget(
                        readOnly: true,
                        absorbing: true,
                        hint: 'Categoria',
                        suffixIcon: Icons.open_in_full,
                      ),
                    ),

                    BounceWidget.withTap(
                      onTap: widget.navigateToDate,
                      child: TextFormFieldWidget(
                        hint: 'Data',
                        readOnly: true,
                        absorbing: true,
                        suffixIcon: Icons.open_in_full,
                      ),
                    ),

                    TextFormFieldWidget(hint: 'Observações'),

                    SelectorWidget(
                      options: ['Receita', 'Despesa'],
                      selected: 1,
                      onSelected: (_) {},
                    ),
                  ],
                ),
              ),
            ),

            Container(
              width: .infinity,
              padding: .only(top: 16.0),
              child: ButtonWidget.elevated(onTap: () {}, label: 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
