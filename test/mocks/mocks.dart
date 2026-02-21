import 'package:mocktail/mocktail.dart';

import 'package:trocado/src/data/mapper/transaction_to_model_mapper.dart';
import 'package:trocado/src/data/mapper/transaction_to_entity_mapper.dart';

import 'package:trocado/src/data/datasources/interface_transaction_data_source.dart';

import 'package:trocado/src/domain/services/interface_money_repository.dart';

import 'package:trocado/src/domain/repositories/interface_transaction_repository.dart';

final class MockMoneyRepository extends Mock implements IMoneyService {}

final class MockTransactionToModelMapper extends Mock
    implements TransactionToModelMapper {}

final class MockTransactionToEntityMapper extends Mock
    implements TransactionToEntityMapper {}

final class MockTransactionDataSource extends Mock
    implements ITransactionDataSource {}

final class MockTransactionRepository extends Mock
    implements ITransactionRepository {}
