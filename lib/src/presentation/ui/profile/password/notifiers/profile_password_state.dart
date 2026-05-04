import 'package:equatable/equatable.dart';

final class ProfilePasswordState extends Equatable {
  final String newPassword;
  final String confirmPassword;
  final bool obscureNewPassword;
  final bool obscureConfirmPassword;
  final String? newPasswordFailure;
  final String? confirmPasswordFailure;

  const ProfilePasswordState({
    this.newPassword = '',
    this.confirmPassword = '',
    this.obscureNewPassword = true,
    this.obscureConfirmPassword = true,
    this.newPasswordFailure,
    this.confirmPasswordFailure,
  });

  ProfilePasswordState copyWith({
    String? newPassword,
    String? confirmPassword,
    bool? obscureNewPassword,
    bool? obscureConfirmPassword,
    String? newPasswordFailure,
    String? confirmPasswordFailure,
    bool clearNewPasswordFailure = false,
    bool clearConfirmPasswordFailure = false,
  }) => ProfilePasswordState(
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
    newPassword,
    confirmPassword,
    obscureNewPassword,
    obscureConfirmPassword,
    newPasswordFailure,
    confirmPasswordFailure,
  ];
}
