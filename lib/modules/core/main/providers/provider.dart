import 'package:trocado/main.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/core/main/providers/client_provider.dart';
import 'package:trocado/modules/core/main/providers/external_provider.dart';
import 'package:trocado/modules/core/main/providers/command_provider.dart';
import 'package:trocado/modules/core/main/providers/resource_provider.dart';
import 'package:trocado/modules/core/main/providers/repository_provider.dart';
import 'package:trocado/modules/core/main/providers/datasource_provider.dart';

Future<void> ensureInitialized() async {
  provideClients();
  provideExternals();
  provideNotifiers();
  provideResources();
  provideDatasources();
  provideRepositories();

  await _ensureInitialized();
}

Future<void> _ensureInitialized() async {
  final user = provider.get<UserCommand>();
  final theme = provider.get<ThemeCommand>();
  final image = provider.get<ImageCommand>();
  final database = provider.get<IDatabaseClient>();
  final onboarding = provider.get<OnboardingCommand>();
  final fingerprint = provider.get<FingerprintCommand>();
  final notification = provider.get<NotificationCommand>();

  await Future.wait([
    user.ensureInitialized(),
    image.ensureInitialized(),
    theme.ensureInitialized(),
    database.ensureInitialized(),
    onboarding.ensureInitialized(),
    fingerprint.ensureInitialized(),
    notification.ensureInitialized(),

    provider.allReady(),
  ]);
}
