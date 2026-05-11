import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/validators_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/repositories/interface_user_repository.dart';

import 'package:trocado/src/presentation/notifiers/user_notifier.dart';

import 'package:trocado/src/presentation/ui/profile/name/notifiers/profile_name_state.dart';
import 'package:trocado/src/presentation/ui/profile/name/notifiers/profile_name_intent.dart';
import 'package:trocado/src/presentation/ui/profile/name/validators/profile_name_form_validator.dart';

part 'profile_name_notifier.g.dart';

@riverpod
final class ProfileNameNotifier extends _$ProfileNameNotifier {
  late IUserRepository _repository;
  late ProfileNameFormValidator _validator;

  @override
  Future<ProfileNameState> build() async {
    _repository = ref.watch(userRepositoryProvider);
    _validator = ref.watch(profileNameFormValidatorProvider);
    final user = await ref.watch(userProvider.future);

    return ProfileNameState(name: user.name);
  }

  void dispatch(ProfileNameIntent intent) => switch (intent) {
    NameChanged(:final value) => state = AsyncData(
      state.value!.copyWith(name: value, clearNameFailure: true),
    ),
    SubmitPressed() => _submit(),
  };

  Future<void> _submit() async {
    final (state: validated, :isValid) = _validator(state.value!);
    state = AsyncData(validated);

    if (!isValid) return;
    if (validated.status == .loading) return;

    state = AsyncData(validated.copyWith(status: .loading));

    final data = await _repository.updateName(name: validated.name);

    data.fold(
      (failure) => state = AsyncData(
        state.value!.copyWith(status: .failure, message: failure.message),
      ),
      (_) {
        ref.invalidate(userProvider);
        state = AsyncData(state.value!.copyWith(status: .success));
      },
    );
  }
}
