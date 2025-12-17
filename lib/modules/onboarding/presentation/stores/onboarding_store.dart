import 'package:mobx/mobx.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/onboarding/presentation/stores/onboarding_step_wallet_store.dart';

part 'onboarding_store.g.dart';

class OnboardingStore = OnboardingStoreBase with _$OnboardingStore;

abstract class OnboardingStoreBase with Store {
  final IStorageRepository _repository;

  final UserStore _user;
  final ThemeStore _theme;
  final OnboardingStepWalletStore _wallet;

  @observable
  bool alreadyDoneOnboarding = false;

  UserStore get user => _user;

  ThemeStore get theme => _theme;

  OnboardingStepWalletStore get wallet => _wallet;

  OnboardingStoreBase({
    required UserStore user,
    required ThemeStore theme,
    required IStorageRepository repository,
    required OnboardingStepWalletStore wallet,
  }) : _user = user,
       _theme = theme,
       _wallet = wallet,
       _repository = repository;

  @action
  Future<void> ensureInitialized() async {
    final data = await _repository.get(key: StorageConstant.onboarding.key);

    if (data == null) return;

    final enabled = bool.tryParse(data);
    if (enabled == null) return;

    alreadyDoneOnboarding = enabled;
  }

  @action
  Future<void> toggle(bool value) async {
    await _save(value);
    alreadyDoneOnboarding = value;
  }

  Future<void> _save(bool data) {
    return _repository.save(
      value: data.toString(),
      key: StorageConstant.onboarding.key,
    );
  }
}
