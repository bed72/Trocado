import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/core/domain/either/either.dart';

import 'package:trocado/modules/transaction/data/dtos/transaction_type_dto.dart';
import 'package:trocado/modules/transaction/domain/models/transaction_model.dart';

import 'package:trocado/modules/home/presentation/cubits/home_cubit.dart';

import 'package:trocado/modules/home/domain/models/home_model.dart';
import 'package:trocado/modules/home/domain/models/balance_model.dart';
import 'package:trocado/modules/home/domain/repositories/interface_home_repository.dart';

import '../../mocks/mocks.dart';

void main() {
  late HomeCubit cubit;
  late IHomeRepository repository;

  final balance = BalanceModel(income: 100, expense: 50, total: 50);

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

  setUp(() {
    repository = MockHomeRepository();
    cubit = HomeCubit(repository: repository);
  });

  tearDown(() {
    cubit.close();
  });

  group('HomeCubit', () {
    test('initial state is HomeIdle', () {
      expect(cubit.state, isA<HomeIdle>());
    });

    group('findTransactionBy', () {
      blocTest<HomeCubit, HomeState>(
        'emits [HomeLoading, HomeSuccess] when success',
        build: () {
          when(
            () => repository.findTransactionBy(
              type: any(named: 'type'),
              startAt: any(named: 'startAt'),
              endAt: any(named: 'endAt'),
            ),
          ).thenReturn(Right(transactions));

          when(
            () => repository.getBalanceBy(
              startAt: any(named: 'startAt'),
              endAt: any(named: 'endAt'),
            ),
          ).thenReturn(Right(balance));

          return cubit;
        },
        act: (cubit) => cubit.findTransactionBy(startAt: 0, endAt: 200),
        expect: () => [
          HomeLoading(),
          HomeSuccess(
            home: HomeModel(balance: balance, transactions: transactions),
          ),
        ],
      );

      blocTest<HomeCubit, HomeState>(
        'emits [HomeLoading, HomeFailure] when transaction fails',
        build: () {
          when(
            () => repository.findTransactionBy(
              type: any(named: 'type'),
              endAt: any(named: 'endAt'),
              startAt: any(named: 'startAt'),
            ),
          ).thenReturn(const Left('Failure'));

          when(
            () => repository.getBalanceBy(
              endAt: any(named: 'endAt'),
              startAt: any(named: 'startAt'),
            ),
          ).thenReturn(
            const Right(BalanceModel(income: 0, expense: 0, total: 0)),
          );

          return cubit;
        },
        act: (cubit) => cubit.findTransactionBy(startAt: 0, endAt: 200),
        expect: () => [HomeLoading(), HomeFailure(failure: 'Failure')],
      );

      blocTest<HomeCubit, HomeState>(
        'emits HomeFailure when balance fails',
        build: () {
          when(
            () => repository.findTransactionBy(
              type: any(named: 'type'),
              endAt: any(named: 'endAt'),
              startAt: any(named: 'startAt'),
            ),
          ).thenReturn(Right(transactions));

          when(
            () => repository.getBalanceBy(
              endAt: any(named: 'endAt'),
              startAt: any(named: 'startAt'),
            ),
          ).thenReturn(const Left('Balance failure'));

          return cubit;
        },
        act: (cubit) => cubit.findTransactionBy(startAt: 0, endAt: 200),
        expect: () => [HomeLoading(), HomeFailure(failure: 'Balance failure')],
      );
    });

    group('deleteTransactionBy', () {
      blocTest<HomeCubit, HomeState>(
        'does nothing when state is not HomeSuccess',
        build: () => cubit,
        act: (cubit) => cubit.deleteTransactionBy(1),
        verify: (_) {
          verifyNever(() => repository.deleteTransactionBy(any()));
        },
      );

      blocTest<HomeCubit, HomeState>(
        'emits optimistic HomeSuccess when delete succeeds',
        build: () {
          when(
            () => repository.deleteTransactionBy(1),
          ).thenReturn(const Right(null));

          return cubit..emit(
            HomeSuccess(
              home: HomeModel(balance: balance, transactions: transactions),
            ),
          );
        },
        act: (cubit) => cubit.deleteTransactionBy(1),
        expect: () => [
          HomeSuccess(
            home: HomeModel(balance: balance, transactions: [transactions[1]]),
          ),
        ],
      );

      blocTest<HomeCubit, HomeState>(
        'emits HomeFailure when delete fails after optimistic update',
        build: () {
          when(
            () => repository.deleteTransactionBy(1),
          ).thenReturn(const Left('Failure'));

          return cubit..emit(
            HomeSuccess(
              home: HomeModel(balance: balance, transactions: transactions),
            ),
          );
        },
        act: (cubit) => cubit.deleteTransactionBy(1),
        expect: () => [
          HomeSuccess(
            home: HomeModel(balance: balance, transactions: [transactions[1]]),
          ),
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
