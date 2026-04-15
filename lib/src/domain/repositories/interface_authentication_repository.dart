import 'package:trocado/src/core/either/either.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/sign_up_model.dart';
import 'package:trocado/src/domain/models/authentication_model.dart';

abstract interface class IAuthenticationRepository {
  Future<Either<Failure, AuthenticationModel>> signIn({
    required String email,
    required String password,
  });

  Future<Either<Failure, SignUpModel>> signUp({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> checkSession();

  Future<Either<Failure, void>> requestPasswordReset({required String email});

  Future<Either<Failure, void>> confirmPasswordReset({
    required String uid,
    required String token,
    required String newPassword,
  });
}
