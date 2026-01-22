import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/home/domain/repositories/interface_home_repository.dart';

import 'package:trocado/modules/home/infrastructure/datasources/home_local_datasource.dart';

final class HomeRepository implements IHomeRepository {
  final TransactionDtoMapper _dtoMapper;
  final TransactionOutMapper _outMapper;
  final IHomeLocalDatasource _datasource;

  HomeRepository({
    required TransactionDtoMapper dtoMapper,
    required TransactionOutMapper outMapper,
    required IHomeLocalDatasource datasource,
  }) : _dtoMapper = dtoMapper,
       _outMapper = outMapper,
       _datasource = datasource;

  @override
  TransactionDto toDto(TransactionModel model) => _dtoMapper(model);

  @override
  Either<String, void> delete(int id) => _datasource.delete(id);

  @override
  Either<String, List<TransactionModel>> findByPeriod({
    int? endAt,
    int? limit,
    int? offset,
    int? startAt,
    TransactionTypeDto? type,
  }) {
    final data = _datasource.findByPeriod(
      endAt: endAt,
      limit: limit,
      offset: offset,
      startAt: startAt,
      type: type?.label,
    );

    return data.mapRight(
      (transactions) => transactions.map(_outMapper.call).toList(),
    );
  }
}
