import 'package:flutter/foundation.dart';

import 'package:trocado/modules/core/domain/constant/logger_level_constant.dart';

abstract interface class ILogger {
  void debug(String message, {Object? error, StackTrace? stackTrace});
  void error(String message, {Object? error, StackTrace? stackTrace});
  void warning(String message, {Object? error, StackTrace? stackTrace});
  void verbose(String message, {Object? error, StackTrace? stackTrace});
  void critical(String message, {Object? error, StackTrace? stackTrace});
  void information(String message, {Object? error, StackTrace? stackTrace});
}

final class Logger implements ILogger {
  final bool showTimestamp;
  final String defaultTitle;

  Logger({this.showTimestamp = true, this.defaultTitle = 'Trocado'});

  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) {
    _log(
      error: error,
      message: message,
      stackTrace: stackTrace,
      level: LoggerLevelConstant.debug,
    );
  }

  @override
  void information(String message, {Object? error, StackTrace? stackTrace}) {
    _log(
      error: error,
      message: message,
      stackTrace: stackTrace,
      level: LoggerLevelConstant.information,
    );
  }

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _log(
      error: error,
      message: message,
      stackTrace: stackTrace,
      level: LoggerLevelConstant.warning,
    );
  }

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _log(
      error: error,
      message: message,
      stackTrace: stackTrace,
      level: LoggerLevelConstant.error,
    );
  }

  @override
  void verbose(String message, {Object? error, StackTrace? stackTrace}) {
    _log(
      error: error,
      message: message,
      stackTrace: stackTrace,
      level: LoggerLevelConstant.verbose,
    );
  }

  @override
  void critical(String message, {Object? error, StackTrace? stackTrace}) {
    _log(
      error: error,
      message: message,
      stackTrace: stackTrace,
      level: LoggerLevelConstant.critical,
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
