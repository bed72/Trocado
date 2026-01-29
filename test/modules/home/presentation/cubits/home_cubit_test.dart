import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/transaction/data/dtos/transaction_type_dto.dart';
import 'package:trocado/modules/transaction/domain/models/transaction_model.dart';

import 'package:trocado/modules/home/presentation/cubits/home_cubit.dart';

import 'package:trocado/modules/home/domain/models/home_model.dart';
import 'package:trocado/modules/home/domain/models/balance_model.dart';
import 'package:trocado/modules/home/domain/repositories/interface_home_repository.dart';

import '../../../../mocks/mocks.dart';

void main() {
  late HomeCubit cubit;
  late IMoneyFormatter formatter;
  late IHomeRepository repository;

  final initialBalance = BalanceModel(income: 100, expense: 50, total: 50);
  final refreshedBalance = BalanceModel(income: 90, expense: 50, total: 40);

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
    formatter = MockMoneyFormatter();
    repository = MockHomeRepository();
    cubit = HomeCubit(formatter: formatter, repository: repository);
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
              endAt: any(named: 'endAt'),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              startAt: any(named: 'startAt'),
            ),
          ).thenReturn(Right(transactions));

          when(
            () => repository.getBalanceBy(
              endAt: any(named: 'endAt'),
              startAt: any(named: 'startAt'),
            ),
          ).thenReturn(Right(initialBalance));

          return cubit;
        },
        act: (cubit) => cubit.findTransactionBy(startAt: 0, endAt: 200),
        expect: () => [
          HomeLoading(),
          HomeSuccess(
            hasReachedEnd: true,
            home: HomeModel(
              balance: initialBalance,
              transactions: transactions,
            ),
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
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
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
        expect: () => [HomeLoading(), HomeFailure(failure: 'Failure')],
        act: (cubit) => cubit.findTransactionBy(startAt: 0, endAt: 200),
      );

      blocTest<HomeCubit, HomeState>(
        'emits HomeFailure when balance fails',
        build: () {
          when(
            () => repository.findTransactionBy(
              type: any(named: 'type'),
              endAt: any(named: 'endAt'),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
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

    group('loadMore', () {
      blocTest<HomeCubit, HomeState>(
        'does nothing when state is not HomeSuccess',
        build: () => cubit,
        act: (cubit) => cubit.loadMore(),
        verify: (_) {
          verifyNever(
            () => repository.findTransactionBy(
              type: any(named: 'type'),
              endAt: any(named: 'endAt'),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              startAt: any(named: 'startAt'),
            ),
          );
        },
      );

      blocTest<HomeCubit, HomeState>(
        'does nothing when hasReachedEnd is true',
        build: () {
          return cubit..emit(
            HomeSuccess(
              hasReachedEnd: true,
              home: HomeModel(
                balance: initialBalance,
                transactions: transactions,
              ),
            ),
          );
        },
        act: (cubit) => cubit.loadMore(),
        verify: (_) {
          verifyNever(
            () => repository.findTransactionBy(
              type: any(named: 'type'),
              endAt: any(named: 'endAt'),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              startAt: any(named: 'startAt'),
            ),
          );
        },
      );

      blocTest<HomeCubit, HomeState>(
        'does nothing when isLoadingMore is true',
        build: () {
          return cubit..emit(
            HomeSuccess(
              isLoadingMore: true,
              home: HomeModel(
                balance: initialBalance,
                transactions: transactions,
              ),
            ),
          );
        },
        act: (cubit) => cubit.loadMore(),
        verify: (_) {
          verifyNever(
            () => repository.findTransactionBy(
              type: any(named: 'type'),
              endAt: any(named: 'endAt'),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              startAt: any(named: 'startAt'),
            ),
          );
        },
      );

      blocTest<HomeCubit, HomeState>(
        'emits [isLoadingMore: true, updated list] when loadMore succeeds',
        build: () {
          final newTransactions = [
            TransactionModel(
              id: 3,
              date: 125,
              amount: 30,
              category: 'bonus',
              description: 'Bonus',
              type: TransactionTypeDto.income.label,
            ),
          ];

          when(
            () => repository.findTransactionBy(
              offset: 2,
              type: any(named: 'type'),
              endAt: any(named: 'endAt'),
              limit: any(named: 'limit'),
              startAt: any(named: 'startAt'),
            ),
          ).thenReturn(Right(newTransactions));

          return cubit..emit(
            HomeSuccess(
              home: HomeModel(
                balance: initialBalance,
                transactions: transactions,
              ),
              hasReachedEnd: false,
            ),
          );
        },
        act: (cubit) => cubit.loadMore(),
        expect: () => [
          HomeSuccess(
            home: HomeModel(
              balance: initialBalance,
              transactions: transactions,
            ),
            isLoadingMore: true,
            hasReachedEnd: false,
          ),
          HomeSuccess(
            home: HomeModel(
              balance: initialBalance,
              transactions: [
                ...transactions,
                TransactionModel(
                  id: 3,
                  date: 125,
                  amount: 30,
                  category: 'bonus',
                  description: 'Bonus',
                  type: TransactionTypeDto.income.label,
                ),
              ],
            ),
            hasReachedEnd: true,
            isLoadingMore: false,
          ),
        ],
      );

      blocTest<HomeCubit, HomeState>(
        'emits [isLoadingMore: true, isLoadingMore: false] when loadMore fails',
        build: () {
          when(
            () => repository.findTransactionBy(
              type: any(named: 'type'),
              endAt: any(named: 'endAt'),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              startAt: any(named: 'startAt'),
            ),
          ).thenReturn(const Left('Failure'));

          return cubit..emit(
            HomeSuccess(
              home: HomeModel(
                balance: initialBalance,
                transactions: transactions,
              ),
              hasReachedEnd: false,
            ),
          );
        },
        act: (cubit) => cubit.loadMore(),
        expect: () => [
          HomeSuccess(
            home: HomeModel(
              balance: initialBalance,
              transactions: transactions,
            ),
            isLoadingMore: true,
            hasReachedEnd: false,
          ),
          HomeSuccess(
            home: HomeModel(
              balance: initialBalance,
              transactions: transactions,
            ),
            isLoadingMore: false,
            hasReachedEnd: false,
          ),
        ],
      );
    });

    group('deleteTransactionBy', () {
      blocTest<HomeCubit, HomeState>(
        'does nothing when state is not HomeSuccess',
        build: () => cubit,
        act: (cubit) => cubit.deleteTransactionBy(id: 1),
        verify: (_) {
          verifyNever(() => repository.deleteTransactionBy(any()));
        },
      );

      blocTest<HomeCubit, HomeState>(
        'emits optimistic HomeSuccess and refreshed HomeSuccess when delete succeeds',
        build: () {
          when(
            () => repository.deleteTransactionBy(1),
          ).thenReturn(const Right(null));

          when(
            () => repository.getBalanceBy(
              endAt: any(named: 'endAt'),
              startAt: any(named: 'startAt'),
            ),
          ).thenReturn(Right(refreshedBalance));

          return cubit..emit(
            HomeSuccess(
              home: HomeModel(
                balance: initialBalance,
                transactions: transactions,
              ),
            ),
          );
        },
        act: (cubit) => cubit.deleteTransactionBy(id: 1),
        expect: () => [
          HomeSuccess(
            home: HomeModel(
              balance: initialBalance,
              transactions: [transactions[1]],
            ),
          ),
          HomeSuccess(
            home: HomeModel(
              balance: refreshedBalance,
              transactions: [transactions[1]],
            ),
            hasReachedEnd: true,
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
              home: HomeModel(
                balance: initialBalance,
                transactions: transactions,
              ),
            ),
          );
        },
        act: (cubit) => cubit.deleteTransactionBy(id: 1),
        expect: () => [
          HomeSuccess(
            home: HomeModel(
              balance: initialBalance,
              transactions: [transactions[1]],
            ),
          ),
          HomeFailure(failure: 'Failure'),
        ],
        verify: (_) {
          verifyNever(
            () => repository.getBalanceBy(
              endAt: any(named: 'endAt'),
              startAt: any(named: 'startAt'),
            ),
          );
        },
      );

      blocTest<HomeCubit, HomeState>(
        'emits HomeFailure when balance refresh fails after delete',
        build: () {
          when(
            () => repository.deleteTransactionBy(1),
          ).thenReturn(const Right(null));

          when(
            () => repository.getBalanceBy(
              endAt: any(named: 'endAt'),
              startAt: any(named: 'startAt'),
            ),
          ).thenReturn(const Left('Balance failure'));

          return cubit..emit(
            HomeSuccess(
              home: HomeModel(
                balance: initialBalance,
                transactions: transactions,
              ),
            ),
          );
        },
        act: (cubit) => cubit.deleteTransactionBy(id: 1),
        expect: () => [
          HomeSuccess(
            home: HomeModel(
              balance: initialBalance,
              transactions: [transactions[1]],
            ),
          ),
          HomeFailure(failure: 'Balance failure'),
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

    group('filterBalanceBy', () {
      blocTest<HomeCubit, HomeState>(
        'does nothing when state is not HomeSuccess',
        build: () => cubit,
        act: (cubit) => cubit.filterBalanceBy(type: .income),
        verify: (_) {
          verifyNever(
            () => repository.findTransactionBy(
              type: any(named: 'type'),
              limit: any(named: 'limit'),
              endAt: any(named: 'endAt'),
              offset: any(named: 'offset'),
              startAt: any(named: 'startAt'),
            ),
          );
        },
      );

      blocTest<HomeCubit, HomeState>(
        'selects type when none is selected and forwards it to findTransactionBy',
        build: () {
          when(
            () => repository.findTransactionBy(
              type: .income,
              endAt: any(named: 'endAt'),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              startAt: any(named: 'startAt'),
            ),
          ).thenReturn(
            Right(
              transactions
                  .where((t) => t.type == TransactionTypeDto.income.label)
                  .toList(),
            ),
          );

          when(
            () => repository.getBalanceBy(
              endAt: any(named: 'endAt'),
              startAt: any(named: 'startAt'),
            ),
          ).thenReturn(Right(initialBalance));

          return cubit..emit(
            HomeSuccess(
              home: HomeModel(
                balance: initialBalance,
                transactions: transactions,
              ),
            ),
          );
        },
        act: (cubit) => cubit.filterBalanceBy(type: .income),
        expect: () => [
          HomeLoading(),
          HomeSuccess(
            type: .income,
            home: HomeModel(
              balance: initialBalance,
              transactions: [transactions[1]],
            ),
            hasReachedEnd: true,
          ),
        ],
        verify: (_) {
          expect(cubit.selectedType, TransactionTypeDto.income);
        },
      );

      blocTest<HomeCubit, HomeState>(
        'toggles back to null when same type is selected again',
        build: () {
          when(
            () => repository.findTransactionBy(
              type: .income,
              endAt: any(named: 'endAt'),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              startAt: any(named: 'startAt'),
            ),
          ).thenReturn(
            Right(
              transactions
                  .where((t) => t.type == TransactionTypeDto.income.label)
                  .toList(),
            ),
          );

          when(
            () => repository.findTransactionBy(
              type: null,
              endAt: any(named: 'endAt'),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              startAt: any(named: 'startAt'),
            ),
          ).thenReturn(Right(transactions));

          when(
            () => repository.getBalanceBy(
              endAt: any(named: 'endAt'),
              startAt: any(named: 'startAt'),
            ),
          ).thenReturn(Right(initialBalance));

          return cubit..emit(
            HomeSuccess(
              home: HomeModel(
                balance: initialBalance,
                transactions: transactions,
              ),
            ),
          );
        },
        act: (cubit) async {
          cubit.filterBalanceBy(type: .income);
          cubit.filterBalanceBy(type: .income);
        },
        expect: () => [
          HomeLoading(),
          HomeSuccess(
            type: .income,
            home: HomeModel(
              balance: initialBalance,
              transactions: [transactions[1]],
            ),
            hasReachedEnd: true,
          ),
          HomeLoading(),
          HomeSuccess(
            home: HomeModel(
              balance: initialBalance,
              transactions: transactions,
            ),
            hasReachedEnd: true,
          ),
        ],
        verify: (_) {
          expect(cubit.selectedType, isNull);
        },
      );
    });
  });
}
