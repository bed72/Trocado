import 'package:provider/provider.dart';

import 'package:trocado/modules/core/presentation/extensions/context_extension.dart';

import 'package:trocado/modules/core/presentation/notifiers/bottom_bar_notifier.dart';
import 'package:trocado/modules/core/presentation/notifiers/image_notifier.dart';
import 'package:trocado/modules/core/presentation/notifiers/onboarding_notifier.dart';
import 'package:trocado/modules/core/presentation/notifiers/fingerprint_notifier.dart';
import 'package:trocado/modules/core/presentation/notifiers/notification_notifier.dart';
import 'package:trocado/modules/core/presentation/notifiers/theme_notifier.dart';

import 'package:trocado/modules/core/domain/repositories/interface_image_repository.dart';
import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

final notifierProvider = [
  ChangeNotifierProvider<BottomBarNotifier>(create: (_) => BottomBarNotifier()),

  ChangeNotifierProvider<ThemeNotifier>(
    create: (context) {
      final notifier = ThemeNotifier(
        repository: context.get<IStorageRepository>(),
      );

      notifier.ensureInitialized();

      return notifier;
    },
  ),

  ChangeNotifierProvider<ImageNotifier>(
    create: (context) {
      final notifier = ImageNotifier(
        imageRepository: context.get<IImageRepository>(),
        storageRepository: context.get<IStorageRepository>(),
      );

      notifier.ensureInitialized();

      return notifier;
    },
  ),

  ChangeNotifierProvider<OnboardingNotifier>(
    create: (context) {
      final notifier = OnboardingNotifier(
        repository: context.get<IStorageRepository>(),
      );

      notifier.ensureInitialized();

      return notifier;
    },
  ),

  ChangeNotifierProvider<FingerprintNotifier>(
    create: (context) {
      final notifier = FingerprintNotifier(
        repository: context.get<IStorageRepository>(),
      );

      notifier.ensureInitialized();

      return notifier;
    },
  ),

  ChangeNotifierProvider<NotificationNotifier>(
    create: (context) {
      final notifier = NotificationNotifier(
        repository: context.get<IStorageRepository>(),
      );

      notifier.ensureInitialized();

      return notifier;
    },
  ),
];
