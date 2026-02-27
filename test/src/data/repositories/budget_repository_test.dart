import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/data/repositories/budget_repository.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/models/budget_model.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';

import 'package:trocado/src/infrastructure/clients/database/entities/budget_entity.dart';

import '../../../mocks/mocks.dart';

void main() {
  late IBudgetRepository repository;
  late MockBudgetDataSource dataSource;
  late MockBudgetEntityToModelMapper entityToModelMapper;
  late MockBudgetModelToEntityMapper modelToEntityMapper;

  final budgetEntity = BudgetEntity(
    id: 1,
    amount: 1000.0,
    startDate: 1000,
    endDate: 2000,
    description: 'Fevereiro',
  );

  final budgetModel = BudgetModel(
    id: 1,
    amount: 1000.0,
    startDate: 1000,
    endDate: 2000,
    description: 'Fevereiro',
  );

  setUpAll(() {
    registerFallbackValue(budgetModel);
    registerFallbackValue(budgetEntity);
  });

  setUp(() {
    dataSource = MockBudgetDataSource();
    entityToModelMapper = MockBudgetEntityToModelMapper();
    modelToEntityMapper = MockBudgetModelToEntityMapper();

    repository = BudgetRepository(
      dataSource: dataSource,
      entityToModelMapper: entityToModelMapper,
      modelToEntityMapper: modelToEntityMapper,
    );
  });

  group('BudgetRepository', () {
    group('upsert', () {
      test('should convert model to entity and delegate to data source', () {
        when(() => modelToEntityMapper.call(budgetModel))
            .thenReturn(budgetEntity);
        when(() => dataSource.upsert(any())).thenReturn(const Right(null));

        final result = repository.upsert(budgetModel);

        expect(result.isRight, true);
        verify(() => modelToEntityMapper.call(budgetModel)).called(1);
        verify(() => dataSource.upsert(budgetEntity)).called(1);
      });

      test('should return Left when data source fails', () {
        when(() => modelToEntityMapper.call(budgetModel))
            .thenReturn(budgetEntity);
        when(() => dataSource.upsert(any()))
            .thenReturn(const Left('Ops, a operação falhou.'));

        final result = repository.upsert(budgetModel);

        expect(result.isLeft, true);
        expect(result.left, 'Ops, a operação falhou.');
      });
    });

    group('findActive', () {
      test('should return mapped model when budget found', () {
        when(() => dataSource.findActive(1500))
            .thenReturn(Right(budgetEntity));
        when(() => entityToModelMapper.call(budgetEntity))
            .thenReturn(budgetModel);

        final result = repository.findActive(1500);

        expect(result.isRight, true);
        expect(result.right, budgetModel);
      });

      test('should return null when no active budget', () {
        when(() => dataSource.findActive(1500))
            .thenReturn(const Right(null));

        final result = repository.findActive(1500);

        expect(result.isRight, true);
        expect(result.right, isNull);
      });

      test('should return Left when data source fails', () {
        when(() => dataSource.findActive(1500))
            .thenReturn(const Left('Ops, a operação falhou.'));

        final result = repository.findActive(1500);

        expect(result.isLeft, true);
      });
    });

    group('findAll', () {
      test('should return mapped list of models', () {
        when(() => dataSource.findAll())
            .thenReturn(Right([budgetEntity]));
        when(() => entityToModelMapper.call(budgetEntity))
            .thenReturn(budgetModel);

        final result = repository.findAll();

        expect(result.isRight, true);
        expect(result.right.length, 1);
        expect(result.right.first, budgetModel);
      });

      test('should return empty list when no budgets', () {
        when(() => dataSource.findAll()).thenReturn(const Right([]));

        final result = repository.findAll();

        expect(result.isRight, true);
        expect(result.right, isEmpty);
      });
    });

    group('deleteById', () {
      test('should delegate to data source', () {
        when(() => dataSource.deleteById(1)).thenReturn(const Right(null));

        final result = repository.deleteById(1);

        expect(result.isRight, true);
        verify(() => dataSource.deleteById(1)).called(1);
      });

      test('should return Left when not found', () {
        when(() => dataSource.deleteById(99))
            .thenReturn(const Left('Budget não encontrado.'));

        final result = repository.deleteById(99);

        expect(result.isLeft, true);
      });
    });
  });
}
