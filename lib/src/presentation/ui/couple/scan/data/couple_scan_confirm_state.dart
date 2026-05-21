import 'package:equatable/equatable.dart';

enum CoupleScanConfirmStatus { initial, loading, success, failure }

final class CoupleScanConfirmState extends Equatable {
  final String message;
  final String partnerName;
  final CoupleScanConfirmStatus status;

  const CoupleScanConfirmState({
    this.message = '',
    this.partnerName = '',
    this.status = .initial,
  });

  CoupleScanConfirmState copyWith({
    String? message,
    String? partnerName,
    CoupleScanConfirmStatus? status,
  }) => CoupleScanConfirmState(
    status: status ?? this.status,
    message: message ?? this.message,
    partnerName: partnerName ?? this.partnerName,
  );

  @override
  List<Object?> get props => [status, message, partnerName];
}
