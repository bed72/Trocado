import 'package:trocado/src/data/extensions/failure_response_extension.dart';
import 'package:trocado/src/data/extensions/notification_response_extension.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/notification/notifications_page_model.dart';
import 'package:trocado/src/domain/repositories/interface_notification_repository.dart';

import 'package:trocado/src/infrastructure/datasources/remote/remote_notification_data_source.dart';

final class NotificationRepository implements INotificationRepository {
  final IRemoteNotificationDataSource _dataSource;

  NotificationRepository({required IRemoteNotificationDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Stream<void> get onTokenRefreshed => _dataSource.onTokenRefreshed;

  @override
  Future<Either<Failure, void>> deleteAll() async {
    final data = await _dataSource.deleteAll();

    return data.either((failure) => failure.toFailure(), (_) {});
  }

  @override
  Future<Either<Failure, void>> deleteById({required int id}) async {
    final data = await _dataSource.deleteById(id: id);

    return data.either((failure) => failure.toFailure(), (_) {});
  }

  @override
  Future<Either<Failure, void>> registerToken() async {
    final data = await _dataSource.registerToken();

    return data.either((failure) => failure.toFailure(), (_) {});
  }

  @override
  Future<Either<Failure, void>> revokeToken() async {
    final data = await _dataSource.revokeToken();

    return data.either((failure) => failure.toFailure(), (_) {});
  }

  @override
  Future<Either<Failure, NotificationsPageModel>> findAll({
    String? cursor,
  }) async {
    final data = await _dataSource.findAll(cursor: cursor);

    return data.either(
      (failure) => failure.toFailure(),
      (response) => response.toPageModel(),
    );
  }
}
