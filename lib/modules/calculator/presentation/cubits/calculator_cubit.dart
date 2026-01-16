import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trocado/modules/calculator/domain/repositories/interface_calculator_repository.dart';

part 'calculator_state.dart';

class CalculatorCubit extends Cubit<CalculatorState> {
  final ICalculatorRepository _repository;

  CalculatorCubit({required ICalculatorRepository repository})
    : _repository = repository,
      super(CalculatorState.empty());

  void onKeyTap(String key) => switch (key) {
    '✓' => apply(),
    '=' => apply(),
    'AC' => clear(),
    'DEL' => delete(),
    '()' => toggleParenthesis(),
    _ => append(key),
  };

  void clear() {
    emit(CalculatorState.empty());
  }

  void delete() {
    if (state.amount.isEmpty) return;

    final amoubt = state.amount.substring(0, state.amount.length - 1);

    emit(state.copyWith(amount: amoubt, preview: _buildPreview(amoubt)));
  }

  void append(String value) {
    if (state.amount.isEmpty && _isOperator(value)) return;
    if (_isOperator(value) && _lastIsOperator()) return;

    final amount = state.amount + value;

    emit(state.copyWith(amount: amount, preview: _buildPreview(amount)));
  }

  void toggleParenthesis() {
    final opens = '('.allMatches(state.amount).length;
    final closes = ')'.allMatches(state.amount).length;

    final amount = state.amount + (opens == closes ? '(' : ')');

    emit(state.copyWith(amount: amount, preview: _buildPreview(amount)));
  }

  void apply() {
    if (state.amount.isEmpty) return;

    final data = _repository.operation(state.amount);

    if (data.isNaN) return;

    final formatted = _format(data);

    emit(state.copyWith(amount: formatted, preview: formatted));
  }

  String _buildPreview(String amount) {
    if (amount.isEmpty) return '...';

    final data = _repository.operation(amount);

    return data.isNaN ? amount : _format(data);
  }

  bool _isOperator(String value) => ['+', '-', '*', '/'].contains(value);

  bool _lastIsOperator() {
    if (state.amount.isEmpty) return false;
    return _isOperator(state.amount[state.amount.length - 1]);
  }

  String _format(double value) => value.toString().endsWith('.0')
      ? value.toInt().toString()
      : value.toString();
}
