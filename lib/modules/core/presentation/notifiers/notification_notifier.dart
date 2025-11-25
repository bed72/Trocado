import 'package:trocado/modules/core/presentation/notifiers/notifier.dart';

import 'package:trocado/modules/core/domain/constant/storage_contant.dart';
import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

final class NotificationNotifier extends Notifier<bool> {
  final IStorageRepository _repository;

  NotificationNotifier({required IStorageRepository repository})
    : _repository = repository,
      super(false);

  bool get enabled => state;

  void toggle(bool data) {
    state = data;
    _save(data);
  }

  Future<void> ensureInitialized() async {
    final data = await _repository.get(key: StorageConstant.notifications.key);
    if (data == null) return;

    final enabled = bool.tryParse(data);
    if (enabled == null) return;

    state = enabled;
  }

  Future<void> _save(bool data) => _repository.save(
    key: StorageConstant.notifications.key,
    value: data.toString(),
  );
}
