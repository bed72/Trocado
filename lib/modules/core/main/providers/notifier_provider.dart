import 'package:trocado/main.dart';

import 'package:trocado/modules/core/presentation/notifiers/user_notifier.dart';
import 'package:trocado/modules/core/presentation/notifiers/theme_notifier.dart';
import 'package:trocado/modules/core/presentation/notifiers/image_notifier.dart';
import 'package:trocado/modules/core/presentation/notifiers/bottom_bar_notifier.dart';
import 'package:trocado/modules/core/presentation/notifiers/onboarding_notifier.dart';
import 'package:trocado/modules/core/presentation/notifiers/fingerprint_notifier.dart';
import 'package:trocado/modules/core/presentation/notifiers/notification_notifier.dart';

import 'package:trocado/modules/core/domain/repositories/interface_user_repository.dart';
import 'package:trocado/modules/core/domain/repositories/interface_image_repository.dart';
import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

void provideNotifiers() {
  provider
    ..registerFactory<BottomBarNotifier>(BottomBarNotifier.new)
    ..registerFactory<UserNotifier>(
      () => UserNotifier(repository: provider<IUserRepository>()),
    )
    // notifier.ensureInitialized();
    ..registerLazySingleton<ThemeNotifier>(
      () => ThemeNotifier(repository: provider<IStorageRepository>()),
    )
    // notifier.ensureInitialized();
    ..registerLazySingleton<ImageNotifier>(
      () => ImageNotifier(
        imageRepository: provider<IImageRepository>(),
        storageRepository: provider<IStorageRepository>(),
      ),
    )
    // notifier.ensureInitialized();
    ..registerLazySingleton<OnboardingNotifier>(
      () => OnboardingNotifier(repository: provider<IStorageRepository>()),
    )
    // notifier.ensureInitialized();
    ..registerLazySingleton<FingerprintNotifier>(
      () => FingerprintNotifier(repository: provider<IStorageRepository>()),
    )
    // notifier.ensureInitialized();
    ..registerLazySingleton<NotificationNotifier>(
      () => NotificationNotifier(repository: provider<IStorageRepository>()),
    );
}
