import 'package:mobx/mobx.dart';

import 'package:trocado/modules/calculator/domain/repositories/interface_calculator_repository.dart';

part 'calculator_store.g.dart';

class CalculatorStore = CalculatorStoreBase with _$CalculatorStore;

abstract class CalculatorStoreBase with Store {
  final ICalculatorRepository _repository;
  CalculatorStoreBase({required ICalculatorRepository repository})
    : _repository = repository;

  @observable
  String? preview;

  @observable
  String expression = '';

  @action
  void onKeyTap(String key) => switch (key) {
    '✓' => null,
    'AC' => clear(),
    'DEL' => delete(),
    '=' => applyResult(),
    '()' => toggleParenthesis(),
    _ => append(key),
  };

  @action
  void clear() {
    expression = '';
    preview = null;
  }

  @action
  void delete() {
    if (expression.isEmpty) return;

    expression = expression.substring(0, expression.length - 1);
    updatePreview();
  }

  @action
  void append(String value) {
    expression += value;
    updatePreview();
  }

  @action
  void toggleParenthesis() {
    final opens = '('.allMatches(expression).length;
    final closes = ')'.allMatches(expression).length;

    expression += opens == closes ? '(' : ')';
    updatePreview();
  }

  @action
  void applyResult() {
    if (expression.isEmpty) return;

    final result = _repository(expression);

    if (result.isNaN) return;

    expression = _format(result);
    preview = null;
  }

  @action
  void updatePreview() {
    if (expression.isEmpty) {
      preview = null;
      return;
    }

    final result = _repository(expression);

    preview = result.isNaN ? null : _format(result);
  }

  String _format(double value) => value.toString().endsWith('.0')
      ? value.toInt().toString()
      : value.toString();
}
