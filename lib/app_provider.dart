import 'package:trocado/main.dart';

import 'package:trocado/modules/core/core.dart';

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
  final user = provider.get<UserStore>();
  final theme = provider.get<ThemeStore>();
  final database = provider.get<IDatabaseClient>();
  final onboarding = provider.get<OnboardingStore>();
  final fingerprint = provider.get<FingerprintStore>();
  final notification = provider.get<NotificationStore>();

  await Future.wait([
    user.ensureInitialized(),
    theme.ensureInitialized(),
    database.ensureInitialized(),
    onboarding.ensureInitialized(),
    fingerprint.ensureInitialized(),
    notification.ensureInitialized(),

    provider.allReady(),
  ]);
}
