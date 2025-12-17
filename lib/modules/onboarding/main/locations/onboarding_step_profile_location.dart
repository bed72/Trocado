import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/images/images.dart';

import 'package:trocado/modules/onboarding/main/locations/onboarding_step_wallet_location.dart';
import 'package:trocado/modules/onboarding/presentation/screens/onboarding_step_profile_screen.dart';

final class OnboardingStepProfileLocation extends Location {
  @override
  String get path => RoutesConstant.onboardingStepProfile.path;

  @override
  LocationBuilder? get builder =>
      (context) => OnboardingStepProfileScreen(
        goBack: context.pop,
        onEdit: () => context.navigate(ImagesLocation()),
        goNext: () => context.navigate(OnboardingStepWalletLocation()),
        navigateToWallet: () =>
            context.navigate(OnboardingStepWalletLocation()),
      );
}
