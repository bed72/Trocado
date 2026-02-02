import 'package:trocado/src/infrastructure/clients/logger/logger_client.dart';

abstract interface class ILoggerLocalDatasource {
  void debug(String message, {Object? error, StackTrace? stackTrace});
  void error(String message, {Object? error, StackTrace? stackTrace});
  void warning(String message, {Object? error, StackTrace? stackTrace});
  void verbose(String message, {Object? error, StackTrace? stackTrace});
  void critical(String message, {Object? error, StackTrace? stackTrace});
  void information(String message, {Object? error, StackTrace? stackTrace});
}

final class LoggerLocalDatasource implements ILoggerLocalDatasource {
  final ILoggerClient _client;

  LoggerLocalDatasource({required ILoggerClient client}) : _client = client;

  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) {
    _client.debug(message, error: error, stackTrace: stackTrace);
  }

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _client.error(message, error: error, stackTrace: stackTrace);
  }

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _client.warning(message, error: error, stackTrace: stackTrace);
  }

  @override
  void verbose(String message, {Object? error, StackTrace? stackTrace}) {
    _client.verbose(message, error: error, stackTrace: stackTrace);
  }

  @override
  void critical(String message, {Object? error, StackTrace? stackTrace}) {
    _client.critical(message, error: error, stackTrace: stackTrace);
  }

  @override
  void information(String message, {Object? error, StackTrace? stackTrace}) {
    _client.information(message, error: error, stackTrace: stackTrace);
  }
}
