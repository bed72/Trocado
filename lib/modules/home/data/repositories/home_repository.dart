import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/home/domain/repositories/interface_home_repository.dart';

import 'package:trocado/modules/home/infrastructure/datasources/home_local_datasource.dart';

final class HomeRepository implements IHomeRepository {
  final TransactionOutMapper _mapper;
  final IHomeLocalDatasource _datasource;

  HomeRepository({
    required TransactionOutMapper mapper,
    required IHomeLocalDatasource datasource,
  }) : _mapper = mapper,
       _datasource = datasource;

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
      (transactions) => transactions.map(_mapper.call).toList(),
    );
  }
}
