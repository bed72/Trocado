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

  void delete(int id) {
    final currentState = state;
    if (currentState is! HomeSuccess) return;

    final optimistic = currentState.home.removeBy(id);
    emit(HomeSuccess(home: optimistic));

    final result = _repository.delete(id);

    result.fold((failure) => emit(HomeFailure(failure: failure)), (_) {});
  }

  void findByPeriod({int? startAt, int? endAt, TransactionTypeDto? type}) {
    emit(HomeLoading());

    final data = _repository.findByPeriod(
      type: type,
      endAt: endAt,
      startAt: startAt,
    );

    data.fold(
      (failure) => emit(HomeFailure(failure: failure)),
      (transactions) =>
          emit(HomeSuccess(home: HomeModel(transactions: transactions))),
    );
  }
}
