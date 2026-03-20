import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

import 'package:trocado/src/presentation/bloc/expense_form/expense_form_bloc.dart';
import 'package:trocado/src/presentation/bloc/expense_form/expense_form_state.dart';

class ExpenseAmountFieldWidget extends StatefulWidget {
  final ExpenseFormBloc bloc;
  final VoidCallback navigateTo;

  const ExpenseAmountFieldWidget({
    super.key,
    required this.bloc,
    required this.navigateTo,
  });

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
    _controller = TextEditingController(
      text: widget.bloc.state.formattedAmount,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExpenseFormBloc, ExpenseFormState>(
      listenWhen: (previous, current) =>
          previous.formattedAmount != current.formattedAmount ||
          previous.amountFailure != current.amountFailure,
      listener: (_, state) {
        _controller.text = state.formattedAmount;
        _key.currentState?.setFailure(state.amountFailure);
      },
      child: BounceWidget.withOnPress(
        onPress: widget.navigateTo,
        child: TextFieldWidget(
          key: _key,
          hint: 'Valor',
          readOnly: true,
          absorbing: true,
          controller: _controller,
          placeholder: 'Ex: R\$ 72.00',
        ),
      ),
    );
  }
}
