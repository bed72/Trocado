import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/repositories/interface_user_repository.dart';

part 'user_notifier.g.dart';

@riverpod
final class UserNotifier extends _$UserNotifier {
  late IUserRepository _repository;

  @override
  Future<UserModel> build() async {
    _repository = ref.watch(userRepositoryProvider);

    return await _getMe();
  }

  Future<UserModel> _getMe() async {
    final data = await _repository.me();

    return data.fold((failure) => throw failure, (user) => user);
  }
}
