import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/insight/insight_type.dart';
import 'package:trocado/src/domain/models/insight/insight_severity.dart';

final class InsightModel extends Equatable {
  final InsightType type;
  final String message;
  final InsightSeverity severity;
  final Map<String, dynamic> data;

  const InsightModel({
    required this.type,
    required this.data,
    required this.message,
    required this.severity,
  });

  InsightModel copyWith({
    String? message,
    InsightType? type,
    InsightSeverity? severity,
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
