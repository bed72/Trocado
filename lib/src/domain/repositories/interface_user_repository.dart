import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';

abstract interface class IUserRepository {
  Future<Either<Failure, UserModel>> me();

  Future<Either<Failure, void>> delete({required String password});

  Future<Either<Failure, UserModel>> updateName({required String name});

  Future<Either<Failure, UserModel>> updatePassword({
    required String newPassword,
    required String currentPassword,
  });
}
