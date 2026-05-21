import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/models/couple/invite_lookup_model.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/couple/invite_lookup_response.dart';

extension InviteLookupResponseExtension on InviteLookupResponse {
  InviteLookupModel toModel() => InviteLookupModel(
    coupleId: coupleId,
    partner: UserModel(
      id: partner.id,
      name: partner.name,
      email: partner.email,
    ),
  );
}
