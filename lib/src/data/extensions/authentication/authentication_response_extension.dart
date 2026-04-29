import 'package:trocado/src/domain/models/authentication/authentication_model.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/authentication/authentication_response.dart';

extension AuthenticationResponseExtension on AuthenticationResponse {
  AuthenticationModel toModel() =>
      AuthenticationModel(access: access, refresh: refresh);
}
