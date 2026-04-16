import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/application/services/money_service.dart';
import 'package:trocado/src/main/providers/services_provider.dart';

import 'package:trocado/src/presentation/screens/calculator/notifiers/calculator_state.dart';
import 'package:trocado/src/presentation/screens/calculator/notifiers/calculator_intent.dart';

part 'calculator_notifier.g.dart';

@riverpod
final class CalculatorNotifier extends _$CalculatorNotifier {
  late IMoneyService _moneyService;

  static const int _maxDigits = 9;

  @override
  CalculatorState build() {
    _moneyService = ref.watch(moneyServiceProvider);
    return const CalculatorState();
  }

  void dispatch(CalculatorIntent intent) => switch (intent) {
    DigitPressed(:final digit) => _appendDigit(digit),
    DeletePressed() => _deleteDigit(),
    ClearPressed() => state = const CalculatorState(),
  };

  void _appendDigit(String digit) {
    if (state.digits.length >= _maxDigits) return;
    final raw = state.digits + digit;
    state = state.copyWith(
      digits: raw,
      displayValue: _moneyService.format(int.parse(raw) / 100),
    );
  }

  void _deleteDigit() {
    if (state.digits.isEmpty) return;
    final raw = state.digits.substring(0, state.digits.length - 1);
    state = state.copyWith(
      digits: raw,
      displayValue: raw.isEmpty
          ? ''
          : _moneyService.format(int.parse(raw) / 100),
    );
  }
}
