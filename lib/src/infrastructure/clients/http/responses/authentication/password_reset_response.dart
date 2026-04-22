final class PasswordResetResponse {
  final String detail;

  const PasswordResetResponse({required this.detail});

  factory PasswordResetResponse.fromJson(Map<String, dynamic> json) =>
      PasswordResetResponse(detail: json['detail'] as String);
}
