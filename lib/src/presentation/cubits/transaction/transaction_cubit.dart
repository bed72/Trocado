import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/src/domain/models/transaction_model.dart';
import 'package:trocado/src/domain/repositories/interface_money_repository.dart';
import 'package:trocado/src/domain/repositories/interface_transaction_repository.dart';

part 'transaction_state.dart';

final class TransactionCubit extends Cubit<TransactionState> {
  final IMoneyRepository _moneyRepository;
  final ITransactionRepository _transactionRepository;

  TransactionCubit({
    required IMoneyRepository formatter,
    required ITransactionRepository repository,
  }) : _moneyRepository = formatter,
       _transactionRepository = repository,
       super(TransactionIdle());

  double parse(String value) => _moneyRepository.parse(value);
  String format(double value) => _moneyRepository.format(value);

  void clear() {
    emit(TransactionIdle());
  }

  void find(int id) {
    emit(TransactionLoading());

    final data = _transactionRepository.findTransactionById(id);

    data.fold(
      (failure) => emit(TransactionFailure(failure: failure)),
      (transaction) => emit(TransactionSuccess(transaction: transaction)),
    );
  }

  void save(TransactionModel model) {
    emit(TransactionLoading());

    final data = _transactionRepository.saveTransactionByModel(model);

    data.fold(
      (failure) => emit(TransactionFailure(failure: failure)),
      (_) => emit(TransactionSuccess()),
    );
  }

  void delete(int id) {
    emit(TransactionLoading());

    final data = _transactionRepository.deleteTransactionById(id);

    data.fold(
      (failure) => emit(TransactionFailure(failure: failure)),
      (_) => emit(TransactionSuccess()),
    );
  }
}
