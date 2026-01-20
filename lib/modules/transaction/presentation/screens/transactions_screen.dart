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
      listener: (_, state) => switch (state) {
        TransactionSuccess() => _showSuccessToast(),
        TransactionFailure() => _showFailureToast(state.failure),
        _ => {},
      },
      child: ScaffoldWidget(
        appBar: AppBarWidget(title: 'Transações'),
        child: Padding(
          padding: const .all(16.0),
          child: BlocBuilder<TransactionCubit, TransactionState>(
            bloc: widget.transactionCubit,
            builder: (_, state) =>
                _buildContent(isLoading: state is TransactionLoading),
          ),
        ),
      ),
    );
  }

  Column _buildContent({bool isLoading = false}) => Column(
    children: [
      Expanded(
        child: SingleChildScrollView(
          child: TransactionsFormWidget(dto: _buildParameterDto()),
        ),
      ),

      _buildSaveButton(isLoading),
      _buildDeleteButton(isLoading),
    ],
  );

  Container _buildSaveButton(bool isLoading) => Container(
    width: .infinity,
    padding: .only(top: 16.0),
    child: ButtonWidget.elevated(
      label: 'Salvar',
      isLoading: isLoading,
      onTap: _handleSaveSubmit,
    ),
  );

  Widget _buildDeleteButton(bool isLoading) => _dto.id == null
      ? const SizedBox.shrink()
      : Container(
          width: .infinity,
          padding: .only(top: 16.0),
          child: ButtonWidget.outlined(
            label: 'Deletar',
            isLoading: isLoading,
            onTap: _handleDeleteSubmit,
          ),
        );

  void _handleDeleteSubmit() {
    hideKeyboard;
  }

  void _handleSaveSubmit() {
    hideKeyboard;

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    widget.transactionCubit.save(_dto);
  }

  void _showFailureToast(String description) {
    showToastWidget(
      context: context,
      type: .failure,
      description: description,
      title: 'Opps algo aconteceu.',
    );
  }

  void _showSuccessToast() {
    showToastWidget(
      context: context,
      onClose: context.pop,
      title: 'Transação salva.',
      description: 'Já já atualizamos suas finanças.',
    );
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
