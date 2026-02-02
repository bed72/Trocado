import 'package:mocktail/mocktail.dart';

import 'package:trocado/src/data/mapper/balance_to_model_mapper.dart';
import 'package:trocado/src/data/mapper/transaction_to_model_mapper.dart';
import 'package:trocado/src/data/mapper/transaction_to_entity_mapper.dart';

import 'package:trocado/src/domain/repositories/interface_home_repository.dart';
import 'package:trocado/src/domain/repositories/interface_transaction_repository.dart';

import 'package:trocado/src/infrastructure/resources/formatters/money_formatter.dart';
import 'package:trocado/src/infrastructure/datasources/local/home_local_datasource.dart';
import 'package:trocado/src/infrastructure/datasources/local/transaction_local_datasource.dart';

final class MockMoneyFormatter extends Mock implements IMoneyFormatter {}

final class MockHomeRepository extends Mock implements IHomeRepository {}

final class MockBalanceToModelMapper extends Mock
    implements BalanceToModelMapper {}

final class MockTransactionToModelMapper extends Mock
    implements TransactionToModelMapper {}

final class MockTransactionToEntityMapper extends Mock
    implements TransactionToEntityMapper {}

final class MockHomeLocalDatasource extends Mock
    implements IHomeLocalDatasource {}

final class MockTransactionLocalDatasource extends Mock
    implements ITransactionLocalDatasource {}

final class MockTransactionRepository extends Mock
    implements ITransactionRepository {}
