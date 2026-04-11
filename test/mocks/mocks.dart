import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

import 'package:trocado/src/application/services/money_service.dart';
import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/logger/logger_client.dart';

final class MockDio extends Mock implements Dio {}

final class MockHttpClient extends Mock implements IHttpClient {}

final class MockLoggerClient extends Mock implements ILoggerClient {}

final class MockMoneyService extends Mock implements IMoneyService {}
