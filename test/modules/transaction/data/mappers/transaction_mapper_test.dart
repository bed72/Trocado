import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/category/data/dtos/category_dto.dart';

import 'package:trocado/modules/transaction/data/dtos/transaction_dto.dart';
import 'package:trocado/modules/transaction/data/mappers/transaction_mapper.dart';
import 'package:trocado/modules/transaction/data/dtos/transaction_type_dto.dart';
import 'package:trocado/modules/transaction/domain/models/transaction_model.dart';

import 'package:trocado/modules/transaction/infrastructure/database/entities/transaction_entity.dart';

void main() {
  group('TransactionInMapper', () {
    test('should map TransactionDto to TransactionEntity correctly', () {
      final date = DateTime(2024, 1, 1);

      final dto = TransactionDto(
        id: null,
        date: date,
        type: .expense,
        amount: '100.5',
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
        type: .income,
        amount: '50.0',
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

  group('TransactionDtoMapper', () {
    test('should map all fields correctly', () {
      final timestamp = DateTime(2024, 1, 1).millisecondsSinceEpoch;

      final model = TransactionModel(
        id: 1,
        amount: 150.75,
        date: timestamp,
        description: 'Almoço',
        observation: 'Restaurante',
        category: CategoryDto.food.label,
        type: TransactionTypeDto.expense.label,
      );

      final mapper = TransactionDtoMapper();

      final dto = mapper(model);

      expect(dto.amount, '150.75');
      expect(dto.description, 'Almoço');
      expect(dto.observation, 'Restaurante');
      expect(dto.category, CategoryDto.food);
      expect(dto.type, TransactionTypeDto.expense);
      expect(dto.date, DateTime.fromMillisecondsSinceEpoch(timestamp));
    });

    test('should map without observation', () {
      final model = TransactionModel(
        id: 2,
        date: 0,
        amount: 3000,
        observation: null,
        description: 'Salário',
        category: CategoryDto.salary.label,
        type: TransactionTypeDto.income.label,
      );

      final mapper = TransactionDtoMapper();

      final dto = mapper(model);

      expect(dto.observation, isNull);
      expect(dto.category, CategoryDto.salary);
      expect(dto.type, TransactionTypeDto.income);
    });
  });
}
