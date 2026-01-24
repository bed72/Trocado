import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/date/date.dart';
import 'package:trocado/modules/category/category.dart';
import 'package:trocado/modules/calculator/calculator.dart';
import 'package:trocado/modules/transaction/data/dtos/transaction_dto.dart';

import 'package:trocado/modules/transaction/data/dtos/transaction_type_dto.dart';
import 'package:trocado/modules/transaction/data/dtos/transaction_parameter_dto.dart';

class TransactionsFormWidget extends StatefulWidget {
  final TransactionParameterDto dto;

  const TransactionsFormWidget({super.key, required this.dto});

  @override
  State<TransactionsFormWidget> createState() => _TransactionsFormWidgetState();
}

class _TransactionsFormWidgetState extends State<TransactionsFormWidget> {
  late TransactionTypeDto _type;
  late TransactionDto? _transaction;

  late bool _mustShowDescriptionHelper;
  late bool _mustShowObservationHelper;

  late final DebounceAction _debounce;

  late final TextEditingController _dateController;
  late final TextEditingController _amountController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _observationController;

  @override
  void initState() {
    super.initState();

    _debounce = DebounceAction();

    _mustShowDescriptionHelper = false;
    _mustShowObservationHelper = false;

    _transaction = widget.dto.transaction;
    _type = _transaction?.type ?? .expense;

    _amountController = TextEditingController(
      text: _transaction?.amount.toString(),
    );
    _dateController = TextEditingController(
      text: _transaction?.date.format() ?? DateTime.now().format(),
    );
    _categoryController = TextEditingController(
      text: (_transaction == null)
          ? CategoryDto.other.label
          : _transaction!.category.label,
    );
    _descriptionController = TextEditingController(
      text: _transaction?.description,
    )..addListener(_handleDescriptionInteractions);
    _observationController = TextEditingController(
      text: _transaction?.observation,
    )..addListener(_handleObservatiobInteractions);
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
            validator: widget.dto.transaction?.validateDescription,
            onChanged: (value) =>
                _debounce(() => widget.dto.onDescriptionSelected(value)),
          ),

          BounceWidget.withTap(
            onTap: widget.dto.navigateToCalculator,
            child: BlocListener<CalculatorCubit, CalculatorState>(
              bloc: widget.dto.calculatorCubit,
              listenWhen: (previous, current) =>
                  previous.preview != current.preview,
              listener: (_, state) {
                widget.dto.onAmountSelected(state.amount);
                _amountController.text = state.amount;
              },
              child: TextFormFieldWidget(
                hint: 'R\$',
                readOnly: true,
                absorbing: true,
                placeholder: 'Ex: 72.00',
                controller: _amountController,
                validator: widget.dto.transaction?.validateAmount,
              ),
            ),
          ),

          BounceWidget.withTap(
            onTap: widget.dto.navigateToCategory,
            child: BlocListener<CategoryCubit, CategoryState>(
              bloc: widget.dto.categoryCubit,
              listenWhen: (previous, current) =>
                  previous.category.label != current.category.label,
              listener: (_, state) {
                widget.dto.onCategorySelected(state.category.label);
                _categoryController.text = state.category.label;
              },
              child: TextFormFieldWidget(
                readOnly: true,
                absorbing: true,
                hint: 'Categoria',
                controller: _categoryController,
              ),
            ),
          ),

          BounceWidget.withTap(
            onTap: widget.dto.navigateToDate,
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
            onChanged: (value) =>
                _debounce(() => widget.dto.onObservationSelected(value)),
          ),

          SelectorWidget(
            options: ['Receita', 'Despesa'],
            selected: _type == .income ? 0 : 1,
            onSelected: (value) {
              setState(() {
                _type = .fromByInt(value);
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
