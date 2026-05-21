import 'package:trocado/src/infrastructure/clients/http/responses/user_response.dart';

final class InviteAcceptResponse {
  final int coupleId;
  final UserResponse partner;

  const InviteAcceptResponse({required this.coupleId, required this.partner});

  factory InviteAcceptResponse.fromJson(Map<String, dynamic> json) =>
      InviteAcceptResponse(
        coupleId: json['couple_id'] as int,
        partner: .fromJson(json['partner'] as Map<String, dynamic>),
      );
}
