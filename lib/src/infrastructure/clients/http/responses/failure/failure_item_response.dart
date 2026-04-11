final class FailureItemResponse {
  final String code;
  final String field;
  final String message;

  const FailureItemResponse({
    required this.code,
    required this.field,
    required this.message,
  });

  factory FailureItemResponse.fromJson(Map<String, dynamic> json) =>
      FailureItemResponse(
        code: json['code'] as String,
        field: json['field'] as String,
        message: json['message'] as String,
      );
}
