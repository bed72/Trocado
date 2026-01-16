import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/calculator/presentation/cubits/calculator_cubit.dart';
import 'package:trocado/modules/calculator/domain/repositories/interface_calculator_repository.dart';

import '../../../../mocks/mocks.dart';

void main() {
  late ICalculatorRepository repository;

  setUp(() {
    repository = MockCalculatorRepository();
  });

  CalculatorCubit build() => CalculatorCubit(repository: repository);

  test('initial state is CalculatorState.empty()', () {
    final cubit = build();

    expect(cubit.state, CalculatorState.empty());
  });

  blocTest<CalculatorCubit, CalculatorState>(
    'clear resets amount and preview',
    build: build,
    act: (cubit) => cubit.clear(),
    expect: () => [CalculatorState.empty()],
    seed: () => const CalculatorState(amount: '12+3', preview: '15'),
  );

  blocTest<CalculatorCubit, CalculatorState>(
    'append adds value and updates preview when calculation is valid',
    build: build,
    setUp: () {
      when(() => repository.operation('1')).thenReturn(double.nan);
      when(() => repository.operation('1+')).thenReturn(double.nan);
      when(() => repository.operation('1+2')).thenReturn(3);
    },
    verify: (_) {
      verify(() => repository.operation(any())).called(3);
    },
    act: (cubit) {
      cubit.onKeyTap('1');
      cubit.onKeyTap('+');
      cubit.onKeyTap('2');
    },
    expect: () => const [
      CalculatorState(amount: '1', preview: '1'),
      CalculatorState(amount: '1+', preview: '1+'),
      CalculatorState(amount: '1+2', preview: '3'),
    ],
  );

  blocTest<CalculatorCubit, CalculatorState>(
    'does not allow operator as first character',
    build: build,
    act: (cubit) => cubit.onKeyTap('+'),
    verify: (_) {
      verifyNever(() => repository.operation(any()));
    },
  );

  blocTest<CalculatorCubit, CalculatorState>(
    'does not allow two consecutive operators',
    build: build,
    setUp: () {
      when(() => repository.operation('1')).thenReturn(double.nan);
      when(() => repository.operation('1+')).thenReturn(double.nan);
    },
    act: (cubit) {
      cubit.onKeyTap('1');
      cubit.onKeyTap('+');
      cubit.onKeyTap('+');
    },
    expect: () => const [
      CalculatorState(amount: '1', preview: '1'),
      CalculatorState(amount: '1+', preview: '1+'),
    ],
  );

  blocTest<CalculatorCubit, CalculatorState>(
    'delete removes last character and recalculates preview',
    build: build,
    act: (cubit) => cubit.onKeyTap('DEL'),
    seed: () => const CalculatorState(amount: '1+2', preview: '3'),
    expect: () => const [CalculatorState(amount: '1+', preview: '1+')],
    setUp: () {
      when(() => repository.operation('1+')).thenReturn(double.nan);
    },
  );

  blocTest<CalculatorCubit, CalculatorState>(
    'delete does nothing when amount is empty',
    build: build,
    act: (cubit) => cubit.onKeyTap('DEL'),
    verify: (_) {
      verifyNever(() => repository.operation(any()));
    },
  );

  blocTest<CalculatorCubit, CalculatorState>(
    'toggleParenthesis adds opening parenthesis when counts are equal',
    build: build,
    act: (cubit) => cubit.onKeyTap('()'),
    expect: () => const [CalculatorState(amount: '(', preview: '(')],
    setUp: () {
      when(() => repository.operation('(')).thenReturn(double.nan);
    },
  );

  blocTest<CalculatorCubit, CalculatorState>(
    'toggleParenthesis adds closing parenthesis when there are more opens',
    build: build,
    act: (cubit) => cubit.onKeyTap('()'),
    seed: () => const CalculatorState(amount: '(', preview: '('),
    expect: () => const [CalculatorState(amount: '()', preview: '()')],
    setUp: () {
      when(() => repository.operation('()')).thenReturn(double.nan);
    },
  );

  blocTest<CalculatorCubit, CalculatorState>(
    'apply formats and commits result when calculation is valid',
    build: build,
    act: (cubit) => cubit.onKeyTap('✓'),
    seed: () => const CalculatorState(amount: '1+2', preview: '3'),
    expect: () => const [CalculatorState(amount: '3', preview: '3')],
    setUp: () {
      when(() => repository.operation('1+2')).thenReturn(3);
    },
  );

  blocTest<CalculatorCubit, CalculatorState>(
    'apply does nothing when result is NaN',
    build: build,
    act: (cubit) => cubit.onKeyTap('✓'),
    seed: () => const CalculatorState(amount: '1+', preview: '1+'),
    setUp: () {
      when(() => repository.operation('1+')).thenReturn(double.nan);
    },
  );
}
