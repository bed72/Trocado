import 'package:equatable/equatable.dart';

enum ProfilePasswordStatus { initial, loading, success, failure }

final class ProfilePasswordState extends Equatable {
  final String message;
  final String newPassword;
  final String currentPassword;
  final bool obscureNewPassword;
  final String? newPasswordFailure;
  final bool obscureCurrentPassword;
  final ProfilePasswordStatus status;
  final String? currentPasswordFailure;

  const ProfilePasswordState({
    this.message = '',
    this.newPassword = '',
    this.status = .initial,
    this.newPasswordFailure,
    this.currentPassword = '',
    this.currentPasswordFailure,
    this.obscureNewPassword = true,
    this.obscureCurrentPassword = true,
  });

  ProfilePasswordState copyWith({
    String? message,
    String? newPassword,
    String? currentPassword,
    bool? obscureNewPassword,
    String? newPasswordFailure,
    bool? obscureCurrentPassword,
    ProfilePasswordStatus? status,
    String? currentPasswordFailure,
    bool clearNewPasswordFailure = false,
    bool clearCurrentPasswordFailure = false,
  }) => ProfilePasswordState(
    status: status ?? this.status,
    message: message ?? this.message,
    newPassword: newPassword ?? this.newPassword,
    currentPassword: currentPassword ?? this.currentPassword,
    obscureNewPassword: obscureNewPassword ?? this.obscureNewPassword,
    obscureCurrentPassword:
        obscureCurrentPassword ?? this.obscureCurrentPassword,
    newPasswordFailure: clearNewPasswordFailure
        ? null
        : newPasswordFailure ?? this.newPasswordFailure,
    currentPasswordFailure: clearCurrentPasswordFailure
        ? null
        : currentPasswordFailure ?? this.currentPasswordFailure,
  );

  @override
  List<Object?> get props => [
    status,
    message,
    newPassword,
    currentPassword,
    obscureNewPassword,
    newPasswordFailure,
    obscureCurrentPassword,
    currentPasswordFailure,
  ];
}
