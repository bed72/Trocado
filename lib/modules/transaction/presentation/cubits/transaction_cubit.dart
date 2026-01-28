import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/transaction/data/dtos/transaction_dto.dart';

import 'package:trocado/modules/transaction/domain/models/transaction_model.dart';
import 'package:trocado/modules/transaction/domain/repositories/interface_transaction_repository.dart';

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

    final date = _repository.find(id);

    date.fold(
      (failure) => emit(TransactionFailure(failure: failure)),
      (transaction) => emit(TransactionSuccess(transaction: transaction)),
    );
  }

  void save(TransactionDto dto) {
    emit(TransactionLoading());

    final date = _repository.save(dto);

    date.fold(
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
