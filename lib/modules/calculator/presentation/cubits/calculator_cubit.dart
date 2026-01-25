import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trocado/modules/calculator/calculator.dart';

part 'calculator_state.dart';

final class CalculatorCubit extends Cubit<CalculatorState> {
  final IMoneyFormatter _formatter;

  CalculatorCubit({required IMoneyFormatter formatter})
    : _formatter = formatter,
      super(CalculatorState.empty());

  void onKeyTap(String key) => switch (key) {
    '✓' => apply(),
    'AC' => clear(),
    'DEL' => delete(),
    _ => append(key),
  };

  void apply() {
    emit(state);
  }

  void clear() {
    emit(CalculatorState.empty());
  }

  void delete() {
    if (state.amount.isEmpty) return;

    final amount = state.amount.substring(0, state.amount.length - 1);

    emit(_buildState(amount));
  }

  void append(String value) {
    if (value == ',' && state.amount.contains(',')) return;

    final amount = state.amount + value;
    emit(_buildState(amount));
  }

  CalculatorState _buildState(String amount) {
    if (amount.isEmpty) return CalculatorState.empty();

    final normalized = amount.replaceAll(',', '.');
    final parsed = double.tryParse(normalized);

    return CalculatorState(
      amount: amount,
      preview: parsed == null ? amount : _formatter.format(parsed),
    );
  }
}
