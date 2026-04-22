final class PasswordResetConfirmResponse {
  final String detail;

  const PasswordResetConfirmResponse({required this.detail});

  factory PasswordResetConfirmResponse.fromJson(Map<String, dynamic> json) =>
      PasswordResetConfirmResponse(detail: json['detail'] as String);
}
