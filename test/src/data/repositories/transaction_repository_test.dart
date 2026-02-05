import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/data/mapper/transaction_to_model_mapper.dart';
import 'package:trocado/src/data/mapper/transaction_to_entity_mapper.dart';
import 'package:trocado/src/data/repositories/transaction_repository.dart';
import 'package:trocado/src/data/datasources/interface_transaction_data_source.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/models/balance_model.dart';
import 'package:trocado/src/domain/models/transaction_model.dart';
import 'package:trocado/src/domain/repositories/interface_transaction_repository.dart';

import 'package:trocado/src/infrastructure/datasources/local/transaction_data_source.dart';
import 'package:trocado/src/infrastructure/clients/database/entities/transaction_entity.dart';

import '../../../mocks/mocks.dart';

void main() {
  late ITransactionRepository repository;
  late ITransactionDataSource dataSource;
  late TransactionToModelMapper transactionToModelMapper;
  late TransactionToEntityMapper transactionToEntityMapper;

  final transactionEntity = TransactionEntity(
    id: 1,
    type: 'income',
    amount: 100.50,
    observation: null,
    category: 'Salário',
    date: 1704067200000,
    description: 'Salário mensal',
  );

  final transactionModel = TransactionModel(
    id: 1,
    type: 'income',
    amount: 100.50,
    category: 'Salário',
    date: 1704067200000,
    description: 'Salário mensal',
  );

  setUpAll(() {
    registerFallbackValue(transactionModel);
    registerFallbackValue(transactionEntity);
  });

  setUp(() {
    dataSource = MockTransactionDataSource();
    transactionToModelMapper = MockTransactionToModelMapper();
    transactionToEntityMapper = MockTransactionToEntityMapper();

    repository = TransactionRepository(
      dataSource: dataSource,
      transactionToModelMapper: transactionToModelMapper,
      transactionToEntityMapper: transactionToEntityMapper,
    );
  });

  group('TransactionRepository', () {
    group('deleteById', () {
      test(
        'should delegate delete to datasource and return Right on success',
        () {
          when(() => dataSource.deleteById(1)).thenReturn(const Right(null));

          final result = repository.deleteById(1);

          expect(result.isRight, true);
          verify(() => dataSource.deleteById(1)).called(1);
        },
      );

      test('should return Left when datasource returns error', () {
        when(
          () => dataSource.deleteById(1),
        ).thenReturn(const Left('Transação não encontrada.'));

        final result = repository.deleteById(1);

        expect(result.isLeft, true);
        expect(result.left, 'Transação não encontrada.');
      });
    });

    group('findById', () {
      test('should return mapped TransactionModel on success', () {
        when(() => dataSource.findById(1)).thenReturn(Right(transactionEntity));

        when(
          () => transactionToModelMapper.call(transactionEntity),
        ).thenReturn(transactionModel);

        final result = repository.findById(1);

        expect(result.isRight, true);
        expect(result.right, transactionModel);
        verify(() => dataSource.findById(1)).called(1);
        verify(
          () => transactionToModelMapper.call(transactionEntity),
        ).called(1);
      });

      test('should return Left when datasource returns error', () {
        when(
          () => dataSource.findById(99),
        ).thenReturn(const Left('Transação não encontrada.'));

        final result = repository.findById(99);

        expect(result.isLeft, true);
        expect(result.left, 'Transação não encontrada.');
        verifyNever(() => transactionToModelMapper.call(any()));
      });
    });

    group('saveTransactionByModel', () {
      test('should call saveTransactionByEntity when model.id is null', () {
        final newModel = TransactionModel(
          id: null,
          date: 1704067200000,
          type: 'income',
          amount: 100.50,
          category: 'Salário',
          description: 'Salário mensal',
        );

        final newEntity = TransactionEntity(
          date: 1704067200000,
          type: 'income',
          amount: 100.50,
          category: 'Salário',
          description: 'Salário mensal',
          observation: null,
        );

        when(
          () => transactionToEntityMapper.call(newModel),
        ).thenReturn(newEntity);
        when(
          () => dataSource.saveTransactionByEntity(any()),
        ).thenReturn(const Right(null));

        final result = repository.saveTransactionByModel(newModel);

        expect(result.isRight, true);
        verify(() => transactionToEntityMapper.call(newModel)).called(1);
        verify(() => dataSource.saveTransactionByEntity(newEntity)).called(1);
        verifyNever(() => dataSource.updateTransactionById(any(), any()));
      });

      test('should call updateTransactionById when model.id is not null', () {
        when(
          () => transactionToEntityMapper.call(transactionModel),
        ).thenReturn(transactionEntity);

        when(
          () => dataSource.updateTransactionById(1, transactionEntity),
        ).thenReturn(const Right(null));

        final result = repository.saveTransactionByModel(transactionModel);

        expect(result.isRight, true);
        verify(
          () => transactionToEntityMapper.call(transactionModel),
        ).called(1);
        verify(
          () => dataSource.updateTransactionById(1, transactionEntity),
        ).called(1);
        verifyNever(() => dataSource.saveTransactionByEntity(any()));
      });

      test('should return Left when save fails', () {
        final newModel = TransactionModel(
          id: null,
          date: 1704067200000,
          type: 'income',
          amount: 100.50,
          category: 'Salário',
          description: 'Salário mensal',
        );

        final newEntity = TransactionEntity(
          date: 1704067200000,
          type: 'income',
          amount: 100.50,
          category: 'Salário',
          description: 'Salário mensal',
          observation: null,
        );

        when(
          () => transactionToEntityMapper.call(newModel),
        ).thenReturn(newEntity);
        when(
          () => dataSource.saveTransactionByEntity(any()),
        ).thenReturn(const Left('Ops, a operação falhou.'));

        final result = repository.saveTransactionByModel(newModel);

        expect(result.isLeft, true);
        expect(result.left, 'Ops, a operação falhou.');
      });

      test('should return Left when update fails', () {
        when(
          () => transactionToEntityMapper.call(transactionModel),
        ).thenReturn(transactionEntity);

        when(
          () => dataSource.updateTransactionById(1, transactionEntity),
        ).thenReturn(const Left('Transação não encontrada.'));

        final result = repository.saveTransactionByModel(transactionModel);

        expect(result.isLeft, true);
        expect(result.left, 'Transação não encontrada.');
      });
    });

    group('findTransactionBy', () {
      test('should return mapped list of TransactionModel on success', () {
        final entities = [
          TransactionEntity(
            date: 1704067200000,
            type: 'income',
            amount: 100.0,
            category: 'Salário',
            description: 'Salário',
            observation: null,
          )..id = 1,
          TransactionEntity(
            date: 1704153600000,
            type: 'expense',
            amount: 50.0,
            category: 'Alimentação',
            description: 'Almoço',
            observation: null,
          )..id = 2,
        ];

        final models = [
          TransactionModel(
            id: 1,
            date: 1704067200000,
            type: 'income',
            amount: 100.0,
            category: 'Salário',
            description: 'Salário',
          ),
          TransactionModel(
            id: 2,
            date: 1704153600000,
            type: 'expense',
            amount: 50.0,
            category: 'Alimentação',
            description: 'Almoço',
          ),
        ];

        when(
          () => dataSource.findTransactionBy(
            startAt: any(named: 'startAt'),
            endAt: any(named: 'endAt'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            type: any(named: 'type'),
          ),
        ).thenReturn(Right(entities));

        when(
          () => transactionToModelMapper.call(entities[0]),
        ).thenReturn(models[0]);
        when(
          () => transactionToModelMapper.call(entities[1]),
        ).thenReturn(models[1]);

        final result = repository.findTransactionBy(
          startAt: 1000,
          endAt: 2000,
          limit: 10,
          offset: 0,
        );

        expect(result.isRight, true);
        expect(result.right.length, 2);
        expect(result.right[0], models[0]);
        expect(result.right[1], models[1]);
        verify(
          () => dataSource.findTransactionBy(
            startAt: 1000,
            endAt: 2000,
            limit: 10,
            offset: 0,
            type: null,
          ),
        ).called(1);
        verify(() => transactionToModelMapper.call(entities[0])).called(1);
        verify(() => transactionToModelMapper.call(entities[1])).called(1);
      });

      test('should pass type label when type is provided', () {
        when(
          () => dataSource.findTransactionBy(
            startAt: any(named: 'startAt'),
            endAt: any(named: 'endAt'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            type: any(named: 'type'),
          ),
        ).thenReturn(const Right([]));

        final result = repository.findTransactionBy(
          startAt: 1000,
          endAt: 2000,
          type: TransactionTypeModel.income,
        );

        expect(result.isRight, true);
        expect(result.right, isEmpty);
        verify(
          () => dataSource.findTransactionBy(
            startAt: 1000,
            endAt: 2000,
            type: 'Receita',
          ),
        ).called(1);
      });

      test('should return empty list when no transactions found', () {
        when(
          () => dataSource.findTransactionBy(
            startAt: any(named: 'startAt'),
            endAt: any(named: 'endAt'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            type: any(named: 'type'),
          ),
        ).thenReturn(const Right([]));

        final result = repository.findTransactionBy();

        expect(result.isRight, true);
        expect(result.right, isEmpty);
        verifyNever(() => transactionToModelMapper.call(any()));
      });

      test('should return Left when datasource returns error', () {
        when(
          () => dataSource.findTransactionBy(
            startAt: any(named: 'startAt'),
            endAt: any(named: 'endAt'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            type: any(named: 'type'),
          ),
        ).thenReturn(const Left('Ops, a operação falhou.'));

        final result = repository.findTransactionBy();

        expect(result.isLeft, true);
        expect(result.left, 'Ops, a operação falhou.');
        verifyNever(() => transactionToModelMapper.call(any()));
      });

      test('should handle all optional parameters', () {
        when(
          () => dataSource.findTransactionBy(
            startAt: any(named: 'startAt'),
            endAt: any(named: 'endAt'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            type: any(named: 'type'),
          ),
        ).thenReturn(const Right([]));

        final result = repository.findTransactionBy(
          startAt: 1000,
          endAt: 2000,
          limit: 20,
          offset: 5,
          type: TransactionTypeModel.expense,
        );

        expect(result.isRight, true);
        verify(
          () => dataSource.findTransactionBy(
            startAt: 1000,
            endAt: 2000,
            limit: 20,
            offset: 5,
            type: 'Despesa',
          ),
        ).called(1);
      });
    });
  });
}
