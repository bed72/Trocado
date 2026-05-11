import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/repositories/interface_user_repository.dart';

import 'package:trocado/src/presentation/ui/profile/name/notifiers/profile_name_state.dart';
import 'package:trocado/src/presentation/ui/profile/name/notifiers/profile_name_intent.dart';
import 'package:trocado/src/presentation/ui/profile/name/notifiers/profile_name_notifier.dart';

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
    container.listen(profileNameProvider, (_, _) {});
    await container.read(profileNameProvider.future);
    return container;
  }

  group('build', () {
    test('pre-fills name with the current user name', () async {
      final container = await makeContainer();

      expect(
        container.read(profileNameProvider).asData?.value.name,
        'Jane Doe',
      );
    });

    test('starts as AsyncLoading until userProvider resolves', () async {
      final container = ProviderContainer(
        overrides: [userRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      container.listen(profileNameProvider, (_, _) {});

      expect(container.read(profileNameProvider).isLoading, isTrue);
    });
  });

  group('NameChanged', () {
    test('updates name in state', () async {
      final container = await makeContainer();

      container
          .read(profileNameProvider.notifier)
          .dispatch(const NameChanged('Kevin'));

      expect(
        container.read(profileNameProvider).asData?.value.name,
        'Kevin',
      );
    });

    test('clears nameFailure when name changes', () async {
      final container = await makeContainer();
      final notifier = container.read(profileNameProvider.notifier);

      notifier.dispatch(const NameChanged(''));
      notifier.dispatch(const SubmitPressed());

      expect(
        container.read(profileNameProvider).asData?.value.nameFailure,
        isNotNull,
      );

      notifier.dispatch(const NameChanged('Kevin'));

      expect(
        container.read(profileNameProvider).asData?.value.nameFailure,
        isNull,
      );
    });
  });

  group('SubmitPressed', () {
    test(
      'sets nameFailure and does not call repository when name is empty',
      () async {
        final container = await makeContainer();
        final notifier = container.read(profileNameProvider.notifier);

        notifier.dispatch(const NameChanged(''));
        notifier.dispatch(const SubmitPressed());

        expect(
          container.read(profileNameProvider).asData?.value.nameFailure,
          'Nome obrigatório',
        );
        verifyNever(() => repository.updateName(name: any(named: 'name')));
      },
    );

    test('calls repository and reaches success when name is valid', () async {
      when(
        () => repository.updateName(name: any(named: 'name')),
      ).thenAnswer((_) async => const Right(_user));

      final container = await makeContainer();
      final notifier = container.read(profileNameProvider.notifier);

      final statuses = <ProfileNameStatus>[];
      container.listen(profileNameProvider, (_, next) {
        final status = next.asData?.value.status;
        if (status != null) statuses.add(status);
      });

      notifier.dispatch(const NameChanged('Kevin'));
      notifier.dispatch(const SubmitPressed());

      await Future<void>.delayed(Duration.zero);

      verify(() => repository.updateName(name: 'Kevin')).called(1);
      expect(statuses, contains(ProfileNameStatus.loading));
      expect(statuses, contains(ProfileNameStatus.success));
    });

    test('sets status to failure with message when repository fails', () async {
      when(
        () => repository.updateName(name: any(named: 'name')),
      ).thenAnswer(
        (_) async => const Left(ServerFailure()),
      );

      final container = await makeContainer();
      final notifier = container.read(profileNameProvider.notifier);

      notifier.dispatch(const NameChanged('Kevin'));
      notifier.dispatch(const SubmitPressed());

      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(profileNameProvider).asData?.value.status,
        ProfileNameStatus.failure,
      );
      expect(
        container.read(profileNameProvider).asData?.value.message,
        const ServerFailure().message,
      );
    });
  });
}
