import 'package:duck_router/duck_router.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/images/images.dart';

import 'package:trocado/modules/onboarding/main/onboarding_step_wallet_location.dart';
import 'package:trocado/modules/onboarding/presentation/screens/onboarding_step_profile_screen.dart';

final class OnboardingStepProfileLocation extends Location {
  @override
  String get path => RoutesConstant.onboardingStepProfile.path;

  @override
  LocationBuilder? get builder => (context) {
    final store = context.get<UserStore>();

    return Observer(
      builder: (_) => OnboardingStepProfileScreen(
        goBack: context.pop,
        isLoading: store.isLoading,
        resource: store.user.image,
        onEdit: () => context.navigate(ImagesLocation()),
        goNext: () => context.navigate(OnboardingStepWalletLocation()),
        onSaved: (name) async {
          await store
              .insert(UserDto(name: name, image: store.user.image))
              .whenComplete(
                () => context.navigate(OnboardingStepWalletLocation()),
              );
        },
      ),
    );
  };
}
