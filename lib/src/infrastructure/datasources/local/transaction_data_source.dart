import 'package:trocado/objectbox.g.dart';

import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/data/datasources/interface_transaction_data_source.dart';

import 'package:trocado/src/infrastructure/clients/database/database_client.dart';
import 'package:trocado/src/infrastructure/clients/database/entities/transaction_entity.dart';

final class TransactionDataSource implements ITransactionDataSource {
  final IDatabaseClient _client;

  late final Box<TransactionEntity> _box;

  TransactionDataSource({required IDatabaseClient client}) : _client = client {
    _box = _client.store.box<TransactionEntity>();
  }

  @override
  Either<String, Null> deleteById(int id) {
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
  Either<String, TransactionEntity> findById(int id) {
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
  Either<String, Null> upsert(TransactionEntity entity) {
    try {
      if (entity.id == 0) return const Left('Transação não encontrada.');

      _box.put(entity);

      return const Right(null);
    } catch (_) {
      return const Left('Ops, a operação falhou.');
    }
  }

  @override
  Either<String, List<TransactionEntity>> findByPeriod({
    int? limit,
    int? offset,
    int? startAt,
    int? endAt,
  }) {
    try {
      final (start, end) = (startAt != null && endAt != null)
          ? (startAt, endAt)
          : _currentMonthRange();

      final query = _box
          .query(TransactionEntity_.date.between(start, end))
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

  (int start, int end) _currentMonthRange() {
    final now = DateTime.now();

    final start = DateTime(now.year, now.month);
    final end = DateTime(now.year, now.month + 1);

    return (start.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
  }
}
