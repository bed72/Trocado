import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/models/couple/couple_model.dart';
import 'package:trocado/src/domain/repositories/interface_user_repository.dart';
import 'package:trocado/src/domain/repositories/interface_couple_repository.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/presentation/ui/couple/dissolve/notifiers/couple_dissolve_state.dart';
import 'package:trocado/src/presentation/ui/couple/dissolve/notifiers/couple_dissolve_intent.dart';
import 'package:trocado/src/presentation/ui/couple/dissolve/notifiers/couple_dissolve_notifier.dart';

import '../../../mocks/mocks.dart';

const _user = UserModel(id: 1, email: 'gabriel@trocado.app', name: 'Gabriel');

final _couple = CoupleModel(
  id: 7,
  createdAt: DateTime(2026, 1, 12).millisecondsSinceEpoch,
  partner: const UserModel(id: 2, name: 'Marina', email: 'marina@trocado.app'),
);

void main() {
  late IUserRepository userRepository;
  late ICoupleRepository coupleRepository;

  setUp(() {
    userRepository = MockUserRepository();
    coupleRepository = MockCoupleRepository();

    when(() => userRepository.me()).thenAnswer((_) async => const Right(_user));
    when(
      () => coupleRepository.findActive(),
    ).thenAnswer((_) async => Right(_couple));
  });

  Future<ProviderContainer> makeContainer() async {
    final container = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWithValue(userRepository),
        coupleRepositoryProvider.overrideWithValue(coupleRepository),
      ],
    );
    addTearDown(container.dispose);
    container.listen(coupleDissolveProvider, (_, _) {});
    await container.read(coupleDissolveProvider.future);
    return container;
  }

  group('build', () {
    test('returns initial state with user and partner names', () async {
      final container = await makeContainer();
      final state = container.read(coupleDissolveProvider).value;

      expect(state, isNotNull);
      expect(state!.status, CoupleDissolveStatus.initial);
      expect(state.message, '');
      expect(state.currentUserName, 'Gabriel');
      expect(state.partnerName, 'Marina');
    });

    test('emits AsyncError when findActive returns Left', () async {
      when(
        () => coupleRepository.findActive(),
      ).thenAnswer((_) async => const Left(NotFoundFailure()));

      final container = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWithValue(userRepository),
          coupleRepositoryProvider.overrideWithValue(coupleRepository),
        ],
      );
      addTearDown(container.dispose);
      container.listen(coupleDissolveProvider, (_, _) {});
      container.read(coupleDissolveProvider);

      await pumpEventQueue();

      final state = container.read(coupleDissolveProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<NotFoundFailure>());
    });
  });

  group('DissolvePressed', () {
    test('transitions to success when repository returns Right', () async {
      when(
        () => coupleRepository.dissolve(),
      ).thenAnswer((_) async => Right(null));

      final container = await makeContainer();
      container
          .read(coupleDissolveProvider.notifier)
          .dispatch(const DissolvePressed());

      await Future<void>.delayed(Duration.zero);

      final state = container.read(coupleDissolveProvider).value;
      expect(state!.status, CoupleDissolveStatus.success);
    });

    test('transitions to failure with message on Left', () async {
      when(
        () => coupleRepository.dissolve(),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = await makeContainer();
      container
          .read(coupleDissolveProvider.notifier)
          .dispatch(const DissolvePressed());

      await Future<void>.delayed(Duration.zero);

      final state = container.read(coupleDissolveProvider).value;
      expect(state!.status, CoupleDissolveStatus.failure);
      expect(state.message, 'Sem conexão com o servidor.');
    });

    test('skips second dispatch while loading', () async {
      var callCount = 0;
      when(() => coupleRepository.dissolve()).thenAnswer((_) async {
        callCount++;
        return Right(null);
      });

      final container = await makeContainer();
      final notifier = container.read(coupleDissolveProvider.notifier);
      notifier.dispatch(const DissolvePressed());
      notifier.dispatch(const DissolvePressed());

      await Future<void>.delayed(Duration.zero);

      expect(callCount, 1);
    });

    test('keeps user and partner names after dispatch', () async {
      when(
        () => coupleRepository.dissolve(),
      ).thenAnswer((_) async => Right(null));

      final container = await makeContainer();
      container
          .read(coupleDissolveProvider.notifier)
          .dispatch(const DissolvePressed());

      await Future<void>.delayed(Duration.zero);

      final state = container.read(coupleDissolveProvider).value;
      expect(state!.currentUserName, 'Gabriel');
      expect(state.partnerName, 'Marina');
    });
  });
}
