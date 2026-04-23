import 'package:equatable/equatable.dart';

enum ForgotPasswordStatus { initial, loading, success, failure }

final class ForgotPasswordState extends Equatable {
  final String email;
  final String message;
  final ForgotPasswordStatus status;
  final String? emailFailure;

  const ForgotPasswordState({
    this.email = '',
    this.message = '',
    this.emailFailure,
    this.status = .initial,
  });

  ForgotPasswordState copyWith({
    String? email,
    String? message,
    String? emailFailure,
    ForgotPasswordStatus? status,
    bool clearEmailFailure = false,
  }) => ForgotPasswordState(
    email: email ?? this.email,
    status: status ?? this.status,
    message: message ?? this.message,
    emailFailure: clearEmailFailure ? null : emailFailure ?? this.emailFailure,
  );

  @override
  List<Object?> get props => [email, message, status, emailFailure];
}
