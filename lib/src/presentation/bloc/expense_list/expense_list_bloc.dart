import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/presentation/bloc/expense_list/expense_list_event.dart';
import 'package:trocado/src/presentation/bloc/expense_list/expense_list_state.dart';

final class ExpenseListBloc extends Bloc<ExpenseListEvent, ExpenseListState> {
  static const _pageSize = 20;

  final IExpenseRepository _repository;

  ExpenseListBloc({required IExpenseRepository repository})
      : _repository = repository,
        super(const ExpenseListState()) {
    on<ExpenseListStarted>(_onStarted);
    on<ExpenseListNextPageRequested>(_onNextPageRequested);
    on<ExpenseListRefreshRequested>(_onRefreshRequested);
  }

  void _onStarted(
    ExpenseListStarted event,
    Emitter<ExpenseListState> emit,
  ) {
    emit(state.copyWith(status: ExpenseListStatus.loading));

    final now = DateTime.now();
    final start = DateTime(now.year, now.month);
    final end = DateTime(now.year, now.month + 1);

    final result = _repository.findByPeriod(
      limit: _pageSize,
      offset: 0,
      startAt: start.millisecondsSinceEpoch,
      endAt: end.millisecondsSinceEpoch,
    );

    result.fold(
      (error) => emit(state.copyWith(
        status: ExpenseListStatus.error,
        errorMessage: error,
      )),
      (expenses) => emit(state.copyWith(
        page: 1,
        expenses: expenses,
        status: ExpenseListStatus.loaded,
        hasReachedMax: expenses.length < _pageSize,
      )),
    );
  }

  void _onNextPageRequested(
    ExpenseListNextPageRequested event,
    Emitter<ExpenseListState> emit,
  ) {
    if (state.hasReachedMax) return;

    final now = DateTime.now();
    final start = DateTime(now.year, now.month);
    final end = DateTime(now.year, now.month + 1);

    final result = _repository.findByPeriod(
      limit: _pageSize,
      offset: state.page * _pageSize,
      startAt: start.millisecondsSinceEpoch,
      endAt: end.millisecondsSinceEpoch,
    );

    result.fold(
      (error) => emit(state.copyWith(
        status: ExpenseListStatus.error,
        errorMessage: error,
      )),
      (expenses) => emit(state.copyWith(
        page: state.page + 1,
        expenses: [...state.expenses, ...expenses],
        hasReachedMax: expenses.length < _pageSize,
      )),
    );
  }

  void _onRefreshRequested(
    ExpenseListRefreshRequested event,
    Emitter<ExpenseListState> emit,
  ) {
    emit(const ExpenseListState(status: ExpenseListStatus.loading));

    final now = DateTime.now();
    final start = DateTime(now.year, now.month);
    final end = DateTime(now.year, now.month + 1);

    final result = _repository.findByPeriod(
      limit: _pageSize,
      offset: 0,
      startAt: start.millisecondsSinceEpoch,
      endAt: end.millisecondsSinceEpoch,
    );

    result.fold(
      (error) => emit(state.copyWith(
        status: ExpenseListStatus.error,
        errorMessage: error,
      )),
      (expenses) => emit(state.copyWith(
        page: 1,
        expenses: expenses,
        status: ExpenseListStatus.loaded,
        hasReachedMax: expenses.length < _pageSize,
      )),
    );
  }
}
