import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/presentation/bloc/budget/budget_bloc.dart';
import 'package:trocado/src/presentation/bloc/budget/budget_event.dart';
import 'package:trocado/src/presentation/bloc/budget/budget_state.dart';

import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/domain/models/budget/budget_model.dart';
import 'package:trocado/src/domain/models/budget/budget_summary_model.dart';

import 'package:trocado/src/domain/use_cases/get_budget_summary_use_case.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';

import '../../../mocks/mocks.dart';

void main() {
  late IBudgetRepository repository;
  late GetBudgetSummaryUseCase useCase;

  final budget = BudgetModel(
    id: 1,
    amount: 1000.0,
    endDate: DateTime(2026, 3).millisecondsSinceEpoch,
    startDate: DateTime(2026, 2).millisecondsSinceEpoch,
  );

  final summary = BudgetSummaryModel(budget: budget, spent: 500.0);

  setUpAll(() {
    registerFallbackValue(budget);
  });

  setUp(() {
    useCase = MockGetBudgetSummary();
    repository = MockBudgetRepository();
  });

  BudgetBloc buildBloc() =>
      BudgetBloc(repository: repository, useCase: useCase);

  group('BudgetBloc', () {
    group('BudgetLoaded', () {
      blocTest<BudgetBloc, BudgetState>(
        'should load active budget and calculate summary',
        setUp: () {
          when(() => repository.findActive(any())).thenReturn(Right(budget));
          when(() => useCase(any())).thenReturn(Right(summary));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const BudgetLoaded()),
        expect: () => [
          isA<BudgetState>().having(
            (s) => s.status,
            'status',
            BudgetStatus.loading,
          ),
          isA<BudgetState>()
              .having((s) => s.status, 'status', BudgetStatus.active)
              .having((s) => s.summary, 'summary', summary),
        ],
      );

      blocTest<BudgetBloc, BudgetState>(
        'should emit empty when no active budget',
        setUp: () {
          when(
            () => repository.findActive(any()),
          ).thenReturn(const Right(null));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const BudgetLoaded()),
        expect: () => [
          isA<BudgetState>().having(
            (s) => s.status,
            'status',
            BudgetStatus.loading,
          ),
          isA<BudgetState>().having(
            (s) => s.status,
            'status',
            BudgetStatus.empty,
          ),
        ],
      );

      blocTest<BudgetBloc, BudgetState>(
        'should emit error when repository fails',
        setUp: () {
          when(
            () => repository.findActive(any()),
          ).thenReturn(const Left('Ops, a operação falhou.'));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const BudgetLoaded()),
        expect: () => [
          isA<BudgetState>().having(
            (s) => s.status,
            'status',
            BudgetStatus.loading,
          ),
          isA<BudgetState>()
              .having((s) => s.status, 'status', BudgetStatus.failure)
              .having(
                (s) => s.failureMessage,
                'error',
                'Ops, a operação falhou.',
              ),
        ],
      );
    });

    group('BudgetCreated', () {
      blocTest<BudgetBloc, BudgetState>(
        'should create budget and reload',
        setUp: () {
          when(() => repository.upsert(any())).thenReturn(const Right(null));
          when(() => repository.findActive(any())).thenReturn(Right(budget));
          when(() => useCase(any())).thenReturn(Right(summary));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(
          BudgetCreated(
            amount: 1000.0,
            endDate: budget.endDate,
            startDate: budget.startDate,
          ),
        ),
        expect: () => [
          isA<BudgetState>().having(
            (s) => s.status,
            'status',
            BudgetStatus.loading,
          ),
          isA<BudgetState>()
              .having((s) => s.status, 'status', BudgetStatus.active)
              .having((s) => s.summary, 'summary', summary),
        ],
      );

      blocTest<BudgetBloc, BudgetState>(
        'should emit error when upsert fails',
        setUp: () {
          when(
            () => repository.upsert(any()),
          ).thenReturn(const Left('Ops, a operação falhou.'));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(
          BudgetCreated(
            amount: 1000.0,
            startDate: budget.startDate,
            endDate: budget.endDate,
          ),
        ),
        expect: () => [
          isA<BudgetState>().having(
            (s) => s.status,
            'status',
            BudgetStatus.loading,
          ),
          isA<BudgetState>().having(
            (s) => s.status,
            'status',
            BudgetStatus.failure,
          ),
        ],
      );
    });

    group('BudgetRecalculated', () {
      blocTest<BudgetBloc, BudgetState>(
        'should recalculate summary for active budget',
        setUp: () {
          final updatedSummary = BudgetSummaryModel(
            budget: budget,
            spent: 750.0,
          );
          when(() => useCase(any())).thenReturn(Right(updatedSummary));
        },
        build: buildBloc,
        seed: () => BudgetState(summary: summary, status: BudgetStatus.active),
        act: (bloc) => bloc.add(const BudgetRecalculated()),
        expect: () => [
          isA<BudgetState>()
              .having((s) => s.status, 'status', BudgetStatus.active)
              .having((s) => s.summary!.spent, 'spent', 750.0),
        ],
      );

      blocTest<BudgetBloc, BudgetState>(
        'should do nothing when no active summary',
        build: buildBloc,
        act: (bloc) => bloc.add(const BudgetRecalculated()),
      );
    });
  });
}
