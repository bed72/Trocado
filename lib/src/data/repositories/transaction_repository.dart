import 'package:trocado/src/data/mapper/transaction_to_model_mapper.dart';
import 'package:trocado/src/data/mapper/transaction_to_entity_mapper.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/models/transaction_model.dart';
import 'package:trocado/src/domain/repositories/interface_transaction_repository.dart';

import 'package:trocado/src/infrastructure/datasources/local/transaction_local_datasource.dart';

final class TransactionRepository implements ITransactionRepository {
  final ITransactionLocalDatasource _datasource;
  final TransactionToModelMapper _toModelMapper;
  final TransactionToEntityMapper _toEntityMapper;

  TransactionRepository({
    required ITransactionLocalDatasource datasource,
    required TransactionToModelMapper toModelMapper,
    required TransactionToEntityMapper toEntityMapper,
  }) : _datasource = datasource,
       _toModelMapper = toModelMapper,
       _toEntityMapper = toEntityMapper;

  @override
  Either<String, void> delete(int id) => _datasource.delete(id);

  @override
  Either<String, TransactionModel> find(int id) {
    final data = _datasource.find(id);

    return data.mapRight(_toModelMapper.call);
  }

  @override
  Either<String, void> save(TransactionModel model) {
    final entity = _toEntityMapper(model);

    return model.id == null
        ? _datasource.save(entity)
        : _datasource.update(model.id!, entity);
  }
}
