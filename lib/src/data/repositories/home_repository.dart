import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/data/mapper/balance_to_model_mapper.dart';
import 'package:trocado/src/data/mapper/transaction_to_model_mapper.dart';

import 'package:trocado/src/domain/models/balance_model.dart';
import 'package:trocado/src/domain/models/transaction_model.dart';

import 'package:trocado/src/domain/repositories/interface_home_repository.dart';

import 'package:trocado/src/infrastructure/datasources/local/home_local_datasource.dart';

final class HomeRepository implements IHomeRepository {
  final IHomeLocalDatasource _datasource;
  final BalanceToModelMapper _balanceToModelMapper;
  final TransactionToModelMapper _transactionToModelMapper;

  HomeRepository({
    required IHomeLocalDatasource datasource,
    required BalanceToModelMapper balanceToModelMapper,
    required TransactionToModelMapper transactionToModelMapper,
  }) : _datasource = datasource,
       _balanceToModelMapper = balanceToModelMapper,
       _transactionToModelMapper = transactionToModelMapper;

  @override
  Either<String, void> deleteTransactionBy(int id) =>
      _datasource.deleteTransactionBy(id);

  @override
  Either<String, BalanceModel> getBalanceBy({int? startAt, int? endAt}) {
    final data = _datasource.getBalanceBy(startAt: startAt, endAt: endAt);

    return data.mapRight(_balanceToModelMapper.call);
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
