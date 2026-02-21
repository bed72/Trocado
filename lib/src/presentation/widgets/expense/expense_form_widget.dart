import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/animation/animation.dart';
import 'package:trocado/src/presentation/extensions/date_time_extension.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/helper_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_form_field_widget.dart';
import 'package:trocado/src/presentation/widgets/expense/expense_category_field_widget.dart';

class TransactionsFormWidget extends StatefulWidget {
  final VoidCallback navigateToDate;
  final VoidCallback navigateToCategory;
  final VoidCallback navigateToCalculator;

  const TransactionsFormWidget({
    super.key,
    required this.navigateToDate,
    required this.navigateToCategory,
    required this.navigateToCalculator,
  });

  @override
  State<TransactionsFormWidget> createState() => _TransactionsFormWidgetState();
}

class _TransactionsFormWidgetState extends State<TransactionsFormWidget> {
  late bool _mustShowDescriptionHelper;

  late final TextEditingController _dateController;
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();

    _mustShowDescriptionHelper = false;

    _amountController = TextEditingController();
    _dateController = TextEditingController(text: DateTime.now().format());

    _descriptionController = TextEditingController()
      ..addListener(_handleDescriptionInteractions);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _amountController.dispose();
    _descriptionController
      ..removeListener(_handleDescriptionInteractions)
      ..dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
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
          ),

          BounceWidget.withOnPress(
            onPress: widget.navigateToCalculator,
            child: TextFormFieldWidget(
              hint: 'Valor',
              readOnly: true,
              absorbing: true,
              placeholder: 'Ex: 72.00',
              controller: _amountController,
            ),
          ),

          ExpenseCategoryFieldWidget(navigateTo: widget.navigateToCategory),

          BounceWidget.withOnPress(
            onPress: widget.navigateToDate,
            child: TextFormFieldWidget(
              hint: 'Data',
              readOnly: true,
              absorbing: true,
              controller: _dateController,
            ),
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

  SwitcherSizeAnimation _buildDescriptionHelper() => SwitcherSizeAnimation(
    child: !_mustShowDescriptionHelper
        ? const SizedBox.shrink(key: ValueKey('description_key'))
        : HelperWidget(title: 'A descrição deve conter ao menos 3 letras.'),
  );
}
