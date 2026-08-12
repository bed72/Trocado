import 'package:trocado/src/data/extensions/failure_response_extension.dart';
import 'package:trocado/src/data/extensions/notification_response_extension.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/page_model.dart';
import 'package:trocado/src/domain/models/notification/notification_model.dart';
import 'package:trocado/src/domain/repositories/interface_notification_repository.dart';

import 'package:trocado/src/infrastructure/datasources/remote/remote_notification_data_source.dart';

final class NotificationRepository implements INotificationRepository {
  final IRemoteNotificationDataSource _dataSource;

  NotificationRepository({required this._dataSource});

  @override
  Stream<void> get onTokenRefreshed => _dataSource.onTokenRefreshed;

  @override
  Future<Either<Failure, void>> deleteAll() async {
    final response = await _dataSource.deleteAll();

    return response.either((failure) => failure.toFailure(), (_) {});
  }

  @override
  Future<Either<Failure, void>> deleteById({required int id}) async {
    final response = await _dataSource.deleteById(id: id);

    return response.either((failure) => failure.toFailure(), (_) {});
  }

  @override
  Future<Either<Failure, void>> registerToken() async {
    final response = await _dataSource.registerToken();

    return response.either((failure) => failure.toFailure(), (_) {});
  }

  @override
  Future<Either<Failure, void>> revokeToken() async {
    final response = await _dataSource.revokeToken();

    return response.either((failure) => failure.toFailure(), (_) {});
  }

  @override
  Future<Either<Failure, PageModel<NotificationModel>>> findAll({
    String? cursor,
  }) async {
    final response = await _dataSource.findAll(cursor: cursor);

    return response.either(
      (failure) => failure.toFailure(),
      (success) => success.toPageModel(),
    );
  }
}
