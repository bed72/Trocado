import 'package:trocado/main.dart';

import 'package:trocado/modules/core/presentation/stores/theme_store.dart';

import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

void storeProvider() {
  provider.registerLazySingleton<ThemeStore>(
    () => ThemeStore(repository: provider<IStorageRepository>()),
  );
}
