import 'package:command_it/command_it.dart';

final class BottomBarCommand {
  late final command = Command.createSync<int, int>(
    (index) => index,
    initialValue: 0,
  );
}
