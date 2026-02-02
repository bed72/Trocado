import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/data/mapper/balance_to_model_mapper.dart';
import 'package:trocado/src/data/repositories/home_repository.dart';
import 'package:trocado/src/domain/models/balance_model.dart';
import 'package:trocado/src/domain/repositories/interface_home_repository.dart';
import 'package:trocado/src/infrastructure/datasources/local/home_local_datasource.dart';
import 'package:trocado/src/infrastructure/database/entities/balance_entity.dart';

import 'package:trocado/src/data/mapper/transaction_to_model_mapper.dart';
import 'package:trocado/src/domain/models/transaction_model.dart';
import 'package:trocado/src/infrastructure/database/entities/transaction_entity.dart';

import '../../../mocks/mocks.dart';

void main() {
  late IHomeRepository repository;
  late IHomeLocalDatasource datasource;
  late BalanceToModelMapper balanceToModelMapper;
  late TransactionToModelMapper transactionToModelMapper;

  registerFallbackValue(BalanceEntity(total: 0, income: 0, expense: 0));

  setUp(() {
    datasource = MockHomeLocalDatasource();
    balanceToModelMapper = MockBalanceToModelMapper();
    transactionToModelMapper = MockTransactionToModelMapper();

    repository = HomeRepository(
      datasource: datasource,
      balanceToModelMapper: balanceToModelMapper,
      transactionToModelMapper: transactionToModelMapper,
    );

    registerFallbackValue(
      TransactionEntity(
        date: 0,
        amount: 0,
        type: 'income',
        category: 'category',
        description: 'description',
        observation: 'observation',
      ),
    );
  });

  group('HomeRepository', () {
    group('delete', () {
      test('should delegate delete to datasource', () {
        when(
          () => datasource.deleteTransactionBy(1),
        ).thenReturn(const Right(null));

        final data = repository.deleteTransactionBy(1);

        expect(data.isRight, true);
        verify(() => datasource.deleteTransactionBy(1)).called(1);
      });

      test('should return failure when datasource returns error on delete', () {
        when(
          () => datasource.deleteTransactionBy(1),
        ).thenReturn(const Left('Delete failure'));

        final data = repository.deleteTransactionBy(1);

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
              observation: 'observation',
            )..id = 1,
            TransactionEntity(
              date: 200,
              amount: 5,
              type: 'expense',
              category: 'food',
              description: 'Lunch',
              observation: 'observation',
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
            () => datasource.findTransactionBy(
              type: 'Receita',
              endAt: any(named: 'endAt'),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              startAt: any(named: 'startAt'),
            ),
          ).thenReturn(Right(entities));

          when(
            () => transactionToModelMapper(entities[0]),
          ).thenReturn(models[0]);
          when(
            () => transactionToModelMapper(entities[1]),
          ).thenReturn(models[1]);

          final data = repository.findTransactionBy(
            endAt: 300,
            startAt: 0,
            type: .income,
          );

          expect(data.isRight, true);
          expect(data.right.length, 2);
          verify(() => transactionToModelMapper(entities[0])).called(1);
          verify(() => transactionToModelMapper(entities[1])).called(1);
        },
      );

      test('should pass null type to datasource when filter type is null', () {
        when(
          () => datasource.findTransactionBy(
            type: null,
            endAt: any(named: 'endAt'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            startAt: any(named: 'startAt'),
          ),
        ).thenReturn(const Right([]));

        final data = repository.findTransactionBy(startAt: 0, endAt: 100);

        expect(data.isRight, true);
        verify(
          () => datasource.findTransactionBy(
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
          () => datasource.findTransactionBy(
            type: any(named: 'type'),
            endAt: any(named: 'endAt'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            startAt: any(named: 'startAt'),
          ),
        ).thenReturn(const Left('Datasource error'));

        final data = repository.findTransactionBy(
          endAt: 100,
          startAt: 0,
          type: .expense,
        );

        expect(data.isLeft, true);
      });
    });
  });

  group('getBalanceByPeriod', () {
    test(
      'should return BalanceModel when datasource returns BalanceEntity',
      () {
        final model = BalanceModel(income: 1000, expense: 400, total: 600);
        final entity = BalanceEntity(income: 1000, expense: 400, total: 600);

        when(
          () => datasource.getBalanceBy(
            endAt: any(named: 'endAt'),
            startAt: any(named: 'startAt'),
          ),
        ).thenReturn(Right(entity));

        when(() => balanceToModelMapper(entity)).thenReturn(model);

        final data = repository.getBalanceBy(startAt: 0, endAt: 100);

        expect(data.right, model);
        expect(data.isRight, true);

        verify(() => datasource.getBalanceBy(startAt: 0, endAt: 100)).called(1);

        verify(() => balanceToModelMapper(entity)).called(1);
      },
    );

    test('should return failure when datasource returns error', () {
      when(
        () => datasource.getBalanceBy(
          endAt: any(named: 'endAt'),
          startAt: any(named: 'startAt'),
        ),
      ).thenReturn(const Left('Datasource error'));

      final data = repository.getBalanceBy(startAt: 0, endAt: 100);

      expect(data.isLeft, true);

      verify(() => datasource.getBalanceBy(startAt: 0, endAt: 100)).called(1);

      verifyNever(() => balanceToModelMapper(any()));
    });
  });
}
