import 'package:trocado/modules/core/data/dtos/user_dto.dart';
import 'package:trocado/modules/core/presentation/notifiers/notifier.dart';
import 'package:trocado/modules/core/domain/repositories/interface_user_repository.dart';

final class UserNotifier extends Notifier<UserDto?> {
  final IUserRepository _repository;

  UserNotifier({required IUserRepository repository})
    : _repository = repository,
      super(null);

  bool get hasUser => success != null;

  Future<void> ensureInitialized() async {
    find();
  }

  Future<void> find() async {
    await flow(() async {
      final data = await _repository.find();

      return data.fold(
        (failure) => this.failure = failure,
        (success) => this.success = success,
      );
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
