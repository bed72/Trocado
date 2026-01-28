import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/home/data/mappers/home_mapper.dart';

import 'package:trocado/modules/home/domain/models/balance_model.dart';
import 'package:trocado/modules/home/domain/repositories/interface_home_repository.dart';

import 'package:trocado/modules/home/infrastructure/datasources/home_local_datasource.dart';

final class HomeRepository implements IHomeRepository {
  final IHomeLocalDatasource _datasource;
  final BalanceOutMapper _balanceOutMapper;
  final TransactionDtoMapper _transactionDtoMapper;
  final TransactionOutMapper _transactionOutMapper;

  HomeRepository({
    required IHomeLocalDatasource datasource,
    required BalanceOutMapper balanceOutMapper,
    required TransactionDtoMapper transactionDtoMapper,
    required TransactionOutMapper transactionOutMapper,
  }) : _datasource = datasource,
       _balanceOutMapper = balanceOutMapper,
       _transactionDtoMapper = transactionDtoMapper,
       _transactionOutMapper = transactionOutMapper;

  @override
  TransactionDto toTransactionDto(TransactionModel model) =>
      _transactionDtoMapper(model);

  @override
  Either<String, void> deleteTransactionBy(int id) =>
      _datasource.deleteTransactionBy(id);

  @override
  Either<String, BalanceModel> getBalanceBy({int? startAt, int? endAt}) {
    final data = _datasource.getBalanceBy(startAt: startAt, endAt: endAt);

    return data.mapRight(_balanceOutMapper.call);
  }

  @override
  Either<String, List<TransactionModel>> findTransactionBy({
    int? endAt,
    int? limit,
    int? offset,
    int? startAt,
    TransactionTypeDto? type,
  }) {
    final data = _datasource.findTransactionBy(
      endAt: endAt,
      limit: limit,
      offset: offset,
      startAt: startAt,
      type: type?.label,
    );

    return data.mapRight(
      (transactions) => transactions.map(_transactionOutMapper.call).toList(),
    );
  }
}
