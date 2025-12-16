import 'package:trocado/main.dart';

import 'package:trocado/modules/onboarding/presentation/stores/onboarding_step_wallet_store.dart';

void onboardingProvider() {
  provider.registerFactory<OnboardingStepWalletStore>(
    OnboardingStepWalletStore.new,
  );
}
