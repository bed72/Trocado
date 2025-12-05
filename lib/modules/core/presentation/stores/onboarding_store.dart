import 'package:mobx/mobx.dart';

import 'package:trocado/modules/core/domain/constant/storage_contant.dart';
import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

part 'onboarding_store.g.dart';

class OnboardingStore = OnboardingStoreBase with _$OnboardingStore;

abstract class OnboardingStoreBase with Store {
  final IStorageRepository repository;

  @observable
  bool onboarding = false;

  OnboardingStoreBase({required this.repository});

  @action
  Future<void> ensureInitialized() async {
    final data = await repository.get(key: StorageConstant.onboarding.key);

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
    return repository.save(
      value: data.toString(),
      key: StorageConstant.onboarding.key,
    );
  }
}
