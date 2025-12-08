import 'package:mobx/mobx.dart';

import 'package:trocado/modules/core/domain/constant/storage_contant.dart';
import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

part 'onboarding_store.g.dart';

class OnboardingStore = OnboardingStoreBase with _$OnboardingStore;

abstract class OnboardingStoreBase with Store {
  final IStorageRepository _repository;

  @observable
  bool onboarding = false;

  OnboardingStoreBase({required IStorageRepository repository})
    : _repository = repository;

  @action
  Future<void> ensureInitialized() async {
    final data = await _repository.get(key: StorageConstant.onboarding.key);

    if (data == null) return;

    final enabled = bool.tryParse(data);
    if (enabled == null) return;

    onboarding = enabled;
  }

  @action
  Future<void> toggle(bool value) async {
    onboarding = value;
    await _save(value);
  }

  Future<void> _save(bool data) {
    return _repository.save(
      value: data.toString(),
      key: StorageConstant.onboarding.key,
    );
  }
}
