import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/data/mapper/transaction_to_model_mapper.dart';
import 'package:trocado/src/data/mapper/transaction_to_entity_mapper.dart';
import 'package:trocado/src/data/repositories/transaction_repository.dart';
import 'package:trocado/src/data/datasources/interface_transaction_data_source.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/models/transaction_model.dart';
import 'package:trocado/src/domain/repositories/interface_transaction_repository.dart';

import 'package:trocado/src/infrastructure/clients/database/entities/transaction_entity.dart';

import '../../../mocks/mocks.dart';

void main() {
  late ITransactionRepository repository;
  late ITransactionDataSource dataSource;
  late TransactionToModelMapper transactionToModelMapper;
  late TransactionToEntityMapper transactionToEntityMapper;

  final transactionEntity = TransactionEntity(
    id: 1,
    amount: 100.50,
    category: 'Salário',
    date: 1704067200000,
    description: 'Salário mensal',
  );

  final transactionModel = TransactionModel(
    id: 1,
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

          final data = repository.deleteById(1);

          expect(data.isRight, true);
          verify(() => dataSource.deleteById(1)).called(1);
        },
      );

      test('should return Left when datasource returns error', () {
        when(
          () => dataSource.deleteById(1),
        ).thenReturn(const Left('Transação não encontrada.'));

        final data = repository.deleteById(1);

        expect(data.isLeft, true);
        expect(data.left, 'Transação não encontrada.');
      });
    });

    group('findById', () {
      test('should return mapped TransactionModel on success', () {
        when(() => dataSource.findById(1)).thenReturn(Right(transactionEntity));

        when(
          () => transactionToModelMapper.call(transactionEntity),
        ).thenReturn(transactionModel);

        final data = repository.findById(1);

        expect(data.isRight, true);
        expect(data.right, transactionModel);
        verify(() => dataSource.findById(1)).called(1);
        verify(
          () => transactionToModelMapper.call(transactionEntity),
        ).called(1);
      });

      test('should return Left when datasource returns error', () {
        when(
          () => dataSource.findById(99),
        ).thenReturn(const Left('Transação não encontrada.'));

        final data = repository.findById(99);

        expect(data.isLeft, true);
        expect(data.left, 'Transação não encontrada.');
        verifyNever(() => transactionToModelMapper.call(any()));
      });
    });

    group('upsert', () {
      test('should call upsert when model.id is null', () {
        final newModel = TransactionModel(
          id: null,
          amount: 100.50,
          category: 'Salário',
          date: 1704067200000,
          description: 'Salário mensal',
        );

        final newEntity = TransactionEntity(
          id: 0,
          amount: 100.50,
          category: 'Salário',
          date: 1704067200000,
          description: 'Salário mensal',
        );

        when(
          () => transactionToEntityMapper.call(newModel),
        ).thenReturn(newEntity);
        when(() => dataSource.upsert(any())).thenReturn(const Right(null));

        final data = repository.upsert(newModel);

        expect(data.isRight, true);
        verify(() => transactionToEntityMapper.call(newModel)).called(1);
        verify(() => dataSource.upsert(newEntity)).called(1);
        verifyNever(() => dataSource.upsert(any()));
      });

      test('should call upsert when model.id is not null', () {
        when(
          () => transactionToEntityMapper.call(transactionModel),
        ).thenReturn(transactionEntity);

        when(
          () => dataSource.upsert(transactionEntity),
        ).thenReturn(const Right(null));

        final data = repository.upsert(transactionModel);

        expect(data.isRight, true);
        verify(
          () => transactionToEntityMapper.call(transactionModel),
        ).called(1);
        verify(() => dataSource.upsert(transactionEntity)).called(1);
        verifyNever(() => dataSource.upsert(any()));
      });

      test('should return Left when save fails', () {
        final newModel = TransactionModel(
          id: null,
          amount: 100.50,
          category: 'Salário',
          date: 1704067200000,
          description: 'Salário mensal',
        );

        final newEntity = TransactionEntity(
          id: 1,
          amount: 100.50,
          category: 'Salário',
          date: 1704067200000,
          description: 'Salário mensal',
        );

        when(
          () => transactionToEntityMapper.call(newModel),
        ).thenReturn(newEntity);
        when(
          () => dataSource.upsert(any()),
        ).thenReturn(const Left('Ops, a operação falhou.'));

        final data = repository.upsert(newModel);

        expect(data.isLeft, true);
        expect(data.left, 'Ops, a operação falhou.');
      });

      test('should return Left when update fails', () {
        when(
          () => transactionToEntityMapper.call(transactionModel),
        ).thenReturn(transactionEntity);

        when(
          () => dataSource.upsert(transactionEntity),
        ).thenReturn(const Left('Transação não encontrada.'));

        final data = repository.upsert(transactionModel);

        expect(data.isLeft, true);
        expect(data.left, 'Transação não encontrada.');
      });
    });

    group('findByPeriod', () {
      test('should return mapped list of TransactionModel on success', () {
        final entities = [
          TransactionEntity(
            id: 1,
            amount: 100.0,
            category: 'Salário',
            date: 1704067200000,
            description: 'Salário',
          ),
          TransactionEntity(
            id: 2,
            amount: 50.0,
            date: 1704153600000,
            description: 'Almoço',
            category: 'Alimentação',
          ),
        ];

        final models = [
          TransactionModel(
            id: 1,
            amount: 100.0,
            date: 1704067200000,
            category: 'Salário',
            description: 'Salário',
          ),
          TransactionModel(
            id: 2,
            amount: 50.0,
            date: 1704153600000,
            description: 'Almoço',
            category: 'Alimentação',
          ),
        ];

        when(
          () => dataSource.findByPeriod(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            startAt: any(named: 'startAt'),
            endAt: any(named: 'endAt'),
          ),
        ).thenReturn(Right(entities));

        when(
          () => transactionToModelMapper.call(entities[0]),
        ).thenReturn(models[0]);
        when(
          () => transactionToModelMapper.call(entities[1]),
        ).thenReturn(models[1]);

        final data = repository.findByPeriod(
          offset: 0,
          limit: 10,
          startAt: 1000,
          endAt: 2000,
        );

        expect(data.isRight, true);
        expect(data.right.length, 2);
        expect(data.right[0], models[0]);
        expect(data.right[1], models[1]);
        verify(
          () => dataSource.findByPeriod(
            startAt: 1000,
            endAt: 2000,
            limit: 10,
            offset: 0,
          ),
        ).called(1);
        verify(() => transactionToModelMapper.call(entities[0])).called(1);
        verify(() => transactionToModelMapper.call(entities[1])).called(1);
      });

      test('should pass type label when type is provided', () {
        when(
          () => dataSource.findByPeriod(
            startAt: any(named: 'startAt'),
            endAt: any(named: 'endAt'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenReturn(const Right([]));

        final data = repository.findByPeriod(startAt: 1000, endAt: 2000);

        expect(data.isRight, true);
        expect(data.right, isEmpty);
        verify(
          () => dataSource.findByPeriod(startAt: 1000, endAt: 2000),
        ).called(1);
      });

      test('should return empty list when no transactions found', () {
        when(
          () => dataSource.findByPeriod(
            startAt: any(named: 'startAt'),
            endAt: any(named: 'endAt'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenReturn(const Right([]));

        final data = repository.findByPeriod();

        expect(data.isRight, true);
        expect(data.right, isEmpty);
        verifyNever(() => transactionToModelMapper.call(any()));
      });

      test('should return Left when datasource returns error', () {
        when(
          () => dataSource.findByPeriod(
            startAt: any(named: 'startAt'),
            endAt: any(named: 'endAt'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenReturn(const Left('Ops, a operação falhou.'));

        final data = repository.findByPeriod();

        expect(data.isLeft, true);
        expect(data.left, 'Ops, a operação falhou.');
        verifyNever(() => transactionToModelMapper.call(any()));
      });

      test('should handle all optional parameters', () {
        when(
          () => dataSource.findByPeriod(
            startAt: any(named: 'startAt'),
            endAt: any(named: 'endAt'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenReturn(const Right([]));

        final data = repository.findByPeriod(
          startAt: 1000,
          endAt: 2000,
          limit: 20,
          offset: 5,
        );

        expect(data.isRight, true);
        verify(
          () => dataSource.findByPeriod(
            startAt: 1000,
            endAt: 2000,
            limit: 20,
            offset: 5,
          ),
        ).called(1);
      });
    });
  });
}
