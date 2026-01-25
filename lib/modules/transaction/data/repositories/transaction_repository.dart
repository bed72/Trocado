import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/transaction/data/dtos/transaction_dto.dart';
import 'package:trocado/modules/transaction/data/mappers/transaction_mapper.dart';

import 'package:trocado/modules/transaction/domain/models/transaction_model.dart';
import 'package:trocado/modules/transaction/domain/repositories/interface_transaction_repository.dart';
import 'package:trocado/modules/transaction/infrastructure/datasources/local/transaction_local_datasource.dart';

final class TransactionRepository implements ITransactionRepository {
  final TransactionInMapper _inMapper;
  final TransactionOutMapper _outMapper;
  final ITransactionLocalDatasource _datasource;

  TransactionRepository({
    required TransactionInMapper inMapper,
    required TransactionOutMapper outMapper,
    required ITransactionLocalDatasource datasource,
  }) : _inMapper = inMapper,
       _outMapper = outMapper,
       _datasource = datasource;

  @override
  Either<String, void> delete(int id) => _datasource.delete(id);

  @override
  Either<String, TransactionModel> find(int id) {
    final data = _datasource.find(id);

    return data.mapRight(_outMapper.call);
  }

  @override
  Either<String, void> save(TransactionDto dto) {
    final entity = _inMapper(dto);

    return dto.id == null
        ? _datasource.save(entity)
        : _datasource.update(dto.id!, entity);
  }
}
