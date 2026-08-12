import 'package:trocado/src/data/extensions/failure_response_extension.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/repositories/interface_health_repository.dart';

import 'package:trocado/src/infrastructure/datasources/remote/remote_health_data_source.dart';

final class HealthRepository implements IHealthRepository {
  final IRemoteHealthDataSource _dataSource;

  HealthRepository({required this._dataSource});

  @override
  Future<Either<Failure, bool>> check() async {
    final response = await _dataSource.check();

    return response.either(
      (failure) => failure.toFailure(),
      (success) => success.data.status == 'ok',
    );
  }
}
