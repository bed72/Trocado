import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/models/category_model.dart';
import 'package:trocado/src/domain/models/transaction_model.dart';

void main() {
  group('TransactionModel', () {
    late TransactionModel model;

    setUp(() {
      model = TransactionModel(
        amount: 10.50,
        type: 'expense',
        category: 'food',
        description: 'Café',
        observation: 'Pago no crédito',
        date: DateTime(2025, 1, 1).millisecondsSinceEpoch,
      );
    });

    group('empty()', () {
      test('should create an empty transaction with default values', () {
        final empty = TransactionModel.empty();

        expect(empty.amount, 0.0);
        expect(empty.description, '');
        expect(empty.date, isA<int>());
        expect(empty.observation, isNull);
        expect(empty.category, CategoryModel.other.label);
        expect(empty.type, TransactionTypeModel.expense.label);
      });
    });

    group('copyWith()', () {
      test('should copy keeping original values when params are null', () {
        final copy = model.copyWith();

        expect(copy.date, model.date);
        expect(copy.type, model.type);
        expect(copy.amount, model.amount);
        expect(copy.category, model.category);
        expect(copy.description, model.description);
        expect(copy.observation, model.observation);
      });

      test('should override provided values', () {
        final date = DateTime(2026, 2, 2).millisecondsSinceEpoch;

        final copy = model.copyWith(
          date: date,
          amount: 99.90,
          type: 'Despesa',
          description: 'Almoço',
          category: 'Alimentação',
          observation: 'Restaurante',
        );

        expect(copy.date, date);
        expect(copy.amount, 99.90);
        expect(copy.description, 'Almoço');
        expect(copy.observation, 'Restaurante');
        expect(copy.category, CategoryModel.food.label);
        expect(copy.type, TransactionTypeModel.expense.label);
      });
    });

    group('validateDescription()', () {
      test('should return error when description is null', () {
        final data = model.validateDescription(null);

        expect(data, 'Adicione uma descrição.');
      });

      test('should return error when description is empty', () {
        final data = model.validateDescription('   ');

        expect(data, 'Adicione uma descrição.');
      });

      test('should return error when description has less than 3 letters', () {
        final data = model.validateDescription('Oi');

        expect(data, 'Use ao menos 3 letras.');
      });

      test('should return error when description has invalid characters', () {
        final data = model.validateDescription('123');

        expect(data, 'Use ao menos 3 letras.');
      });

      test('should return null when description is valid', () {
        final data = model.validateDescription('Café da manhã');

        expect(data, isNull);
      });
    });

    group('validateAmount()', () {
      double parseAmount(String value) {
        final normalized = value.replaceAll(',', '.');
        final parsed = double.tryParse(normalized);
        if (parsed == null) {
          throw FormatException('Invalid number');
        }
        return parsed;
      }

      test('should return error when amount is null', () {
        final data = model.validateAmount(value: null, parse: parseAmount);

        expect(data, 'Adicione um valor.');
      });

      test('should return error when amount is empty', () {
        final data = model.validateAmount(value: '   ', parse: parseAmount);

        expect(data, 'Adicione um valor.');
      });

      test('should throw when amount is not a number', () {
        expect(
          () => model.validateAmount(value: 'abc', parse: parseAmount),
          throwsA(isA<FormatException>()),
        );
      });

      test('should return error when amount is zero', () {
        final data = model.validateAmount(value: '0', parse: parseAmount);

        expect(data, 'Adicione um valor válido');
      });

      test('should return error when amount is negative', () {
        final data = model.validateAmount(value: '-10', parse: parseAmount);

        expect(data, 'Adicione um valor válido');
      });

      test('should accept comma as decimal separator', () {
        final data = model.validateAmount(value: '10,50', parse: parseAmount);

        expect(data, isNull);
      });

      test('should return null when amount is valid', () {
        final data = model.validateAmount(value: '25.90', parse: parseAmount);

        expect(data, isNull);
      });
    });
  });
}
