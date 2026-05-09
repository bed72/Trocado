import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/validators_provider.dart';

import 'package:trocado/src/presentation/notifiers/user_notifier.dart';

import 'package:trocado/src/presentation/ui/profile/name/notifiers/profile_name_state.dart';
import 'package:trocado/src/presentation/ui/profile/name/notifiers/profile_name_intent.dart';
import 'package:trocado/src/presentation/ui/profile/name/validators/profile_name_form_validator.dart';

part 'profile_name_notifier.g.dart';

@riverpod
final class ProfileNameNotifier extends _$ProfileNameNotifier {
  late ProfileNameFormValidator _validator;

  @override
  Future<ProfileNameState> build() async {
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

  void _submit() {
    final (:state, :isValid) = _validator(this.state.value!);
    this.state = AsyncData(state);

    if (!isValid) return;
    // TODO Parte 6: chamar repository.updateName(name: this.state.value!.name)
  }
}
