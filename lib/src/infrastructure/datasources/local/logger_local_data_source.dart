import 'package:trocado/src/infrastructure/clients/logger/logger_client.dart';
import 'package:trocado/src/data/datasources/interface_logger_data_source.dart';

final class LoggerLocalDatasource implements ILoggerDataSource {
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
