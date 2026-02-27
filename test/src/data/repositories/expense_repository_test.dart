import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/data/mapper/expense_mapper.dart';
import 'package:trocado/src/data/repositories/expense_repository.dart';
import 'package:trocado/src/data/datasources/interface_expense_data_source.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/models/expense_model.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/infrastructure/clients/database/entities/expense_entity.dart';

import '../../../mocks/mocks.dart';

void main() {
  late IExpenseRepository repository;
  late IExpenseDataSource dataSource;
  late ExpenseEntityToModelMapper expenseToModelMapper;
  late ExpenseModelToEntityMapper expenseEntityMapper;

  final expenseEntity = ExpenseEntity(
    id: 1,
    amount: 100.50,
    date: 1704067200000,
    category: 'Alimentação',
    description: 'Compras semanal',
  );

  final expenseModel = ExpenseModel(
    id: 1,
    amount: 100.50,
    date: 1704067200000,
    category: 'Alimentação',
    description: 'Compras semanal',
  );

  setUpAll(() {
    registerFallbackValue(expenseModel);
    registerFallbackValue(expenseEntity);
  });

  setUp(() {
    dataSource = MockExpenseDataSource();
    expenseToModelMapper = MockExpenseEntityToModelMapper();
    expenseEntityMapper = MockExpenseModelToEntityMapper();

    repository = ExpenseRepository(
      dataSource: dataSource,
      expenseToModelMapper: expenseToModelMapper,
      expenseToEntityMapper: expenseEntityMapper,
    );
  });

  group('ExpenseRepository', () {
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
        ).thenReturn(const Left('Despesa não encontrada.'));

        final data = repository.deleteById(1);

        expect(data.isLeft, true);
        expect(data.left, 'Despesa não encontrada.');
      });
    });

    group('findById', () {
      test('should return mapped ExpenseModel on success', () {
        when(() => dataSource.findById(1)).thenReturn(Right(expenseEntity));

        when(
          () => expenseToModelMapper.call(expenseEntity),
        ).thenReturn(expenseModel);

        final data = repository.findById(1);

        expect(data.isRight, true);
        expect(data.right, expenseModel);
        verify(() => dataSource.findById(1)).called(1);
        verify(() => expenseToModelMapper.call(expenseEntity)).called(1);
      });

      test('should return Left when dataSource returns error', () {
        when(
          () => dataSource.findById(99),
        ).thenReturn(const Left('Despesa não encontrada.'));

        final data = repository.findById(99);

        expect(data.isLeft, true);
        expect(data.left, 'Despesa não encontrada.');
        verifyNever(() => expenseToModelMapper.call(any()));
      });
    });

    group('upsert', () {
      test('should call upsert when model.id is null', () {
        final newModel = ExpenseModel(
          id: null,
          amount: 100.50,
          date: 1704067200000,
          category: 'Alimentação',
          description: 'Compras semanal',
        );

        final newEntity = ExpenseEntity(
          id: 0,
          amount: 100.50,
          date: 1704067200000,
          category: 'Alimentação',
          description: 'Compras semanal',
        );

        when(() => expenseEntityMapper.call(newModel)).thenReturn(newEntity);
        when(() => dataSource.upsert(any())).thenReturn(const Right(null));

        final data = repository.upsert(newModel);

        expect(data.isRight, true);
        verify(() => expenseEntityMapper.call(newModel)).called(1);
        verify(() => dataSource.upsert(newEntity)).called(1);
        verifyNever(() => dataSource.upsert(any()));
      });

      test('should call upsert when model.id is not null', () {
        when(
          () => expenseEntityMapper.call(expenseModel),
        ).thenReturn(expenseEntity);

        when(
          () => dataSource.upsert(expenseEntity),
        ).thenReturn(const Right(null));

        final data = repository.upsert(expenseModel);

        expect(data.isRight, true);
        verify(() => expenseEntityMapper.call(expenseModel)).called(1);
        verify(() => dataSource.upsert(expenseEntity)).called(1);
        verifyNever(() => dataSource.upsert(any()));
      });

      test('should return Left when save fails', () {
        final newModel = ExpenseModel(
          id: null,
          amount: 100.50,
          date: 1704067200000,
          category: 'Alimentação',
          description: 'Compras semanal',
        );

        final newEntity = ExpenseEntity(
          id: 1,
          amount: 100.50,
          date: 1704067200000,
          category: 'Alimentação',
          description: 'Compras semanal',
        );

        when(() => expenseEntityMapper.call(newModel)).thenReturn(newEntity);
        when(
          () => dataSource.upsert(any()),
        ).thenReturn(const Left('Ops, a operação falhou.'));

        final data = repository.upsert(newModel);

        expect(data.isLeft, true);
        expect(data.left, 'Ops, a operação falhou.');
      });

      test('should return Left when update fails', () {
        when(
          () => expenseEntityMapper.call(expenseModel),
        ).thenReturn(expenseEntity);

        when(
          () => dataSource.upsert(expenseEntity),
        ).thenReturn(const Left('Despesa não encontrada.'));

        final data = repository.upsert(expenseModel);

        expect(data.isLeft, true);
        expect(data.left, 'Despesa não encontrada.');
      });
    });

    group('findByPeriod', () {
      test('should return mapped list of ExpenseModel on success', () {
        final entities = [
          ExpenseEntity(
            id: 1,
            amount: 100.0,
            date: 1704067200000,
            category: 'Alimentação',
            description: 'Compras semanal',
          ),
          ExpenseEntity(
            id: 2,
            amount: 50.0,
            date: 1704153600000,
            description: 'Almoço',
            category: 'Alimentação',
          ),
        ];

        final models = [
          ExpenseModel(
            id: 1,
            amount: 100.0,
            date: 1704067200000,
            category: 'Alimentação',
            description: 'Compras semanal',
          ),
          ExpenseModel(
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
          () => expenseToModelMapper.call(entities[0]),
        ).thenReturn(models[0]);
        when(
          () => expenseToModelMapper.call(entities[1]),
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
        verify(() => expenseToModelMapper.call(entities[0])).called(1);
        verify(() => expenseToModelMapper.call(entities[1])).called(1);
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

      test('should return empty list when no expenses found', () {
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
        verifyNever(() => expenseToModelMapper.call(any()));
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
        verifyNever(() => expenseToModelMapper.call(any()));
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
