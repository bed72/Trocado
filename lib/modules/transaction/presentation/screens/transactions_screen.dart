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
import 'package:trocado/modules/transaction/presentation/widgets/transactions_listener_widget.dart';

class TransactionsScreen extends StatefulWidget {
  final int? id;

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
    this.id,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late TransactionDto _dto;
  late final GlobalKey<FormState> _formKey;

  bool get _isEditing => widget.id != null;

  @override
  void initState() {
    super.initState();

    widget.categoryCubit.clear();
    widget.transactionCubit.clear();
    _formKey = GlobalKey<FormState>();
    _dto = .empty(date: widget.dateCubit.state.date);

    if (_isEditing) {
      addPostFrameCallback(() => widget.transactionCubit.find(widget.id!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return TransactionsListenerWidget(
      cubit: widget.transactionCubit,
      child: ScaffoldWidget(
        appBar: AppBarWidget(
          leading: _buildGoBack(),
          title: _isEditing ? 'Editar Transação' : 'Nova Transação',
        ),
        child: Padding(
          padding: const .all(16.0),
          child: BlocConsumer<TransactionCubit, TransactionState>(
            bloc: widget.transactionCubit,
            listenWhen: (_, current) =>
                current is TransactionSuccess && current.transaction != null,
            listener: (_, state) {
              if (state is TransactionSuccess && state.transaction != null) {
                setState(() {
                  _dto = widget.transactionCubit.toTransactionDto(
                    state.transaction!,
                  );
                });
              }
            },
            builder: (_, state) =>
                _buildContent(isLoading: state is TransactionLoading),
          ),
        ),
      ),
    );
  }

  IconButtonWidget _buildGoBack() => IconButtonWidget(
    width: 36.0,
    height: 36.0,
    iconSize: 22.0,
    onPress: context.pop,
    icon: Icons.chevron_left,
    borderRadius: .circular(12.0),
  );

  Column _buildContent({bool isLoading = false}) => Column(
    children: [
      Expanded(
        child: SingleChildScrollView(
          child: TransactionsFormWidget(dto: _buildParameterDto()),
        ),
      ),

      _buildDeleteButton(isLoading),
      _buildSaveButton(isLoading),
    ],
  );

  Container _buildSaveButton(bool isLoading) => Container(
    width: .infinity,
    padding: .only(top: 16.0),
    child: ButtonWidget.outlined(
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
          child: ButtonWidget.elevated(
            label: 'Deletar',
            isLoading: isLoading,
            onTap: _handleDeleteSubmit,
          ),
        );

  void _handleDeleteSubmit() {
    hideKeyboard;

    if (_dto.id == null) {
      return _showFailureToast('Não foi possivel deletar a transação');
    }

    widget.transactionCubit.delete(_dto.id!);
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
      title: 'Ops, algo aconteceu.',
    );
  }

  TransactionParameterDto _buildParameterDto() => TransactionParameterDto(
    formKey: _formKey,
    transaction: _dto,
    dateCubit: widget.dateCubit,
    categoryCubit: widget.categoryCubit,
    calculatorCubit: widget.caculatorCubit,
    parse: widget.transactionCubit.parse,
    format: widget.transactionCubit.format,
    navigateToDate: widget.navigateToDate,
    navigateToCategory: widget.navigateToCategory,
    navigateToCalculator: widget.navigateToCalculator,
    onTypeSelected: (int value) {
      _dto = _dto.copyWith(type: .fromByInt(value));
    },
    onDateSelected: (DateTime value) {
      _dto = _dto.copyWith(date: value);
    },
    onAmountSelected: (double value) {
      _dto = _dto.copyWith(amount: value);
    },
    onDescriptionSelected: (String value) {
      _dto = _dto.copyWith(description: value);
    },
    onObservationSelected: (String value) {
      _dto = _dto.copyWith(observation: value);
    },
    onCategorySelected: (String value) {
      _dto = _dto.copyWith(category: .fromByString(value));
    },
  );
}
