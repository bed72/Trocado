import 'package:equatable/equatable.dart';

enum PasswordResetConfirmStatus { initial, loading, success, failure }

final class PasswordResetConfirmState extends Equatable {
  final String newPassword;
  final String confirmPassword;
  final String message;
  final PasswordResetConfirmStatus status;
  final String? newPasswordFailure;
  final String? confirmPasswordFailure;

  const PasswordResetConfirmState({
    this.newPassword = '',
    this.confirmPassword = '',
    this.message = '',
    this.status = .initial,
    this.newPasswordFailure,
    this.confirmPasswordFailure,
  });

  PasswordResetConfirmState copyWith({
    String? newPassword,
    String? confirmPassword,
    String? message,
    PasswordResetConfirmStatus? status,
    String? newPasswordFailure,
    String? confirmPasswordFailure,
    bool clearNewPasswordFailure = false,
    bool clearConfirmPasswordFailure = false,
  }) => PasswordResetConfirmState(
    newPassword: newPassword ?? this.newPassword,
    confirmPassword: confirmPassword ?? this.confirmPassword,
    message: message ?? this.message,
    status: status ?? this.status,
    newPasswordFailure: clearNewPasswordFailure
        ? null
        : newPasswordFailure ?? this.newPasswordFailure,
    confirmPasswordFailure: clearConfirmPasswordFailure
        ? null
        : confirmPasswordFailure ?? this.confirmPasswordFailure,
  );

  @override
  List<Object?> get props => [
    newPassword,
    confirmPassword,
    message,
    status,
    newPasswordFailure,
    confirmPasswordFailure,
  ];
}
