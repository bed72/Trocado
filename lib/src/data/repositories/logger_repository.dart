import 'package:trocado/src/domain/repositories/interface_logger_repository.dart';
import 'package:trocado/src/infrastructure/datasources/local/logger_local_datasource.dart';

final class LoggerRepository implements ILoggerRepository {
  final ILoggerLocalDatasource _datasource;

  LoggerRepository({required ILoggerLocalDatasource datasource})
    : _datasource = datasource;

  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) {
    _datasource.debug(message, error: error, stackTrace: stackTrace);
  }

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _datasource.error(message, error: error, stackTrace: stackTrace);
  }

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _datasource.warning(message, error: error, stackTrace: stackTrace);
  }

  @override
  void verbose(String message, {Object? error, StackTrace? stackTrace}) {
    _datasource.verbose(message, error: error, stackTrace: stackTrace);
  }

  @override
  void critical(String message, {Object? error, StackTrace? stackTrace}) {
    _datasource.critical(message, error: error, stackTrace: stackTrace);
  }

  @override
  void information(String message, {Object? error, StackTrace? stackTrace}) {
    _datasource.information(message, error: error, stackTrace: stackTrace);
  }
}
