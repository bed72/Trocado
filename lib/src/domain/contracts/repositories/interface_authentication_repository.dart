import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/authentication_model.dart';

abstract interface class IAuthenticationRepository {
  Future<Either<Failure, AuthenticationModel>> signIn({
    required String email,
    required String password,
  });
}
