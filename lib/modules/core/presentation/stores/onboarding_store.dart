import 'package:flutter_solidart/flutter_solidart.dart';

import 'package:trocado/modules/core/domain/constant/storage_contant.dart';
import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

final class OnboardingStore {
  final IStorageRepository _repository;

  final onboarding = Signal(false);

  OnboardingStore({required IStorageRepository repository})
    : _repository = repository;

  Future<void> ensureInitialized() async {
    final data = await _repository.get(key: StorageConstant.onboarding.key);

    if (data == null) return;

    final enabled = bool.tryParse(data);
    if (enabled == null) return;

    onboarding.value = enabled;
  }

  Future<void> toggle(bool value) async {
    await _save(value);

    onboarding.value = value;
  }

  Future<void> _save(bool data) {
    return _repository.save(
      value: data.toString(),
      key: StorageConstant.onboarding.key,
    );
  }
}
