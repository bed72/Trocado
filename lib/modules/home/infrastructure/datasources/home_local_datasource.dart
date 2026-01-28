import 'package:trocado/objectbox.g.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/home/infrastructure/entities/balance_entity.dart';

abstract interface class IHomeLocalDatasource {
  Either<String, void> deleteTransactionBy(int id);
  Either<String, BalanceEntity> getBalanceBy({int? startAt, int? endAt});
  Either<String, List<TransactionEntity>> findTransactionBy({
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
  Either<String, void> deleteTransactionBy(int id) {
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

  (int, int) _resolvePeriod(int? startAt, int? endAt) =>
      (startAt != null && endAt != null)
      ? (startAt, endAt)
      : currentMonthRange();

  double _sumByType({
    required int? endAt,
    required int? startAt,
    required TransactionTypeDto type,
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
