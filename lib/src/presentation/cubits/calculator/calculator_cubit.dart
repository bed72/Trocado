import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/src/domain/repositories/interface_money_repository.dart';

part 'calculator_state.dart';

final class CalculatorCubit extends Cubit<CalculatorState> {
  String _buffer = '';

  final IMoneyRepository _repository;

  CalculatorCubit({required IMoneyRepository repository})
    : _repository = repository,
      super(CalculatorState.empty());

  String format(double value) => _repository.format(value);

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
    _buffer = '';
    emit(CalculatorState.empty());
  }

  void delete() {
    if (_buffer.isEmpty) return;

    _buffer = _buffer.substring(0, _buffer.length - 1);
    _emit();
  }

  void append(String value) {
    if (value == ',' && _buffer.contains(',')) return;

    _buffer += value;
    _emit();
  }

  void _emit() {
    if (_buffer.isEmpty) {
      emit(CalculatorState.empty());

      return;
    }

    final normalized = _buffer.replaceAll(',', '.');
    final parsed = double.tryParse(normalized) ?? 0.0;

    emit(state.copyWith(amount: parsed));
  }
}
