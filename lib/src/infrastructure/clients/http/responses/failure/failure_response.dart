final class FailureSourceResponse {
  final String? field;

  const FailureSourceResponse({required this.field});

  factory FailureSourceResponse.fromJson(Map<String, dynamic> json) =>
      FailureSourceResponse(field: json['field'] as String?);
}

final class FailureItemResponse {
  final String? code;
  final String? status;
  final String? message;
  final FailureSourceResponse? source;

  const FailureItemResponse({
    required this.code,
    required this.message,
    this.status,
    this.source,
  });

  factory FailureItemResponse.fromJson(Map<String, dynamic> json) =>
      FailureItemResponse(
        code: json['code'] as String?,
        status: json['status'] as String?,
        message: json['message'] as String?,
        source: json['source'] is Map
            ? FailureSourceResponse.fromJson(
                Map<String, dynamic>.from(json['source'] as Map),
              )
            : null,
      );
}

final class FailureResponse {
  final List<FailureItemResponse> errors;

  const FailureResponse({required this.errors});

  factory FailureResponse.fromJson(Map<String, dynamic> json) =>
      FailureResponse(
        errors: (json['errors'] as List)
            .map(
              (error) =>
                  FailureItemResponse.fromJson(error as Map<String, dynamic>),
            )
            .toList(),
      );
}
