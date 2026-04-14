import 'package:trocado/src/core/either/either.dart';

import 'package:trocado/src/data/extensions/failure_response_extension.dart';
import 'package:trocado/src/data/extensions/sign_in_response_extension.dart';
import 'package:trocado/src/data/extensions/sign_up_response_extension.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/sign_up_model.dart';
import 'package:trocado/src/domain/models/authentication_model.dart';

import 'package:trocado/src/domain/repositories/interface_authentication_repository.dart';

import 'package:trocado/src/infrastructure/datasources/local/local_token_data_source.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_authentication_data_source.dart';

final class AuthenticationRepository implements IAuthenticationRepository {
  final ILocalTokenDataSource _tokenDataSource;
  final IRemoteAuthenticationDataSource _authenticationDataSource;

  AuthenticationRepository({
    required ILocalTokenDataSource tokenDataSource,
    required IRemoteAuthenticationDataSource authenticationDataSource,
  }) : _tokenDataSource = tokenDataSource,
       _authenticationDataSource = authenticationDataSource;

  @override
  Future<Either<Failure, AuthenticationModel>> signIn({
    required String email,
    required String password,
  }) async {
    final data = await _authenticationDataSource.signIn(
      email: email,
      password: password,
    );

    if (data.isLeft) return Left(data.left.toFailure());

    await _tokenDataSource.save(
      access: data.right.access,
      refresh: data.right.refresh,
    );

    return Right(data.right.toModel());
  }

  @override
  Future<Either<Failure, SignUpModel>> signUp({
    required String email,
    required String password,
  }) async {
    final name = email.split('@').first;

    final data = await _authenticationDataSource.signUp(
      name: name,
      email: email,
      password: password,
    );

    if (data.isLeft) return Left(data.left.toFailure());

    await _tokenDataSource.save(
      access: data.right.access,
      refresh: data.right.refresh,
    );

    return Right(data.right.toModel());
  }

  @override
  Future<Either<Failure, void>> requestPasswordReset({
    required String email,
  }) async {
    final data = await _authenticationDataSource.requestPasswordReset(
      email: email,
    );
    return data.either((failure) => failure.toFailure(), (_) {});
  }

  @override
  Future<Either<Failure, void>> confirmPasswordReset({
    required String uid,
    required String token,
    required String newPassword,
  }) async {
    final data = await _authenticationDataSource.confirmPasswordReset(
      uid: uid,
      token: token,
      newPassword: newPassword,
    );
    return data.either((failure) => failure.toFailure(), (_) {});
  }
}
