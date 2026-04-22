import 'package:trocado/src/domain/models/authentication/authentication_model.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/authentication/sign_in_response.dart';

extension SignInResponseExtension on SignInResponse {
  AuthenticationModel toModel() =>
      AuthenticationModel(access: access, refresh: refresh);
}
