import 'package:trocado/modules/core/presentation/notifiers/notifier.dart';

final class BottomBarNotifier extends Notifier<int> {
  BottomBarNotifier() : super(0);

  int get current => success;

  void switchChild(int index) {
    success = index;
  }
}
