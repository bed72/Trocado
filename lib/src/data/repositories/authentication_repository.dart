import 'package:trocado/src/data/extensions/failure_response_extension.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/authentication_model.dart';

import 'package:trocado/src/domain/contracts/repositories/interface_authentication_repository.dart';

import 'package:trocado/src/infrastructure/clients/http/requests/sign_in_request.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_authentication_data_source.dart';

final class AuthenticationRepository implements IAuthenticationRepository {
  final IRemoteAuthenticationDataSource _dataSource;

  AuthenticationRepository({
    required IRemoteAuthenticationDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  Future<Either<Failure, AuthenticationModel>> signIn({
    required String email,
    required String password,
  }) async {
    final data = await _dataSource.signIn(
      parameter: SignInRequest(email: email, password: password),
    );

    return data.either(
      (failure) => failure.toFailure(),
      (success) => success.toModel(),
    );
  }
}
