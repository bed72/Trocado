import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/ui/profile/password/notifiers/profile_password_intent.dart';
import 'package:trocado/src/presentation/ui/profile/password/notifiers/profile_password_notifier.dart';

void main() {
  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(profilePasswordProvider, (_, _) {});
    return container;
  }

  group('NewPasswordChanged', () {
    test('updates newPassword in state', () {
      final container = makeContainer();

      container
          .read(profilePasswordProvider.notifier)
          .dispatch(const NewPasswordChanged('NewSecure!456'));

      expect(
        container.read(profilePasswordProvider).newPassword,
        'NewSecure!456',
      );
    });

    test('clears newPasswordFailure when password changes', () {
      final container = makeContainer();
      final notifier = container.read(profilePasswordProvider.notifier);

      notifier.dispatch(const SubmitPressed());
      expect(
        container.read(profilePasswordProvider).newPasswordFailure,
        isNotNull,
      );

      notifier.dispatch(const NewPasswordChanged('NewSecure!456'));
      expect(
        container.read(profilePasswordProvider).newPasswordFailure,
        isNull,
      );
    });
  });

  group('ConfirmPasswordChanged', () {
    test('updates confirmPassword in state', () {
      final container = makeContainer();

      container
          .read(profilePasswordProvider.notifier)
          .dispatch(const ConfirmPasswordChanged('NewSecure!456'));

      expect(
        container.read(profilePasswordProvider).confirmPassword,
        'NewSecure!456',
      );
    });

    test('clears confirmPasswordFailure when confirmation changes', () {
      final container = makeContainer();
      final notifier = container.read(profilePasswordProvider.notifier);

      notifier.dispatch(const NewPasswordChanged('NewSecure!456'));
      notifier.dispatch(const ConfirmPasswordChanged('Different!789'));
      notifier.dispatch(const SubmitPressed());
      expect(
        container.read(profilePasswordProvider).confirmPasswordFailure,
        isNotNull,
      );

      notifier.dispatch(const ConfirmPasswordChanged('NewSecure!456'));
      expect(
        container.read(profilePasswordProvider).confirmPasswordFailure,
        isNull,
      );
    });
  });

  group('NewPasswordVisibilityToggled', () {
    test('toggles obscureNewPassword without affecting the other field', () {
      final container = makeContainer();
      final notifier = container.read(profilePasswordProvider.notifier);

      expect(
        container.read(profilePasswordProvider).obscureNewPassword,
        isTrue,
      );
      expect(
        container.read(profilePasswordProvider).obscureConfirmPassword,
        isTrue,
      );

      notifier.dispatch(const NewPasswordVisibilityToggled());

      expect(
        container.read(profilePasswordProvider).obscureNewPassword,
        isFalse,
      );
      expect(
        container.read(profilePasswordProvider).obscureConfirmPassword,
        isTrue,
      );
    });
  });

  group('ConfirmPasswordVisibilityToggled', () {
    test('toggles obscureConfirmPassword without affecting the other field', () {
      final container = makeContainer();
      final notifier = container.read(profilePasswordProvider.notifier);

      notifier.dispatch(const ConfirmPasswordVisibilityToggled());

      expect(
        container.read(profilePasswordProvider).obscureNewPassword,
        isTrue,
      );
      expect(
        container.read(profilePasswordProvider).obscureConfirmPassword,
        isFalse,
      );
    });
  });

  group('SubmitPressed', () {
    test('sets newPasswordFailure when password is empty', () {
      final container = makeContainer();

      container
          .read(profilePasswordProvider.notifier)
          .dispatch(const SubmitPressed());

      expect(
        container.read(profilePasswordProvider).newPasswordFailure,
        isNotNull,
      );
    });

    test('sets confirmPasswordFailure when passwords do not match', () {
      final container = makeContainer();
      final notifier = container.read(profilePasswordProvider.notifier);

      notifier.dispatch(const NewPasswordChanged('NewSecure!456'));
      notifier.dispatch(const ConfirmPasswordChanged('Different!789'));
      notifier.dispatch(const SubmitPressed());

      expect(
        container.read(profilePasswordProvider).confirmPasswordFailure,
        'As senhas não coincidem',
      );
    });

    test('clears all failures when passwords are valid and match', () {
      final container = makeContainer();
      final notifier = container.read(profilePasswordProvider.notifier);

      notifier.dispatch(const NewPasswordChanged('NewSecure!456'));
      notifier.dispatch(const ConfirmPasswordChanged('NewSecure!456'));
      notifier.dispatch(const SubmitPressed());

      final state = container.read(profilePasswordProvider);
      expect(state.newPasswordFailure, isNull);
      expect(state.confirmPasswordFailure, isNull);
    });
  });
}
