import 'package:trocado/src/data/mapper/balance_to_model_mapper.dart';
import 'package:trocado/src/data/mapper/transaction_to_model_mapper.dart';
import 'package:trocado/src/data/mapper/transaction_to_entity_mapper.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/models/balance_model.dart';
import 'package:trocado/src/domain/models/transaction_model.dart';
import 'package:trocado/src/domain/repositories/interface_transaction_repository.dart';

import 'package:trocado/src/infrastructure/datasources/local/transaction_local_datasource.dart';

final class TransactionRepository implements ITransactionRepository {
  final ITransactionLocalDatasource _datasource;
  final BalanceToModelMapper _balanceToModelMapper;
  final TransactionToModelMapper _transactionToModelMapper;
  final TransactionToEntityMapper _transactionToEntityMapper;

  TransactionRepository({
    required ITransactionLocalDatasource datasource,
    required BalanceToModelMapper balanceToModelMapper,
    required TransactionToModelMapper transactionToModelMapper,
    required TransactionToEntityMapper transactionToEntityMapper,
  }) : _datasource = datasource,
       _balanceToModelMapper = balanceToModelMapper,
       _transactionToModelMapper = transactionToModelMapper,
       _transactionToEntityMapper = transactionToEntityMapper;

  @override
  Either<String, void> deleteTransactionById(int id) =>
      _datasource.deleteTransactionById(id);

  @override
  Either<String, TransactionModel> findTransactionById(int id) {
    final data = _datasource.findTransactionById(id);

    return data.mapRight(_transactionToModelMapper.call);
  }

  @override
  Either<String, BalanceModel> getBalanceBy({int? startAt, int? endAt}) {
    final data = _datasource.getBalanceBy(startAt: startAt, endAt: endAt);

    return data.mapRight(_balanceToModelMapper.call);
  }

  @override
  Either<String, void> saveTransactionByModel(TransactionModel model) {
    final entity = _transactionToEntityMapper(model);

    return model.id == null
        ? _datasource.saveTransactionByEntity(entity)
        : _datasource.updateTransactionById(model.id!, entity);
  }

  @override
  Either<String, List<TransactionModel>> findTransactionBy({
    int? endAt,
    int? limit,
    int? offset,
    int? startAt,
    TransactionTypeModel? type,
  }) {
    final data = _datasource.findTransactionBy(
      endAt: endAt,
      limit: limit,
      offset: offset,
      startAt: startAt,
      type: type?.label,
    );

    return data.mapRight(
      (transactions) =>
          transactions.map(_transactionToModelMapper.call).toList(),
    );
  }
}
