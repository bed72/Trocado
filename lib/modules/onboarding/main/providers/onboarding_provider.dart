import 'package:trocado/main.dart';
import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/onboarding/presentation/stores/onboarding_store.dart';
import 'package:trocado/modules/onboarding/presentation/stores/onboarding_step_wallet_store.dart';

void onboardingProvider() {
  provider
    ..registerCachedFactory<OnboardingStepWalletStore>(
      OnboardingStepWalletStore.new,
    )
    ..registerLazySingleton<OnboardingStore>(
      () => OnboardingStore(
        repository: provider<IStorageRepository>(),
        user: provider.get<UserStore>(),
        theme: provider.get<ThemeStore>(),
        wallet: provider.get<OnboardingStepWalletStore>(),
      ),
    );
}
