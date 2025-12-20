import 'package:mobx/mobx.dart';

import 'package:trocado/modules/core/domain/constant/storage_contant.dart';
import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

part 'fingerprint_store.g.dart';

class FingerprintStore = FingerprintStoreBase with _$FingerprintStore;

abstract class FingerprintStoreBase with Store {
  final IStorageRepository _repository;

  @observable
  bool fingerprint = false;

  FingerprintStoreBase({required IStorageRepository repository})
    : _repository = repository;

  @action
  Future<void> ensureInitialized() async {
    final data = await _repository.get(key: StorageConstant.fingerprint.key);
    if (data == null) return;
    fingerprint = bool.tryParse(data) ?? false;
  }

  @action
  void onChanged(bool value) {
    fingerprint = value;
    _repository.save(
      value: value.toString(),
      key: StorageConstant.fingerprint.key,
    );
  }
}
