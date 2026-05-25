import 'package:flutter_local_notifications/flutter_local_notifications.dart';

abstract interface class ILocalNotificationClient {
  Future<void> initialize();
  Future<void> show({
    required int id,
    required String body,
    required String title,
  });
}

final class LocalNotificationClient implements ILocalNotificationClient {
  final FlutterLocalNotificationsPlugin _plugin;

  LocalNotificationClient({required FlutterLocalNotificationsPlugin plugin})
    : _plugin = plugin;

  @override
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('ic_notification');
    const darwinSettings = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const settings = InitializationSettings(
      iOS: darwinSettings,
      android: androidSettings,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'trocado_default',
        'Notificações',
        importance: .high,
        description: 'Notificações do Trocado',
      ),
    );

    await _plugin.initialize(settings: settings);
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'trocado_default',
      'Notificações',
      priority: .high,
      importance: .high,
      icon: 'ic_notification',
      channelDescription: 'Notificações do Trocado',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      id: id,
      body: body,
      title: title,
      notificationDetails: notificationDetails,
    );
  }
}
