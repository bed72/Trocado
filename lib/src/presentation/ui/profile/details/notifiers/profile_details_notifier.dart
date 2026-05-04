import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/repositories/interface_user_repository.dart';

import 'package:trocado/src/presentation/notifiers/user_notifier.dart';

import 'package:trocado/src/presentation/ui/profile/details/notifiers/profile_details_state.dart';
import 'package:trocado/src/presentation/ui/profile/details/notifiers/profile_details_intent.dart';

part 'profile_details_notifier.g.dart';

@riverpod
final class ProfileDetailsNotifier extends _$ProfileDetailsNotifier {
  late IUserRepository _repository;

  @override
  ProfileDetailsState build() {
    _repository = ref.watch(userRepositoryProvider);

    return const ProfileDetailsState();
  }

  void dispatch(ProfileDetailsIntent intent) => switch (intent) {
    DeactivatePressed() => _deactivate(),
  };

  Future<void> _deactivate() async {
    if (state.status == .loading) return;

    state = state.copyWith(status: .loading);

    final data = await _repository.deactivate();

    data.fold(
      (failure) =>
          state = state.copyWith(status: .failure, message: failure.message),
      (_) {
        ref.invalidate(userProvider);
        state = state.copyWith(status: .success);
      },
    );
  }
}
