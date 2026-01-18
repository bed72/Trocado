import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/date/date.dart';
import 'package:trocado/modules/category/category.dart';
import 'package:trocado/modules/calculator/calculator.dart';
import 'package:trocado/modules/transaction/transaction.dart';

class TransactionsFormWidget extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final ValueChanged<int> onTypeSelected;

  final DateCubit dateCubit;
  final CategoryCubit categoryCubit;
  final CalculatorCubit caculatorCubit;

  final VoidCallback navigateToDate;
  final VoidCallback navigateToCategory;
  final VoidCallback navigateToCalculator;

  const TransactionsFormWidget({
    super.key,
    required this.formKey,
    required this.dateCubit,
    required this.categoryCubit,
    required this.caculatorCubit,
    required this.onTypeSelected,
    required this.navigateToDate,
    required this.navigateToCategory,
    required this.navigateToCalculator,
  });

  @override
  State<TransactionsFormWidget> createState() => _TransactionsFormWidgetState();
}

class _TransactionsFormWidgetState extends State<TransactionsFormWidget> {
  late TransactionTypeData _type;

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

    _type = TransactionTypeData.expense;

    _dateController = TextEditingController();
    _amountController = TextEditingController();
    _categoryController = TextEditingController();
    _descriptionController = TextEditingController()
      ..addListener(_handleDescriptionInteractions);
    _observationController = TextEditingController()
      ..addListener(_handleObservatiobInteractions);
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
      key: widget.formKey,
      child: Column(
        spacing: 16.0,
        crossAxisAlignment: .start,
        children: [
          TextFormFieldWidget(
            hint: 'Descrição',
            inputAction: .done,
            keyboardType: .name,
            placeholder: 'Ex: Café',
            controller: _descriptionController,
            helperWidget: _buildDescriptionHelper(),
          ),

          BounceWidget.withTap(
            onTap: widget.navigateToCalculator,
            child: BlocListener<CalculatorCubit, CalculatorState>(
              bloc: widget.caculatorCubit,
              listenWhen: (previous, current) =>
                  previous.preview != current.preview,
              listener: (_, state) {
                _amountController.text = state.amount;
              },
              child: TextFieldWidget(
                hint: 'R\$',
                readOnly: true,
                absorbing: true,
                placeholder: 'Ex: 72.00',
                controller: _amountController,
              ),
            ),
          ),

          BounceWidget.withTap(
            onTap: widget.navigateToCategory,
            child: BlocListener<CategoryCubit, CategoryState>(
              bloc: widget.categoryCubit,
              listenWhen: (previous, current) =>
                  previous.category.label != current.category.label,
              listener: (_, state) {
                _categoryController.text = state.category.label;
              },
              child: TextFormFieldWidget(
                readOnly: true,
                absorbing: true,
                hint: 'Categoria',
                controller: _categoryController,
                placeholder: 'Ex: ${CategoryData.other.label}',
              ),
            ),
          ),

          BounceWidget.withTap(
            onTap: widget.navigateToDate,
            child: BlocListener<DateCubit, DateState>(
              bloc: widget.dateCubit,
              listenWhen: (previous, current) =>
                  previous.formatted != current.formatted,
              listener: (_, state) {
                _dateController.text = state.formatted;
              },
              child: TextFormFieldWidget(
                hint: 'Data',
                readOnly: true,
                absorbing: true,
                controller: _dateController,
                placeholder: 'Ex: ${DateTime.now().format()}',
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
          ),

          SelectorWidget(
            options: ['Receita', 'Despesa'],
            selected: _type == .income ? 0 : 1,
            onSelected: (value) {
              setState(() {
                widget.onTypeSelected(value);
                _type = TransactionTypeData.from(value);
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
