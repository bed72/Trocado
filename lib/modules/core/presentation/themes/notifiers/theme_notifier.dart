import 'package:flutter/material.dart';

import 'package:trocado/modules/core/presentation/notifiers/notifier.dart';
import 'package:trocado/modules/core/domain/constant/storage_contant.dart';
import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

final class ThemeNotifier extends Notifier<ThemeMode> {
  final IStorageRepository _repository;

  ThemeNotifier({required IStorageRepository repository})
    : _repository = repository,
      super(ThemeMode.system);

  bool get isDark => state == ThemeMode.dark;

  void toggle(bool data) async {
    state = data ? ThemeMode.dark : ThemeMode.light;
    _save(state == ThemeMode.dark);
  }

  Future<void> ensureInitialized() async {
    final data = await _repository.get(key: StorageConstant.theme.key);
    if (data == null) return;

    final isDark = bool.tryParse(data);
    if (isDark == null) return;

    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> _save(bool data) =>
      _repository.save(key: StorageConstant.theme.key, value: data.toString());
}
