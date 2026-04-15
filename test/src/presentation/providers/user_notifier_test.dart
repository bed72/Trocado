import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/core/either/either.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/presentation/screens/home/notifiers/user_notifier.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/repositories/interface_user_repository.dart';

import '../../../mocks/mocks.dart';

const _user = UserModel(id: 1, email: 'jane@trocado.app', name: 'Jane Doe');

void main() {
  late IUserRepository repository;

  setUp(() {
    repository = MockUserRepository();
  });

  Future<ProviderContainer> makeContainer() async {
    final container = ProviderContainer(
      overrides: [userRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.listen(userProvider, (_, _) {});
    await container.read(userProvider.future);
    return container;
  }

  group('build', () {
    test('returns UserModel on success', () async {
      when(() => repository.me()).thenAnswer((_) async => const Right(_user));

      final container = await makeContainer();

      expect(container.read(userProvider).asData?.value, _user);
    });

    test('returns AsyncError on failure', () async {
      when(
        () => repository.me(),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = ProviderContainer(
        overrides: [userRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      container.listen(userProvider, (_, _) {});
      container.read(userProvider);

      await pumpEventQueue();

      expect(container.read(userProvider).hasError, isTrue);
      expect(container.read(userProvider).error, isA<NetworkFailure>());
    });
  });
}
