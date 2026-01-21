import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/core/domain/either/either.dart';

import 'package:trocado/modules/home/data/repositories/home_repository.dart';
import 'package:trocado/modules/home/domain/repositories/interface_home_repository.dart';
import 'package:trocado/modules/home/infrastructure/datasources/home_local_datasource.dart';

import 'package:trocado/modules/transaction/data/mappers/transaction_mapper.dart';
import 'package:trocado/modules/transaction/domain/models/transaction_model.dart';
import 'package:trocado/modules/transaction/infrastructure/database/entities/transaction_entity.dart';

import '../../mocks/mocks.dart';

void main() {
  late IHomeRepository repository;
  late TransactionOutMapper mapper;
  late IHomeLocalDatasource datasource;

  setUp(() {
    datasource = MockHomeLocalDatasource();
    mapper = MockTransactionOutMapper();

    repository = HomeRepository(datasource: datasource, mapper: mapper);

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

          when(() => mapper(entities[0])).thenReturn(models[0]);
          when(() => mapper(entities[1])).thenReturn(models[1]);

          final data = repository.findByPeriod(
            endAt: 300,
            startAt: 0,
            type: .income,
          );

          expect(data.isRight, true);
          expect(data.right.length, 2);
          verify(() => mapper(entities[0])).called(1);
          verify(() => mapper(entities[1])).called(1);
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
}
