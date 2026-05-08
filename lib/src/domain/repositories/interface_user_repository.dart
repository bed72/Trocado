import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';

abstract interface class IUserRepository {
  Future<Either<Failure, UserModel>> me();

  Future<Either<Failure, void>> deactivate();

  Future<Either<Failure, void>> purge({
    required String email,
    required String password,
  });
}
