import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/category/category.dart';

import 'package:trocado/modules/transaction/data/dtos/transaction_dto.dart';
import 'package:trocado/modules/transaction/data/dtos/transaction_type_dto.dart';

void main() {
  group('TransactionDto', () {
    late TransactionDto dto;

    setUp(() {
      dto = TransactionDto(
        type: .expense,
        amount: 10.50,
        category: .food,
        description: 'Café',
        date: DateTime(2025, 1, 1),
        observation: 'Pago no crédito',
      );
    });

    group('empty()', () {
      test('should create an empty transaction with default values', () {
        final empty = TransactionDto.empty();

        expect(empty.amount, 0);
        expect(empty.description, '');
        expect(empty.observation, isNull);
        expect(empty.date, isA<DateTime>());
        expect(empty.category, CategoryDto.other);
        expect(empty.type, TransactionTypeDto.expense);
      });
    });

    group('copyWith()', () {
      test('should copy keeping original values when params are null', () {
        final copy = dto.copyWith();

        expect(copy.date, dto.date);
        expect(copy.type, dto.type);
        expect(copy.amount, dto.amount);
        expect(copy.category, dto.category);
        expect(copy.description, dto.description);
        expect(copy.observation, dto.observation);
      });

      test('should override provided values', () {
        final date = DateTime(2026, 2, 2);

        final copy = dto.copyWith(
          date: date,
          amount: 99.90,
          type: .expense,
          category: .food,
          description: 'Almoço',
          observation: 'Restaurante',
        );

        expect(copy.date, date);
        expect(copy.amount, 99.90);
        expect(copy.description, 'Almoço');
        expect(copy.observation, 'Restaurante');
        expect(copy.category, CategoryDto.food);
        expect(copy.type, TransactionTypeDto.expense);
      });
    });

    group('toString()', () {
      test('should return a readable string representation', () {
        final data = dto.toString();

        expect(data, contains('amount: 10.5'));
        expect(data, contains('type: expense'));
        expect(data, contains('category: food'));
        expect(data, contains('TransactionDto('));
        expect(data, contains('description: Café'));
        expect(data, contains('observation: Pago no crédito'));
      });
    });

    group('validateDescription()', () {
      test('should return error when description is null', () {
        final data = dto.validateDescription(null);

        expect(data, 'Adicione uma descrição.');
      });

      test('should return error when description is empty', () {
        final data = dto.validateDescription('   ');

        expect(data, 'Adicione uma descrição.');
      });

      test('should return error when description has less than 3 letters', () {
        final data = dto.validateDescription('Oi');

        expect(data, 'Use ao menos 3 letras.');
      });

      test('should return error when description has invalid characters', () {
        final data = dto.validateDescription('123');

        expect(data, 'Use ao menos 3 letras.');
      });

      test('should return null when description is valid', () {
        final data = dto.validateDescription('Café da manhã');

        expect(data, isNull);
      });
    });

    group('validateAmount()', () {
      test('should return error when amount is null', () {
        final data = dto.validateAmount(null);

        expect(data, 'Adicione um valor.');
      });

      test('should return error when amount is empty', () {
        final data = dto.validateAmount('   ');

        expect(data, 'Adicione um valor.');
      });

      test('should return error when amount is not a number', () {
        final data = dto.validateAmount('abc');

        expect(data, 'Adicione um valor válido');
      });

      test('should return error when amount is zero', () {
        final data = dto.validateAmount('0');

        expect(data, 'Adicione um valor válido');
      });

      test('should return error when amount is negative', () {
        final data = dto.validateAmount('-10');

        expect(data, 'Adicione um valor válido');
      });

      test('should accept comma as decimal separator', () {
        final data = dto.validateAmount('10,50');

        expect(data, isNull);
      });

      test('should return null when amount is valid', () {
        final data = dto.validateAmount('25.90');

        expect(data, isNull);
      });
    });
  });
}
