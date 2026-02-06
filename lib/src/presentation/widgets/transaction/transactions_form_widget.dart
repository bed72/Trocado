import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/animation/animation.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/helper_widget.dart';
import 'package:trocado/src/presentation/widgets/selectors/selector_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_form_field_widget.dart';

class TransactionsFormWidget extends StatefulWidget {
  const TransactionsFormWidget({super.key});

  @override
  State<TransactionsFormWidget> createState() => _TransactionsFormWidgetState();
}

class _TransactionsFormWidgetState extends State<TransactionsFormWidget> {
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
            onPress: () {},
            child: TextFormFieldWidget(
              hint: 'Valor',
              readOnly: true,
              absorbing: true,
              placeholder: 'Ex: 72.00',
              controller: _amountController,
            ),
          ),

          BounceWidget.withOnPress(
            onPress: () {},
            child: TextFormFieldWidget(
              readOnly: true,
              absorbing: true,
              hint: 'Categoria',
              controller: _categoryController,
            ),
          ),

          BounceWidget.withOnPress(
            onPress: () {},
            child: TextFormFieldWidget(
              hint: 'Data',
              readOnly: true,
              absorbing: true,
              controller: _dateController,
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
            selected: 0,
            onSelected: (value) {},
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
