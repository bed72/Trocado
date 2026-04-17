import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/domain/services/money_service.dart';

import 'package:trocado/src/presentation/screens/calculator/notifiers/calculator_state.dart';
import 'package:trocado/src/presentation/screens/calculator/notifiers/calculator_intent.dart';
import 'package:trocado/src/presentation/screens/calculator/notifiers/calculator_notifier.dart';

ProviderContainer _makeContainer() {
  final container = ProviderContainer(
    overrides: [moneyServiceProvider.overrideWithValue(MoneyService())],
  );
  addTearDown(container.dispose);
  container.listen(calculatorProvider, (_, _) {});
  container.read(calculatorProvider);
  return container;
}

String _normalize(String value) => value.replaceAll('\u00A0', ' ');

void main() {
  group('initial state', () {
    test('rawDigits is empty', () {
      final container = _makeContainer();
      expect(container.read(calculatorProvider).digits, '');
    });

    test('displayValue is empty', () {
      final container = _makeContainer();
      expect(container.read(calculatorProvider).displayValue, '');
    });

    test('centValue is zero', () {
      final container = _makeContainer();
      expect(container.read(calculatorProvider).centValue, 0);
    });
  });

  group('dispatch — DigitPressed', () {
    test('appends digit to rawDigits', () {
      final container = _makeContainer();

      container
          .read(calculatorProvider.notifier)
          .dispatch(const DigitPressed('8'));

      expect(container.read(calculatorProvider).digits, '8');
    });

    test('appends multiple digits sequentially', () {
      final container = _makeContainer();
      final notifier = container.read(calculatorProvider.notifier);

      notifier.dispatch(const DigitPressed('8'));
      notifier.dispatch(const DigitPressed('5'));
      notifier.dispatch(const DigitPressed('0'));

      expect(container.read(calculatorProvider).digits, '850');
    });

    test('centValue reflects rawDigits as cents', () {
      final container = _makeContainer();
      final notifier = container.read(calculatorProvider.notifier);

      notifier.dispatch(const DigitPressed('8'));
      notifier.dispatch(const DigitPressed('5'));
      notifier.dispatch(const DigitPressed('0'));

      expect(container.read(calculatorProvider).centValue, 850);
    });

    test('updates displayValue with pt_BR formatted amount', () {
      final container = _makeContainer();
      final notifier = container.read(calculatorProvider.notifier);

      notifier.dispatch(const DigitPressed('8'));
      notifier.dispatch(const DigitPressed('5'));
      notifier.dispatch(const DigitPressed('0'));

      expect(
        _normalize(container.read(calculatorProvider).displayValue),
        'R\$ 8,50',
      );
    });

    test('displays leading zeros correctly', () {
      final container = _makeContainer();

      container
          .read(calculatorProvider.notifier)
          .dispatch(const DigitPressed('8'));

      expect(
        _normalize(container.read(calculatorProvider).displayValue),
        'R\$ 0,08',
      );
    });

    test('does not append beyond 9 digits', () {
      final container = _makeContainer();
      final notifier = container.read(calculatorProvider.notifier);

      for (final digit in '123456789'.split('')) {
        notifier.dispatch(DigitPressed(digit));
      }
      notifier.dispatch(const DigitPressed('0'));

      expect(container.read(calculatorProvider).digits, '123456789');
    });
  });

  group('dispatch — DeletePressed', () {
    test('removes the last digit', () {
      final container = _makeContainer();
      final notifier = container.read(calculatorProvider.notifier);

      notifier.dispatch(const DigitPressed('8'));
      notifier.dispatch(const DigitPressed('5'));
      notifier.dispatch(const DeletePressed());

      expect(container.read(calculatorProvider).digits, '8');
    });

    test('clears displayValue when the last digit is removed', () {
      final container = _makeContainer();
      final notifier = container.read(calculatorProvider.notifier);

      notifier.dispatch(const DigitPressed('8'));
      notifier.dispatch(const DeletePressed());

      expect(container.read(calculatorProvider).displayValue, '');
    });

    test('updates displayValue after partial deletion', () {
      final container = _makeContainer();
      final notifier = container.read(calculatorProvider.notifier);

      notifier.dispatch(const DigitPressed('8'));
      notifier.dispatch(const DigitPressed('5'));
      notifier.dispatch(const DigitPressed('0'));
      notifier.dispatch(const DeletePressed());

      expect(
        _normalize(container.read(calculatorProvider).displayValue),
        'R\$ 0,85',
      );
    });

    test('does nothing when rawDigits is empty', () {
      final container = _makeContainer();

      container
          .read(calculatorProvider.notifier)
          .dispatch(const DeletePressed());

      expect(container.read(calculatorProvider), const CalculatorState());
    });
  });

  group('dispatch — ClearPressed', () {
    test('resets to initial state', () {
      final container = _makeContainer();
      final notifier = container.read(calculatorProvider.notifier);

      notifier.dispatch(const DigitPressed('8'));
      notifier.dispatch(const DigitPressed('5'));
      notifier.dispatch(const DigitPressed('0'));
      notifier.dispatch(const ClearPressed());

      expect(container.read(calculatorProvider), const CalculatorState());
    });

    test('does nothing when already in initial state', () {
      final container = _makeContainer();

      container
          .read(calculatorProvider.notifier)
          .dispatch(const ClearPressed());

      expect(container.read(calculatorProvider), const CalculatorState());
    });
  });
}
