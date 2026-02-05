import 'package:mocktail/mocktail.dart';

import 'package:trocado/src/data/mapper/balance_to_model_mapper.dart';
import 'package:trocado/src/data/mapper/transaction_to_model_mapper.dart';
import 'package:trocado/src/data/mapper/transaction_to_entity_mapper.dart';

import 'package:trocado/src/domain/repositories/interface_money_repository.dart';
import 'package:trocado/src/domain/repositories/interface_transaction_repository.dart';

import 'package:trocado/src/infrastructure/datasources/local/transaction_data_source.dart';

final class MockMoneyRepository extends Mock implements IMoneyRepository {}

final class MockBalanceToModelMapper extends Mock
    implements BalanceToModelMapper {}

final class MockTransactionToModelMapper extends Mock
    implements TransactionToModelMapper {}

final class MockTransactionToEntityMapper extends Mock
    implements TransactionToEntityMapper {}

final class MockTransactionLocalDatasource extends Mock
    implements ITransactionLocalDatasource {}

final class MockTransactionRepository extends Mock
    implements ITransactionRepository {}
