import 'package:trocado/src/data/mapper/transaction_to_model_mapper.dart';
import 'package:trocado/src/data/mapper/transaction_to_entity_mapper.dart';
import 'package:trocado/src/data/datasources/interface_transaction_data_source.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/models/entry_model.dart';
import 'package:trocado/src/domain/models/transaction_model.dart';
import 'package:trocado/src/domain/repositories/interface_transaction_repository.dart';

final class TransactionRepository implements ITransactionRepository {
  final ITransactionDataSource _dataSource;
  final TransactionToModelMapper _transactionToModelMapper;
  final TransactionToEntityMapper _transactionToEntityMapper;

  TransactionRepository({
    required ITransactionDataSource dataSource,
    required TransactionToModelMapper transactionToModelMapper,
    required TransactionToEntityMapper transactionToEntityMapper,
  }) : _dataSource = dataSource,
       _transactionToModelMapper = transactionToModelMapper,
       _transactionToEntityMapper = transactionToEntityMapper;

  @override
  Either<String, void> deleteById(int id) => _dataSource.deleteById(id);

  @override
  Either<String, TransactionModel> findById(int id) {
    final data = _dataSource.findById(id);

    return data.mapRight(_transactionToModelMapper.call);
  }

  @override
  Either<String, void> upsert(TransactionModel model) {
    final entity = _transactionToEntityMapper(model);

    return _dataSource.upsert(entity);
  }

  @override
  Either<String, List<TransactionModel>> findByEntry(EntryModel model) {
    final data = _dataSource.findByEntry(model.name);

    return data.mapRight(
      (transactions) =>
          transactions.map(_transactionToModelMapper.call).toList(),
    );
  }

  @override
  Either<String, List<TransactionModel>> findByPeriod({
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
      (transactions) =>
          transactions.map(_transactionToModelMapper.call).toList(),
    );
  }
}
