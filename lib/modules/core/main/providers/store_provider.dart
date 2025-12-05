import 'package:trocado/main.dart';

import 'package:trocado/modules/core/presentation/stores/user_store.dart';
import 'package:trocado/modules/core/presentation/stores/theme_store.dart';
import 'package:trocado/modules/core/presentation/stores/image_store.dart';
import 'package:trocado/modules/core/presentation/stores/bottom_bar_store.dart';
import 'package:trocado/modules/core/presentation/stores/onboarding_store.dart';
import 'package:trocado/modules/core/presentation/stores/fingerprint_store.dart';
import 'package:trocado/modules/core/presentation/stores/notification_store.dart';

import 'package:trocado/modules/core/domain/repositories/interface_user_repository.dart';
import 'package:trocado/modules/core/domain/repositories/interface_image_repository.dart';
import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

void provideStores() {
  provider
    ..registerLazySingleton<BottomBarStore>(BottomBarStore.new)
    ..registerLazySingleton<UserStore>(
      () => UserStore(repository: provider<IUserRepository>()),
    )
    ..registerLazySingleton<ThemeStore>(
      () => ThemeStore(repository: provider<IStorageRepository>()),
    )
    ..registerLazySingleton<OnboardingStore>(
      () => OnboardingStore(repository: provider<IStorageRepository>()),
    )
    ..registerLazySingleton<FingerprintStore>(
      () => FingerprintStore(repository: provider<IStorageRepository>()),
    )
    ..registerLazySingleton<NotificationStore>(
      () => NotificationStore(repository: provider<IStorageRepository>()),
    )
    ..registerLazySingleton<ImageStore>(
      () => ImageStore(
        imageRepository: provider<IImageRepository>(),
        storageRepository: provider<IStorageRepository>(),
      ),
    );
}
