import 'package:mobx/mobx.dart';
import 'package:flutter/material.dart';

import 'package:trocado/modules/core/domain/constant/storage_contant.dart';
import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

part 'theme_store.g.dart';

class ThemeStore = ThemeStoreBase with _$ThemeStore;

abstract class ThemeStoreBase with Store {
  final IStorageRepository repository;

  @observable
  ThemeMode theme = ThemeMode.system;

  @computed
  bool get isDark => theme == ThemeMode.dark;

  ThemeStoreBase({required this.repository});

  @action
  Future<void> ensureInitialized() async {
    final data = await repository.get(key: StorageConstant.theme.key);
    if (data == null) return;
    final parsed = bool.tryParse(data);
    if (parsed == null) return;

    theme = parsed ? ThemeMode.dark : ThemeMode.light;
  }

  @action
  Future<void> toggle(bool dark) async {
    theme = dark ? ThemeMode.dark : ThemeMode.light;
    await repository.save(
      value: dark.toString(),
      key: StorageConstant.theme.key,
    );
  }
}
