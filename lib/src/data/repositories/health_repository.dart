import 'package:trocado/src/data/extensions/failure_response_extension.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/repositories/interface_health_repository.dart';

import 'package:trocado/src/infrastructure/datasources/remote/remote_health_data_source.dart';

final class HealthRepository implements IHealthRepository {
  final IRemoteHealthDataSource _dataSource;

  HealthRepository({required IRemoteHealthDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Either<Failure, bool>> check() async {
    final data = await _dataSource.check();

    return data.either(
      (failure) => failure.toFailure(),
      (response) => response.status == 'ok',
    );
  }
}
