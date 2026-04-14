import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/models/sign_up_model.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/sign_up_response.dart';

extension SignUpResponseExtension on SignUpResponse {
  SignUpModel toModel() => SignUpModel(
    access: access,
    refresh: refresh,
    user: UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      avatar: user.avatar,
    ),
  );
}
