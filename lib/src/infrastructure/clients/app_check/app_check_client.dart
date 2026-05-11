import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

abstract interface class IAppCheckClient {
  Future<void> activate();
  Future<String?> getToken();
}

final class AppCheckClient implements IAppCheckClient {
  @override
  Future<String?> getToken() => FirebaseAppCheck.instance.getToken();

  @override
  Future<void> activate() => FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? AndroidDebugProvider()
        : AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode ? AppleDebugProvider() : AppleAppAttestProvider(),
  );
}
