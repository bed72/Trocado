import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/me_response.dart';

extension MeResponseExtension on MeResponse {
  UserModel toModel() =>
      UserModel(id: id, name: name, email: email, avatar: avatar);
}
