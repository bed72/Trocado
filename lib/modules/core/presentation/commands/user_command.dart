import 'package:command_it/command_it.dart';

import 'package:trocado/modules/core/data/dtos/user_dto.dart';
import 'package:trocado/modules/core/domain/repositories/interface_user_repository.dart';

final class UserCommand {
  final IUserRepository _repository;

  late final command = Command.createAsync<UserDto?, UserDto?>(
    _call,
    initialValue: null,
  );

  UserCommand({required IUserRepository repository}) : _repository = repository;

  Future<void> ensureInitialized() async {
    await find();
  }

  Future<void> find() async {
    final result = await _repository.find();

    result.fold((_) => command(null), (user) => command(user));
  }

  Future<void> insert(UserDto data) async {
    await _repository.insert(data: data);
    command(data);
  }

  Future<void> update(UserDto data) async {
    await _repository.update(data: data);
    command(data);
  }

  Future<void> delete(UserDto filter) async {
    await _repository.delete(data: filter);
    command(null);
  }

  Future<UserDto?> _call(UserDto? user) async {
    return user;
  }
}
