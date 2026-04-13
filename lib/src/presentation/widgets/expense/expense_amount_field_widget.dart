import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

class ExpenseAmountFieldWidget extends StatefulWidget {
  final VoidCallback navigateTo;

  const ExpenseAmountFieldWidget({super.key, required this.navigateTo});

  @override
  State<ExpenseAmountFieldWidget> createState() =>
      _ExpenseAmountFieldWidgetState();
}

class _ExpenseAmountFieldWidgetState extends State<ExpenseAmountFieldWidget> {
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
    return BounceWidget.withOnPress(
      onPress: widget.navigateTo,
      child: TextFieldWidget(
        key: _key,
        hint: 'Valor',
        readOnly: true,
        absorbing: true,
        controller: _controller,
        placeholder: 'Ex: R\$ 72.00',
      ),
    );
  }
}
