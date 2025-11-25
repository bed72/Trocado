import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/user/data/dtos/user_dto.dart';
import 'package:trocado/modules/user/domain/models/user_model.dart';

final class UserMapper extends Mapper<UserDto, UserModel> {
  @override
  UserModel toModel(UserDto data) =>
      UserModel(name: data.name, email: data.email, password: data.password);

  @override
  Either<String, UserDto> fromJson(Map<String, dynamic>? data) =>
      data == null ? Left(defaultError) : Right(_fromJson(data));

  @override
  Map<String, dynamic> toJson(UserDto data) => <String, dynamic>{
    'id': data.id,
    'name': data.name,
    'email': data.email,
    'password': data.password,
  };

  UserDto _fromJson(Map<String, dynamic> data) => UserDto(
    id: data['id']! as String?,
    name: data['name']! as String,
    email: data['email']! as String,
    password: data['password']! as String,
  );
}
