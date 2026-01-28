import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/home/domain/models/home_model.dart';
import 'package:trocado/modules/home/domain/repositories/interface_home_repository.dart';

part 'home_state.dart';

final class HomeCubit extends Cubit<HomeState> {
  final IMoneyFormatter _formatter;
  final IHomeRepository _repository;

  TransactionTypeDto? _selectedType;

  TransactionTypeDto? get selectedType => _selectedType;

  HomeCubit({
    required IMoneyFormatter formatter,
    required IHomeRepository repository,
  }) : _formatter = formatter,
       _repository = repository,
       super(HomeIdle());

  String format(double value) => _formatter.format(value);

  void clear() {
    emit(HomeIdle());
  }

  TransactionDto toTransactionDto(TransactionModel model) =>
      _repository.toTransactionDto(model);

  void filterBalanceBy({int? endAt, int? startAt, TransactionTypeDto? type}) {
    final currentState = state;
    if (currentState is! HomeSuccess) return;

    final nextType = _selectedType == type ? null : type;
    _selectedType = nextType;

    findTransactionBy(startAt: startAt, endAt: endAt, type: nextType);
  }

  void deleteTransactionBy({required int id, int? startAt, int? endAt}) {
    final currentState = state;
    if (currentState is! HomeSuccess) return;

    final optimistic = currentState.home.removeTransactionBy(id);
    emit(HomeSuccess(home: optimistic));

    final data = _repository
        .deleteTransactionBy(id)
        .flatMap(
          (_) => _repository
              .getBalanceBy(startAt: startAt, endAt: endAt)
              .mapRight((balance) => optimistic.copyWith(balance: balance)),
        );

    data.fold(
      (failure) => emit(HomeFailure(failure: failure)),
      (home) => emit(HomeSuccess(home: home)),
    );
  }

  void findTransactionBy({int? startAt, int? endAt, TransactionTypeDto? type}) {
    emit(HomeLoading());

    final data = _repository
        .findTransactionBy(type: type, endAt: endAt, startAt: startAt)
        .flatMap(
          (transactions) => _repository
              .getBalanceBy(startAt: startAt, endAt: endAt)
              .mapRight(
                (balance) =>
                    HomeModel(balance: balance, transactions: transactions),
              ),
        );

    data.fold(
      (failure) => emit(HomeFailure(failure: failure)),
      (home) => emit(HomeSuccess(home: home)),
    );
  }
}
