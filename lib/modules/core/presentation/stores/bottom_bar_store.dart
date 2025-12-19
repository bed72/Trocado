import 'package:mobx/mobx.dart';

part 'bottom_bar_store.g.dart';

class BottomBarStore = BottomBarStoreBase with _$BottomBarStore;

abstract class BottomBarStoreBase with Store {
  @observable
  int index = 0;

  @action
  void switchChild(int value) {
    index = value;
  }
}
