import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trocado/src/data/mapper/balance_to_model_mapper.dart';

import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/data/mapper/transaction_to_model_mapper.dart';
import 'package:trocado/src/data/mapper/transaction_to_entity_mapper.dart';
import 'package:trocado/src/data/repositories/transaction_repository.dart';

import 'package:trocado/src/domain/repositories/interface_transaction_repository.dart';

import 'package:trocado/src/infrastructure/database/entities/transaction_entity.dart';
import 'package:trocado/src/infrastructure/datasources/local/transaction_local_datasource.dart';

import '../../../mocks/mocks.dart';

void main() {
  late ITransactionRepository repository;
  late ITransactionLocalDatasource datasource;
  late BalanceToModelMapper balanceToModelMapper;
  late TransactionToModelMapper transactionToModelMapper;
  late TransactionToEntityMapper transactionToEntityMapper;

  setUp(() {
    datasource = MockTransactionLocalDatasource();
    balanceToModelMapper = MockBalanceToModelMapper();
    transactionToModelMapper = MockTransactionToModelMapper();
    transactionToEntityMapper = MockTransactionToEntityMapper();

    repository = TransactionRepository(
      datasource: datasource,
      balanceToModelMapper: balanceToModelMapper,
      transactionToModelMapper: transactionToModelMapper,
      transactionToEntityMapper: transactionToEntityMapper,
    );

    registerFallbackValue(
      TransactionEntity(
        date: 0,
        amount: 0,
        type: 'type',
        category: 'category',
        description: 'description',
        observation: 'observation',
      ),
    );
  });

  group('TransactionRepository', () {
    test('should return failure when datasource returns error', () {
      when(
        () => datasource.findTransactionById(99),
      ).thenReturn(const Left('Not found'));

      final data = repository.findTransactionById(99);

      expect(data.isLeft, true);
    });

    group('delete', () {
      test('should delegate delete to datasource', () {
        when(
          () => datasource.deleteTransactionById(1),
        ).thenReturn(const Right(null));

        final data = repository.deleteTransactionById(1);

        expect(data.isRight, true);
        verify(() => datasource.deleteTransactionById(1)).called(1);
      });

      test('should return failure when datasource returns error on delete', () {
        when(
          () => datasource.deleteTransactionById(1),
        ).thenReturn(const Left('Delete error'));

        final data = repository.deleteTransactionById(1);

        expect(data.isLeft, true);
      });
    });
  });
}
