import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/domain/failures/failure.dart';

abstract interface class INotificationRepository {
  Future<Either<Failure, void>> revokeToken();
  Future<Either<Failure, void>> registerToken();
}
