import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/modules/core/core.dart';

part 'calculator_state.dart';

final class CalculatorCubit extends Cubit<CalculatorState> {
  late final IMoneyDto _formatter;

  CalculatorCubit() : super(CalculatorState.empty()) {
    _formatter = MoneyDto();
  }

  void onKeyTap(String key) => switch (key) {
    '✓' => apply(),
    'AC' => clear(),
    'DEL' => delete(),
    _ => append(key),
  };

  void clear() {
    emit(CalculatorState.empty());
  }

  void delete() {
    if (state.preview.isEmpty || state.preview == '...') return;

    final next = state.preview.substring(0, state.preview.length - 1);

    emit(_buildState(next));
  }

  void apply() {
    final formatted = _formatter.format(state.amount);

    emit(state.copyWith(preview: formatted));
  }

  void append(String value) {
    if (value == ',' && state.preview.contains(',')) return;

    final base = state.preview == '...' ? '' : state.preview;
    final next = '$base$value';

    emit(_buildState(next));
  }

  CalculatorState _buildState(String preview) {
    if (preview.isEmpty) return CalculatorState.empty();

    final normalized = preview.replaceAll(',', '.');
    final parsed = double.tryParse(normalized);

    return CalculatorState(amount: parsed ?? 0.0, preview: preview);
  }
}
