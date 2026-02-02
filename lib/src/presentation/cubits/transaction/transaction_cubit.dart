import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/src/domain/models/transaction_model.dart';
import 'package:trocado/src/domain/repositories/interface_transaction_repository.dart';
import 'package:trocado/src/infrastructure/resources/formatters/money_formatter.dart';

part 'transaction_state.dart';

final class TransactionCubit extends Cubit<TransactionState> {
  final IMoneyFormatter _formatter;
  final ITransactionRepository _repository;

  TransactionCubit({
    required IMoneyFormatter formatter,
    required ITransactionRepository repository,
  }) : _formatter = formatter,
       _repository = repository,
       super(TransactionIdle());

  double parse(String value) => _formatter.parse(value);
  String format(double value) => _formatter.format(value);

  void clear() {
    emit(TransactionIdle());
  }

  void find(int id) {
    emit(TransactionLoading());

    final data = _repository.find(id);

    data.fold(
      (failure) => emit(TransactionFailure(failure: failure)),
      (transaction) => emit(TransactionSuccess(transaction: transaction)),
    );
  }

  void save(TransactionModel model) {
    emit(TransactionLoading());

    final data = _repository.save(model);

    data.fold(
      (failure) => emit(TransactionFailure(failure: failure)),
      (_) => emit(TransactionSuccess()),
    );
  }

  void delete(int id) {
    emit(TransactionLoading());

    final data = _repository.delete(id);

    data.fold(
      (failure) => emit(TransactionFailure(failure: failure)),
      (_) => emit(TransactionSuccess()),
    );
  }
}
