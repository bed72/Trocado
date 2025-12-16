import 'package:mobx/mobx.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

part 'onboarding_step_wallet_store.g.dart';

class OnboardingStepWalletStore = OnboardingStepWalletStoreBase
    with _$OnboardingStepWalletStore;

abstract class OnboardingStepWalletStoreBase with Store {
  @observable
  String name = '';

  @observable
  String amount = '';

  @observable
  IconData icon = LucideIcons.banknote;

  @action
  void setName(String value) {
    name = value;
  }

  @action
  void setAmount(String value) {
    amount = value;
  }

  @action
  void setIcon(IconData value) {
    icon = value;
  }
}
