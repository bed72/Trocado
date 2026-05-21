import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/models/couple/invite_accept_model.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/couple/invite_accept_response.dart';

extension InviteAcceptResponseExtension on InviteAcceptResponse {
  InviteAcceptModel toModel() => InviteAcceptModel(
    coupleId: coupleId,
    partner: UserModel(
      id: partner.id,
      name: partner.name,
      email: partner.email,
    ),
  );
}
