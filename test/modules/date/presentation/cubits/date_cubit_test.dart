import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:trocado/modules/date/presentation/cubits/date_cubit.dart';

void main() {
  group('DateCubit', () {
    late DateCubit cubit;

    setUp(() {
      cubit = DateCubit();
    });

    tearDown(() {
      cubit.close();
    });

    setUpAll(() async {
      await initializeDateFormatting('pt_BR');
    });

    test('initial state should be DateState.empty()', () {
      final state = cubit.state;

      expect(state.formatted, isEmpty);
      expect(state.date, isA<DateTime>());
    });

    blocTest<DateCubit, DateState>(
      'emits formatted pt-BR date when select is called',
      build: () => DateCubit(),
      act: (cubit) => cubit.select(DateTime(2025, 1, 10)),
      expect: () => [
        DateState(date: DateTime(2025, 1, 10), formatted: '10/01/2025'),
      ],
    );

    blocTest<DateCubit, DateState>(
      'emits empty state when reset is called',
      build: () => DateCubit(),
      act: (cubit) {
        cubit.select(DateTime(2024, 12, 25));
        cubit.clear();
      },
      expect: () => [
        DateState(date: DateTime(2024, 12, 25), formatted: '25/12/2024'),
        isA<DateState>().having(
          (state) => state.formatted,
          'formatted',
          isEmpty,
        ),
      ],
    );

    blocTest<DateCubit, DateState>(
      'overwrites previous date when select is called multiple times',
      build: () => DateCubit(),
      act: (cubit) {
        cubit.select(DateTime(2024, 1, 1));
        cubit.select(DateTime(2024, 2, 2));
      },
      expect: () => [
        DateState(date: DateTime(2024, 1, 1), formatted: '01/01/2024'),
        DateState(date: DateTime(2024, 2, 2), formatted: '02/02/2024'),
      ],
    );
  });
}
