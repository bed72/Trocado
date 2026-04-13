import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

class ExpenseDescriptionFieldWidget extends StatefulWidget {
  const ExpenseDescriptionFieldWidget({super.key});

  @override
  State<ExpenseDescriptionFieldWidget> createState() =>
      _ExpenseDescriptionFieldWidgetState();
}

class _ExpenseDescriptionFieldWidgetState
    extends State<ExpenseDescriptionFieldWidget> {
  late final TextEditingController _controller;
  late final GlobalKey<TextFieldWidgetState> _key;

  @override
  void initState() {
    super.initState();
    _key = GlobalKey<TextFieldWidgetState>();
    _controller = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFieldWidget(
      key: _key,
      hint: 'Descrição',
      keyboardType: .name,
      controller: _controller,
      placeholder: 'Ex: Café',
      onChanged:
          (value) {}, //=> widget.bloc.add(ExpenseDescriptionChanged(value)),
    );
  }
}
