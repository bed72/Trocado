import 'package:mocktail/mocktail.dart';

import 'package:trocado/modules/core/data/dtos/money_dto.dart';

import 'package:trocado/modules/transaction/data/mappers/transaction_mapper.dart';
import 'package:trocado/modules/transaction/domain/repositories/interface_transaction_repository.dart';
import 'package:trocado/modules/transaction/infrastructure/datasources/local/transaction_local_datasource.dart';

final class MockMoneyFormatter extends Mock implements IMoneyDto {}

final class MockTransactionInMapper extends Mock
    implements TransactionInMapper {}

final class MockTransactionOutMapper extends Mock
    implements TransactionOutMapper {}

final class MockTransactionLocalDatasource extends Mock
    implements ITransactionLocalDatasource {}

final class MockTransactionRepository extends Mock
    implements ITransactionRepository {}
