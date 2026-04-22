final class RefreshTokenResponse {
  final String access;
  final String refresh;

  const RefreshTokenResponse({required this.access, required this.refresh});

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) =>
      RefreshTokenResponse(
        access: json['access'] as String,
        refresh: json['refresh'] as String,
      );
}
