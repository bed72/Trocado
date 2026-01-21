import 'package:trocado/objectbox.g.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/transaction/transaction.dart';

abstract interface class IHomeLocalDatasource {
  Either<String, void> delete(int id);

  Either<String, List<TransactionEntity>> findByPeriod({
    int? endAt,
    int? limit,
    int? offset,
    int? startAt,
    String? type,
  });
}

final class HomeLocalDatasource implements IHomeLocalDatasource {
  final IDatabaseClient _client;

  late final Box<TransactionEntity> _box;

  HomeLocalDatasource({required IDatabaseClient client}) : _client = client {
    _box = _client.store.box<TransactionEntity>();
  }

  @override
  Either<String, void> delete(int id) {
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
  Either<String, List<TransactionEntity>> findByPeriod({
    int? endAt,
    int? limit,
    int? offset,
    int? startAt,
    String? type,
  }) {
    try {
      final (start, end) = (startAt != null && endAt != null)
          ? (startAt, endAt)
          : _currentMonthRange();

      final condition = (type == null)
          ? TransactionEntity_.date.between(start, end)
          : TransactionEntity_.date
                .between(start, end)
                .and(TransactionEntity_.type.equals(type));

      final query = _box
          .query(condition)
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
