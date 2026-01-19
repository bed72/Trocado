import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/core/domain/either/either.dart';

import 'package:trocado/modules/transaction/data/dtos/transaction_dto.dart';
import 'package:trocado/modules/transaction/data/mappers/transaction_mapper.dart';
import 'package:trocado/modules/transaction/data/repositories/transaction_repository.dart';
import 'package:trocado/modules/transaction/data/datasources/interface_transaction_datasource.dart';

import 'package:trocado/modules/transaction/infrastructure/database/entities/transaction_entity.dart';

import 'package:trocado/modules/transaction/domain/models/transaction_model.dart';
import 'package:trocado/modules/transaction/domain/repositories/interface_transaction_repository.dart';

import '../../mocks/mocks.dart';

void main() {
  late TransactionInMapper inMapper;
  late TransactionOutMapper outMapper;
  late ITransactionRepository repository;
  late ITransactionLocalDatasource datasource;

  setUp(() {
    inMapper = MockTransactionInMapper();
    outMapper = MockTransactionOutMapper();
    datasource = MockITransactionLocalDatasource();

    repository = TransactionRepository(
      datasource: datasource,
      inMapper: inMapper,
      outMapper: outMapper,
    );

    registerFallbackValue(
      TransactionEntity(
        date: 0,
        amount: 0,
        type: 'type',
        category: 'category',
        description: 'description',
      ),
    );
  });

  group('TransactionRepository', () {
    group('save', () {
      test('should insert when dto id is null', () {
        final dto = TransactionDto(
          id: null,
          amount: 10.0,
          type: .expense,
          category: .other,
          description: 'Lunch',
          date: DateTime.now(),
        );

        final entity = TransactionEntity(
          date: 123,
          amount: 10.0,
          type: 'expense',
          category: 'food',
          description: 'Lunch',
        );

        when(() => inMapper(dto)).thenReturn(entity);
        when(() => datasource.save(any())).thenAnswer((_) => Right(null));

        final data = repository.save(dto);

        expect(data.isRight, true);
        verifyNever(() => datasource.update(any()));
        verify(() => datasource.save(any())).called(1);
      });

      test('should update when dto id is not null', () {
        final dto = TransactionDto.empty().copyWith(id: 1);
        final entity = TransactionEntity(
          date: 456,
          amount: 20.0,
          type: 'income',
          category: 'salary',
          description: 'Salary',
        )..id = 1;

        when(() => inMapper(dto)).thenReturn(entity);
        when(() => datasource.update(entity)).thenReturn(const Right(null));

        final result = repository.save(dto);

        expect(result.isRight, true);
        verifyNever(() => datasource.save(any()));
        verify(() => datasource.update(entity)).called(1);
      });

      test('should return failure when datasource returns error on save', () {
        final dto = TransactionDto(
          id: null,
          amount: 10.0,
          type: .expense,
          category: .other,
          description: 'Lunch',
          date: DateTime.now(),
        );

        final entity = TransactionEntity(
          date: 123,
          amount: 10.0,
          type: 'expense',
          category: 'food',
          description: 'Lunch',
        );

        when(() => inMapper(dto)).thenReturn(entity);
        when(
          () => datasource.save(entity),
        ).thenReturn(const Left('Database error'));

        final data = repository.save(dto);
        expect(data.isLeft, true);
      });
    });

    group('find', () {
      test('should return TransactionModel when datasource returns entity', () {
        final entity = TransactionEntity(
          date: 789,
          amount: 15.0,
          type: 'expense',
          category: 'food',
          description: 'Dinner',
        )..id = 2;

        final model = TransactionModel(
          id: 2,
          date: 789,
          type: 'expense',
          amount: 15.0,
          category: 'food',
          description: 'Dinner',
        );

        when(() => datasource.find(2)).thenReturn(Right(entity));
        when(() => outMapper(entity)).thenReturn(model);

        final data = repository.find(2);

        expect(data.isRight, true);
      });

      test('should return failure when datasource returns error', () {
        when(() => datasource.find(99)).thenReturn(const Left('Not found'));

        final data = repository.find(99);

        expect(data.isLeft, true);
      });
    });

    group('delete', () {
      test('should delegate delete to datasource', () {
        when(() => datasource.delete(1)).thenReturn(const Right(null));

        final data = repository.delete(1);

        expect(data.isRight, true);
        verify(() => datasource.delete(1)).called(1);
      });

      test('should return failure when datasource returns error on delete', () {
        when(() => datasource.delete(1)).thenReturn(const Left('Delete error'));

        final data = repository.delete(1);

        expect(data.isLeft, true);
      });
    });
  });
}
