import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class TransactionsScreen extends StatelessWidget {
  final VoidCallback navigateToDate;
  final VoidCallback navigateToCategory;

  const TransactionsScreen({
    super.key,
    required this.navigateToDate,
    required this.navigateToCategory,
  });

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

                    TextFormFieldWidget(hint: 'Valor'),

                    BounceWidget.withTap(
                      onTap: navigateToCategory,
                      child: TextFormFieldWidget(
                        readOnly: true,
                        absorbing: true,
                        hint: 'Categoria',
                        suffixIcon: Icons.open_in_full,
                      ),
                    ),

                    BounceWidget.withTap(
                      onTap: navigateToDate,
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
