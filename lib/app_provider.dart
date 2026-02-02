import 'package:trocado/main.dart';

import 'package:trocado/src/main/providers/providers.dart';

import 'package:trocado/src/infrastructure/clients/database/database_client.dart';

Future<void> ensureInitialized() async {
  providers();

  final database = i.get<IDatabaseClient>();

  await Future.wait([database.ensureInitialized(), i.allReady()]);
}
