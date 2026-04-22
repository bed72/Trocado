import 'package:trocado/src/core/either/either.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/insights/insights_bundle_model.dart';
import 'package:trocado/src/domain/repositories/interface_insights_repository.dart';

import 'package:trocado/src/data/extensions/failure_response_extension.dart';
import 'package:trocado/src/data/extensions/insights_response_extension.dart';

import 'package:trocado/src/infrastructure/datasources/remote/remote_insights_data_source.dart';

final class InsightsRepository implements IInsightsRepository {
  final IRemoteInsightsDataSource _dataSource;

  InsightsRepository({required IRemoteInsightsDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Either<Failure, InsightsBundleModel>> findAll() async {
    final data = await _dataSource.findAll();

    return data.either(
      (failure) => failure.toFailure(),
      (response) => response.toModel(),
    );
  }
}
