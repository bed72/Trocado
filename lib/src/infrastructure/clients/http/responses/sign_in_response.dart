import 'package:trocado/src/domain/models/authentication_model.dart';

final class SignInResponse {
  final String access;
  final String refresh;

  const SignInResponse({required this.access, required this.refresh});

  factory SignInResponse.fromJson(Map<String, dynamic> json) => SignInResponse(
    access: json['access'] as String,
    refresh: json['refresh'] as String,
  );

  AuthenticationModel toModel() =>
      AuthenticationModel(access: access, refresh: refresh);
}
