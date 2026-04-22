import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/insight/insight_model.dart';

final class InsightsBundleModel extends Equatable {
  final bool hasEnoughData;
  final DateTime generatedAt;
  final List<InsightModel> insights;

  const InsightsBundleModel({
    required this.insights,
    required this.generatedAt,
    required this.hasEnoughData,
  });

  InsightsBundleModel copyWith({
    bool? hasEnoughData,
    DateTime? generatedAt,
    List<InsightModel>? insights,
  }) => InsightsBundleModel(
    insights: insights ?? this.insights,
    generatedAt: generatedAt ?? this.generatedAt,
    hasEnoughData: hasEnoughData ?? this.hasEnoughData,
  );

  @override
  List<Object?> get props => [insights, hasEnoughData, generatedAt];
}
