import 'package:flutter_solidart/flutter_solidart.dart';

final class BottomBarStore {
  final index = Signal(0);

  set index(int value) {
    index.value = value;
  }
}
