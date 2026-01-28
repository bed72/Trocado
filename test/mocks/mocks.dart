import 'package:mocktail/mocktail.dart';

import 'package:trocado/modules/home/data/mappers/home_mapper.dart';
import 'package:trocado/modules/home/domain/repositories/interface_home_repository.dart';
import 'package:trocado/modules/home/infrastructure/datasources/home_local_datasource.dart';

import 'package:trocado/modules/core/infrastructure/resources/formatters/money_formatter.dart';

import 'package:trocado/modules/transaction/data/mappers/transaction_mapper.dart';
import 'package:trocado/modules/transaction/domain/repositories/interface_transaction_repository.dart';
import 'package:trocado/modules/transaction/infrastructure/datasources/local/transaction_local_datasource.dart';

final class MockMoneyFormatter extends Mock implements IMoneyFormatter {}

final class MockHomeRepository extends Mock implements IHomeRepository {}

final class MockBalanceOutMapper extends Mock implements BalanceOutMapper {}

final class MockTransactionDtoMapper extends Mock
    implements TransactionDtoMapper {}

final class MockTransactionOutMapper extends Mock
    implements TransactionOutMapper {}

final class MockHomeLocalDatasource extends Mock
    implements IHomeLocalDatasource {}

final class MockTransactionInMapper extends Mock
    implements TransactionInMapper {}

final class MockTransactionLocalDatasource extends Mock
    implements ITransactionLocalDatasource {}

final class MockTransactionRepository extends Mock
    implements ITransactionRepository {}
