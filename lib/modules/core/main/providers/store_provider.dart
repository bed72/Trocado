import 'package:trocado/main.dart';

import 'package:trocado/modules/core/presentation/stores/user_store.dart';
import 'package:trocado/modules/core/presentation/stores/theme_store.dart';
import 'package:trocado/modules/core/presentation/stores/bottom_bar_store.dart';

import 'package:trocado/modules/core/domain/repositories/interface_user_repository.dart';
import 'package:trocado/modules/core/domain/repositories/interface_image_repository.dart';
import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

void storeProvider() {
  provider
    ..registerLazySingleton<BottomBarStore>(BottomBarStore.new)
    ..registerLazySingleton<ThemeStore>(
      () => ThemeStore(repository: provider<IStorageRepository>()),
    )
    ..registerLazySingleton<UserStore>(
      () => UserStore(
        userRepository: provider<IUserRepository>(),
        imageRepository: provider<IImageRepository>(),
      ),
    );
}
