import 'package:mocktail/mocktail.dart';

import 'package:trocado/modules/transaction/data/mappers/transaction_mapper.dart';
import 'package:trocado/modules/transaction/data/datasources/interface_transaction_datasource.dart';

final class MockTransactionInMapper extends Mock
    implements TransactionInMapper {}

final class MockTransactionOutMapper extends Mock
    implements TransactionOutMapper {}

final class MockITransactionLocalDatasource extends Mock
    implements ITransactionLocalDatasource {}
