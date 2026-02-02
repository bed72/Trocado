import 'package:trocado/objectbox.g.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/models/transaction_model.dart';

import 'package:trocado/src/infrastructure/clients/database/database_client.dart';
import 'package:trocado/src/infrastructure/database/entities/balance_entity.dart';
import 'package:trocado/src/infrastructure/database/entities/transaction_entity.dart';

abstract interface class ITransactionLocalDatasource {
  Either<String, void> deleteTransactionById(int id);
  Either<String, TransactionEntity> findTransactionById(int id);
  Either<String, void> saveTransactionByEntity(TransactionEntity entity);
  Either<String, BalanceEntity> getBalanceBy({int? startAt, int? endAt});
  Either<String, void> updateTransactionById(int id, TransactionEntity entity);

  Either<String, List<TransactionEntity>> findTransactionBy({
    int? endAt,
    int? limit,
    int? offset,
    int? startAt,
    String? type,
  });
}

final class TransactionLocalDatasource implements ITransactionLocalDatasource {
  final IDatabaseClient _client;

  late final Box<TransactionEntity> _box;

  TransactionLocalDatasource({required IDatabaseClient client})
    : _client = client {
    _box = _client.store.box<TransactionEntity>();
  }

  @override
  Either<String, Null> deleteTransactionById(int id) {
    try {
      final removed = _box.remove(id);

      return removed
          ? const Right(null)
          : const Left('Transação não encontrada.');
    } catch (_) {
      return const Left('Ops, a operação falhou.');
    }
  }

  @override
  Either<String, TransactionEntity> findTransactionById(int id) {
    try {
      final entity = _box.get(id);

      return entity != null
          ? Right(entity)
          : const Left('Transação não encontrada.');
    } catch (_) {
      return const Left('Ops, a operação falhou.');
    }
  }

  @override
  Either<String, Null> saveTransactionByEntity(TransactionEntity entity) {
    try {
      _box.put(entity);
      return const Right(null);
    } catch (_) {
      return const Left('Ops, a operação falhou.');
    }
  }

  @override
  Either<String, Null> updateTransactionById(int id, TransactionEntity entity) {
    try {
      if (id == 0) return const Left('Transação não encontrada.');

      entity.id = id;
      _box.put(entity);

      return const Right(null);
    } catch (_) {
      return const Left('Ops, a operação falhou.');
    }
  }

  @override
  Either<String, List<TransactionEntity>> findTransactionBy({
    int? endAt,
    int? limit,
    int? offset,
    int? startAt,
    String? type,
  }) {
    try {
      final (start, end) = _resolvePeriod(startAt, endAt);

      final condition = (type == null)
          ? TransactionEntity_.date.between(start, end)
          : TransactionEntity_.date
                .between(start, end)
                .and(TransactionEntity_.type.equals(type));

      final query = _box
          .query(condition)
          .order(TransactionEntity_.id, flags: Order.descending)
          .order(TransactionEntity_.date, flags: Order.descending)
          .build();

      if (limit != null) query.limit = limit;
      if (offset != null) query.offset = offset;

      final data = query.find();
      query.close();

      return Right(data);
    } catch (_) {
      return const Left('Ops, a operação falhou.');
    }
  }

  @override
  Either<String, BalanceEntity> getBalanceBy({int? startAt, int? endAt}) {
    try {
      final income = _sumByType(endAt: endAt, type: .income, startAt: startAt);
      final expense = _sumByType(
        endAt: endAt,
        type: .expense,
        startAt: startAt,
      );

      return Right(
        BalanceEntity(
          income: income,
          expense: expense,
          total: income - expense,
        ),
      );
    } catch (_) {
      return const Left('Ops, a operação falhou.');
    }
  }

  (int start, int end) _currentMonthRange() {
    final now = DateTime.now();

    final start = DateTime(now.year, now.month);
    final end = DateTime(now.year, now.month + 1);

    return (start.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
  }

  (int, int) _resolvePeriod(int? startAt, int? endAt) =>
      (startAt != null && endAt != null)
      ? (startAt, endAt)
      : _currentMonthRange();

  double _sumByType({
    required int? endAt,
    required int? startAt,
    required TransactionTypeModel type,
  }) {
    final (start, end) = _resolvePeriod(startAt, endAt);

    final query = _box
        .query(
          TransactionEntity_.date
              .between(start, end)
              .and(TransactionEntity_.type.equals(type.label)),
        )
        .build();

    final value = query.property(TransactionEntity_.amount).sum();
    query.close();

    return value;
  }
}
