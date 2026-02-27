import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/src/domain/models/budget_model.dart';
import 'package:trocado/src/domain/usecases/get_budget_summary.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';

import 'package:trocado/src/presentation/bloc/budget/budget_event.dart';
import 'package:trocado/src/presentation/bloc/budget/budget_state.dart';

final class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final IBudgetRepository _budgetRepository;
  final GetBudgetSummary _getBudgetSummary;

  BudgetBloc({
    required IBudgetRepository budgetRepository,
    required GetBudgetSummary getBudgetSummary,
  }) : _budgetRepository = budgetRepository,
       _getBudgetSummary = getBudgetSummary,
       super(const BudgetState()) {
    on<BudgetLoaded>(_onLoaded);
    on<BudgetCreated>(_onCreated);
    on<BudgetRecalculated>(_onRecalculated);
  }

  void _onLoaded(BudgetLoaded event, Emitter<BudgetState> emit) {
    emit(state.copyWith(status: BudgetStatus.loading));

    final now = DateTime.now().millisecondsSinceEpoch;
    final result = _budgetRepository.findActive(now);

    result.fold(
      (error) => emit(state.copyWith(
        status: BudgetStatus.error,
        errorMessage: error,
      )),
      (budget) {
        if (budget == null) {
          emit(state.copyWith(status: BudgetStatus.empty));
          return;
        }

        final summaryResult = _getBudgetSummary(budget);
        summaryResult.fold(
          (error) => emit(state.copyWith(
            status: BudgetStatus.error,
            errorMessage: error,
          )),
          (summary) => emit(state.copyWith(
            summary: summary,
            status: BudgetStatus.active,
          )),
        );
      },
    );
  }

  void _onCreated(BudgetCreated event, Emitter<BudgetState> emit) {
    emit(state.copyWith(status: BudgetStatus.loading));

    final model = BudgetModel(
      amount: event.amount,
      startDate: event.startDate,
      endDate: event.endDate,
      description: event.description,
    );

    final result = _budgetRepository.upsert(model);

    result.fold(
      (error) => emit(state.copyWith(
        status: BudgetStatus.error,
        errorMessage: error,
      )),
      (_) => add(const BudgetLoaded()),
    );
  }

  void _onRecalculated(BudgetRecalculated event, Emitter<BudgetState> emit) {
    final summary = state.summary;
    if (summary == null) return;

    final result = _getBudgetSummary(summary.budget);
    result.fold(
      (error) => emit(state.copyWith(
        status: BudgetStatus.error,
        errorMessage: error,
      )),
      (newSummary) => emit(state.copyWith(
        summary: newSummary,
        status: BudgetStatus.active,
      )),
    );
  }
}
