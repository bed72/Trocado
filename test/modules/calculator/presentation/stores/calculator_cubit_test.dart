import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/calculator/data/formatters/money_formater.dart';
import 'package:trocado/modules/calculator/presentation/cubits/calculator_cubit.dart';

import '../../mocks/mocks.dart';

void main() {
  late IMoneyFormatter formatter;

  setUp(() {
    formatter = MockMoneyFormatter();

    when(() => formatter.format(any())).thenAnswer((invocation) {
      final value = invocation.positionalArguments.first as double;
      return 'R\$ ${value.toStringAsFixed(2)}';
    });
  });

  CalculatorCubit build() => CalculatorCubit(formatter: formatter);

  test('initial state is CalculatorState.empty()', () {
    final cubit = build();

    expect(cubit.state, CalculatorState.empty());
  });

  blocTest<CalculatorCubit, CalculatorState>(
    'append builds value and formatted preview',
    build: build,
    act: (cubit) {
      cubit.onKeyTap('2');
      cubit.onKeyTap('0');
    },
    expect: () => const [
      CalculatorState(amount: '2', preview: 'R\$ 2.00'),
      CalculatorState(amount: '20', preview: 'R\$ 20.00'),
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
      CalculatorState(amount: '2', preview: 'R\$ 2.00'),
      CalculatorState(amount: '20', preview: 'R\$ 20.00'),
      CalculatorState(amount: '20,', preview: 'R\$ 20.00'),
      CalculatorState(amount: '20,1', preview: 'R\$ 20.10'),
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
      CalculatorState(amount: '1', preview: 'R\$ 1.00'),
      CalculatorState(amount: '1,', preview: 'R\$ 1.00'),
    ],
  );

  blocTest<CalculatorCubit, CalculatorState>(
    'delete removes last character and updates preview',
    build: build,
    act: (cubit) => cubit.onKeyTap('DEL'),
    seed: () => const CalculatorState(amount: '20,1', preview: 'R\$ 20.10'),
    expect: () => const [CalculatorState(amount: '20,', preview: 'R\$ 20.00')],
  );

  blocTest<CalculatorCubit, CalculatorState>(
    'delete does nothing when amount is empty',
    build: build,
    act: (cubit) => cubit.onKeyTap('DEL'),
  );

  blocTest<CalculatorCubit, CalculatorState>(
    'AC clears state',
    build: build,
    act: (cubit) => cubit.onKeyTap('AC'),
    expect: () => [CalculatorState.empty()],
    seed: () => const CalculatorState(amount: '10', preview: 'R\$ 10.00'),
  );

  blocTest<CalculatorCubit, CalculatorState>(
    'apply only confirms current value',
    build: build,
    expect: () => [],
    act: (cubit) => cubit.onKeyTap('✓'),
    seed: () => const CalculatorState(amount: '15', preview: 'R\$ 15.00'),
  );
}
