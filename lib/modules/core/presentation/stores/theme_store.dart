import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

import 'package:trocado/modules/core/domain/constant/storage_contant.dart';
import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

final class ThemeStore {
  final IStorageRepository _repository;

  final theme = Signal(ThemeMode.dark);

  late final isDark = Computed<bool>(() => theme.value == ThemeMode.dark);

  ThemeStore({required IStorageRepository repository})
    : _repository = repository;

  Future<void> ensureInitialized() async {
    final data = await _repository.get(key: StorageConstant.theme.key);
    if (data == null) return;

    final parsed = bool.tryParse(data);
    if (parsed == null) return;

    theme.value = parsed ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle(bool value) async {
    await _save(value);

    theme.value = value ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> _save(bool value) {
    return _repository.save(
      value: value.toString(),
      key: StorageConstant.theme.key,
    );
  }
}
