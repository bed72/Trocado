import 'package:mobx/mobx.dart';

part 'bottom_bar_store.g.dart';

class BottomBarStore = BottomBarStoreBase with _$BottomBarStore;

abstract class BottomBarStoreBase with Store {
  @observable
  int index = 0;

  @observable
  bool visible = false;

  @action
  void onChanged(bool value) {
    visible = value;
  }

  @action
  void switchChild(int value) {
    index = value;
  }
}
