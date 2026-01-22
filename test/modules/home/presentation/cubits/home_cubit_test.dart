import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/core/domain/either/either.dart';

import 'package:trocado/modules/transaction/data/dtos/transaction_type_dto.dart';
import 'package:trocado/modules/transaction/domain/models/transaction_model.dart';

import 'package:trocado/modules/home/presentation/cubits/home_cubit.dart';

import 'package:trocado/modules/home/domain/models/home_model.dart';
import 'package:trocado/modules/home/domain/repositories/interface_home_repository.dart';

import '../../mocks/mocks.dart';

void main() {
  late HomeCubit cubit;
  late IHomeRepository repository;

  setUp(() {
    repository = MockHomeRepository();
    cubit = HomeCubit(repository: repository);
  });

  tearDown(() {
    cubit.close();
  });

  group('HomeCubit', () {
    group('initial state', () {
      test('should be HomeIdle', () {
        expect(cubit.state, isA<HomeIdle>());
      });
    });

    group('findByPeriod', () {
      final transactions = [
        TransactionModel(
          id: 1,
          date: 123,
          amount: 10,
          category: 'food',
          description: 'Lunch',
          type: TransactionTypeDto.expense.label,
        ),
        TransactionModel(
          id: 2,
          date: 124,
          amount: 20,
          category: 'salary',
          description: 'Salary',
          type: TransactionTypeDto.income.label,
        ),
      ];

      blocTest<HomeCubit, HomeState>(
        'emits [HomeLoading, HomeSuccess] when findByPeriod succeeds',
        act: (cubit) => cubit.findByPeriod(),
        build: () {
          when(
            () => repository.findByPeriod(
              type: any(named: 'type'),
              endAt: any(named: 'endAt'),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              startAt: any(named: 'startAt'),
            ),
          ).thenReturn(Right(transactions));
          return cubit;
        },
        expect: () => [
          HomeLoading(),
          HomeSuccess(home: HomeModel(transactions: transactions)),
        ],
        verify: (_) {
          verify(() => repository.findByPeriod()).called(1);
        },
      );

      blocTest<HomeCubit, HomeState>(
        'emits [HomeLoading, HomeFailure] when findByPeriod fails',
        act: (cubit) => cubit.findByPeriod(),
        build: () {
          when(
            () => repository.findByPeriod(
              type: any(named: 'type'),
              endAt: any(named: 'endAt'),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              startAt: any(named: 'startAt'),
            ),
          ).thenReturn(const Left('Failure'));
          return cubit;
        },
        expect: () => [HomeLoading(), HomeFailure(failure: 'Failure')],
      );
    });

    group('delete', () {
      final transactions = [
        TransactionModel(
          id: 1,
          date: 123,
          amount: 10,
          category: 'food',
          description: 'Lunch',
          type: TransactionTypeDto.expense.label,
        ),
        TransactionModel(
          id: 2,
          date: 124,
          amount: 20,
          category: 'salary',
          description: 'Salary',
          type: TransactionTypeDto.income.label,
        ),
      ];

      blocTest<HomeCubit, HomeState>(
        'does nothing when state is not HomeSuccess',
        build: () => cubit,
        act: (cubit) => cubit.delete(1),
        verify: (_) {
          verifyNever(() => repository.delete(any()));
        },
      );

      blocTest<HomeCubit, HomeState>(
        'emits optimistic HomeSuccess when delete succeeds',
        build: () {
          when(
            () => repository.delete(1),
          ).thenReturn(Right<String, void>(null));

          return cubit
            ..emit(HomeSuccess(home: HomeModel(transactions: transactions)));
        },
        act: (cubit) => cubit.delete(1),
        expect: () => [
          HomeSuccess(home: HomeModel(transactions: [transactions[1]])),
        ],
        verify: (_) {
          verify(() => repository.delete(1)).called(1);
        },
      );

      blocTest<HomeCubit, HomeState>(
        'emits HomeFailure when delete fails after optimistic update',
        build: () {
          when(() => repository.delete(1)).thenReturn(const Left('Failure'));

          return cubit
            ..emit(HomeSuccess(home: HomeModel(transactions: transactions)));
        },
        act: (cubit) => cubit.delete(1),
        expect: () => [
          HomeSuccess(home: HomeModel(transactions: [transactions[1]])),
          HomeFailure(failure: 'Failure'),
        ],
      );
    });

    group('clear', () {
      blocTest<HomeCubit, HomeState>(
        'emits HomeIdle when clear is called',
        build: () => cubit,
        expect: () => [HomeIdle()],
        act: (cubit) => cubit.clear(),
      );
    });
  });
}
