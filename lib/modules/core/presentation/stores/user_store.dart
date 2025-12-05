import 'package:flutter_solidart/flutter_solidart.dart';

import 'package:trocado/modules/core/data/dtos/user_dto.dart';
import 'package:trocado/modules/core/domain/repositories/interface_user_repository.dart';

final class UserStore {
  final IUserRepository _repository;

  final resource = Signal<UserDto?>(null);

  late final insert = Resource(_find, source: resource);

  UserStore({required IUserRepository repository}) : _repository = repository;

  Future<UserDto?> _find() async {
    final data = await _repository.find();

    return data.fold((_) => null, (success) => success);
  }

  // Future<void> _insert(UserDto data) async {
  //   await _repository.insert(data: data);
  //   resource.value = data;
  // }

  // Future<void> _update(UserDto data) async {
  //   await _repository.update(data: data);
  //   resource.value = data;
  // }

  // Future<void> _delete(UserDto filter) async {
  //   resource.value = UserDto.empty();
  //   await _repository.delete(data: filter);
  // }
}
