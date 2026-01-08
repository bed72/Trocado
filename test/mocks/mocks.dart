import 'package:mocktail/mocktail.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/calculator/calculator.dart';

final class MockStorageRepository extends Mock implements IStorageRepository {}

final class MockDatabaseDatasource extends Mock
    implements IDatabaseDatasource {}

final class MockCalculatorRepository extends Mock
    implements ICalculatorRepository {}
