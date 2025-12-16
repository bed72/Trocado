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
    '✓' => null,
    'AC' => clear(),
    'DEL' => delete(),
    '=' => applyresponse(),
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
  void applyresponse() {
    if (amount.isEmpty) return;

    final response = _repository(amount);

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

    final response = _repository(amount);

    preview = response.isNaN ? amount : _format(response);
  }

  String _format(double value) => value.toString().endsWith('.0')
      ? value.toInt().toString()
      : value.toString();
}
