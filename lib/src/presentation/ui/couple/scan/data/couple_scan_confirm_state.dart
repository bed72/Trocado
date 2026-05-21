import 'package:equatable/equatable.dart';

enum CoupleScanConfirmStatus { initial, loading, success, failure }

final class CoupleScanConfirmState extends Equatable {
  final String message;
  final CoupleScanConfirmStatus status;

  const CoupleScanConfirmState({this.message = '', this.status = .initial});

  CoupleScanConfirmState copyWith({
    String? message,
    CoupleScanConfirmStatus? status,
  }) => CoupleScanConfirmState(
    status: status ?? this.status,
    message: message ?? this.message,
  );

  @override
  List<Object?> get props => [status, message];
}
