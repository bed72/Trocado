import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/user_response.dart';

extension UserResponseExtension on UserResponse {
  UserModel toModel() => UserModel(id: id, name: name, email: email);
}
