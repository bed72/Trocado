import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';

import 'package:trocado/src/data/dtos/transaction_form_dto.dart';

import 'package:trocado/src/presentation/extensions/date_time_extension.dart';

import 'package:trocado/src/domain/models/category_model.dart';
import 'package:trocado/src/domain/models/transaction_model.dart';
import 'package:trocado/src/domain/repositories/interface_money_repository.dart';
import 'package:trocado/src/domain/repositories/interface_transaction_repository.dart';

part 'transaction_state.dart';

final class TransactionCubit extends Cubit<TransactionState> {
  String _buffer = '';

  final IMoneyRepository _moneyRepository;
  final ITransactionRepository _transactionRepository;

  TransactionCubit({
    required IMoneyRepository formatter,
    required ITransactionRepository repository,
  }) : _moneyRepository = formatter,
       _transactionRepository = repository,
       super(TransactionIdle(form: TransactionFormDto.empty()));

  double parse(String value) => _moneyRepository.parse(value);
  String format(double value) => _moneyRepository.format(value);

  void onKeyTap(String key) => switch (key) {
    '✓' => applyAmount(),
    'AC' => clearAmount(),
    'DEL' => deleteAmount(),
    _ => appendAmount(key),
  };

  void applyAmount() {
    emit(_copyStateWith());
  }

  void clearAmount() {
    _buffer = '';
    emit(_copyStateWith(form: state.form.copyWith(amount: 0.0)));
  }

  void deleteAmount() {
    if (_buffer.isEmpty) return;

    _buffer = _buffer.substring(0, _buffer.length - 1);
    _emitAmountFromBuffer();
  }

  void appendAmount(String value) {
    if (value == ',' && _buffer.contains(',')) return;

    _buffer += value;
    _emitAmountFromBuffer();
  }

  void _emitAmountFromBuffer() {
    if (_buffer.isEmpty) {
      emit(_copyStateWith(form: state.form.copyWith(amount: 0.0)));
      return;
    }

    final normalized = _buffer.replaceAll(',', '.');
    final parsed = double.tryParse(normalized) ?? 0.0;

    emit(_copyStateWith(form: state.form.copyWith(amount: parsed)));
  }

  void clearDate() {
    emit(
      _copyStateWith(
        form: state.form.copyWith(date: DateTime.now(), formattedDate: ''),
      ),
    );
  }

  void selectDate(DateTime date) {
    emit(
      _copyStateWith(
        form: state.form.copyWith(date: date, formattedDate: date.format()),
      ),
    );
  }

  void clearCategory() {
    emit(
      _copyStateWith(form: state.form.copyWith(category: CategoryModel.other)),
    );
  }

  void selectCategory(CategoryModel category) {
    emit(_copyStateWith(form: state.form.copyWith(category: category)));
  }

  void clear() {
    _buffer = '';
    emit(TransactionIdle(form: TransactionFormDto.empty()));
  }

  void find(int id) {
    emit(TransactionLoading(form: state.form));

    final data = _transactionRepository.findTransactionById(id);

    data.fold(
      (failure) => emit(TransactionFailure(form: state.form, failure: failure)),
      (transaction) {
        final form = state.form.copyWith(
          amount: transaction.amount,
          category: .fromByString(transaction.category),
          date: .fromMillisecondsSinceEpoch(transaction.date),
          formattedDate: DateTime.fromMillisecondsSinceEpoch(
            transaction.date,
          ).format(),
        );
        _buffer = transaction.amount.toString();

        emit(TransactionSuccess(form: form, transaction: transaction));
      },
    );
  }

  void save(TransactionModel model) {
    emit(TransactionLoading(form: state.form));

    final data = _transactionRepository.saveTransactionByModel(model);

    data.fold(
      (failure) => emit(TransactionFailure(form: state.form, failure: failure)),
      (_) => emit(TransactionSuccess(form: state.form)),
    );
  }

  void delete(int id) {
    emit(TransactionLoading(form: state.form));

    final data = _transactionRepository.deleteTransactionById(id);

    data.fold(
      (failure) => emit(TransactionFailure(form: state.form, failure: failure)),
      (_) => emit(TransactionSuccess(form: state.form)),
    );
  }

  TransactionState _copyStateWith({TransactionFormDto? form}) {
    final newForm = form ?? state.form;

    return switch (state) {
      TransactionIdle() => TransactionIdle(form: newForm),
      TransactionLoading() => TransactionLoading(form: newForm),
      TransactionSuccess(:final transaction) => TransactionSuccess(
        form: newForm,
        transaction: transaction,
      ),
      TransactionFailure(:final failure) => TransactionFailure(
        form: newForm,
        failure: failure,
      ),
    };
  }
}
