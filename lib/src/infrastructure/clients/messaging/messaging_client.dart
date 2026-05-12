import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

abstract interface class IMessagingClient {
  String get platform;
  Future<String?> getToken();
  Stream<String> get onTokenRefresh;
}

final class MessagingClient implements IMessagingClient {
  @override
  String get platform => Platform.isIOS ? 'ios' : 'android';

  @override
  Stream<String> get onTokenRefresh =>
      FirebaseMessaging.instance.onTokenRefresh;

  @override
  Future<String?> getToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }
}
