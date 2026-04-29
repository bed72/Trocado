final class AuthenticationResponse {
  final String access;
  final String refresh;

  const AuthenticationResponse({required this.access, required this.refresh});

  factory AuthenticationResponse.fromJson(Map<String, dynamic> json) =>
      AuthenticationResponse(
        access: json['access'] as String,
        refresh: json['refresh'] as String,
      );
}
