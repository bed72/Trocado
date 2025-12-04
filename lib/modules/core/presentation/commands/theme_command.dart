import 'package:flutter/material.dart';
import 'package:command_it/command_it.dart';

import 'package:trocado/modules/core/domain/constant/storage_contant.dart';
import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

final class ThemeCommand {
  final IStorageRepository _repository;

  late final command = Command.createAsync<bool, ThemeMode>(
    _call,
    initialValue: ThemeMode.system,
  );

  late final isDark = Command.createSyncNoParam<bool>(
    () => command.value == ThemeMode.dark,
    initialValue: false,
  );

  ThemeCommand({required IStorageRepository repository})
    : _repository = repository;

  Future<void> ensureInitialized() async {
    final data = await _repository.get(key: StorageConstant.theme.key);
    if (data == null) return;

    final isDark = bool.tryParse(data);
    if (isDark == null) return;

    command.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<ThemeMode> _call(bool isDark) async {
    final theme = isDark ? ThemeMode.dark : ThemeMode.light;

    await _save(isDark);

    return theme;
  }

  Future<void> _save(bool value) {
    return _repository.save(
      value: value.toString(),
      key: StorageConstant.theme.key,
    );
  }
}
