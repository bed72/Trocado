import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import 'package:trocado/src/application/services/money_service.dart';

import 'package:trocado/src/data/repositories/authentication_repository.dart';

import 'package:trocado/src/domain/contracts/repositories/interface_authentication_repository.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/logger/logger_client.dart';
import 'package:trocado/src/infrastructure/clients/storage/storage_client.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_authentication_data_source.dart';

import 'package:trocado/src/presentation/mapper/expense_presentation_mapper.dart';

final sl = GetIt.instance;

void ensureInitialized() {
  sl.registerLazySingleton<ILoggerClient>(LoggerClient.new);

  // Services
  sl.registerLazySingleton<IMoneyService>(MoneyService.new);

  // Clients
  sl.registerLazySingleton<IHttpClient>(() => HttpClient(dio: Dio()));
  sl.registerLazySingleton<IStorageClient>(
    () => StorageClient(storage: const FlutterSecureStorage()),
  );

  // Data Sources (Infrastructure)
  sl.registerLazySingleton<IRemoteAuthenticationDataSource>(
    () => RemoteAuthenticationDataSource(client: sl()),
  );

  // Repositories (Data)
  sl.registerLazySingleton<IAuthenticationRepository>(
    () => AuthenticationRepository(dataSource: sl()),
  );

  // Mappers (Data)
  sl
    ..registerFactory(ExpenseModelToPresentationMapper.new)
    ..registerFactory(ExpenseStateToModelMapper.new);
}
