import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/date/date.dart';
import 'package:trocado/modules/category/category.dart';
import 'package:trocado/modules/calculator/calculator.dart';

import 'package:trocado/modules/transaction/domain/models/transaction_model.dart';

import 'package:trocado/modules/transaction/data/dtos/transaction_dto.dart';
import 'package:trocado/modules/transaction/data/dtos/transaction_parameter_dto.dart';

class TransactionsFormWidget extends StatefulWidget {
  final TransactionParameterDto dto;

  const TransactionsFormWidget({super.key, required this.dto});

  @override
  State<TransactionsFormWidget> createState() => _TransactionsFormWidgetState();
}

class _TransactionsFormWidgetState extends State<TransactionsFormWidget> {
  late TransactionTypeModel _typeModel;
  late TransactionDto? _transactionDto;

  late bool _mustShowDescriptionHelper;
  late bool _mustShowObservationHelper;

  late final TextEditingController _dateController;
  late final TextEditingController _amountController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _observationController;

  @override
  void initState() {
    super.initState();

    _mustShowDescriptionHelper = false;
    _mustShowObservationHelper = false;

    _transactionDto = widget.dto.transaction;
    _typeModel = _transactionDto?.type ?? .expense;

    _dateController = TextEditingController();
    _amountController = TextEditingController();
    _categoryController = TextEditingController();
    _descriptionController = TextEditingController()
      ..addListener(_handleDescriptionInteractions);
    _observationController = TextEditingController()
      ..addListener(_handleObservatiobInteractions);

    _populateControllers();
  }

  @override
  void didUpdateWidget(covariant TransactionsFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.dto.transaction?.id != widget.dto.transaction?.id) {
      _transactionDto = widget.dto.transaction;
      _typeModel = _transactionDto?.type ?? .expense;
      _populateControllers();
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _descriptionController
      ..removeListener(_handleDescriptionInteractions)
      ..dispose();
    _observationController
      ..removeListener(_handleObservatiobInteractions)
      ..dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.dto.formKey,
      child: Column(
        spacing: 16.0,
        crossAxisAlignment: .start,
        children: [
          TextFormFieldWidget(
            hint: 'Descrição',
            keyboardType: .name,
            placeholder: 'Ex: Café',
            controller: _descriptionController,
            helperWidget: _buildDescriptionHelper(),
            onChanged: widget.dto.onDescriptionSelected,
            validator: widget.dto.transaction?.validateDescription,
          ),

          BounceWidget.withOnPress(
            onPress: widget.dto.navigateToCalculator,
            child: BlocListener<CalculatorCubit, CalculatorState>(
              bloc: widget.dto.calculatorCubit,
              listenWhen: (previous, current) =>
                  previous.amount != current.amount,
              listener: (_, state) {
                widget.dto.onAmountSelected(state.amount);
                _amountController.text = widget.dto.format(state.amount);
              },
              child: TextFormFieldWidget(
                hint: 'Valor',
                readOnly: true,
                absorbing: true,
                placeholder: 'Ex: 72.00',
                controller: _amountController,
                validator: (value) => widget.dto.transaction?.validateAmount(
                  value: value,
                  parse: widget.dto.parse,
                ),
              ),
            ),
          ),

          BounceWidget.withOnPress(
            onPress: widget.dto.navigateToCategory,
            child: BlocListener<CategoryCubit, CategoryState>(
              bloc: widget.dto.categoryCubit,
              listenWhen: (previous, current) =>
                  previous.category.label != current.category.label,
              listener: (_, state) {
                _categoryController.text = state.category.label;
                widget.dto.onCategorySelected(state.category.label);
              },
              child: TextFormFieldWidget(
                readOnly: true,
                absorbing: true,
                hint: 'Categoria',
                controller: _categoryController,
              ),
            ),
          ),

          BounceWidget.withOnPress(
            onPress: widget.dto.navigateToDate,
            child: BlocListener<DateCubit, DateState>(
              bloc: widget.dto.dateCubit,
              listenWhen: (previous, current) =>
                  previous.formatted != current.formatted,
              listener: (_, state) {
                widget.dto.onDateSelected(state.date);
                _dateController.text = state.formatted;
              },
              child: TextFormFieldWidget(
                hint: 'Data',
                readOnly: true,
                absorbing: true,
                controller: _dateController,
              ),
            ),
          ),

          TextFormFieldWidget(
            hint: 'Observações',
            inputAction: .send,
            keyboardType: .name,
            controller: _observationController,
            placeholder: 'Ex: Meio quilo em grão',
            helperWidget: _buildObservationHelper(),
            onChanged: widget.dto.onObservationSelected,
          ),

          SelectorWidget(
            options: ['Receita', 'Despesa'],
            selected: _typeModel == .income ? 0 : 1,
            onSelected: (value) {
              setState(() {
                _typeModel = .fromByInt(value);
                widget.dto.onTypeSelected(value);
              });
            },
          ),
        ],
      ),
    );
  }

  void _handleDescriptionInteractions() {
    setState(() {
      _mustShowDescriptionHelper =
          _descriptionController.text.isNotEmpty &&
          _descriptionController.text.length < 3;
    });
  }

  void _handleObservatiobInteractions() {
    setState(() {
      _mustShowObservationHelper =
          _observationController.text.isNotEmpty &&
          _observationController.text.length < 3;
    });
  }

  void _populateControllers() {
    _dateController.text = _transactionDto?.date.format() ?? '';
    _descriptionController.text = _transactionDto?.description ?? '';
    _observationController.text = _transactionDto?.observation ?? '';
    _categoryController.text =
        _transactionDto?.category.label ?? CategoryModel.other.label;
    _amountController.text = _transactionDto?.amount == null
        ? ''
        : widget.dto.format(_transactionDto!.amount!);
  }

  SwitcherSizeAnimation _buildDescriptionHelper() => SwitcherSizeAnimation(
    child: !_mustShowDescriptionHelper
        ? const SizedBox.shrink(key: ValueKey('description_key'))
        : HelperWidget(title: 'A descrição deve conter ao menos 3 letras.'),
  );

  SwitcherSizeAnimation _buildObservationHelper() => SwitcherSizeAnimation(
    child: !_mustShowObservationHelper
        ? const SizedBox.shrink(key: ValueKey('observation_key'))
        : HelperWidget(title: 'A observação deve conter ao menos 3 letras.'),
  );
}
