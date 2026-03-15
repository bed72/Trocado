import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/src/application/services/money_service.dart';

import 'package:trocado/src/domain/models/expense_model.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/presentation/data/expense_presentation_data.dart';
import 'package:trocado/src/presentation/mapper/expense_presentation_mapper.dart';
import 'package:trocado/src/presentation/bloc/expense_list/expense_list_event.dart';
import 'package:trocado/src/presentation/bloc/expense_list/expense_list_state.dart';

final class ExpenseListBloc extends Bloc<ExpenseListEvent, ExpenseListState> {
  static const _pageSize = 20;

  final IMoneyService _service;
  final IExpenseRepository _repository;
  final ExpenseModelToPresentationMapper _mapper;

  ExpenseListBloc({
    required IMoneyService service,
    required IExpenseRepository repository,
    required ExpenseModelToPresentationMapper mapper,
  }) : _service = service,
       _mapper = mapper,
       _repository = repository,
       super(const ExpenseListState()) {
    on<ExpenseListStarted>(_onStarted);
    on<ExpenseListRefreshRequested>(_onRefreshRequested);
    on<ExpenseListNextPageRequested>(_onNextPageRequested);
  }

  void _onStarted(ExpenseListStarted event, Emitter<ExpenseListState> emit) {
    emit(state.copyWith(status: .loading));

    final now = DateTime.now();
    final start = DateTime(now.year, now.month);
    final end = DateTime(now.year, now.month + 1);

    final data = _repository.findByPeriod(
      offset: 0,
      limit: _pageSize,
      endAt: end.millisecondsSinceEpoch,
      startAt: start.millisecondsSinceEpoch,
    );

    data.fold(
      (failure) =>
          emit(state.copyWith(status: .failure, failureMessage: failure)),
      (success) => emit(
        state.copyWith(
          page: 1,
          status: .loaded,
          expenses: _map(success),
          hasReachedMax: success.length < _pageSize,
        ),
      ),
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

    final data = _repository.findByPeriod(
      limit: _pageSize,
      offset: state.page * _pageSize,
      endAt: end.millisecondsSinceEpoch,
      startAt: start.millisecondsSinceEpoch,
    );

    data.fold(
      (failure) =>
          emit(state.copyWith(status: .failure, failureMessage: failure)),
      (success) => emit(
        state.copyWith(
          page: state.page + 1,
          hasReachedMax: success.length < _pageSize,
          expenses: [...state.expenses, ..._map(success)],
        ),
      ),
    );
  }

  void _onRefreshRequested(
    ExpenseListRefreshRequested event,
    Emitter<ExpenseListState> emit,
  ) {
    emit(const ExpenseListState(status: .loading));

    final now = DateTime.now();
    final start = DateTime(now.year, now.month);
    final end = DateTime(now.year, now.month + 1);

    final data = _repository.findByPeriod(
      offset: 0,
      limit: _pageSize,
      endAt: end.millisecondsSinceEpoch,
      startAt: start.millisecondsSinceEpoch,
    );

    data.fold(
      (failure) =>
          emit(state.copyWith(status: .failure, failureMessage: failure)),
      (success) => emit(
        state.copyWith(
          page: 1,
          status: .loaded,
          expenses: _map(success),
          hasReachedMax: success.length < _pageSize,
        ),
      ),
    );
  }

  List<ExpensePresentationData> _map(List<ExpenseModel> model) => model
      .map(_mapper.call)
      .map(
        (expense) =>
            expense.copyWith(formattedAmount: _service.format(expense.amount)),
      )
      .toList();
}
