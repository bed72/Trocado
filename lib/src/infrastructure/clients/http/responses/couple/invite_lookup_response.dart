import 'package:trocado/src/infrastructure/clients/http/responses/user_response.dart';

final class InviteLookupResponse {
  final int coupleId;
  final UserResponse partner;

  const InviteLookupResponse({required this.coupleId, required this.partner});

  factory InviteLookupResponse.fromJson(Map<String, dynamic> json) =>
      InviteLookupResponse(
        coupleId: json['couple_id'] as int,
        partner: .fromJson(json['partner'] as Map<String, dynamic>),
      );
}
