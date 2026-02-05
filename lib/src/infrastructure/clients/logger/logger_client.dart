import 'package:flutter/foundation.dart';

enum LoggerLevelConstant {
  error('ERROR'),
  debug('DEBUG'),
  warning('WARNING'),
  verbose('VERBOSE'),
  information('INFO'),
  critical('CRITICAL');

  final String type;

  const LoggerLevelConstant(this.type);
}

abstract interface class ILoggerClient {
  void debug(String message, {Object? error, StackTrace? stackTrace});
  void error(String message, {Object? error, StackTrace? stackTrace});
  void warning(String message, {Object? error, StackTrace? stackTrace});
  void verbose(String message, {Object? error, StackTrace? stackTrace});
  void critical(String message, {Object? error, StackTrace? stackTrace});
  void information(String message, {Object? error, StackTrace? stackTrace});
}

final class LoggerClient implements ILoggerClient {
  final bool showTimestamp;
  final String defaultTitle;

  LoggerClient({this.showTimestamp = true, this.defaultTitle = 'Trocado'});

  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) {
    _log(error: error, level: .debug, message: message, stackTrace: stackTrace);
  }

  @override
  void information(String message, {Object? error, StackTrace? stackTrace}) {
    _log(
      error: error,
      message: message,
      level: .information,
      stackTrace: stackTrace,
    );
  }

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _log(
      error: error,
      level: .warning,
      message: message,
      stackTrace: stackTrace,
    );
  }

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _log(error: error, level: .error, message: message, stackTrace: stackTrace);
  }

  @override
  void verbose(String message, {Object? error, StackTrace? stackTrace}) {
    _log(
      error: error,
      level: .verbose,
      message: message,
      stackTrace: stackTrace,
    );
  }

  @override
  void critical(String message, {Object? error, StackTrace? stackTrace}) {
    _log(
      error: error,
      level: .critical,
      message: message,
      stackTrace: stackTrace,
    );
  }

  void _log({
    required String message,
    required LoggerLevelConstant level,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kReleaseMode) return;

    final time = showTimestamp ? '${DateTime.now()}' : '';
    final formatted = _format(message, error, stackTrace);

    debugPrint('[$defaultTitle] [${level.type}] $time → $formatted');
  }

  String _format(String message, Object? error, StackTrace? stack) {
    if (error == null && stack == null) return message;

    final buffer = StringBuffer(message);

    if (error != null) buffer.write(' | error: $error');
    if (stack != null) buffer.write(' | stack: $stack');

    return buffer.toString();
  }
}
