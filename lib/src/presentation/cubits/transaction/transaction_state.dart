part of 'transaction_cubit.dart';

@immutable
sealed class TransactionState extends Equatable {
  final TransactionFormDto form;

  const TransactionState({required this.form});

  @override
  List<Object> get props => [form];
}

final class TransactionIdle extends TransactionState {
  const TransactionIdle({required super.form});
}

final class TransactionLoading extends TransactionState {
  const TransactionLoading({required super.form});
}

final class TransactionSuccess extends TransactionState {
  final TransactionModel? transaction;

  const TransactionSuccess({required super.form, this.transaction});

  @override
  List<Object> get props => [form, transaction ?? []];
}

final class TransactionFailure extends TransactionState {
  final String failure;

  const TransactionFailure({required super.form, required this.failure});

  @override
  List<Object> get props => [form, failure];
}
