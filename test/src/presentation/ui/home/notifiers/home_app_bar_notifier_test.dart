import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/models/couple/couple_model.dart';
import 'package:trocado/src/domain/repositories/interface_user_repository.dart';
import 'package:trocado/src/domain/repositories/interface_couple_repository.dart';

import 'package:trocado/src/presentation/ui/home/notifiers/home_app_bar_notifier.dart';
import 'package:trocado/src/presentation/ui/home/data/home_app_bar_presentation_data.dart';

import '../../../../../mocks/mocks.dart';

const _user = UserModel(
  id: 1,
  name: 'Gabriel Ramos',
  email: 'gabriel@trocado.app',
);

final _couple = CoupleModel(
  id: 7,
  createdAt: DateTime(2026, 1, 12).millisecondsSinceEpoch,
  partner: const UserModel(id: 2, name: 'Kira', email: 'kira@trocado.app'),
);

void main() {
  late IUserRepository userRepository;
  late ICoupleRepository coupleRepository;

  setUp(() {
    userRepository = MockUserRepository();
    coupleRepository = MockCoupleRepository();

    when(() => userRepository.me()).thenAnswer((_) async => const Right(_user));
  });

  Future<ProviderContainer> makeContainer() async {
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        userRepositoryProvider.overrideWithValue(userRepository),
        coupleRepositoryProvider.overrideWithValue(coupleRepository),
      ],
    );
    addTearDown(container.dispose);
    container.listen(homeAppBarProvider, (_, _) {}, onError: (_, _) {});
    unawaited(
      container
          .read(homeAppBarProvider.future)
          .then<void>((_) {}, onError: (_, _) {}),
    );
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    return container;
  }

  group('build', () {
    test('returns Solo presentation data when couple is null', () async {
      when(
        () => coupleRepository.findActive(),
      ).thenAnswer((_) async => const Left(NotFoundFailure()));

      final container = await makeContainer();
      final state = container.read(homeAppBarProvider).asData?.value;

      expect(state, isA<HomeAppBarSoloPresentationData>());
      expect((state! as HomeAppBarSoloPresentationData).name, 'Gabriel Ramos');
    });

    test(
      'returns Couple presentation data with initials and combined title',
      () async {
        when(
          () => coupleRepository.findActive(),
        ).thenAnswer((_) async => Right(_couple));

        final container = await makeContainer();
        final state = container.read(homeAppBarProvider).asData?.value;

        expect(state, isA<HomeAppBarCouplePresentationData>());
        final data = state! as HomeAppBarCouplePresentationData;
        expect(data.title, 'Gabriel & Kira');
        expect(data.currentInitial, 'G');
        expect(data.partnerInitial, 'K');
      },
    );

    test('returns AsyncError when user repository fails', () async {
      when(
        () => userRepository.me(),
      ).thenAnswer((_) async => const Left(NetworkFailure()));
      when(
        () => coupleRepository.findActive(),
      ).thenAnswer((_) async => const Left(NotFoundFailure()));

      final container = await makeContainer();
      final state = container.read(homeAppBarProvider);

      expect(state, isA<AsyncError<HomeAppBarPresentationData>>());
      expect(state.error, isA<NetworkFailure>());
    });

    test('returns AsyncError when couple repository fails', () async {
      when(
        () => coupleRepository.findActive(),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = await makeContainer();
      final state = container.read(homeAppBarProvider);

      expect(state, isA<AsyncError<HomeAppBarPresentationData>>());
      expect(state.error, isA<NetworkFailure>());
    });

    test('handles partner name with diacritics', () async {
      final coupleWithDiacritics = _couple.copyWith(
        partner: const UserModel(
          id: 2,
          name: 'Ágata',
          email: 'agata@trocado.app',
        ),
      );

      when(
        () => coupleRepository.findActive(),
      ).thenAnswer((_) async => Right(coupleWithDiacritics));

      final container = await makeContainer();
      final state = container.read(homeAppBarProvider).asData?.value;

      expect(state, isA<HomeAppBarCouplePresentationData>());
      final data = state! as HomeAppBarCouplePresentationData;
      expect(data.partnerInitial, 'Á');
      expect(data.title, 'Gabriel & Ágata');
    });

    test('uses only first name for both partners in couple title', () async {
      final coupleWithLongName = _couple.copyWith(
        partner: const UserModel(
          id: 2,
          name: 'Kira Fernandes da Silva',
          email: 'kira@trocado.app',
        ),
      );

      when(
        () => coupleRepository.findActive(),
      ).thenAnswer((_) async => Right(coupleWithLongName));

      final container = await makeContainer();
      final state = container.read(homeAppBarProvider).asData?.value;

      expect(state, isA<HomeAppBarCouplePresentationData>());
      final data = state! as HomeAppBarCouplePresentationData;
      expect(data.title, 'Gabriel & Kira');
    });
  });
}
