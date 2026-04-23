import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/presentation/ui/expense/notifiers/expense_state.dart';

import 'package:trocado/src/presentation/ui/expense/validators/expense_form_validator.dart';
import 'package:trocado/src/presentation/ui/expense/validators/expense_date_validation.dart';
import 'package:trocado/src/presentation/ui/expense/validators/expense_value_validation.dart';
import 'package:trocado/src/presentation/ui/expense/validators/expense_description_validation.dart';

const _date = 1741996800000; // 2026-03-15 UTC

void main() {
  const validator = ExpenseFormValidator(
    dateValidation: ExpenseDateValidation(),
    valueValidation: ExpenseValueValidation(),
    descriptionValidation: ExpenseDescriptionValidation(),
  );

  group('ExpenseFormValidator', () {
    test('sets all failures when state is empty', () {
      const input = ExpenseState();

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.dateFailure, isNotNull);
      expect(state.valueFailure, isNotNull);
      expect(state.descriptionFailure, isNotNull);
    });

    test('returns isValid true when all fields are valid', () {
      const input = ExpenseState(
        date: _date,
        value: 8550,
        description: 'Mercado',
      );

      final (:state, :isValid) = validator(input);

      expect(isValid, isTrue);
      expect(state.dateFailure, isNull);
      expect(state.valueFailure, isNull);
      expect(state.descriptionFailure, isNull);
    });

    test('sets only valueFailure when value is zero', () {
      const input = ExpenseState(value: 0, description: 'Mercado', date: _date);

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.dateFailure, isNull);
      expect(state.valueFailure, isNotNull);
      expect(state.descriptionFailure, isNull);
    });

    test('sets only descriptionFailure when description is empty', () {
      const input = ExpenseState(value: 8550, description: '', date: _date);

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.dateFailure, isNull);
      expect(state.valueFailure, isNull);
      expect(state.descriptionFailure, isNotNull);
    });

    test('sets only dateFailure when date is null', () {
      const input = ExpenseState(
        date: null,
        value: 8550,
        description: 'Mercado',
      );

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.valueFailure, isNull);
      expect(state.dateFailure, isNotNull);
      expect(state.descriptionFailure, isNull);
    });

    test('sets valueFailure message correctly', () {
      const input = ExpenseState(value: 0, description: 'Mercado', date: _date);

      final (:state, :isValid) = validator(input);

      expect(state.valueFailure, 'Valor é obrigatório');
    });

    test('sets descriptionFailure message correctly', () {
      const input = ExpenseState(value: 8550, description: '', date: _date);

      final (:state, :isValid) = validator(input);

      expect(state.descriptionFailure, 'Descrição é obrigatória');
    });

    test('sets dateFailure message correctly', () {
      const input = ExpenseState(value: 8550, description: 'Mercado');

      final (:state, :isValid) = validator(input);

      expect(state.dateFailure, 'Data é obrigatória');
    });

    test('trims whitespace-only description', () {
      const input = ExpenseState(value: 8550, description: '   ', date: _date);

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.descriptionFailure, isNotNull);
    });
  });
}
