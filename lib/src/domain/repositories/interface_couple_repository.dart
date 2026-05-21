import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';

import 'package:trocado/src/domain/models/couple/invite_model.dart';
import 'package:trocado/src/domain/models/couple/couple_model.dart';
import 'package:trocado/src/domain/models/couple/invite_accept_model.dart';

abstract interface class ICoupleRepository {
  Future<Either<Failure, void>> dissolve();
  Future<Either<Failure, CoupleModel>> findActive();
  Future<Either<Failure, InviteModel>> createInvite();
  Future<Either<Failure, void>> shareInvite({required String qrData});
  Future<Either<Failure, InviteAcceptModel>> acceptInvite({
    required String code,
  });
}
