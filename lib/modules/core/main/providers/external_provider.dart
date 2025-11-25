import 'package:provider/provider.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final externalProviders = [
  Provider<FlutterSecureStorage>(create: (_) => FlutterSecureStorage()),
];
