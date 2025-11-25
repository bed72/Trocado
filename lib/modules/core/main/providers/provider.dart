import 'package:trocado/modules/core/main/providers/client_provider.dart';
import 'package:trocado/modules/core/main/providers/external_provider.dart';
import 'package:trocado/modules/core/main/providers/notifier_provider.dart';
import 'package:trocado/modules/core/main/providers/resource_provider.dart';
import 'package:trocado/modules/core/main/providers/repository_provider.dart';
import 'package:trocado/modules/core/main/providers/datasource_provider.dart';

final providers = [
  ...resourceProvider,
  ...externalProviders,
  ...clientProvider,
  ...datasourceProvider,
  ...repositoryProvider,
  ...notifierProvider,
];
