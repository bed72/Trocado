import 'package:flutter_solidart/flutter_solidart.dart';

import 'package:trocado/modules/core/domain/constant/storage_contant.dart';
import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

final class NotificationStore {
  final IStorageRepository _repository;

  final notification = Signal(false);

  NotificationStore({required IStorageRepository repository})
    : _repository = repository;

  Future<void> ensureInitialized() async {
    final data = await _repository.get(key: StorageConstant.notifications.key);

    if (data == null) return;

    final enabled = bool.tryParse(data);
    if (enabled == null) return;

    notification.value = enabled;
  }

  Future<void> toggle(bool value) async {
    await _save(value);

    notification.value = value;
  }

  Future<void> _save(bool data) => _repository.save(
    value: data.toString(),
    key: StorageConstant.notifications.key,
  );
}
