import 'package:trocado/src/domain/models/couple/invite_model.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/couple/invite_response.dart';

extension InviteResponseExtension on InviteResponse {
  InviteModel toModel() => InviteModel(
    code: code,
    qrData: qrData,
    expiresAt: DateTime.parse(expiresAt).millisecondsSinceEpoch,
  );
}
