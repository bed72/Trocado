import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

import 'package:trocado/src/application/services/money_service.dart';
import 'package:trocado/src/domain/contracts/repositories/interface_authentication_repository.dart';
import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/logger/logger_client.dart';
import 'package:trocado/src/infrastructure/clients/storage/storage_client.dart';
import 'package:trocado/src/infrastructure/datasources/local/local_token_data_source.dart';

final class MockDio extends Mock implements Dio {}

final class MockHttpClient extends Mock implements IHttpClient {}

final class MockLoggerClient extends Mock implements ILoggerClient {}

final class MockMoneyService extends Mock implements IMoneyService {}

final class MockStorageClient extends Mock implements IStorageClient {}

final class MockTokenDataSource extends Mock implements ILocalTokenDataSource {}

final class MockAuthenticationRepository extends Mock
    implements IAuthenticationRepository {}
