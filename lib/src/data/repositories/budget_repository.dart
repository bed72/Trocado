import 'package:trocado/src/data/mapper/budget_mapper.dart';
import 'package:trocado/src/data/datasources/interface_budget_data_source.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/models/budget_model.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';

final class BudgetRepository implements IBudgetRepository {
  final IBudgetDataSource _dataSource;
  final BudgetEntityToModelMapper _entityToModelMapper;
  final BudgetModelToEntityMapper _modelToEntityMapper;

  BudgetRepository({
    required IBudgetDataSource dataSource,
    required BudgetEntityToModelMapper entityToModelMapper,
    required BudgetModelToEntityMapper modelToEntityMapper,
  }) : _dataSource = dataSource,
       _entityToModelMapper = entityToModelMapper,
       _modelToEntityMapper = modelToEntityMapper;

  @override
  Either<String, void> upsert(BudgetModel model) {
    final entity = _modelToEntityMapper(model);
    return _dataSource.upsert(entity);
  }

  @override
  Either<String, BudgetModel?> findActive(int currentDate) {
    final result = _dataSource.findActive(currentDate);
    return result.mapRight(
      (entity) => entity != null ? _entityToModelMapper(entity) : null,
    );
  }

  @override
  Either<String, List<BudgetModel>> findAll() {
    final result = _dataSource.findAll();
    return result.mapRight(
      (entities) => entities.map(_entityToModelMapper.call).toList(),
    );
  }

  @override
  Either<String, void> deleteById(int id) => _dataSource.deleteById(id);
}
