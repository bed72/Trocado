import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/infrastructure/providers/providers.dart';

import 'package:trocado/src/domain/models/category_model.dart';
import 'package:trocado/src/domain/models/transaction_model.dart';

import 'package:trocado/src/domain/repositories/interface_money_repository.dart';
import 'package:trocado/src/domain/repositories/interface_transaction_repository.dart';

import 'package:trocado/src/presentation/extensions/date_time_extension.dart';
import 'package:trocado/src/presentation/notifiers/data/transaction_data.dart';
import 'package:trocado/src/presentation/notifiers/transaction/transaction_state.dart';

part 'transaction_notifier.g.dart';

@riverpod
final class TransactionNotifier extends _$TransactionNotifier {
  String _buffer = '';

  late final IMoneyRepository _moneyRepository;
  late final ITransactionRepository _transactionRepository;

  @override
  TransactionState build() {
    _moneyRepository = ref.read(moneyRepositoryProvider);
    _transactionRepository = ref.read(transactionRepositoryProvider);

    return TransactionIdle(form: .empty());
  }

  double parse(String value) => _moneyRepository.parse(value);
  String format(double value) => _moneyRepository.format(value);

  void onKeyTap(String key) => switch (key) {
    '✓' => applyAmount(),
    'AC' => clearAmount(),
    'DEL' => deleteAmount(),
    _ => appendAmount(key),
  };

  void applyAmount() {
    state = _copyStateWith();
  }

  void clearAmount() {
    _buffer = '';
    state = _copyStateWith(form: state.form.copyWith(amount: 0.0));
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
      state = _copyStateWith(form: state.form.copyWith(amount: 0.0));
      return;
    }

    final normalized = _buffer.replaceAll(',', '.');
    final parsed = double.tryParse(normalized) ?? 0.0;

    state = _copyStateWith(form: state.form.copyWith(amount: parsed));
  }

  void clearDate() {
    state = _copyStateWith(
      form: state.form.copyWith(date: .now(), formattedDate: ''),
    );
  }

  void selectDate(DateTime date) {
    state = _copyStateWith(
      form: state.form.copyWith(date: date, formattedDate: date.format()),
    );
  }

  void clearCategory() {
    state = _copyStateWith(form: state.form.copyWith(category: .other));
  }

  void selectCategory(CategoryModel category) {
    state = _copyStateWith(form: state.form.copyWith(category: category));
  }

  void clear() {
    _buffer = '';
    state = TransactionIdle(form: .empty());
  }

  void find(int id) {
    state = TransactionLoading(form: state.form);

    final data = _transactionRepository.findById(id);

    data.fold(
      (failure) {
        state = TransactionFailure(form: state.form, failure: failure);
      },
      (transaction) {
        final date = DateTime.fromMillisecondsSinceEpoch(transaction.date);

        final form = state.form.copyWith(
          amount: transaction.amount,
          date: date,
          formattedDate: date.format(),
          category: CategoryModel.bills, // TODO
        );

        _buffer = transaction.amount.toString();

        state = TransactionSuccess(form: form, transaction: transaction);
      },
    );
  }

  void save(TransactionModel model) {
    state = TransactionLoading(form: state.form);

    final data = _transactionRepository.upsert(model);

    data.fold(
      (failure) {
        state = TransactionFailure(form: state.form, failure: failure);
      },
      (_) {
        state = TransactionSuccess(form: state.form);
      },
    );
  }

  void delete(int id) {
    state = TransactionLoading(form: state.form);

    final data = _transactionRepository.deleteById(id);

    data.fold(
      (failure) {
        state = TransactionFailure(form: state.form, failure: failure);
      },
      (_) {
        state = TransactionSuccess(form: state.form);
      },
    );
  }

  TransactionState _copyStateWith({TransactionData? form}) {
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
