import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/core/domain/either/either.dart';

import 'package:trocado/modules/transaction/data/dtos/transaction_dto.dart';
import 'package:trocado/modules/transaction/data/mappers/transaction_mapper.dart';
import 'package:trocado/modules/transaction/data/repositories/transaction_repository.dart';

import 'package:trocado/modules/transaction/domain/models/transaction_model.dart';
import 'package:trocado/modules/transaction/domain/repositories/interface_transaction_repository.dart';

import 'package:trocado/modules/transaction/infrastructure/database/entities/transaction_entity.dart';
import 'package:trocado/modules/transaction/infrastructure/datasources/local/transaction_local_datasource.dart';

import '../../../../mocks/mocks.dart';

void main() {
  late TransactionInMapper inMapper;
  late TransactionDtoMapper dtoMapper;
  late TransactionOutMapper outMapper;
  late ITransactionRepository repository;
  late ITransactionLocalDatasource datasource;

  setUp(() {
    inMapper = MockTransactionInMapper();
    dtoMapper = MockTransactionDtoMapper();
    outMapper = MockTransactionOutMapper();
    datasource = MockTransactionLocalDatasource();

    repository = TransactionRepository(
      inMapper: inMapper,
      dtoMapper: dtoMapper,
      outMapper: outMapper,
      datasource: datasource,
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
        verifyNever(() => datasource.update(any(), any()));
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
        when(
          () => datasource.update(any(), entity),
        ).thenReturn(const Right(null));

        final result = repository.save(dto);

        expect(result.isRight, true);
        verifyNever(() => datasource.save(any()));
        verify(() => datasource.update(any(), entity)).called(1);
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
          amount: 15.0,
          type: 'expense',
          category: 'food',
          description: 'Dinner',
        );

        when(() => outMapper(entity)).thenReturn(model);
        when(() => datasource.find(2)).thenReturn(Right(entity));

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
