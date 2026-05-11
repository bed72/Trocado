import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/repositories/interface_user_repository.dart';

import 'package:trocado/src/presentation/ui/profile/password/notifiers/profile_password_state.dart';
import 'package:trocado/src/presentation/ui/profile/password/notifiers/profile_password_intent.dart';
import 'package:trocado/src/presentation/ui/profile/password/notifiers/profile_password_notifier.dart';

import '../../../../../mocks/mocks.dart';

const _user = UserModel(id: 1, email: 'jane@trocado.app', name: 'Jane Doe');

void main() {
  late IUserRepository repository;

  setUp(() {
    repository = MockUserRepository();
    when(() => repository.me()).thenAnswer((_) async => const Right(_user));
  });

  Future<ProviderContainer> makeContainer() async {
    final container = ProviderContainer(
      overrides: [userRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.listen(profilePasswordProvider, (_, _) {});
    await container.read(profilePasswordProvider.future);
    return container;
  }

  group('CurrentPasswordChanged', () {
    test('updates currentPassword in state', () async {
      final container = await makeContainer();

      container
          .read(profilePasswordProvider.notifier)
          .dispatch(const CurrentPasswordChanged('OldPassword!123'));

      expect(
        container.read(profilePasswordProvider).asData?.value.currentPassword,
        'OldPassword!123',
      );
    });

    test('clears currentPasswordFailure when current password changes', () async {
      final container = await makeContainer();
      final notifier = container.read(profilePasswordProvider.notifier);

      notifier.dispatch(const SubmitPressed());
      expect(
        container
            .read(profilePasswordProvider)
            .asData
            ?.value
            .currentPasswordFailure,
        isNotNull,
      );

      notifier.dispatch(const CurrentPasswordChanged('OldPassword!123'));

      expect(
        container
            .read(profilePasswordProvider)
            .asData
            ?.value
            .currentPasswordFailure,
        isNull,
      );
    });
  });

  group('NewPasswordChanged', () {
    test('updates newPassword in state', () async {
      final container = await makeContainer();

      container
          .read(profilePasswordProvider.notifier)
          .dispatch(const NewPasswordChanged('NewSecure!456'));

      expect(
        container.read(profilePasswordProvider).asData?.value.newPassword,
        'NewSecure!456',
      );
    });

    test('clears newPasswordFailure when new password changes', () async {
      final container = await makeContainer();
      final notifier = container.read(profilePasswordProvider.notifier);

      notifier.dispatch(const SubmitPressed());
      expect(
        container
            .read(profilePasswordProvider)
            .asData
            ?.value
            .newPasswordFailure,
        isNotNull,
      );

      notifier.dispatch(const NewPasswordChanged('NewSecure!456'));

      expect(
        container
            .read(profilePasswordProvider)
            .asData
            ?.value
            .newPasswordFailure,
        isNull,
      );
    });
  });

  group('CurrentPasswordVisibilityToggled', () {
    test(
      'toggles obscureCurrentPassword without affecting the other field',
      () async {
        final container = await makeContainer();
        final notifier = container.read(profilePasswordProvider.notifier);

        expect(
          container
              .read(profilePasswordProvider)
              .asData
              ?.value
              .obscureCurrentPassword,
          isTrue,
        );
        expect(
          container
              .read(profilePasswordProvider)
              .asData
              ?.value
              .obscureNewPassword,
          isTrue,
        );

        notifier.dispatch(const CurrentPasswordVisibilityToggled());

        expect(
          container
              .read(profilePasswordProvider)
              .asData
              ?.value
              .obscureCurrentPassword,
          isFalse,
        );
        expect(
          container
              .read(profilePasswordProvider)
              .asData
              ?.value
              .obscureNewPassword,
          isTrue,
        );
      },
    );
  });

  group('NewPasswordVisibilityToggled', () {
    test(
      'toggles obscureNewPassword without affecting the other field',
      () async {
        final container = await makeContainer();
        final notifier = container.read(profilePasswordProvider.notifier);

        notifier.dispatch(const NewPasswordVisibilityToggled());

        expect(
          container
              .read(profilePasswordProvider)
              .asData
              ?.value
              .obscureNewPassword,
          isFalse,
        );
        expect(
          container
              .read(profilePasswordProvider)
              .asData
              ?.value
              .obscureCurrentPassword,
          isTrue,
        );
      },
    );
  });

  group('SubmitPressed', () {
    test('sets currentPasswordFailure when current password is empty', () async {
      final container = await makeContainer();
      final notifier = container.read(profilePasswordProvider.notifier);

      notifier.dispatch(const NewPasswordChanged('NewSecure!456'));
      notifier.dispatch(const SubmitPressed());

      expect(
        container
            .read(profilePasswordProvider)
            .asData
            ?.value
            .currentPasswordFailure,
        isNotNull,
      );
      verifyNever(
        () => repository.updatePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        ),
      );
    });

    test('sets newPasswordFailure when new password is empty', () async {
      final container = await makeContainer();
      final notifier = container.read(profilePasswordProvider.notifier);

      notifier.dispatch(const CurrentPasswordChanged('OldPassword!123'));
      notifier.dispatch(const SubmitPressed());

      expect(
        container
            .read(profilePasswordProvider)
            .asData
            ?.value
            .newPasswordFailure,
        isNotNull,
      );
      verifyNever(
        () => repository.updatePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        ),
      );
    });

    test(
      'calls repository and reaches success when both passwords are valid',
      () async {
        when(
          () => repository.updatePassword(
            currentPassword: any(named: 'currentPassword'),
            newPassword: any(named: 'newPassword'),
          ),
        ).thenAnswer((_) async => const Right(_user));

        final container = await makeContainer();
        final notifier = container.read(profilePasswordProvider.notifier);

        notifier.dispatch(const CurrentPasswordChanged('OldPassword!123'));
        notifier.dispatch(const NewPasswordChanged('NewSecure!456'));
        notifier.dispatch(const SubmitPressed());

        await Future<void>.delayed(Duration.zero);

        verify(
          () => repository.updatePassword(
            currentPassword: 'OldPassword!123',
            newPassword: 'NewSecure!456',
          ),
        ).called(1);
        expect(
          container.read(profilePasswordProvider).asData?.value.status,
          ProfilePasswordStatus.success,
        );
      },
    );

    test(
      'sets status to failure with message when repository fails',
      () async {
        when(
          () => repository.updatePassword(
            currentPassword: any(named: 'currentPassword'),
            newPassword: any(named: 'newPassword'),
          ),
        ).thenAnswer(
          (_) async => const Left(ValidationFailure('Senha incorreta.')),
        );

        final container = await makeContainer();
        final notifier = container.read(profilePasswordProvider.notifier);

        notifier.dispatch(const CurrentPasswordChanged('OldPassword!123'));
        notifier.dispatch(const NewPasswordChanged('NewSecure!456'));
        notifier.dispatch(const SubmitPressed());

        await Future<void>.delayed(Duration.zero);

        expect(
          container.read(profilePasswordProvider).asData?.value.status,
          ProfilePasswordStatus.failure,
        );
        expect(
          container.read(profilePasswordProvider).asData?.value.message,
          'Senha incorreta.',
        );
      },
    );
  });
}
