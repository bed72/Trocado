part of 'transaction_cubit.dart';

@immutable
sealed class TransactionState extends Equatable {
  const TransactionState();
}

final class TransactionIdle extends TransactionState {
  const TransactionIdle();

  @override
  List<Object> get props => [];
}

final class TransactionLoading extends TransactionState {
  const TransactionLoading();

  @override
  List<Object> get props => [];
}

final class TransactionSuccess extends TransactionState {
  final TransactionModel? transaction;

  const TransactionSuccess({this.transaction});

  @override
  List<Object?> get props => [transaction];
}

final class TransactionFailure extends TransactionState {
  final String failure;

  const TransactionFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}
