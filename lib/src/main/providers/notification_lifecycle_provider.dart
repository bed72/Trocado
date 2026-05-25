import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/clients_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

part 'notification_lifecycle_provider.g.dart';

@Riverpod(keepAlive: true)
final class NotificationLifecycle extends _$NotificationLifecycle {
  @override
  void build() {
    final messagingClient = ref.watch(messagingClientProvider);
    final repository = ref.watch(notificationRepositoryProvider);
    final localNotificationClient = ref.watch(localNotificationClientProvider);

    final tokenSubscription = repository.onTokenRefreshed.listen((_) {
      unawaited(repository.registerToken());
    });

    final foregroundSubscription = messagingClient.onForegroundMessage.listen((
      message,
    ) {
      unawaited(
        localNotificationClient.show(
          body: message['body'] as String,
          title: message['title'] as String,
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
      );
    });

    ref.onDispose(() {
      tokenSubscription.cancel();
      foregroundSubscription.cancel();
    });
  }
}
