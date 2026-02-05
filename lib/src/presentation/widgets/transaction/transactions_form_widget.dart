import 'package:flutter/material.dart';

import 'package:trocado/src/domain/models/category_model.dart';
import 'package:trocado/src/domain/models/transaction_model.dart';

import 'package:trocado/src/presentation/animation/animation.dart';
import 'package:trocado/src/presentation/extensions/int_time_extension.dart';

import 'package:trocado/src/presentation/notifiers/transaction/transaction_notifier.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/helper_widget.dart';
import 'package:trocado/src/presentation/widgets/selectors/selector_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_form_field_widget.dart';

class TransactionsFormWidget extends StatefulWidget {
  final TransactionParameterDto dto;

  const TransactionsFormWidget({super.key, required this.dto});

  @override
  State<TransactionsFormWidget> createState() => _TransactionsFormWidgetState();
}

class _TransactionsFormWidgetState extends State<TransactionsFormWidget> {
  late TransactionTypeModel _typeModel;
  late TransactionModel? _transactionModel;

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

    _transactionModel = widget.dto.transaction;
    _typeModel = .fromByString(
      _transactionModel?.type ?? TransactionTypeModel.expense.label,
    );

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
      _transactionModel = widget.dto.transaction;
      _typeModel = .fromByString(
        _transactionModel?.type ?? TransactionTypeModel.expense.label,
      );

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
            child: BlocListener<TransactionCubit, TransactionState>(
              bloc: widget.dto.transactionCubit,
              listenWhen: (previous, current) =>
                  previous.form.amount != current.form.amount,
              listener: (_, state) {
                widget.dto.onAmountSelected(state.form.amount);
                _amountController.text = widget.dto.format(state.form.amount);
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
            child: BlocListener<TransactionCubit, TransactionState>(
              bloc: widget.dto.transactionCubit,
              listenWhen: (previous, current) =>
                  previous.form.category.label != current.form.category.label,
              listener: (_, state) {
                _categoryController.text = state.form.category.label;
                widget.dto.onCategorySelected(state.form.category.label);
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
            child: BlocListener<TransactionCubit, TransactionState>(
              bloc: widget.dto.transactionCubit,
              listenWhen: (previous, current) =>
                  previous.form.formattedDate != current.form.formattedDate,
              listener: (_, state) {
                widget.dto.onDateSelected(state.form.date);
                _dateController.text = state.form.formattedDate;
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
                _typeModel = .fromByString(value);
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
    _dateController.text = _transactionModel?.date.format() ?? '';
    _descriptionController.text = _transactionModel?.description ?? '';
    _observationController.text = _transactionModel?.observation ?? '';
    _categoryController.text =
        _transactionModel?.category ?? CategoryModel.other.label;
    _amountController.text = _transactionModel?.amount == null
        ? ''
        : widget.dto.format(_transactionModel!.amount);
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
