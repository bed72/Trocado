import 'package:trocado/main.dart';

import 'package:trocado/modules/core/presentation/commands/user_command.dart';
import 'package:trocado/modules/core/presentation/commands/theme_command.dart';
import 'package:trocado/modules/core/presentation/commands/image_command.dart';
import 'package:trocado/modules/core/presentation/commands/bottom_bar_command.dart';
import 'package:trocado/modules/core/presentation/commands/onboarding_command.dart';
import 'package:trocado/modules/core/presentation/commands/fingerprint_command.dart';
import 'package:trocado/modules/core/presentation/commands/notification_command.dart';

import 'package:trocado/modules/core/domain/repositories/interface_user_repository.dart';
import 'package:trocado/modules/core/domain/repositories/interface_image_repository.dart';
import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

void provideNotifiers() {
  provider
    ..registerFactory<BottomBarCommand>(BottomBarCommand.new)
    ..registerFactory<UserCommand>(
      () => UserCommand(repository: provider<IUserRepository>()),
    )
    ..registerLazySingleton<ThemeCommand>(
      () => ThemeCommand(repository: provider<IStorageRepository>()),
    )
    ..registerLazySingleton<ImageCommand>(
      () => ImageCommand(
        imageRepository: provider<IImageRepository>(),
        storageRepository: provider<IStorageRepository>(),
      ),
    )
    ..registerLazySingleton<OnboardingCommand>(
      () => OnboardingCommand(repository: provider<IStorageRepository>()),
    )
    ..registerLazySingleton<FingerprintCommand>(
      () => FingerprintCommand(repository: provider<IStorageRepository>()),
    )
    ..registerLazySingleton<NotificationCommand>(
      () => NotificationCommand(repository: provider<IStorageRepository>()),
    );
}
