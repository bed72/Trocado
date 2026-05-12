import 'package:trocado/src/data/extensions/failure_response_extension.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/repositories/interface_notification_repository.dart';

import 'package:trocado/src/infrastructure/datasources/remote/remote_notification_data_source.dart';

final class NotificationRepository implements INotificationRepository {
  final IRemoteNotificationDataSource _dataSource;

  NotificationRepository({required IRemoteNotificationDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Either<Failure, void>> registerToken() async {
    final data = await _dataSource.registerToken();

    return data.either((failure) => failure.toFailure(), (_) {});
  }
}
