import 'dart:developer';

import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/date/date.dart';
import 'package:trocado/modules/category/category.dart';
import 'package:trocado/modules/calculator/calculator.dart';

import 'package:trocado/modules/transaction/data/dtos/transaction_dto.dart';
import 'package:trocado/modules/transaction/data/dtos/transaction_parameter_dto.dart';
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
  late TransactionDto _dto;
  late final GlobalKey<FormState> _formKey;

  @override
  void initState() {
    super.initState();

    _dto = TransactionDto.empty();
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
                child: TransactionsFormWidget(dto: _buildParameterDto()),
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

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    log(_dto.toString(), name: 'BED');
  }

  TransactionParameterDto _buildParameterDto() => TransactionParameterDto(
    formKey: _formKey,
    dateCubit: widget.dateCubit,
    categoryCubit: widget.categoryCubit,
    calculatorCubit: widget.caculatorCubit,
    amountValidator: _dto.validateAmount,
    descriptionValidator: _dto.validateDescription,
    navigateToDate: widget.navigateToDate,
    navigateToCategory: widget.navigateToCategory,
    navigateToCalculator: widget.navigateToCalculator,
    onTypeSelected: (int value) {
      _dto = _dto.copyWith(type: .from(value));
    },
    onDateSelected: (DateTime value) {
      _dto = _dto.copyWith(date: value);
    },
    onAmountSelected: (String value) {
      _dto = _dto.copyWith(amount: value);
    },
    onCategorySelected: (String value) {
      _dto = _dto.copyWith(category: .categoryBy(value));
    },
    onDescriptionSelected: (String value) {
      _dto = _dto.copyWith(description: value);
    },
    onObservationSelected: (String value) {
      _dto = _dto.copyWith(observation: value);
    },
  );
}
