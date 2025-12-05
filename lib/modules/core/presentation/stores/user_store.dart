import 'package:mobx/mobx.dart';

import 'package:trocado/modules/core/data/dtos/user_dto.dart';
import 'package:trocado/modules/core/domain/repositories/interface_user_repository.dart';

part 'user_store.g.dart';

class UserStore = UserStoreBase with _$UserStore;

abstract class UserStoreBase with Store {
  final IUserRepository repository;

  @observable
  UserDto? user;

  UserStoreBase({required this.repository});

  @action
  Future<void> ensureInitialized() => find();

  @action
  Future<void> find() async {
    final result = await repository.find();
    result.fold((_) => user = null, (user) => this.user = user);
  }

  @action
  Future<void> insert(UserDto data) async {
    await repository.insert(data: data);
    user = data;
  }

  @action
  Future<void> update(UserDto data) async {
    await repository.update(data: data);
    user = data;
  }

  @action
  Future<void> delete(UserDto filter) async {
    await repository.delete(data: filter);
    user = null;
  }
}
