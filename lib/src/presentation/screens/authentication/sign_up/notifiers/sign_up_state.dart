import 'package:equatable/equatable.dart';

enum SignUpStatus { initial, loading, success, failure }

final class SignUpState extends Equatable {
  final String email;
  final String password;
  final bool termsAccepted;
  final String message;
  final SignUpStatus status;
  final String? emailFailure;
  final String? passwordFailure;
  final String? termsFailure;

  const SignUpState({
    this.email = '',
    this.password = '',
    this.termsAccepted = false,
    this.message = '',
    this.status = SignUpStatus.initial,
    this.emailFailure,
    this.passwordFailure,
    this.termsFailure,
  });

  SignUpState copyWith({
    String? email,
    String? password,
    bool? termsAccepted,
    String? message,
    SignUpStatus? status,
    String? emailFailure,
    String? passwordFailure,
    String? termsFailure,
    bool clearEmailFailure = false,
    bool clearPasswordFailure = false,
    bool clearTermsFailure = false,
  }) => SignUpState(
    email: email ?? this.email,
    password: password ?? this.password,
    termsAccepted: termsAccepted ?? this.termsAccepted,
    message: message ?? this.message,
    status: status ?? this.status,
    emailFailure: clearEmailFailure ? null : emailFailure ?? this.emailFailure,
    passwordFailure: clearPasswordFailure
        ? null
        : passwordFailure ?? this.passwordFailure,
    termsFailure: clearTermsFailure ? null : termsFailure ?? this.termsFailure,
  );

  @override
  List<Object?> get props => [
    email,
    password,
    termsAccepted,
    message,
    status,
    emailFailure,
    passwordFailure,
    termsFailure,
  ];
}
