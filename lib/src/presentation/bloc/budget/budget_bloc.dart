import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/src/presentation/bloc/budget/budget_event.dart';
import 'package:trocado/src/presentation/bloc/budget/budget_state.dart';

import 'package:trocado/src/domain/models/budget/budget_model.dart';

import 'package:trocado/src/domain/use_cases/get_budget_summary_use_case.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';

final class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final IBudgetRepository _repository;
  final GetBudgetSummaryUseCase _useCase;

  BudgetBloc({
    required IBudgetRepository repository,
    required GetBudgetSummaryUseCase useCase,
  }) : _useCase = useCase,
       _repository = repository,
       super(const BudgetState()) {
    on<BudgetLoaded>(_onLoaded);
    on<BudgetCreated>(_onCreated);
    on<BudgetRecalculated>(_onRecalculated);
  }

  void _onLoaded(BudgetLoaded event, Emitter<BudgetState> emit) {
    emit(state.copyWith(status: .loading));

    final now = DateTime.now().millisecondsSinceEpoch;
    final budgetData = _repository.findActive(now);

    budgetData.fold(
      (failure) =>
          emit(state.copyWith(status: .failure, failureMessage: failure)),
      (success) {
        if (success == null) {
          emit(state.copyWith(status: .empty));
          return;
        }

        final summaryData = _useCase(success);
        summaryData.fold(
          (failure) =>
              emit(state.copyWith(status: .failure, failureMessage: failure)),
          (success) => emit(state.copyWith(summary: success, status: .active)),
        );
      },
    );
  }

  void _onCreated(BudgetCreated event, Emitter<BudgetState> emit) {
    emit(state.copyWith(status: .loading));

    final model = BudgetModel(
      amount: event.amount,
      endDate: event.endDate,
      startDate: event.startDate,
      description: event.description,
    );

    final data = _repository.upsert(model);

    data.fold(
      (failure) =>
          emit(state.copyWith(status: .failure, failureMessage: failure)),
      (_) => add(const BudgetLoaded()),
    );
  }

  void _onRecalculated(BudgetRecalculated event, Emitter<BudgetState> emit) {
    final summary = state.summary;
    if (summary == null) return;

    final data = _useCase(summary.budget);
    data.fold(
      (failure) =>
          emit(state.copyWith(status: .failure, failureMessage: failure)),
      (success) => emit(state.copyWith(summary: success, status: .active)),
    );
  }
}
