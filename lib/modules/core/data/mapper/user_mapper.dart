import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/core/data/dtos/user_dto.dart';
import 'package:trocado/modules/core/domain/models/user_model.dart';

final class UserMapper extends Mapper<UserDto, UserModel> {
  @override
  UserModel toModel(UserDto data) =>
      UserModel(id: data.id, name: data.name, image: data.image);

  @override
  Either<String, UserDto> fromJson(Map<String, dynamic>? data) =>
      data == null ? Left(defaultError) : Right(_fromJson(data));

  @override
  Map<String, dynamic> toJson(UserDto data) => <String, dynamic>{
    'id': data.id,
    'name': data.name,
    'image': data.image,
  };

  UserDto _fromJson(Map<String, dynamic> data) => UserDto(
    id: data['id']! as String,
    name: data['name']! as String,
    image: data['image']! as String,
  );
}
