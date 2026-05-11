import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

abstract interface class ICrashClient {
  Future<void> recordFlutterError(FlutterErrorDetails details);

  Future<void> recordError({
    required Object error,
    required StackTrace stackTrace,
    bool fatal = false,
  });
}

final class CrashClient implements ICrashClient {
  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) =>
      FirebaseCrashlytics.instance.recordFlutterError(details);

  @override
  Future<void> recordError({
    required Object error,
    required StackTrace stackTrace,
    bool fatal = false,
  }) =>
      FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: fatal);
}
