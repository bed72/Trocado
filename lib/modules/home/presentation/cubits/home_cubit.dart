import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/home/domain/models/home_model.dart';
import 'package:trocado/modules/home/domain/repositories/interface_home_repository.dart';

part 'home_state.dart';

final class HomeCubit extends Cubit<HomeState> {
  final IHomeRepository _repository;

  HomeCubit({required IHomeRepository repository})
    : _repository = repository,
      super(HomeIdle());

  void clear() {
    emit(HomeIdle());
  }

  TransactionDto toDto(TransactionModel model) => _repository.toDto(model);

  void deleteTransactionBy(int id) {
    final currentState = state;
    if (currentState is! HomeSuccess) return;

    final optimistic = currentState.home.removeTransactionBy(id);
    emit(HomeSuccess(home: optimistic));

    final result = _repository.deleteTransactionBy(id);

    result.fold((failure) => emit(HomeFailure(failure: failure)), (_) {});
  }

  void findTransactionBy({int? startAt, int? endAt, TransactionTypeDto? type}) {
    emit(HomeLoading());

    final balance = _repository.getBalanceBy(endAt: endAt, startAt: startAt);
    final transaction = _repository.findTransactionBy(
      type: type,
      endAt: endAt,
      startAt: startAt,
    );

    transaction.fold((failure) => emit(HomeFailure(failure: failure)), (
      transactions,
    ) {
      balance.fold(
        (failure) => emit(HomeFailure(failure: failure)),
        (balance) => emit(
          HomeSuccess(
            home: HomeModel(balance: balance, transactions: transactions),
          ),
        ),
      );
    });
  }
}
