import 'package:flutter_solidart/flutter_solidart.dart';

import 'package:trocado/modules/core/domain/constant/storage_contant.dart';
import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

final class FingerprintStore {
  final IStorageRepository _repository;

  final fingerprint = Signal<bool>(false);

  FingerprintStore({required IStorageRepository repository})
    : _repository = repository;

  Future<void> ensureInitialized() async {
    final data = await _repository.get(key: StorageConstant.fingerprint.key);

    if (data == null) return;

    final enabled = bool.tryParse(data);
    if (enabled == null) return;

    fingerprint.value = enabled;
  }

  Future<void> toggle(bool value) async {
    await _save(value);

    fingerprint.value = value;
  }

  Future<void> _save(bool data) => _repository.save(
    value: data.toString(),
    key: StorageConstant.fingerprint.key,
  );
}
