import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/data/extensions/user_response_extension.dart';
import 'package:trocado/src/data/extensions/failure_response_extension.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/repositories/interface_user_repository.dart';

import 'package:trocado/src/infrastructure/datasources/local/local_token_data_source.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_user_data_source.dart';

final class UserRepository implements IUserRepository {
  final IRemoteUserDataSource _userDataSource;
  final ILocalTokenDataSource _tokenDataSource;

  UserRepository({
    required IRemoteUserDataSource userDataSource,
    required ILocalTokenDataSource tokenDataSource,
  }) : _userDataSource = userDataSource,
       _tokenDataSource = tokenDataSource;

  @override
  Future<Either<Failure, UserModel>> me() async {
    final data = await _userDataSource.me();

    return data.either(
      (failure) => failure.toFailure(),
      (response) => response.toModel(),
    );
  }

  @override
  Future<Either<Failure, void>> delete({required String password}) async {
    final tokens = await _tokenDataSource.get();

    if (tokens.refresh == null) return const Left(UnknownFailure());

    final data = await _userDataSource.delete(
      password: password,
      refresh: tokens.refresh!,
    );

    return data.either((failure) => failure.toFailure(), (_) {});
  }
}
