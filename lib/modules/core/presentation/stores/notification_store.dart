import 'package:mobx/mobx.dart';

import 'package:trocado/modules/core/domain/constant/storage_contant.dart';
import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

part 'notification_store.g.dart';

class NotificationStore = NotificationStoreBase with _$NotificationStore;

abstract class NotificationStoreBase with Store {
  final IStorageRepository repository;

  @observable
  bool notification = false;

  NotificationStoreBase({required this.repository});

  @action
  Future<void> ensureInitialized() async {
    final data = await repository.get(key: StorageConstant.notifications.key);
    if (data == null) return;
    notification = bool.tryParse(data) ?? false;
  }

  @action
  Future<void> toggle(bool value) async {
    notification = value;
    await repository.save(
      value: value.toString(),
      key: StorageConstant.notifications.key,
    );
  }
}
