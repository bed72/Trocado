import 'package:equatable/equatable.dart';

enum ProfilePurgeStatus { initial, loading, success, failure }

final class ProfilePurgeState extends Equatable {
  final String message;
  final String password;
  final bool obscurePassword;
  final String? passwordFailure;
  final ProfilePurgeStatus status;

  const ProfilePurgeState({
    this.password = '',
    this.message = '',
    this.passwordFailure,
    this.status = .initial,
    this.obscurePassword = true,
  });

  ProfilePurgeState copyWith({
    String? message,
    String? password,
    bool? obscurePassword,
    String? passwordFailure,
    ProfilePurgeStatus? status,
    bool clearPasswordFailure = false,
  }) => ProfilePurgeState(
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
