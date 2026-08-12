import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/page_model.dart';
import 'package:trocado/src/domain/models/notification/notification_model.dart';

abstract interface class INotificationRepository {
  Stream<void> get onTokenRefreshed;
  Future<Either<Failure, void>> deleteAll();
  Future<Either<Failure, void>> revokeToken();
  Future<Either<Failure, void>> registerToken();
  Future<Either<Failure, void>> deleteById({required int id});
  Future<Either<Failure, PageModel<NotificationModel>>> findAll({
    String? cursor,
  });
}
