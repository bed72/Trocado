final class InviteResponse {
  final String code;
  final String qrData;
  final String expiresAt;

  const InviteResponse({
    required this.code,
    required this.qrData,
    required this.expiresAt,
  });

  factory InviteResponse.fromJson(Map<String, dynamic> json) => InviteResponse(
    code: json['code'] as String,
    qrData: json['qr_data'] as String,
    expiresAt: json['expires_at'] as String,
  );
}
