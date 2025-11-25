import 'package:provider/provider.dart';
import 'package:trocado/modules/core/presentation/notifiers/bottom_bar_notifier.dart';

import 'package:trocado/modules/core/presentation/themes/notifiers/theme_notifier.dart';
import 'package:trocado/modules/core/presentation/notifiers/notification_notifier.dart';

import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

final notifierProvider = [
  ChangeNotifierProvider<BottomBarNotifier>(create: (_) => BottomBarNotifier()),
  ChangeNotifierProvider<ThemeNotifier>(
    create: (context) {
      final notifier = ThemeNotifier(
        repository: context.read<IStorageRepository>(),
      );

      notifier.ensureInitialized();

      return notifier;
    },
  ),

  ChangeNotifierProvider<NotificationNotifier>(
    create: (context) {
      final notifier = NotificationNotifier(
        repository: context.read<IStorageRepository>(),
      );

      notifier.ensureInitialized();

      return notifier;
    },
  ),
];
