import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/enums/scope/financial_scope_enum.dart';
import 'package:trocado/src/domain/models/insight/insights_bundle_model.dart';

abstract interface class IInsightsRepository {
  Future<Either<Failure, InsightsBundleModel>> findAll({
    required FinancialScopeEnum scope,
  });
}
