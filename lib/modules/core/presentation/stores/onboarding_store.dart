import 'package:mobx/mobx.dart';

import 'package:trocado/modules/core/core.dart';

part 'onboarding_store.g.dart';

class OnboardingStore = OnboardingStoreBase with _$OnboardingStore;

abstract class OnboardingStoreBase with Store {
  final IStorageRepository _repository;

  @observable
  bool alreadyDoneOnboarding = false;

  OnboardingStoreBase({required IStorageRepository repository})
    : _repository = repository;

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
