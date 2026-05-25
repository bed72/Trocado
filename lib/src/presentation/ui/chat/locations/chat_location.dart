import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/ui/chat/screens/chat_screen.dart';

final class ChatLocation extends Location {
  @override
  String get path => AppRoutes.chat.path;

  @override
  LocationBuilder? get builder => (context) => const ChatScreen();
}
