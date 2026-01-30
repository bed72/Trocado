import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/home/presentation/notifiers/swipe_radius_notifier.dart';

void main() {
  group('SwipeRadiusNotifier', () {
    late SwipeRadiusNotifier notifier;

    setUp(() {
      notifier = SwipeRadiusNotifier(maxRadius: 20, deadZone: 0.04);
    });

    tearDown(() {
      notifier.dispose();
    });

    test('starts with progress 0 and max radius', () {
      expect(notifier.progress.value, 0.0);
      expect(notifier.radius, 20.0);
    });

    test('radius decreases aggressively inside deadZone', () {
      notifier.update(0.02);

      expect(notifier.radius, closeTo(10.0, 0.001));
    });

    test('radius becomes zero after deadZone', () {
      notifier.update(0.04);
      expect(notifier.radius, 0.0);

      notifier.update(0.5);
      expect(notifier.radius, 0.0);

      notifier.update(1.0);
      expect(notifier.radius, 0.0);
    });

    test('progress is clamped to 0 when negative', () {
      notifier.update(-1.0);
      expect(notifier.radius, 20.0);
    });

    test('progress is clamped to 1 when above 1', () {
      notifier.update(2.0);
      expect(notifier.radius, 0.0);
    });

    test('notifies listeners when progress changes', () {
      int callCount = 0;

      notifier.progress.addListener(() {
        callCount++;
      });

      notifier.update(0.01);
      notifier.update(0.02);

      expect(callCount, 2);
    });
  });
}
