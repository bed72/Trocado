import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

abstract interface class IMessagingClient {
  Future<String?> getToken();
}

final class MessagingClient implements IMessagingClient {
  @override
  Future<String?> getToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } on FirebaseException catch (exception) {
      if (exception.code == 'apns-token-not-set') return null;
      rethrow;
    }
  }
}
