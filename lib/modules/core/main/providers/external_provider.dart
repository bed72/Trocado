import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:trocado/main.dart';

void externalProvider() {
  provider.registerLazySingleton<FlutterSecureStorage>(
    FlutterSecureStorage.new,
  );
}
