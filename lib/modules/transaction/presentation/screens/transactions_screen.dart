import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/date/date.dart';
import 'package:trocado/modules/category/category.dart';
import 'package:trocado/modules/calculator/calculator.dart';

import 'package:trocado/modules/transaction/presentation/widgets/transactions_form_widget.dart';

class TransactionsScreen extends StatefulWidget {
  final DateCubit dateCubit;
  final CategoryCubit categoryCubit;
  final CalculatorCubit caculatorCubit;

  final VoidCallback navigateToDate;
  final VoidCallback navigateToCategory;
  final VoidCallback navigateToCalculator;

  const TransactionsScreen({
    super.key,
    required this.dateCubit,
    required this.categoryCubit,
    required this.caculatorCubit,
    required this.navigateToDate,
    required this.navigateToCategory,
    required this.navigateToCalculator,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late final GlobalKey<FormState> _formKey;

  @override
  void initState() {
    super.initState();

    _formKey = GlobalKey<FormState>();
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
                child: TransactionsFormWidget(
                  formKey: _formKey,
                  dateCubit: widget.dateCubit,
                  categoryCubit: widget.categoryCubit,
                  caculatorCubit: widget.caculatorCubit,
                  navigateToDate: widget.navigateToDate,
                  navigateToCategory: widget.navigateToCategory,
                  navigateToCalculator: widget.navigateToCalculator,
                  onTypeSelected: (value) {},
                ),
              ),
            ),

            Container(
              width: .infinity,
              padding: .only(top: 16.0),
              child: ButtonWidget.elevated(
                label: 'Salvar',
                onTap: _handleSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit() {
    hideKeyboard;
  }
}
