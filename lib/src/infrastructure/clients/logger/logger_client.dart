import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

abstract interface class ILoggerClient {
  void debug(String message, {Object? error, StackTrace? stackTrace});
  void error(String message, {Object? error, StackTrace? stackTrace});
  void warning(String message, {Object? error, StackTrace? stackTrace});
  void verbose(String message, {Object? error, StackTrace? stackTrace});
  void critical(String message, {Object? error, StackTrace? stackTrace});
  void information(String message, {Object? error, StackTrace? stackTrace});
}

final class LoggerClient implements ILoggerClient {
  final Logger _logger = Logger(
    filter: kReleaseMode ? ProductionFilter() : DevelopmentFilter(),
    printer: PrettyPrinter(
      colors: true,
      methodCount: 0,
      lineLength: 80,
      printEmojis: true,
      errorMethodCount: 8,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.d(message, error: error, stackTrace: stackTrace);

  @override
  void information(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.i(message, error: error, stackTrace: stackTrace);

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.w(message, error: error, stackTrace: stackTrace);

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(message, error: error, stackTrace: stackTrace);

  @override
  void verbose(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.t(message, error: error, stackTrace: stackTrace);

  @override
  void critical(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.f(message, error: error, stackTrace: stackTrace);
}
