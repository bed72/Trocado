import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/domain/failures/failure.dart';

abstract interface class IHealthRepository {
  Future<Either<Failure, bool>> check();
}
