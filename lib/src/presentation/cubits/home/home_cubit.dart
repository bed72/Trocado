import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/src/domain/models/month_model.dart';

import 'package:trocado/src/domain/models/home_model.dart';
import 'package:trocado/src/domain/models/transaction_model.dart';
import 'package:trocado/src/domain/repositories/interface_money_repository.dart';
import 'package:trocado/src/domain/repositories/interface_transaction_repository.dart';

import 'package:trocado/src/presentation/cubits/transaction/transaction_cubit.dart';

part 'home_state.dart';

final class HomeCubit extends Cubit<HomeState> {
  final int _pageSize = 40;

  final IMoneyRepository _moneyRepository;
  final TransactionCubit _transactionCubit;
  final ITransactionRepository _transactionRepository;

  StreamSubscription<TransactionState>? _transactionSubscription;

  MonthModel _currentMonth = MonthModel.now();
  MonthModel get currentMonth => _currentMonth;

  TransactionTypeModel? _selectedType;
  TransactionTypeModel? get selectedType => _selectedType;

  HomeCubit({
    required IMoneyRepository moneyRepository,
    required TransactionCubit transactionCubit,
    required ITransactionRepository transactionRepository,
  }) : _moneyRepository = moneyRepository,
       _transactionCubit = transactionCubit,
       _transactionRepository = transactionRepository,
       super(HomeIdle()) {
    _listenToTransactionCubit();
  }

  @override
  Future<void> close() {
    _transactionSubscription?.cancel();
    return super.close();
  }

  String format(double value) => _moneyRepository.format(value);

  void clear() {
    emit(HomeIdle());

    _selectedType = null;
    _currentMonth = MonthModel.now();
  }

  void nextMonth() => changeMonth(_currentMonth.next);
  void previousMonth() => changeMonth(_currentMonth.previous);

  void changeMonth(MonthModel model) {
    _selectedType = null;
    _currentMonth = model;

    findTransactionBy();

    if (_transactionCubit.state is! TransactionSuccess) {
      _transactionCubit.selectDate(.fromMillisecondsSinceEpoch(model.startAt));
    }
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

    final data = _transactionRepository
        .deleteTransactionById(id)
        .flatMap(
          (_) => _transactionRepository
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

    final data = _transactionRepository
        .findTransactionBy(
          offset: 0,
          type: type,
          limit: _pageSize,
          endAt: _currentMonth.endAt,
          startAt: _currentMonth.startAt,
        )
        .flatMap(
          (transactions) => _transactionRepository
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

    final data = _transactionRepository.findTransactionBy(
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

  void _listenToTransactionCubit() {
    _transactionSubscription = _transactionCubit.stream.listen((state) {
      if (state is TransactionSuccess && state.transaction == null) {
        findTransactionBy();
      }
    });
  }
}
