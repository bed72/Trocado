import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/calculator/presentation/cubits/calculator_cubit.dart';
import 'package:trocado/modules/core/core.dart';

import '../../../../mocks/mocks.dart';

void main() {
  late IMoneyFormatter formatter;

  setUp(() {
    formatter = MockMoneyFormatter();
  });

  CalculatorCubit build() => CalculatorCubit(formatter: formatter);

  group('CalculatorCubit', () {
    test('initial state is empty', () {
      final cubit = build();

      expect(cubit.state, CalculatorState.empty());
    });

    blocTest<CalculatorCubit, CalculatorState>(
      'digits build the numeric amount incrementally',
      build: build,
      act: (cubit) {
        cubit.onKeyTap('2');
        cubit.onKeyTap('0');
      },
      expect: () => const [
        CalculatorState(amount: 2.0),
        CalculatorState(amount: 20.0),
      ],
    );

    blocTest<CalculatorCubit, CalculatorState>(
      'allows decimal comma input',
      build: build,
      act: (cubit) {
        cubit.onKeyTap('2');
        cubit.onKeyTap(',');
        cubit.onKeyTap('5');
      },
      expect: () => const [
        CalculatorState(amount: 2.0),
        CalculatorState(amount: 2.5),
      ],
    );

    blocTest<CalculatorCubit, CalculatorState>(
      'ignores second comma',
      build: build,
      act: (cubit) {
        cubit.onKeyTap('1');
        cubit.onKeyTap(',');
        cubit.onKeyTap(',');
        cubit.onKeyTap('2');
      },
      expect: () => const [
        CalculatorState(amount: 1.0),
        CalculatorState(amount: 1.2),
      ],
    );

    blocTest<CalculatorCubit, CalculatorState>(
      'delete removes last digit from buffer',
      build: build,
      act: (cubit) {
        cubit.onKeyTap('2');
        cubit.onKeyTap('5');
        cubit.onKeyTap('DEL');
      },
      expect: () => const [
        CalculatorState(amount: 2.0),
        CalculatorState(amount: 25.0),
        CalculatorState(amount: 2.0),
      ],
    );

    blocTest<CalculatorCubit, CalculatorState>(
      'delete does nothing when buffer is empty',
      build: build,
      act: (cubit) => cubit.onKeyTap('DEL'),
      expect: () => const <CalculatorState>[],
    );

    blocTest<CalculatorCubit, CalculatorState>(
      'AC clears buffer and emits empty state',
      build: build,
      act: (cubit) {
        cubit.onKeyTap('1');
        cubit.onKeyTap('0');
        cubit.onKeyTap('AC');
      },
      expect: () => const [
        CalculatorState(amount: 1.0),
        CalculatorState(amount: 10.0),
        CalculatorState(amount: 0.0),
      ],
    );

    blocTest<CalculatorCubit, CalculatorState>(
      'apply does not change state',
      build: build,
      act: (cubit) {
        cubit.onKeyTap('3');
        cubit.onKeyTap('✓');
      },
      expect: () => const [CalculatorState(amount: 3.0)],
    );
  });
}
