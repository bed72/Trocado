import 'package:mocktail/mocktail.dart';

import 'package:trocado/modules/transaction/data/mappers/transaction_mapper.dart';

import 'package:trocado/modules/home/domain/repositories/interface_home_repository.dart';
import 'package:trocado/modules/home/infrastructure/datasources/home_local_datasource.dart';

final class MockTransactionOutMapper extends Mock
    implements TransactionOutMapper {}

final class MockHomeLocalDatasource extends Mock
    implements IHomeLocalDatasource {}

final class MockHomeRepository extends Mock implements IHomeRepository {}
