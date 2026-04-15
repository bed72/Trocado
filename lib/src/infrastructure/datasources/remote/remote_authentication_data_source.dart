import 'package:trocado/src/core/either/either.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';

import 'package:trocado/src/infrastructure/clients/http/endpoint_key.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/sign_in_request.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/sign_up_request.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/password_reset_request.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/password_reset_confirm_request.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/sign_in_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/sign_up_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/password_reset_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/refresh_token_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/password_reset_confirm_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/failure/failure_response.dart';

abstract interface class IRemoteAuthenticationDataSource {
  Future<Either<FailureResponse, SignInResponse>> signIn({
    required String email,
    required String password,
  });

  Future<Either<FailureResponse, SignUpResponse>> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<Either<FailureResponse, void>> verifyToken({required String token});

  Future<Either<FailureResponse, RefreshTokenResponse>> refreshToken({
    required String refresh,
  });

  Future<Either<FailureResponse, PasswordResetResponse>> requestPasswordReset({
    required String email,
  });

  Future<Either<FailureResponse, PasswordResetConfirmResponse>>
  confirmPasswordReset({
    required String uid,
    required String token,
    required String newPassword,
  });
}

final class RemoteAuthenticationDataSource
    implements IRemoteAuthenticationDataSource {
  final IHttpClient _client;

  RemoteAuthenticationDataSource({required IHttpClient client})
    : _client = client;

  @override
  Future<Either<FailureResponse, SignInResponse>> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      parameter: Requests(
        EndpointKey.signIn.path,
        body: SignInRequest(email: email, password: password).toJson(),
      ),
    );

    return response.either(FailureResponse.fromJson, SignInResponse.fromJson);
  }

  @override
  Future<Either<FailureResponse, SignUpResponse>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      parameter: Requests(
        EndpointKey.signUp.path,
        body: SignUpRequest(
          name: name,
          email: email,
          password: password,
        ).toJson(),
      ),
    );

    return response.either(FailureResponse.fromJson, SignUpResponse.fromJson);
  }

  @override
  Future<Either<FailureResponse, void>> verifyToken({
    required String token,
  }) async {
    final response = await _client.post(
      parameter: Requests(EndpointKey.verifyToken.path, body: {'token': token}),
    );

    return response.either(FailureResponse.fromJson, (_) {});
  }

  @override
  Future<Either<FailureResponse, RefreshTokenResponse>> refreshToken({
    required String refresh,
  }) async {
    final response = await _client.post(
      parameter: Requests(
        EndpointKey.refreshToken.path,
        body: {'refresh': refresh},
      ),
    );

    return response.either(
      FailureResponse.fromJson,
      RefreshTokenResponse.fromJson,
    );
  }

  @override
  Future<Either<FailureResponse, PasswordResetResponse>> requestPasswordReset({
    required String email,
  }) async {
    final response = await _client.post(
      parameter: Requests(
        EndpointKey.passwordResetRequest.path,
        body: PasswordResetRequest(email: email).toJson(),
      ),
    );

    return response.either(
      FailureResponse.fromJson,
      PasswordResetResponse.fromJson,
    );
  }

  @override
  Future<Either<FailureResponse, PasswordResetConfirmResponse>>
  confirmPasswordReset({
    required String uid,
    required String token,
    required String newPassword,
  }) async {
    final response = await _client.post(
      parameter: Requests(
        EndpointKey.passwordResetConfirm.path,
        body: PasswordResetConfirmRequest(
          uid: uid,
          token: token,
          newPassword: newPassword,
        ).toJson(),
      ),
    );

    return response.either(
      FailureResponse.fromJson,
      PasswordResetConfirmResponse.fromJson,
    );
  }
}
