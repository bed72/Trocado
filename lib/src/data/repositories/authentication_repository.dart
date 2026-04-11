import 'package:trocado/src/data/extensions/failure_response_extension.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/authentication_model.dart';

import 'package:trocado/src/domain/contracts/repositories/interface_authentication_repository.dart';

import 'package:trocado/src/infrastructure/clients/http/requests/sign_in_request.dart';
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
      parameter: SignInRequest(email: email, password: password),
    );
    if (data.isLeft) return Left(data.left.toFailure());
    await _tokenDataSource.save(
      access: data.right.access,
      refresh: data.right.refresh,
    );
    return Right(data.right.toModel());
  }

  @override
  Future<AuthenticationModel?> getTokens() async {
    final tokens = await _tokenDataSource.get();
    if (tokens.access == null || tokens.refresh == null) return null;
    return AuthenticationModel(
      access: tokens.access!,
      refresh: tokens.refresh!,
    );
  }

  @override
  Future<void> clearTokens() => _tokenDataSource.clear();
}
