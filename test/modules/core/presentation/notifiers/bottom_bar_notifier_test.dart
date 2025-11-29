import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/core/core.dart';

void main() {
  group('BottomBarNotifier', () {
    test('should start with initial state 0', () {
      final notifier = BottomBarNotifier();
      expect(notifier.success, 0);
      expect(notifier.current, 0);
    });

    test('should update state when switchChild is called', () {
      final notifier = BottomBarNotifier();

      notifier.switchChild(2);

      expect(notifier.current, 2);
    });

    test('should notify listeners on state change', () {
      final notifier = BottomBarNotifier();

      var called = 0;
      notifier.addListener(() => called++);

      notifier.switchChild(1);

      expect(called, 1);
    });

    test('should not notify listeners when setting same state', () {
      int called = 0;
      final notifier = BottomBarNotifier();

      notifier.addListener(() => called++);

      notifier.switchChild(0);

      expect(called, 0);
    });

    test('should update state using update reducer', () {
      final notifier = BottomBarNotifier();

      notifier.replace((value) => value + 3);

      expect(notifier.current, 3);
    });

    test('should notify listeners when using update reducer', () {
      int called = 0;
      final notifier = BottomBarNotifier();

      notifier.addListener(() => called++);

      notifier.replace((value) => value + 1);

      expect(called, 1);
      expect(notifier.current, 1);
    });

    test('should update state using updateAsync reducer', () async {
      final notifier = BottomBarNotifier();

      await notifier.replaceAsync((value) async {
        await Future.delayed(Duration(milliseconds: 10));
        return value + 5;
      });

      expect(notifier.current, 5);
    });

    test('should notify listeners when using updateAsync reducer', () async {
      int called = 0;
      final notifier = BottomBarNotifier();

      notifier.addListener(() => called++);

      await notifier.replaceAsync((value) async => value + 2);

      expect(called, 3);
      expect(notifier.current, 2);
    });
  });
}
