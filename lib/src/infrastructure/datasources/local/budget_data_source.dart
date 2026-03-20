import 'package:trocado/objectbox.g.dart';

import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/data/datasources/interface_budget_data_source.dart';

import 'package:trocado/src/infrastructure/clients/database/database_client.dart';
import 'package:trocado/src/infrastructure/clients/database/entities/budget_entity.dart';

final class BudgetDataSource implements IBudgetDataSource {
  final IDatabaseClient _client;

  late final Box<BudgetEntity> _box;

  BudgetDataSource({required IDatabaseClient client}) : _client = client {
    _box = _client.store.box<BudgetEntity>();
  }

  @override
  Either<String, void> upsert(BudgetEntity entity) {
    try {
      _box.put(entity);
      return const Right(null);
    } catch (_) {
      return const Left('Ops, a operação falhou.');
    }
  }

  @override
  Either<String, BudgetEntity?> findActive(int currentDate) {
    try {
      final query = _box
          .query(BudgetEntity_.startDate
              .lessOrEqual(currentDate)
              .and(BudgetEntity_.endDate.greaterThan(currentDate)))
          .order(BudgetEntity_.id, flags: Order.descending)
          .build();

      final result = query.findFirst();
      query.close();

      return Right(result);
    } catch (_) {
      return const Left('Ops, a operação falhou.');
    }
  }

  @override
  Either<String, List<BudgetEntity>> findAll() {
    try {
      final query = _box
          .query()
          .order(BudgetEntity_.id, flags: Order.descending)
          .build();

      final data = query.find();
      query.close();

      return Right(data);
    } catch (_) {
      return const Left('Ops, a operação falhou.');
    }
  }

  @override
  Either<String, void> deleteById(int id) {
    try {
      final removed = _box.remove(id);
      return removed
          ? const Right(null)
          : const Left('Budget não encontrado.');
    } catch (_) {
      return const Left('Ops, a operação falhou.');
    }
  }
}
