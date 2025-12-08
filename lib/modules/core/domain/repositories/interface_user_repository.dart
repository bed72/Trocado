import 'package:trocado/modules/core/core.dart';

typedef FindUserRepository = Either<String, UserDto>;

abstract interface class IUserRepository {
  Future<FindUserRepository> find();
  Future<void> delete({required UserDto data});
  Future<bool> update({required UserDto data});
  Future<bool> insert({required UserDto data});
}
