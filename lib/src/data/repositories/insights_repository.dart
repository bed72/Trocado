import 'package:trocado/src/data/extensions/failure_response_extension.dart';
import 'package:trocado/src/data/extensions/insights_response_extension.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/enums/scope/financial_scope_enum.dart';
import 'package:trocado/src/domain/models/insight/insights_bundle_model.dart';
import 'package:trocado/src/domain/repositories/interface_insights_repository.dart';

import 'package:trocado/src/infrastructure/datasources/remote/remote_insights_data_source.dart';

final class InsightsRepository implements IInsightsRepository {
  final IRemoteInsightsDataSource _dataSource;

  InsightsRepository({required this._dataSource});

  @override
  Future<Either<Failure, InsightsBundleModel>> findAll({
    required FinancialScopeEnum scope,
  }) async {
    final response = await _dataSource.findAll(scope: scope);

    return response.either(
      (failure) => failure.toFailure(),
      (success) => success.data.toModel(),
    );
  }
}
