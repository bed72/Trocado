import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/data/extensions/user_response_extension.dart';
import 'package:trocado/src/data/extensions/failure_response_extension.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/repositories/interface_user_repository.dart';

import 'package:trocado/src/infrastructure/datasources/remote/remote_user_data_source.dart';

final class UserRepository implements IUserRepository {
  final IRemoteUserDataSource _userDataSource;

  UserRepository({required IRemoteUserDataSource userDataSource})
    : _userDataSource = userDataSource;

  @override
  Future<Either<Failure, UserModel>> me() async {
    final data = await _userDataSource.me();

    return data.either(
      (failure) => failure.toFailure(),
      (response) => response.toModel(),
    );
  }

  @override
  Future<Either<Failure, void>> purge({
    required String email,
    required String password,
  }) async {
    final data = await _userDataSource.purge(email: email, password: password);

    return data.either((failure) => failure.toFailure(), (_) {});
  }
}
