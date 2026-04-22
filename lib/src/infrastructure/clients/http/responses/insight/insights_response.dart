import 'package:trocado/src/infrastructure/clients/http/responses/insight/insight_item_response.dart';

final class InsightsResponse {
  final List<InsightItemResponse> insights;
  final bool hasEnoughData;
  final String generatedAt;

  const InsightsResponse({
    required this.insights,
    required this.hasEnoughData,
    required this.generatedAt,
  });

  factory InsightsResponse.fromJson(Map<String, dynamic> json) =>
      InsightsResponse(
        insights: (json['insights'] as List)
            .map(
              (item) =>
                  InsightItemResponse.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
        hasEnoughData: json['has_enough_data'] as bool,
        generatedAt: json['generated_at'] as String,
      );
}
