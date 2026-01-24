import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/core/domain/either/either.dart';

import 'package:trocado/modules/home/data/repositories/home_repository.dart';
import 'package:trocado/modules/home/domain/repositories/interface_home_repository.dart';
import 'package:trocado/modules/home/infrastructure/datasources/home_local_datasource.dart';
import 'package:trocado/modules/transaction/data/dtos/transaction_dto.dart';

import 'package:trocado/modules/transaction/data/mappers/transaction_mapper.dart';
import 'package:trocado/modules/transaction/domain/models/transaction_model.dart';
import 'package:trocado/modules/transaction/infrastructure/database/entities/transaction_entity.dart';

import '../../mocks/mocks.dart';

void main() {
  late IHomeRepository repository;
  late TransactionDtoMapper dtoMapper;
  late TransactionOutMapper outMapper;
  late IHomeLocalDatasource datasource;

  setUp(() {
    dtoMapper = MockTransactionDtoMapper();
    outMapper = MockTransactionOutMapper();
    datasource = MockHomeLocalDatasource();

    repository = HomeRepository(
      dtoMapper: dtoMapper,
      outMapper: outMapper,
      datasource: datasource,
    );

    registerFallbackValue(
      TransactionEntity(
        date: 0,
        amount: 0,
        type: 'income',
        category: 'category',
        description: 'description',
      ),
    );
  });

  group('HomeRepository', () {
    group('delete', () {
      test('should delegate delete to datasource', () {
        when(() => datasource.delete(1)).thenReturn(const Right(null));

        final data = repository.delete(1);

        expect(data.isRight, true);
        verify(() => datasource.delete(1)).called(1);
      });

      test('should return failure when datasource returns error on delete', () {
        when(
          () => datasource.delete(1),
        ).thenReturn(const Left('Delete failure'));

        final data = repository.delete(1);

        expect(data.isLeft, true);
      });
    });

    group('findByPeriod', () {
      test(
        'should return a list of TransactionModel when datasource returns entities',
        () {
          final entities = [
            TransactionEntity(
              date: 100,
              amount: 10,
              type: 'income',
              category: 'salary',
              description: 'Salary',
            )..id = 1,
            TransactionEntity(
              date: 200,
              amount: 5,
              type: 'expense',
              category: 'food',
              description: 'Lunch',
            )..id = 2,
          ];

          final models = [
            TransactionModel(
              id: 1,
              date: 100,
              amount: 10,
              type: 'income',
              category: 'salary',
              description: 'Salary',
            ),
            TransactionModel(
              id: 2,
              date: 200,
              amount: 5,
              type: 'expense',
              category: 'food',
              description: 'Lunch',
            ),
          ];

          when(
            () => datasource.findByPeriod(
              type: 'Receita',
              endAt: any(named: 'endAt'),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              startAt: any(named: 'startAt'),
            ),
          ).thenReturn(Right(entities));

          when(() => outMapper(entities[0])).thenReturn(models[0]);
          when(() => outMapper(entities[1])).thenReturn(models[1]);

          final data = repository.findByPeriod(
            endAt: 300,
            startAt: 0,
            type: .income,
          );

          expect(data.isRight, true);
          expect(data.right.length, 2);
          verify(() => outMapper(entities[0])).called(1);
          verify(() => outMapper(entities[1])).called(1);
        },
      );

      test('should pass null type to datasource when filter type is null', () {
        when(
          () => datasource.findByPeriod(
            type: null,
            endAt: any(named: 'endAt'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            startAt: any(named: 'startAt'),
          ),
        ).thenReturn(const Right([]));

        final data = repository.findByPeriod(startAt: 0, endAt: 100);

        expect(data.isRight, true);
        verify(
          () => datasource.findByPeriod(
            endAt: 100,
            startAt: 0,
            type: null,
            limit: null,
            offset: null,
          ),
        ).called(1);
      });

      test('should return failure when datasource returns error', () {
        when(
          () => datasource.findByPeriod(
            type: any(named: 'type'),
            endAt: any(named: 'endAt'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            startAt: any(named: 'startAt'),
          ),
        ).thenReturn(const Left('Datasource error'));

        final data = repository.findByPeriod(
          endAt: 100,
          startAt: 0,
          type: .expense,
        );

        expect(data.isLeft, true);
      });
    });
  });

  group('toDto', () {
    test('should map TransactionModel to TransactionDto using dtoMapper', () {
      final model = TransactionModel(
        id: 1,
        amount: 100.5,
        type: 'expense',
        category: 'food',
        date: 1704067200000,
        description: 'Groceries',
        observation: 'Weekly shopping',
      );

      final dto = TransactionDto(
        type: .expense,
        category: .food,
        amount: '100.5',
        description: 'Groceries',
        observation: 'Weekly shopping',
        date: DateTime.fromMillisecondsSinceEpoch(1704067200000),
      );

      when(() => dtoMapper(model)).thenReturn(dto);

      final data = repository.toDto(model);

      expect(data, dto);
      verify(() => dtoMapper(model)).called(1);
    });
  });
}
