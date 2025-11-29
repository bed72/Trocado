import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/core/data/dtos/user_dto.dart';

final class UserNotifier extends Notifier<UserDto?> {
  final IUserRepository _repository;

  UserNotifier({required IUserRepository repository})
    : _repository = repository,
      super(null);

  bool get hasUser => success != null;

  Future<void> find(UserDto data) async {
    await flow(() async {
      final result = await _repository.find(data: data);

      return result.fold((_) => null, (success) => this.success = success);
    });
  }

  Future<void> insert(UserDto data) async {
    await flow(() async {
      await _repository.insert(data: data);
      success = data;
    });
  }

  Future<void> update(UserDto data) async {
    await flow(() async {
      await _repository.update(data: data);
      success = data;
    });
  }

  Future<void> delete(UserDto filter) async {
    await flow(() async {
      await _repository.delete(data: filter);
      success = null;
    });
  }
}
