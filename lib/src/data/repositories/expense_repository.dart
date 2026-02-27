import 'package:trocado/src/data/mapper/expense_mapper.dart';
import 'package:trocado/src/data/datasources/interface_expense_data_source.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/models/expense_model.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

final class ExpenseRepository implements IExpenseRepository {
  final IExpenseDataSource _dataSource;
  final ExpenseEntityToModelMapper _entityToModelMapper;
  final ExpenseModelToEntityMapper _modelToEntityMapper;

  ExpenseRepository({
    required IExpenseDataSource dataSource,
    required ExpenseEntityToModelMapper expenseToModelMapper,
    required ExpenseModelToEntityMapper expenseToEntityMapper,
  }) : _dataSource = dataSource,
       _entityToModelMapper = expenseToModelMapper,
       _modelToEntityMapper = expenseToEntityMapper;

  @override
  Either<String, void> deleteById(int id) => _dataSource.deleteById(id);

  @override
  Either<String, ExpenseModel> findById(int id) {
    final data = _dataSource.findById(id);

    return data.mapRight(_entityToModelMapper.call);
  }

  @override
  Either<String, void> upsert(ExpenseModel model) {
    final entity = _modelToEntityMapper(model);

    return _dataSource.upsert(entity);
  }

  @override
  Either<String, List<ExpenseModel>> findByPeriod({
    int? limit,
    int? offset,
    int? startAt,
    int? endAt,
  }) {
    final data = _dataSource.findByPeriod(
      limit: limit,
      offset: offset,
      startAt: startAt,
      endAt: endAt,
    );

    return data.mapRight(
      (expenses) => expenses.map(_entityToModelMapper.call).toList(),
    );
  }
}
