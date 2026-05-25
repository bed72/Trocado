final class HealthResponse {
  final int version;
  final String status;

  HealthResponse({required this.status, required this.version});

  factory HealthResponse.fromJson(Map<String, dynamic> json) => HealthResponse(
    version: json['version'] as int,
    status: json['status'] as String,
  );
}
