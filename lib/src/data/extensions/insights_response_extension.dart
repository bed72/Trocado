import 'package:trocado/src/domain/models/insight/insight_model.dart';
import 'package:trocado/src/domain/models/insight/insights_bundle_model.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/insight/insights_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/insight/insight_item_response.dart';

extension InsightItemResponseExtension on InsightItemResponse {
  InsightModel toModel() => InsightModel(
    data: data,
    message: message,
    type: .fromString(type),
    severity: .fromString(severity),
  );
}

extension InsightsResponseExtension on InsightsResponse {
  InsightsBundleModel toModel() => InsightsBundleModel(
    hasEnoughData: hasEnoughData,
    generatedAt: .parse(generatedAt),
    insights: insights.map((item) => item.toModel()).toList(),
  );
}
