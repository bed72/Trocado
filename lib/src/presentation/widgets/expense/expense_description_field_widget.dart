import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

import 'package:trocado/src/presentation/bloc/expense_form/expense_form_bloc.dart';
import 'package:trocado/src/presentation/bloc/expense_form/expense_form_event.dart';
import 'package:trocado/src/presentation/bloc/expense_form/expense_form_state.dart';

class ExpenseDescriptionFieldWidget extends StatefulWidget {
  final ExpenseFormBloc bloc;

  const ExpenseDescriptionFieldWidget({super.key, required this.bloc});

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
    _controller = TextEditingController(text: widget.bloc.state.description);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExpenseFormBloc, ExpenseFormState>(
      bloc: widget.bloc,
      listener: (_, state) =>
          _key.currentState?.setFailure(state.descriptionFailure),
      listenWhen: (previous, current) =>
          previous.descriptionFailure != current.descriptionFailure,
      child: TextFieldWidget(
        key: _key,
        hint: 'Descrição',
        keyboardType: .name,
        controller: _controller,
        placeholder: 'Ex: Café',
        onChanged: (value) => widget.bloc.add(ExpenseDescriptionChanged(value)),
      ),
    );
  }
}
