import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/category/data/dtos/category_dto.dart';

import 'package:trocado/modules/transaction/data/dtos/transaction_dto.dart';
import 'package:trocado/modules/transaction/data/mappers/transaction_mapper.dart';
import 'package:trocado/modules/transaction/data/dtos/transaction_type_dto.dart';

import 'package:trocado/modules/transaction/infrastructure/database/entities/transaction_entity.dart';

void main() {
  group('TransactionInMapper', () {
    test('should map TransactionDto to TransactionEntity correctly', () {
      final date = DateTime(2024, 1, 1);

      final dto = TransactionDto(
        id: null,
        date: date,
        amount: 100.5,
        type: .expense,
        category: .other,
        description: 'Groceries',
        observation: 'Weekly shopping',
      );

      final mapper = TransactionInMapper();
      final entity = mapper(dto);

      expect(entity.amount, 100.5);
      expect(entity.description, 'Groceries');
      expect(entity.observation, 'Weekly shopping');
      expect(entity.date, date.millisecondsSinceEpoch);
      expect(entity.category, CategoryDto.other.label);
      expect(entity.type, TransactionTypeDto.expense.label);
    });

    test('should map TransactionDto without observation', () {
      final date = DateTime(2024, 1, 1);

      final dto = TransactionDto(
        id: null,
        date: date,
        amount: 50.0,
        type: .income,
        category: .salary,
        observation: null,
        description: 'Salary',
      );

      final mapper = TransactionInMapper();
      final entity = mapper(dto);

      expect(entity.observation, isNull);
    });
  });

  group('TransactionOutMapper', () {
    test('should map TransactionEntity to TransactionModel correctly', () {
      final entity = TransactionEntity(
        type: 'income',
        amount: 200.75,
        category: 'salary',
        date: 1704067200000,
        observation: 'Paid on time',
        description: 'Monthly salary',
      )..id = 10;

      final mapper = TransactionOutMapper();
      final model = mapper(entity);

      expect(model.id, 10);
      expect(model.type, 'income');
      expect(model.amount, 200.75);
      expect(model.category, 'salary');
      expect(model.date, 1704067200000);
      expect(model.observation, 'Paid on time');
      expect(model.description, 'Monthly salary');
    });

    test('should map TransactionEntity without observation', () {
      final entity = TransactionEntity(
        amount: 30.0,
        type: 'expense',
        category: 'food',
        observation: null,
        date: 1704067200000,
        description: 'Snack',
      )..id = 5;

      final mapper = TransactionOutMapper();
      final model = mapper(entity);

      expect(model.observation, isNull);
    });
  });
}
