import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/data/mapper/budget_mapper.dart';
import 'package:trocado/src/data/repositories/budget_repository.dart';
import 'package:trocado/src/data/datasources/interface_budget_data_source.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/models/budget/budget_model.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';

import 'package:trocado/src/infrastructure/clients/database/entities/budget_entity.dart';

import '../../../mocks/mocks.dart';

void main() {
  late IBudgetDataSource dataSource;
  late IBudgetRepository repository;
  late BudgetEntityToModelMapper entityToModelMapper;
  late BudgetModelToEntityMapper modelToEntityMapper;

  final entity = BudgetEntity(
    id: 1,
    endDate: 2000,
    amount: 1000.0,
    startDate: 1000,
    description: 'Fevereiro',
  );

  final model = BudgetModel(
    id: 1,
    endDate: 2000,
    amount: 1000.0,
    startDate: 1000,
    description: 'Fevereiro',
  );

  setUpAll(() {
    registerFallbackValue(model);
    registerFallbackValue(entity);
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
        when(() => modelToEntityMapper.call(model)).thenReturn(entity);
        when(() => dataSource.upsert(any())).thenReturn(const Right(null));

        final data = repository.upsert(model);

        expect(data.isRight, true);
        verify(() => modelToEntityMapper.call(model)).called(1);
        verify(() => dataSource.upsert(entity)).called(1);
      });

      test('should return Left when data source fails', () {
        when(() => modelToEntityMapper.call(model)).thenReturn(entity);
        when(
          () => dataSource.upsert(any()),
        ).thenReturn(const Left('Ops, a operação falhou.'));

        final data = repository.upsert(model);

        expect(data.isLeft, true);
        expect(data.left, 'Ops, a operação falhou.');
      });
    });

    group('findActive', () {
      test('should return mapped model when budget found', () {
        when(() => dataSource.findActive(1500)).thenReturn(Right(entity));
        when(() => entityToModelMapper.call(entity)).thenReturn(model);

        final data = repository.findActive(1500);

        expect(data.right, model);
        expect(data.isRight, true);
      });

      test('should return null when no active budget', () {
        when(() => dataSource.findActive(1500)).thenReturn(const Right(null));

        final data = repository.findActive(1500);

        expect(data.isRight, true);
        expect(data.right, isNull);
      });

      test('should return Left when data source fails', () {
        when(
          () => dataSource.findActive(1500),
        ).thenReturn(const Left('Ops, a operação falhou.'));

        final data = repository.findActive(1500);

        expect(data.isLeft, true);
      });
    });

    group('findAll', () {
      test('should return mapped list of models', () {
        when(() => dataSource.findAll()).thenReturn(Right([entity]));
        when(() => entityToModelMapper.call(entity)).thenReturn(model);

        final data = repository.findAll();

        expect(data.isRight, true);
        expect(data.right.length, 1);
        expect(data.right.first, model);
      });

      test('should return empty list when no budgets', () {
        when(() => dataSource.findAll()).thenReturn(const Right([]));

        final data = repository.findAll();

        expect(data.isRight, true);
        expect(data.right, isEmpty);
      });
    });

    group('deleteById', () {
      test('should delegate to data source', () {
        when(() => dataSource.deleteById(1)).thenReturn(const Right(null));

        final data = repository.deleteById(1);

        expect(data.isRight, true);
        verify(() => dataSource.deleteById(1)).called(1);
      });

      test('should return Left when not found', () {
        when(
          () => dataSource.deleteById(99),
        ).thenReturn(const Left('Budget não encontrado.'));

        final data = repository.deleteById(99);

        expect(data.isLeft, true);
      });
    });
  });
}
