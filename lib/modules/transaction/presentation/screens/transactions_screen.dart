import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/date/date.dart';
import 'package:trocado/modules/category/category.dart';
import 'package:trocado/modules/calculator/calculator.dart';

import 'package:trocado/modules/transaction/data/dtos/transaction_dto.dart';
import 'package:trocado/modules/transaction/data/dtos/transaction_parameter_dto.dart';
import 'package:trocado/modules/transaction/presentation/cubits/transaction_cubit.dart';
import 'package:trocado/modules/transaction/presentation/widgets/transactions_form_widget.dart';

class TransactionsScreen extends StatefulWidget {
  final TransactionDto? dto;

  final DateCubit dateCubit;
  final CategoryCubit categoryCubit;
  final CalculatorCubit caculatorCubit;
  final TransactionCubit transactionCubit;

  final VoidCallback navigateToDate;
  final VoidCallback navigateToCategory;
  final VoidCallback navigateToCalculator;

  const TransactionsScreen({
    super.key,
    required this.dateCubit,
    required this.categoryCubit,
    required this.caculatorCubit,
    required this.transactionCubit,
    required this.navigateToDate,
    required this.navigateToCategory,
    required this.navigateToCalculator,
    this.dto,
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

    widget.transactionCubit.clear();

    _formKey = GlobalKey<FormState>();
    _dto = widget.dto ?? TransactionDto.empty();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransactionCubit, TransactionState>(
      bloc: widget.transactionCubit,
      listener: (_, state) {
        switch (state) {
          case TransactionSuccess():
            _showSuccessSnackBar();
            // Navigator.of(context).maybePop(); // opcional
            break;

          case TransactionFailure(:final failure):
            _showFailureSnackBar(failure);
            break;

          default:
            break;
        }
      },
      child: ScaffoldWidget(
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

              _buildSaveButton(),
              _buildDeleteButton(),
            ],
          ),
        ),
      ),
    );
  }

  Container _buildSaveButton() => Container(
    width: .infinity,
    padding: .only(top: 16.0),
    child: ButtonWidget.elevated(label: 'Salvar', onTap: _handleSubmit),
  );

  Widget _buildDeleteButton() => _dto.id == null
      ? const SizedBox.shrink()
      : Container(
          width: .infinity,
          padding: .only(top: 16.0),
          child: ButtonWidget.outlined(label: 'Deletar', onTap: _handleSubmit),
        );

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Transação salva.')));
  }

  void _showFailureSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleSubmit() {
    hideKeyboard;

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    widget.transactionCubit.save(_dto);
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
      _dto = _dto.copyWith(amount: double.tryParse(value));
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
