import 'package:trocado/src/infrastructure/clients/http/responses/user_response.dart';

final class CoupleResponse {
  final int id;
  final String createdAt;
  final UserResponse partner;

  const CoupleResponse({
    required this.id,
    required this.partner,
    required this.createdAt,
  });

  factory CoupleResponse.fromJson(Map<String, dynamic> json) => CoupleResponse(
    id: json['id'] as int,
    createdAt: json['created_at'] as String,
    partner: .fromJson(json['partner'] as Map<String, dynamic>),
  );
}
