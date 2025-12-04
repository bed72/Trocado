import 'package:command_it/command_it.dart';

import 'package:trocado/modules/core/domain/constant/storage_contant.dart';
import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

final class OnboardingCommand {
  final IStorageRepository _repository;

  bool get enabled => command.value;

  late final command = Command.createAsync<bool, bool>(
    _call,
    initialValue: false,
  );

  OnboardingCommand({required IStorageRepository repository})
    : _repository = repository;

  Future<void> ensureInitialized() async {
    final data = await _repository.get(key: StorageConstant.onboarding.key);

    if (data == null) return;

    final enabled = bool.tryParse(data);
    if (enabled == null) return;

    command.value = enabled;
  }

  Future<bool> _call(bool value) async {
    await _save(value);
    return value;
  }

  Future<void> _save(bool data) {
    return _repository.save(
      value: data.toString(),
      key: StorageConstant.onboarding.key,
    );
  }
}
