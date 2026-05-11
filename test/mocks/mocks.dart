import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

import 'package:trocado/src/domain/services/money_service.dart';

import 'package:trocado/src/domain/repositories/interface_user_repository.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';
import 'package:trocado/src/domain/repositories/interface_insights_repository.dart';
import 'package:trocado/src/domain/repositories/interface_authentication_repository.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/logger/logger_client.dart';
import 'package:trocado/src/infrastructure/clients/storage/storage_client.dart';
import 'package:trocado/src/infrastructure/clients/app_check/app_check_client.dart';
import 'package:trocado/src/infrastructure/datasources/local/local_token_data_source.dart';

final class MockDio extends Mock implements Dio {}

final class MockHttpClient extends Mock implements IHttpClient {}

final class MockLoggerClient extends Mock implements ILoggerClient {}

final class MockMoneyService extends Mock implements IMoneyService {}

final class MockStorageClient extends Mock implements IStorageClient {}

final class MockAppCheckClient extends Mock implements IAppCheckClient {}

final class MockUserRepository extends Mock implements IUserRepository {}

final class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

final class MockTokenDataSource extends Mock implements ILocalTokenDataSource {}

final class MockAuthenticationRepository extends Mock
    implements IAuthenticationRepository {}

final class MockBudgetRepository extends Mock implements IBudgetRepository {}

final class MockExpenseRepository extends Mock implements IExpenseRepository {}

final class MockInsightsRepository extends Mock
    implements IInsightsRepository {}
