import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/calculator/calculator.dart';

import 'package:trocado/modules/onboarding/presentation/screens/onboarding_step_wallet_screen.dart';

final class OnboardingStepWalletLocation extends Location {
  @override
  String get path => RoutesConstant.onboardingStepWallet.path;

  @override
  LocationBuilder? get builder => (context) {
    final store = context.get<CalculatorStore>();

    return OnboardingStepWalletScreen(
      store: store,
      goBack: context.pop,
      goNext: () => context.navigate(CoreLocation(), clearStack: true),
      navigateToCaculator: () => context.navigate(CalculatorLocation()),
    );
  };
}
