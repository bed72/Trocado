import 'package:equatable/equatable.dart';

enum CoupleDissolveStatus { initial, loading, success, failure }

final class CoupleDissolveState extends Equatable {
  final String message;
  final String partnerName;
  final String currentUserName;
  final CoupleDissolveStatus status;

  const CoupleDissolveState({
    this.message = '',
    this.partnerName = '',
    this.status = .initial,
    this.currentUserName = '',
  });

  CoupleDissolveState copyWith({
    String? message,
    String? partnerName,
    String? currentUserName,
    CoupleDissolveStatus? status,
  }) => CoupleDissolveState(
    status: status ?? this.status,
    message: message ?? this.message,
    partnerName: partnerName ?? this.partnerName,
    currentUserName: currentUserName ?? this.currentUserName,
  );

  @override
  List<Object?> get props => [status, message, partnerName, currentUserName];
}
