import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/models/expense_model.dart';

import 'package:trocado/src/presentation/bloc/expense_list/expense_list_bloc.dart';
import 'package:trocado/src/presentation/bloc/expense_list/expense_list_event.dart';
import 'package:trocado/src/presentation/bloc/expense_list/expense_list_state.dart';

import '../../../mocks/mocks.dart';

void main() {
  late MockExpenseRepository repository;

  final expenses = List.generate(
    20,
    (i) => ExpenseModel(
      id: i + 1,
      amount: 10.0 * (i + 1),
      date: DateTime(2026, 2, 1).millisecondsSinceEpoch,
      category: 'food',
      description: 'Despesa $i',
    ),
  );

  setUp(() {
    repository = MockExpenseRepository();
  });

  ExpenseListBloc buildBloc() => ExpenseListBloc(repository: repository);

  group('ExpenseListBloc', () {
    group('ExpenseListStarted', () {
      blocTest<ExpenseListBloc, ExpenseListState>(
        'should load first page on start',
        setUp: () {
          when(
            () => repository.findByPeriod(
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              startAt: any(named: 'startAt'),
              endAt: any(named: 'endAt'),
            ),
          ).thenReturn(Right(expenses));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const ExpenseListStarted()),
        expect: () => [
          isA<ExpenseListState>()
              .having((s) => s.status, 'status', ExpenseListStatus.loading),
          isA<ExpenseListState>()
              .having((s) => s.status, 'status', ExpenseListStatus.loaded)
              .having((s) => s.expenses.length, 'length', 20)
              .having((s) => s.hasReachedMax, 'hasReachedMax', false)
              .having((s) => s.page, 'page', 1),
        ],
      );

      blocTest<ExpenseListBloc, ExpenseListState>(
        'should mark hasReachedMax when less than pageSize',
        setUp: () {
          when(
            () => repository.findByPeriod(
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              startAt: any(named: 'startAt'),
              endAt: any(named: 'endAt'),
            ),
          ).thenReturn(Right(expenses.sublist(0, 5)));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const ExpenseListStarted()),
        expect: () => [
          isA<ExpenseListState>()
              .having((s) => s.status, 'status', ExpenseListStatus.loading),
          isA<ExpenseListState>()
              .having((s) => s.status, 'status', ExpenseListStatus.loaded)
              .having((s) => s.expenses.length, 'length', 5)
              .having((s) => s.hasReachedMax, 'hasReachedMax', true),
        ],
      );

      blocTest<ExpenseListBloc, ExpenseListState>(
        'should emit error when repository fails',
        setUp: () {
          when(
            () => repository.findByPeriod(
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              startAt: any(named: 'startAt'),
              endAt: any(named: 'endAt'),
            ),
          ).thenReturn(const Left('Ops, a operação falhou.'));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const ExpenseListStarted()),
        expect: () => [
          isA<ExpenseListState>()
              .having((s) => s.status, 'status', ExpenseListStatus.loading),
          isA<ExpenseListState>()
              .having((s) => s.status, 'status', ExpenseListStatus.error)
              .having((s) => s.errorMessage, 'error', 'Ops, a operação falhou.'),
        ],
      );
    });

    group('ExpenseListNextPageRequested', () {
      blocTest<ExpenseListBloc, ExpenseListState>(
        'should load next page and append expenses',
        setUp: () {
          when(
            () => repository.findByPeriod(
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              startAt: any(named: 'startAt'),
              endAt: any(named: 'endAt'),
            ),
          ).thenReturn(Right(expenses));
        },
        build: buildBloc,
        seed: () => ExpenseListState(
          page: 1,
          expenses: expenses,
          status: ExpenseListStatus.loaded,
        ),
        act: (bloc) => bloc.add(const ExpenseListNextPageRequested()),
        expect: () => [
          isA<ExpenseListState>()
              .having((s) => s.expenses.length, 'length', 40)
              .having((s) => s.page, 'page', 2)
              .having((s) => s.hasReachedMax, 'hasReachedMax', false),
        ],
      );

      blocTest<ExpenseListBloc, ExpenseListState>(
        'should not load when hasReachedMax is true',
        build: buildBloc,
        seed: () => ExpenseListState(
          page: 1,
          expenses: expenses.sublist(0, 5),
          status: ExpenseListStatus.loaded,
          hasReachedMax: true,
        ),
        act: (bloc) => bloc.add(const ExpenseListNextPageRequested()),
        expect: () => [],
      );
    });

    group('ExpenseListRefreshRequested', () {
      blocTest<ExpenseListBloc, ExpenseListState>(
        'should reset and reload expenses',
        setUp: () {
          when(
            () => repository.findByPeriod(
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              startAt: any(named: 'startAt'),
              endAt: any(named: 'endAt'),
            ),
          ).thenReturn(Right(expenses.sublist(0, 3)));
        },
        build: buildBloc,
        seed: () => ExpenseListState(
          page: 2,
          expenses: expenses,
          status: ExpenseListStatus.loaded,
        ),
        act: (bloc) => bloc.add(const ExpenseListRefreshRequested()),
        expect: () => [
          isA<ExpenseListState>()
              .having((s) => s.status, 'status', ExpenseListStatus.loading)
              .having((s) => s.expenses, 'expenses', isEmpty),
          isA<ExpenseListState>()
              .having((s) => s.status, 'status', ExpenseListStatus.loaded)
              .having((s) => s.expenses.length, 'length', 3)
              .having((s) => s.page, 'page', 1)
              .having((s) => s.hasReachedMax, 'hasReachedMax', true),
        ],
      );

      blocTest<ExpenseListBloc, ExpenseListState>(
        'should emit error on refresh failure',
        setUp: () {
          when(
            () => repository.findByPeriod(
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              startAt: any(named: 'startAt'),
              endAt: any(named: 'endAt'),
            ),
          ).thenReturn(const Left('Ops, a operação falhou.'));
        },
        build: buildBloc,
        seed: () => ExpenseListState(
          page: 1,
          expenses: expenses,
          status: ExpenseListStatus.loaded,
        ),
        act: (bloc) => bloc.add(const ExpenseListRefreshRequested()),
        expect: () => [
          isA<ExpenseListState>()
              .having((s) => s.status, 'status', ExpenseListStatus.loading),
          isA<ExpenseListState>()
              .having((s) => s.status, 'status', ExpenseListStatus.error)
              .having((s) => s.errorMessage, 'error', 'Ops, a operação falhou.'),
        ],
      );
    });

    group('totalAmount', () {
      test('should calculate total from all expenses', () {
        final state = ExpenseListState(
          expenses: [
            const ExpenseModel(
              id: 1, amount: 10.0, date: 0, category: 'food', description: 'a',
            ),
            const ExpenseModel(
              id: 2, amount: 20.0, date: 0, category: 'food', description: 'b',
            ),
          ],
          status: ExpenseListStatus.loaded,
        );

        expect(state.totalAmount, 30.0);
      });
    });
  });
}
