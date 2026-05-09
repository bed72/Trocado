import 'package:equatable/equatable.dart';

enum ProfileDeleteStatus { initial, loading, success, failure }

final class ProfileDeleteState extends Equatable {
  final String message;
  final String password;
  final bool obscurePassword;
  final String? passwordFailure;
  final ProfileDeleteStatus status;

  const ProfileDeleteState({
    this.password = '',
    this.message = '',
    this.passwordFailure,
    this.status = .initial,
    this.obscurePassword = true,
  });

  ProfileDeleteState copyWith({
    String? message,
    String? password,
    bool? obscurePassword,
    String? passwordFailure,
    ProfileDeleteStatus? status,
    bool clearPasswordFailure = false,
  }) => ProfileDeleteState(
    status: status ?? this.status,
    message: message ?? this.message,
    password: password ?? this.password,
    obscurePassword: obscurePassword ?? this.obscurePassword,
    passwordFailure: clearPasswordFailure
        ? null
        : passwordFailure ?? this.passwordFailure,
  );

  @override
  List<Object?> get props => [
    status,
    message,
    password,
    obscurePassword,
    passwordFailure,
  ];
}
