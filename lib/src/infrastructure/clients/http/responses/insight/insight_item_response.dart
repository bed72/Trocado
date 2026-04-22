final class InsightItemResponse {
  final String? type;
  final String? severity;
  final String message;
  final Map<String, dynamic> data;

  const InsightItemResponse({
    required this.type,
    required this.severity,
    required this.message,
    required this.data,
  });

  factory InsightItemResponse.fromJson(Map<String, dynamic> json) =>
      InsightItemResponse(
        type: json['type'] as String?,
        severity: json['severity'] as String?,
        message: json['message'] as String? ?? '',
        data: (json['data'] as Map<String, dynamic>?) ?? const {},
      );
}
