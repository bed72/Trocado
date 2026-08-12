import 'dart:async';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/authentication/authentication_model.dart';
import 'package:trocado/src/domain/repositories/interface_notification_repository.dart';
import 'package:trocado/src/domain/repositories/interface_authentication_repository.dart';

import 'package:trocado/src/data/extensions/failure_response_extension.dart';
import 'package:trocado/src/data/extensions/authentication/authentication_response_extension.dart';

import 'package:trocado/src/infrastructure/datasources/local/local_token_data_source.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_authentication_data_source.dart';

final class AuthenticationRepository implements IAuthenticationRepository {
  final ILocalTokenDataSource _tokenDataSource;
  final INotificationRepository _notificationRepository;
  final IRemoteAuthenticationDataSource _authenticationDataSource;

  AuthenticationRepository({
    required this._tokenDataSource,
    required this._notificationRepository,
    required this._authenticationDataSource,
  });

  @override
  Future<Either<Failure, void>> logout() async {
    unawaited(_notificationRepository.revokeToken());

    final tokens = await _tokenDataSource.get();

    if (tokens.refresh == null) {
      await _tokenDataSource.clear();
      return const Right(null);
    }

    final response = await _authenticationDataSource.logout(
      refresh: tokens.refresh!,
    );

    if (response.isLeft) return Left(response.left.toFailure());

    await _tokenDataSource.clear();
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> requestPasswordReset({
    required String email,
  }) async {
    final response = await _authenticationDataSource.requestPasswordReset(
      email: email,
    );

    return response.either((failure) => failure.toFailure(), (_) {});
  }

  @override
  Future<Either<Failure, void>> confirmPasswordReset({
    required String uid,
    required String token,
    required String newPassword,
  }) async {
    final reponse = await _authenticationDataSource.confirmPasswordReset(
      uid: uid,
      token: token,
      newPassword: newPassword,
    );

    return reponse.either((failure) => failure.toFailure(), (_) {});
  }

  @override
  Future<Either<Failure, AuthenticationModel>> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _authenticationDataSource.signIn(
      email: email,
      password: password,
    );

    if (response.isLeft) return Left(response.left.toFailure());

    await _tokenDataSource.save(
      access: response.right.data.access,
      refresh: response.right.data.refresh,
    );

    return Right(response.right.data.toModel());
  }

  @override
  Future<Either<Failure, AuthenticationModel>> signUp({
    required String email,
    required String password,
  }) async {
    final response = await _authenticationDataSource.signUp(
      email: email,
      password: password,
      name: email.split('@').first,
    );

    if (response.isLeft) return Left(response.left.toFailure());

    await _tokenDataSource.save(
      access: response.right.data.access,
      refresh: response.right.data.refresh,
    );

    return Right(response.right.data.toModel());
  }

  @override
  Future<Either<Failure, void>> checkSession() async {
    final tokens = await _tokenDataSource.get();
    if (tokens.access == null) return Left(const UnknownFailure());

    final verify = await _authenticationDataSource.verifyToken(
      token: tokens.access!,
    );
    if (verify.isRight) return const Right(null);
    if (tokens.refresh == null) return Left(const UnknownFailure());

    final refresh = await _authenticationDataSource.refreshToken(
      refresh: tokens.refresh!,
    );
    if (refresh.isLeft) {
      await _tokenDataSource.clear();
      return Left(refresh.left.toFailure());
    }

    await _tokenDataSource.save(
      access: refresh.right.data.access,
      refresh: refresh.right.data.refresh,
    );

    return const Right(null);
  }
}
