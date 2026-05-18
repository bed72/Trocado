import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

part 'notification_lifecycle_provider.g.dart';

@Riverpod(keepAlive: true)
final class NotificationLifecycle extends _$NotificationLifecycle {
  @override
  void build() {
    final repository = ref.watch(notificationRepositoryProvider);

    final subscription = repository.onTokenRefreshed.listen((_) {
      unawaited(repository.registerToken());
    });

    ref.onDispose(subscription.cancel);
  }
}
