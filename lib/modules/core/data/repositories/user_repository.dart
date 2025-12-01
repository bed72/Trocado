import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/core/data/dtos/user_dto.dart';
import 'package:trocado/modules/core/data/mapper/user_mapper.dart';

final class UserRepository implements IUserRepository {
  final UserMapper _mapper;
  final IDatabaseDatasource _datasource;

  UserRepository({
    required UserMapper mapper,
    required IDatabaseDatasource datasource,
  }) : _mapper = mapper,
       _datasource = datasource;

  @override
  Future<void> delete({required UserDto data}) async {
    _datasource.delete(DatabaseConstant.userTableName.name, data.id);
  }

  @override
  Future<void> insert({required UserDto data}) async {
    _datasource.upsert(
      DatabaseConstant.userTableName.name,
      _mapper.toJson(data),
    );
  }

  @override
  Future<void> update({required UserDto data}) async {
    _datasource.upsert(
      DatabaseConstant.userTableName.name,
      _mapper.toJson(data),
    );
  }

  @override
  Future<FindUserRepository> find() async {
    final user = await _datasource.all(DatabaseConstant.userTableName.name);

    return user
        .mapLeft((_) => 'Opss, não encontramos seus dados, tente mais tarde!')
        .flatMap(
          (values) =>
              _mapper.fromJsons(values).mapRight((users) => users.first),
        );
  }
}
