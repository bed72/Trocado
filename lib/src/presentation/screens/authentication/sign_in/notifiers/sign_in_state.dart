import 'package:equatable/equatable.dart';

enum SignInStatus { initial, loading, success, failure }

final class SignInState extends Equatable {
  final String email;
  final String message;
  final String password;
  final SignInStatus status;
  final String? emailFailure;
  final String? passwordFailure;

  const SignInState({
    this.email = '',
    this.message = '',
    this.password = '',
    this.status = .initial,
    this.emailFailure,
    this.passwordFailure,
  });

  SignInState copyWith({
    String? email,
    String? message,
    String? password,
    SignInStatus? status,
    String? emailFailure,
    String? passwordFailure,
    bool clearEmailFailure = false,
    bool clearPasswordFailure = false,
  }) => SignInState(
    email: email ?? this.email,
    status: status ?? this.status,
    message: message ?? this.message,
    password: password ?? this.password,
    emailFailure: clearEmailFailure ? null : emailFailure ?? this.emailFailure,
    passwordFailure: clearPasswordFailure
        ? null
        : passwordFailure ?? this.passwordFailure,
  );

  @override
  List<Object?> get props => [
    email,
    status,
    message,
    password,
    emailFailure,
    passwordFailure,
  ];
}
