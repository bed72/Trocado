import 'package:mobx/mobx.dart';

import 'package:trocado/modules/calculator/domain/repositories/interface_calculator_repository.dart';

part 'calculator_store.g.dart';

class CalculatorStore = CalculatorStoreBase with _$CalculatorStore;

abstract class CalculatorStoreBase with Store {
  final ICalculatorRepository _repository;

  CalculatorStoreBase({required ICalculatorRepository repository})
    : _repository = repository;

  @observable
  String amount = '';

  @observable
  String preview = '...';

  @action
  void onKeyTap(String key) => switch (key) {
    '✓' => apply(),
    '=' => apply(),
    'AC' => clear(),
    'DEL' => delete(),
    '()' => toggleParenthesis(),
    _ => append(key),
  };

  @action
  void clear() {
    amount = '';
    preview = '...';
  }

  @action
  void delete() {
    if (amount.isEmpty) return;

    amount = amount.substring(0, amount.length - 1);
    updatePreview();
  }

  @action
  void append(String value) {
    if (amount.isEmpty && _isOperator(value)) return;

    if (_isOperator(value) && _lastIsOperator()) return;

    amount += value;
    updatePreview();
  }

  @action
  void toggleParenthesis() {
    final opens = '('.allMatches(amount).length;
    final closes = ')'.allMatches(amount).length;

    amount += opens == closes ? '(' : ')';
    updatePreview();
  }

  @action
  void apply() {
    if (amount.isEmpty) return;

    final response = _repository.operation(amount);

    if (response.isNaN) return;

    amount = _format(response);
    preview = amount;
  }

  @action
  void updatePreview() {
    if (amount.isEmpty) {
      preview = '...';
      return;
    }

    final response = _repository.operation(amount);

    preview = response.isNaN ? amount : _format(response);
  }

  bool _isOperator(String value) => ['+', '-', '*', '/'].contains(value);

  bool _lastIsOperator() {
    if (amount.isEmpty) return false;

    return _isOperator(amount[amount.length - 1]);
  }

  String _format(double value) => value.toString().endsWith('.0')
      ? value.toInt().toString()
      : value.toString();
}
