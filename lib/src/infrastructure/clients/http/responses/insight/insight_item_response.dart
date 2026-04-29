final class InsightItemResponse {
  final String? type;
  final String? severity;
  final String title;
  final String description;
  final Map<String, dynamic> data;

  const InsightItemResponse({
    required this.type,
    required this.title,
    required this.severity,
    required this.description,
    required this.data,
  });

  factory InsightItemResponse.fromJson(Map<String, dynamic> json) =>
      InsightItemResponse(
        type: json['type'] as String?,
        severity: json['severity'] as String?,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        data: (json['data'] as Map<String, dynamic>?) ?? const {},
      );
}
