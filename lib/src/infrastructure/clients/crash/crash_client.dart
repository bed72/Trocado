import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

abstract interface class ICrashClient {
  Future<void> recordError({
    required Object error,
    required StackTrace stackTrace,
    bool fatal = false,
  });

  Future<void> recordFlutterError(FlutterErrorDetails details);
}

final class CrashClient implements ICrashClient {
  @override
  Future<void> recordError({
    required Object error,
    required StackTrace stackTrace,
    bool fatal = false,
  }) =>
      FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: fatal);

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) =>
      FirebaseCrashlytics.instance.recordFlutterError(details);
}
