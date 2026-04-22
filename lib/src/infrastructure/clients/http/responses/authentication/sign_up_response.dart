import 'package:trocado/src/infrastructure/clients/http/responses/user_response.dart';

final class SignUpResponse {
  final String access;
  final String refresh;
  final UserResponse user;

  const SignUpResponse({
    required this.access,
    required this.refresh,
    required this.user,
  });

  factory SignUpResponse.fromJson(Map<String, dynamic> json) => SignUpResponse(
    access: json['access'] as String,
    refresh: json['refresh'] as String,
    user: .fromJson(json['user'] as Map<String, dynamic>),
  );
}
