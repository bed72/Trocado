import 'package:equatable/equatable.dart';

enum PasswordResetConfirmStatus { initial, loading, success, failure }

final class PasswordResetConfirmState extends Equatable {
  final String message;
  final String newPassword;
  final String confirmPassword;
  final bool obscureNewPassword;
  final String? newPasswordFailure;
  final bool obscureConfirmPassword;
  final String? confirmPasswordFailure;
  final PasswordResetConfirmStatus status;

  const PasswordResetConfirmState({
    this.message = '',
    this.newPassword = '',
    this.status = .initial,
    this.newPasswordFailure,
    this.confirmPassword = '',
    this.confirmPasswordFailure,
    this.obscureNewPassword = true,
    this.obscureConfirmPassword = true,
  });

  PasswordResetConfirmState copyWith({
    String? message,
    String? newPassword,
    String? confirmPassword,
    bool? obscureNewPassword,
    String? newPasswordFailure,
    bool? obscureConfirmPassword,
    String? confirmPasswordFailure,
    PasswordResetConfirmStatus? status,
    bool clearNewPasswordFailure = false,
    bool clearConfirmPasswordFailure = false,
  }) => PasswordResetConfirmState(
    status: status ?? this.status,
    message: message ?? this.message,
    newPassword: newPassword ?? this.newPassword,
    confirmPassword: confirmPassword ?? this.confirmPassword,
    obscureNewPassword: obscureNewPassword ?? this.obscureNewPassword,
    obscureConfirmPassword:
        obscureConfirmPassword ?? this.obscureConfirmPassword,
    newPasswordFailure: clearNewPasswordFailure
        ? null
        : newPasswordFailure ?? this.newPasswordFailure,
    confirmPasswordFailure: clearConfirmPasswordFailure
        ? null
        : confirmPasswordFailure ?? this.confirmPasswordFailure,
  );

  @override
  List<Object?> get props => [
    status,
    message,
    newPassword,
    confirmPassword,
    newPasswordFailure,
    obscureNewPassword,
    confirmPasswordFailure,
    obscureConfirmPassword,
  ];
}
