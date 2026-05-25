import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

abstract interface class IMessagingClient {
  String get platform;
  Future<String?> getToken();
  Future<bool> requestPermission();
  Stream<String> get onTokenRefresh;
  Stream<Map<String, dynamic>> get onForegroundMessage;
}

final class MessagingClient implements IMessagingClient {
  @override
  String get platform => Platform.isIOS ? 'ios' : 'android';

  @override
  Stream<String> get onTokenRefresh =>
      FirebaseMessaging.instance.onTokenRefresh;

  @override
  Stream<Map<String, dynamic>> get onForegroundMessage => FirebaseMessaging
      .onMessage
      .where((m) => m.notification != null)
      .map(
        (m) => {
          'title': m.notification!.title ?? '',
          'body': m.notification!.body ?? '',
        },
      );

  @override
  Future<String?> getToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      return settings.authorizationStatus == .authorized ||
          settings.authorizationStatus == .provisional;
    } catch (_) {
      return false;
    }
  }
}
