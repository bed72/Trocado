import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/core/data/dtos/money_dto.dart';
import 'package:trocado/modules/calculator/presentation/cubits/calculator_cubit.dart';

import '../../mocks/mocks.dart';

void main() {
  late IMoneyDto formatter;

  setUp(() {
    formatter = MockMoneyFormatter();

    when(() => formatter.format(any())).thenAnswer((invocation) {
      final value = invocation.positionalArguments.first as double;
      return 'R\$ ${value.toStringAsFixed(2)}';
    });
  });

  CalculatorCubit build() => CalculatorCubit();

  test('initial state is CalculatorState.empty()', () {
    final cubit = build();

    expect(cubit.state, CalculatorState.empty());
  });

  blocTest<CalculatorCubit, CalculatorState>(
    'append builds raw preview and parsed amount',
    build: build,
    act: (cubit) {
      cubit.onKeyTap('2');
      cubit.onKeyTap('0');
    },
    expect: () => const [
      CalculatorState(amount: 2.0, preview: '2'),
      CalculatorState(amount: 20.0, preview: '20'),
    ],
  );

  blocTest<CalculatorCubit, CalculatorState>(
    'append allows decimal comma',
    build: build,
    act: (cubit) {
      cubit.onKeyTap('2');
      cubit.onKeyTap('0');
      cubit.onKeyTap(',');
      cubit.onKeyTap('1');
    },
    expect: () => const [
      CalculatorState(amount: 2.0, preview: '2'),
      CalculatorState(amount: 20.0, preview: '20'),
      CalculatorState(amount: 20.0, preview: '20,'),
      CalculatorState(amount: 20.1, preview: '20,1'),
    ],
  );

  blocTest<CalculatorCubit, CalculatorState>(
    'does not allow two commas',
    build: build,
    act: (cubit) {
      cubit.onKeyTap('1');
      cubit.onKeyTap(',');
      cubit.onKeyTap(',');
    },
    expect: () => const [
      CalculatorState(amount: 1.0, preview: '1'),
      CalculatorState(amount: 1.0, preview: '1,'),
    ],
  );

  blocTest<CalculatorCubit, CalculatorState>(
    'delete removes last character',
    build: build,
    seed: () => const CalculatorState(amount: 20.1, preview: '20,1'),
    act: (cubit) => cubit.onKeyTap('DEL'),
    expect: () => const [CalculatorState(amount: 20.0, preview: '20,')],
  );

  blocTest<CalculatorCubit, CalculatorState>(
    'delete does nothing when state is empty',
    build: build,
    act: (cubit) => cubit.onKeyTap('DEL'),
    expect: () => [],
  );

  blocTest<CalculatorCubit, CalculatorState>(
    'AC clears state',
    build: build,
    seed: () => const CalculatorState(amount: 10.0, preview: '10'),
    act: (cubit) => cubit.onKeyTap('AC'),
    expect: () => [CalculatorState.empty()],
  );

  blocTest<CalculatorCubit, CalculatorState>(
    'apply formats preview but keeps amount',
    build: build,
    seed: () => const CalculatorState(amount: 15.0, preview: '15'),
    act: (cubit) => cubit.onKeyTap('✓'),
    expect: () => [
      isA<CalculatorState>()
          .having((s) => s.amount, 'amount', 15.0)
          .having((s) => s.preview, 'preview', contains('15')),
    ],
  );
}
