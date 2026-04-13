import 'package:equatable/equatable.dart';

enum SignInStatus { initial, loading, success, failure }

final class SignInState extends Equatable {
  final String email;
  final String message;
  final String password;
  final SignInStatus status;

  const SignInState({
    this.email = '',
    this.message = '',
    this.password = '',
    this.status = .initial,
  });

  SignInState copyWith({
    String? email,
    String? message,
    String? password,
    SignInStatus? status,
  }) => SignInState(
    email: email ?? this.email,
    status: status ?? this.status,
    message: message ?? this.message,
    password: password ?? this.password,
  );

  @override
  List<Object> get props => [email, password, status, message];
}
