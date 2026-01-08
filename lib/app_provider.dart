import 'package:trocado/main.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/calculator/calculator.dart';

Future<void> ensureInitialized() async {
  storeProvider();
  clientProvider();
  externalProvider();
  resourceProvider();
  datasourceProvider();
  repositoryProvider();

  calculatorProvider();

  await _ensureInitialized();
}

Future<void> _ensureInitialized() async {
  final theme = provider.get<ThemeStore>();
  final database = provider.get<IDatabaseClient>();

  await Future.wait([
    theme.ensureInitialized(),
    database.ensureInitialized(),

    provider.allReady(),
  ]);
}
