import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/models/expense_model.dart';
import 'package:trocado/src/domain/services/interface_money_service.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/presentation/data/expense_presentation_data.dart';
import 'package:trocado/src/presentation/mapper/expense_presentation_mapper.dart';

import 'package:trocado/src/presentation/bloc/expense_list/expense_list_bloc.dart';
import 'package:trocado/src/presentation/bloc/expense_list/expense_list_event.dart';
import 'package:trocado/src/presentation/bloc/expense_list/expense_list_state.dart';

import '../../../mocks/mocks.dart';

void main() {
  late IMoneyService service;
  late IExpenseRepository repository;
  late ExpenseModelToPresentationMapper mapper;

  final data = List.generate(
    20,
    (i) => ExpensePresentationData(
      category: .food,
      amount: 10.0 * (i + 1),
      description: 'Despesa $i',
      date: '27 de Fevereiro de 2026',
    ),
  );

  final model = List.generate(
    20,
    (i) => ExpenseModel(
      id: i + 1,
      category: 'food',
      amount: 10.0 * (i + 1),
      description: 'Despesa $i',
      date: DateTime(2026, 2, 1).millisecondsSinceEpoch,
    ),
  );

  setUpAll(() {
    registerFallbackValue(
      ExpenseModel(
        id: 0,
        amount: 0,
        category: '',
        description: '',
        date: DateTime(2026).millisecondsSinceEpoch,
      ),
    );
  });

  setUp(() {
    service = MockMoneyService();
    repository = MockExpenseRepository();
    mapper = MockExpenseModelToPresentationMapper();

    when(() => mapper.call(any())).thenReturn(data.first);
    when(() => service.format(any())).thenAnswer((invocation) {
      final value = invocation.positionalArguments[0] as double;
      return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
    });
  });

  ExpenseListBloc buildBloc() =>
      ExpenseListBloc(service: service, mapper: mapper, repository: repository);

  group('ExpenseListBloc', () {
    group('ExpenseListStarted', () {
      blocTest<ExpenseListBloc, ExpenseListState>(
        'should load first page on start',
        setUp: () {
          when(
            () => repository.findByPeriod(
              limit: any(named: 'limit'),
              endAt: any(named: 'endAt'),
              offset: any(named: 'offset'),
              startAt: any(named: 'startAt'),
            ),
          ).thenReturn(Right(model));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const ExpenseListStarted()),
        expect: () => [
          isA<ExpenseListState>().having(
            (s) => s.status,
            'status',
            ExpenseListStatus.loading,
          ),
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
              endAt: any(named: 'endAt'),
              offset: any(named: 'offset'),
              startAt: any(named: 'startAt'),
            ),
          ).thenReturn(Right(model.sublist(0, 5)));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const ExpenseListStarted()),
        expect: () => [
          isA<ExpenseListState>().having(
            (s) => s.status,
            'status',
            ExpenseListStatus.loading,
          ),
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
              endAt: any(named: 'endAt'),
              offset: any(named: 'offset'),
              startAt: any(named: 'startAt'),
            ),
          ).thenReturn(const Left('Ops, a operação falhou.'));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const ExpenseListStarted()),
        expect: () => [
          isA<ExpenseListState>().having(
            (s) => s.status,
            'status',
            ExpenseListStatus.loading,
          ),
          isA<ExpenseListState>()
              .having((s) => s.status, 'status', ExpenseListStatus.failure)
              .having(
                (s) => s.failureMessage,
                'error',
                'Ops, a operação falhou.',
              ),
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
              endAt: any(named: 'endAt'),
              offset: any(named: 'offset'),
              startAt: any(named: 'startAt'),
            ),
          ).thenReturn(Right(model));
        },
        build: buildBloc,
        seed: () => ExpenseListState(page: 1, expenses: data, status: .loaded),
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
          status: .loaded,
          hasReachedMax: true,
          expenses: data.sublist(0, 5),
        ),
        act: (bloc) => bloc.add(const ExpenseListNextPageRequested()),
      );
    });

    group('ExpenseListRefreshRequested', () {
      blocTest<ExpenseListBloc, ExpenseListState>(
        'should reset and reload expenses',
        setUp: () {
          when(
            () => repository.findByPeriod(
              limit: any(named: 'limit'),
              endAt: any(named: 'endAt'),
              offset: any(named: 'offset'),
              startAt: any(named: 'startAt'),
            ),
          ).thenReturn(Right(model.sublist(0, 3)));
        },
        build: buildBloc,
        seed: () => ExpenseListState(page: 2, expenses: data, status: .loaded),
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
              endAt: any(named: 'endAt'),
              offset: any(named: 'offset'),
              startAt: any(named: 'startAt'),
            ),
          ).thenReturn(const Left('Ops, a operação falhou.'));
        },
        build: buildBloc,
        seed: () => ExpenseListState(page: 1, expenses: data, status: .loaded),
        act: (bloc) => bloc.add(const ExpenseListRefreshRequested()),
        expect: () => [
          isA<ExpenseListState>().having(
            (s) => s.status,
            'status',
            ExpenseListStatus.loading,
          ),
          isA<ExpenseListState>()
              .having((s) => s.status, 'status', ExpenseListStatus.failure)
              .having(
                (s) => s.failureMessage,
                'error',
                'Ops, a operação falhou.',
              ),
        ],
      );
    });

    group('totalAmount', () {
      test('should calculate total from all expenses', () {
        final state = ExpenseListState(
          expenses: [
            ExpensePresentationData(
              amount: 10.0,
              category: .food,
              description: 'a',
              date: '27 de Fevereiro de 2026',
            ),
            ExpensePresentationData(
              amount: 20.0,
              category: .food,
              description: 'b',
              date: '27 de Fevereiro de 2026',
            ),
          ],
          status: .loaded,
        );

        expect(state.totalAmount, 30.0);
      });
    });
  });
}
