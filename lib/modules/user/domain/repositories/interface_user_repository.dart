import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/user/data/dtos/user_dto.dart';

typedef FindUserRepository = Either<String, UserDto>;

abstract interface class IUserRepository {
  Future<void> delete({required UserDto data});
  Future<void> update({required UserDto data});
  Future<void> insert({required UserDto data});
  Future<FindUserRepository> find({required UserDto data});
}
