import 'package:mocktail/mocktail.dart';

import 'package:trocado/modules/core/data/datasources/interface_database_datasource.dart';
import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

import 'package:trocado/modules/calculator/domain/repositories/interface_calculator_repository.dart';

final class MockStorageRepository extends Mock implements IStorageRepository {}

final class MockDatabaseDatasource extends Mock
    implements IDatabaseDatasource {}

final class MockCalculatorRepository extends Mock
    implements ICalculatorRepository {}
