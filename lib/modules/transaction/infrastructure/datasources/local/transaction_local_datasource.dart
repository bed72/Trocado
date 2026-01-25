import 'package:objectbox/objectbox.dart';
import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/transaction/infrastructure/database/entities/transaction_entity.dart';

abstract interface class ITransactionLocalDatasource {
  Either<String, void> delete(int id);
  Either<String, TransactionEntity> find(int id);
  Either<String, void> save(TransactionEntity entity);
  Either<String, void> update(int id, TransactionEntity entity);
}

final class TransactionLocalDatasource implements ITransactionLocalDatasource {
  final IDatabaseClient _client;

  late final Box<TransactionEntity> _box;

  TransactionLocalDatasource({required IDatabaseClient client})
    : _client = client {
    _box = _client.store.box<TransactionEntity>();
  }

  @override
  Either<String, Null> delete(int id) {
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
  Either<String, TransactionEntity> find(int id) {
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
  Either<String, Null> save(TransactionEntity entity) {
    try {
      _box.put(entity);
      return const Right(null);
    } catch (_) {
      return const Left('Ops, a operação falhou.');
    }
  }

  @override
  Either<String, Null> update(int id, TransactionEntity entity) {
    try {
      if (id == 0) return const Left('Transação não encontrada.');

      _box.put(entity);

      return const Right(null);
    } catch (_) {
      return const Left('Ops, a operação falhou.');
    }
  }
}
