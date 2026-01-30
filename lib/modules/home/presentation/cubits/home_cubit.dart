import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/home/domain/models/month_model.dart';
import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/home/domain/models/home_model.dart';
import 'package:trocado/modules/home/domain/repositories/interface_home_repository.dart';

part 'home_state.dart';

final class HomeCubit extends Cubit<HomeState> {
  final int _pageSize = 40;

  final IMoneyFormatter _formatter;
  final IHomeRepository _repository;

  MonthModel _currentMonth = MonthModel.now();
  MonthModel get currentMonth => _currentMonth;

  TransactionTypeModel? _selectedType;
  TransactionTypeModel? get selectedType => _selectedType;

  HomeCubit({
    required IMoneyFormatter formatter,
    required IHomeRepository repository,
  }) : _formatter = formatter,
       _repository = repository,
       super(HomeIdle());

  String format(double value) => _formatter.format(value);

  void clear() {
    emit(HomeIdle());

    _selectedType = null;
    _currentMonth = MonthModel.now();
  }

  TransactionDto toTransactionDto(TransactionModel model) =>
      _repository.toTransactionDto(model);

  void nextMonth() => changeMonth(_currentMonth.next);
  void previousMonth() => changeMonth(_currentMonth.previous);

  void changeMonth(MonthModel model) {
    _selectedType = null;
    _currentMonth = model;

    findTransactionBy();
  }

  void filterBalanceBy({int? endAt, int? startAt, TransactionTypeModel? type}) {
    final currentState = state;
    if (currentState is! HomeSuccess) return;

    final nextType = _selectedType == type ? null : type;
    _selectedType = nextType;

    findTransactionBy(type: nextType);
  }

  void deleteTransactionBy({required int id, int? startAt, int? endAt}) {
    final currentState = state;
    if (currentState is! HomeSuccess) return;

    final optimistic = currentState.home.removeTransactionBy(id);
    emit(currentState.copyWith(home: optimistic));

    final data = _repository
        .deleteTransactionBy(id)
        .flatMap(
          (_) => _repository
              .getBalanceBy(
                endAt: _currentMonth.endAt,
                startAt: _currentMonth.startAt,
              )
              .mapRight((balance) => optimistic.copyWith(balance: balance)),
        );

    data.fold(
      (failure) => emit(HomeFailure(failure: failure)),
      (home) => emit(
        currentState.copyWith(
          home: home,
          hasReachedEnd: home.transactions.length < _pageSize,
        ),
      ),
    );
  }

  void findTransactionBy({TransactionTypeModel? type}) {
    emit(HomeLoading());

    _selectedType = type;

    final data = _repository
        .findTransactionBy(
          offset: 0,
          type: type,
          limit: _pageSize,
          endAt: _currentMonth.endAt,
          startAt: _currentMonth.startAt,
        )
        .flatMap(
          (transactions) => _repository
              .getBalanceBy(
                endAt: _currentMonth.endAt,
                startAt: _currentMonth.startAt,
              )
              .mapRight(
                (balance) =>
                    HomeModel(balance: balance, transactions: transactions),
              ),
        );

    data.fold(
      (failure) => emit(HomeFailure(failure: failure)),
      (home) => emit(
        HomeSuccess(
          home: home,
          type: type,
          month: _currentMonth,
          hasReachedEnd: home.transactions.length < _pageSize,
        ),
      ),
    );
  }

  void loadMore() {
    final currentState = state;
    if (currentState is! HomeSuccess) return;
    if (currentState.isLoadingMore || currentState.hasReachedEnd) return;

    emit(currentState.copyWith(isLoadingMore: true));

    final currentOffset = currentState.home.transactions.length;

    final data = _repository.findTransactionBy(
      limit: _pageSize,
      type: _selectedType,
      offset: currentOffset,
      endAt: _currentMonth.endAt,
      startAt: _currentMonth.startAt,
    );

    data.fold((failure) => emit(currentState.copyWith(isLoadingMore: false)), (
      transactions,
    ) {
      final updated = [...currentState.home.transactions, ...transactions];

      emit(
        currentState.copyWith(
          isLoadingMore: false,
          hasReachedEnd: transactions.length < _pageSize,
          home: currentState.home.copyWith(transactions: updated),
        ),
      );
    });
  }
}
