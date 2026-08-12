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
    required this._userDataSource,
    required this._tokenDataSource,
  });

  @override
  Future<Either<Failure, UserModel>> me() async {
    final response = await _userDataSource.me();

    return response.either(
      (failure) => failure.toFailure(),
      (success) => success.data.toModel(),
    );
  }

  @override
  Future<Either<Failure, void>> delete({required String password}) async {
    final tokens = await _tokenDataSource.get();

    if (tokens.refresh == null) return const Left(UnknownFailure());

    final response = await _userDataSource.delete(
      password: password,
      refresh: tokens.refresh!,
    );

    return response.either((failure) => failure.toFailure(), (_) {});
  }

  @override
  Future<Either<Failure, UserModel>> updateName({required String name}) async {
    final response = await _userDataSource.update(name: name);

    return response.either(
      (failure) => failure.toFailure(),
      (success) => success.data.toModel(),
    );
  }

  @override
  Future<Either<Failure, UserModel>> updatePassword({
    required String newPassword,
    required String currentPassword,
  }) async {
    final response = await _userDataSource.update(
      newPassword: newPassword,
      currentPassword: currentPassword,
    );

    return response.either(
      (failure) => failure.toFailure(),
      (success) => success.data.toModel(),
    );
  }
}
