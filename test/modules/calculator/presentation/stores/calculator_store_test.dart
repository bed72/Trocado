import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/calculator/presentation/stores/calculator_store.dart';
import 'package:trocado/modules/calculator/domain/repositories/interface_calculator_repository.dart';

import '../../../../mocks/mocks.dart';

void main() {
  late CalculatorStore store;
  late ICalculatorRepository repository;

  setUp(() {
    repository = MockCalculatorRepository();
    store = CalculatorStore(repository: repository);
  });

  group('CalculatorStore - Typing and Editing', () {
    test('You must add characters to the amount and update the preview.', () {
      when(() => repository.operation('1')).thenReturn(1.0);
      when(() => repository.operation('12')).thenReturn(12.0);
      when(() => repository.operation('12+2')).thenReturn(14.0);
      when(() => repository.operation('12+')).thenReturn(double.nan);
      when(() => repository.isInvalidFirstInput(any())).thenReturn(false);

      store.onKeyTap('1');
      store.onKeyTap('2');
      store.onKeyTap('+');
      store.onKeyTap('2');

      expect(store.preview, '14');
      expect(store.amount, '12+2');
    });

    test('You should clear everything by clicking on AC.', () {
      store.amount = '123';
      store.onKeyTap('AC');

      expect(store.amount, '');
      expect(store.preview, '...');
    });

    test('You must delete the last character.', () {
      when(() => repository.operation('1')).thenReturn(1.0);

      store.amount = '12';
      store.onKeyTap('DEL');

      expect(store.amount, '1');
      verify(() => repository.operation('1')).called(1);
    });
  });

  group('CalculatorStore - Parentheses Logic', () {
    test('You must alternate parentheses correctly.', () {
      when(() => repository.operation(any())).thenReturn(double.nan);
      when(() => repository.isInvalidFirstInput(any())).thenReturn(false);

      store.onKeyTap('()');
      expect(store.amount, '(');

      store.onKeyTap('1');
      store.onKeyTap('()');
      expect(store.amount, '(1)');

      store.onKeyTap('()');
      expect(store.amount, '(1)(');
    });
  });

  group('CalculatorStore - Result (Apply)', () {
    test('You should apply the result to the amount by clicking on =.', () {
      when(() => repository.operation('10+10')).thenReturn(20.0);

      store.amount = '10+10';
      store.onKeyTap('=');

      expect(store.amount, '20');
      expect(store.preview, '20');
    });

    test('Do not change the amount if the repository returns NaN.', () {
      when(() => repository.operation('10/')).thenReturn(double.nan);

      store.amount = '10/';
      store.onKeyTap('=');

      expect(store.amount, '10/');
    });
  });

  group('CalculatorStore - Formatting', () {
    test('You must format .0 as an integer in the preview.', () {
      when(() => repository.operation('5+5')).thenReturn(10.0);
      when(() => repository.isInvalidFirstInput(any())).thenReturn(false);

      store.append('5+5');

      expect(store.preview, '10');
    });

    test('It must retain decimal places if it is not .0.', () {
      when(() => repository.operation('10/4')).thenReturn(2.5);
      when(() => repository.isInvalidFirstInput(any())).thenReturn(false);

      store.append('10/4');

      expect(store.preview, '2.5');
    });
  });
}
