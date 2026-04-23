import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/enums/insight/insight_type_enum.dart';
import 'package:trocado/src/domain/enums/insight/insight_severity_enum.dart';

final class InsightModel extends Equatable {
  final InsightTypeEnum type;
  final String message;
  final InsightSeverityEnum severity;
  final Map<String, dynamic> data;

  const InsightModel({
    required this.type,
    required this.data,
    required this.message,
    required this.severity,
  });

  InsightModel copyWith({
    String? message,
    InsightTypeEnum? type,
    InsightSeverityEnum? severity,
    Map<String, dynamic>? data,
  }) => InsightModel(
    type: type ?? this.type,
    data: data ?? this.data,
    message: message ?? this.message,
    severity: severity ?? this.severity,
  );

  @override
  List<Object?> get props => [type, data, severity, message];
}
