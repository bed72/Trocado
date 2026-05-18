import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/notification/notifications_page_model.dart';

abstract interface class INotificationRepository {
  Stream<void> get onTokenRefreshed;
  Future<Either<Failure, void>> deleteAll();
  Future<Either<Failure, void>> revokeToken();
  Future<Either<Failure, void>> registerToken();
  Future<Either<Failure, void>> deleteById({required int id});
  Future<Either<Failure, NotificationsPageModel>> findAll({String? cursor});
}
