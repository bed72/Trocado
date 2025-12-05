import 'package:trocado/main.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/core/main/providers/client_provider.dart';
import 'package:trocado/modules/core/main/providers/external_provider.dart';
import 'package:trocado/modules/core/main/providers/store_provider.dart';
import 'package:trocado/modules/core/main/providers/resource_provider.dart';
import 'package:trocado/modules/core/main/providers/repository_provider.dart';
import 'package:trocado/modules/core/main/providers/datasource_provider.dart';

Future<void> ensureInitialized() async {
  provideStores();
  provideClients();
  provideExternals();
  provideResources();
  provideDatasources();
  provideRepositories();

  await _ensureInitialized();
}

Future<void> _ensureInitialized() async {
  final theme = provider.get<ThemeStore>();
  final database = provider.get<IDatabaseClient>();
  final onboarding = provider.get<OnboardingStore>();
  final fingerprint = provider.get<FingerprintStore>();
  final notification = provider.get<NotificationStore>();

  await Future.wait([
    theme.ensureInitialized(),
    database.ensureInitialized(),
    onboarding.ensureInitialized(),
    fingerprint.ensureInitialized(),
    notification.ensureInitialized(),

    provider.allReady(),
  ]);
}
