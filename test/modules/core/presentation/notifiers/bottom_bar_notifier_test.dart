import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';

import 'package:trocado/modules/core/core.dart';

void main() {
  group('BottomBarStore', () {
    test('should start with index = 0', () {
      final store = BottomBarStore();

      expect(store.index, equals(0));
    });

    test('should update index when setIndex is called', () {
      final store = BottomBarStore();

      store.setIndex(2);

      expect(store.index, equals(2));
    });

    test('should trigger reaction when index changes', () {
      int called = 0;
      final store = BottomBarStore();

      final dispose = reaction<int>((_) => store.index, (_) => called++);

      store.setIndex(1);

      expect(called, 1);

      dispose();
    });

    test('should NOT trigger reaction when setting same value', () {
      int called = 0;
      final store = BottomBarStore();

      final dispose = reaction<int>((_) => store.index, (_) => called++);

      store.setIndex(0);

      expect(called, 0);

      dispose();
    });
  });
}
