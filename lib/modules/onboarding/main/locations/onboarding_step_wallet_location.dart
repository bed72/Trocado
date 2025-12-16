import 'package:duck_router/duck_router.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/calculator/calculator.dart';

import 'package:trocado/modules/onboarding/presentation/screens/onboarding_step_wallet_screen.dart';
import 'package:trocado/modules/onboarding/presentation/stores/onboarding_step_wallet_store.dart';

final class OnboardingStepWalletLocation extends Location {
  @override
  String get path => RoutesConstant.onboardingStepWallet.path;

  @override
  LocationBuilder? get builder => (context) {
    final store = context.get<OnboardingStepWalletStore>();

    return Observer(
      builder: (_) => OnboardingStepWalletScreen(
        goBack: context.pop,
        amount: store.amount,
        goNext: () => context.navigate(CoreLocation(), clearStack: true),
        navigateToCaculator: () => context.navigate(CalculatorLocation()),
      ),
    );
  };
}
