import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/enums/insight/insight_type_enum.dart';
import 'package:trocado/src/domain/enums/insight/insight_severity_enum.dart';

final class InsightModel extends Equatable {
  final String title;
  final String description;
  final InsightTypeEnum type;
  final Map<String, dynamic> data;
  final InsightSeverityEnum severity;

  const InsightModel({
    required this.type,
    required this.data,
    required this.title,
    required this.severity,
    required this.description,
  });

  InsightModel copyWith({
    String? title,
    String? description,
    InsightTypeEnum? type,
    Map<String, dynamic>? data,
    InsightSeverityEnum? severity,
  }) => InsightModel(
    type: type ?? this.type,
    data: data ?? this.data,
    title: title ?? this.title,
    severity: severity ?? this.severity,
    description: description ?? this.description,
  );

  @override
  List<Object?> get props => [type, data, severity, title, description];
}
