import 'package:trocado/modules/core/presentation/notifiers/notifier.dart';

final class BottomBarNotifier extends Notifier<int> {
  BottomBarNotifier() : super(0);

  int get current => state;

  void switchChild(int index) {
    state = index;
  }
}
