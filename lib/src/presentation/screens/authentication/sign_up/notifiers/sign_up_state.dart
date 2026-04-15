import 'package:equatable/equatable.dart';

enum SignUpStatus { initial, loading, success, failure }

final class SignUpState extends Equatable {
  final String email;
  final String message;
  final String password;
  final bool termsAccepted;
  final SignUpStatus status;
  final bool obscurePassword;
  final String? emailFailure;
  final String? termsFailure;
  final String? passwordFailure;

  const SignUpState({
    this.email = '',
    this.emailFailure,
    this.termsFailure,
    this.message = '',
    this.password = '',
    this.passwordFailure,
    this.status = .initial,
    this.termsAccepted = false,
    this.obscurePassword = true,
  });

  SignUpState copyWith({
    String? email,
    String? message,
    String? password,
    bool? termsAccepted,
    String? emailFailure,
    String? termsFailure,
    SignUpStatus? status,
    bool? obscurePassword,
    String? passwordFailure,
    bool clearEmailFailure = false,
    bool clearTermsFailure = false,
    bool clearPasswordFailure = false,
  }) => SignUpState(
    email: email ?? this.email,
    status: status ?? this.status,
    message: message ?? this.message,
    password: password ?? this.password,
    termsAccepted: termsAccepted ?? this.termsAccepted,
    obscurePassword: obscurePassword ?? this.obscurePassword,
    emailFailure: clearEmailFailure ? null : emailFailure ?? this.emailFailure,
    passwordFailure: clearPasswordFailure
        ? null
        : passwordFailure ?? this.passwordFailure,
    termsFailure: clearTermsFailure ? null : termsFailure ?? this.termsFailure,
  );

  @override
  List<Object?> get props => [
    email,
    status,
    message,
    password,
    emailFailure,
    termsFailure,
    termsAccepted,
    obscurePassword,
    passwordFailure,
  ];
}
