import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/src/data/dtos/transaction_parameter_dto.dart';
import 'package:trocado/src/domain/models/transaction_model.dart';
import 'package:trocado/src/presentation/actions/callback_action.dart';
import 'package:trocado/src/presentation/cubits/calculator/calculator_cubit.dart';
import 'package:trocado/src/presentation/cubits/category/category_cubit.dart';
import 'package:trocado/src/presentation/cubits/date/date_cubit.dart';
import 'package:trocado/src/presentation/cubits/transaction/transaction_cubit.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/extensions/widget_extension.dart';
import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/icon_button_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/transaction/transactions_form_widget.dart';
import 'package:trocado/src/presentation/widgets/transaction/transactions_listener_widget.dart';

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
  late TransactionModel _model;
  late final GlobalKey<FormState> _formKey;

  bool get _isEditing => widget.id != null;

  @override
  void initState() {
    super.initState();

    widget.categoryCubit.clear();
    widget.transactionCubit.clear();
    _formKey = GlobalKey<FormState>();
    _model = .empty(date: widget.dateCubit.state.date);

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
                setState(() => _model = state.transaction!);
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

  Widget _buildDeleteButton(bool isLoading) => _model.id == null
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

    if (_model.id == null) {
      return _showFailureToast('Não foi possivel deletar a transação');
    }

    widget.transactionCubit.delete(_model.id!);
  }

  void _handleSaveSubmit() {
    hideKeyboard;

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    widget.transactionCubit.save(_model);
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
    transaction: _model,
    dateCubit: widget.dateCubit,
    categoryCubit: widget.categoryCubit,
    calculatorCubit: widget.caculatorCubit,
    parse: widget.transactionCubit.parse,
    format: widget.transactionCubit.format,
    navigateToDate: widget.navigateToDate,
    navigateToCategory: widget.navigateToCategory,
    navigateToCalculator: widget.navigateToCalculator,
    onTypeSelected: (String value) {
      _model = _model.copyWith(type: value);
    },
    onAmountSelected: (double value) {
      _model = _model.copyWith(amount: value);
    },
    onDescriptionSelected: (String value) {
      _model = _model.copyWith(description: value);
    },
    onObservationSelected: (String value) {
      _model = _model.copyWith(observation: value);
    },
    onCategorySelected: (String value) {
      _model = _model.copyWith(category: value);
    },
    onDateSelected: (DateTime value) {
      _model = _model.copyWith(date: value.millisecondsSinceEpoch);
    },
  );
}
