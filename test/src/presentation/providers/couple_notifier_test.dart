import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/models/couple/couple_model.dart';
import 'package:trocado/src/domain/repositories/interface_couple_repository.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/presentation/notifiers/couple_notifier.dart';

import '../../../mocks/mocks.dart';

final _couple = CoupleModel(
  id: 7,
  createdAt: DateTime(2026, 1, 12).millisecondsSinceEpoch,
  partner: const UserModel(id: 2, name: 'Marina', email: 'marina@trocado.app'),
);

void main() {
  late ICoupleRepository coupleRepository;

  setUp(() {
    coupleRepository = MockCoupleRepository();
  });

  Future<ProviderContainer> makeContainer() async {
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [coupleRepositoryProvider.overrideWithValue(coupleRepository)],
    );
    addTearDown(container.dispose);
    container.listen(coupleProvider, (_, _) {}, onError: (_, _) {});
    unawaited(
      container
          .read(coupleProvider.future)
          .then<void>((_) {}, onError: (_, _) {}),
    );
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    return container;
  }

  group('build', () {
    test('returns AsyncData with couple on success', () async {
      when(
        () => coupleRepository.findActive(),
      ).thenAnswer((_) async => Right(_couple));

      final container = await makeContainer();
      final state = container.read(coupleProvider);

      expect(state.asData?.value, _couple);
      expect(state, isA<AsyncData<CoupleModel?>>());
    });

    test('returns AsyncData with null on NotFoundFailure', () async {
      when(
        () => coupleRepository.findActive(),
      ).thenAnswer((_) async => const Left(NotFoundFailure()));

      final container = await makeContainer();
      final state = container.read(coupleProvider);

      expect(state.asData?.value, isNull);
      expect(state, isA<AsyncData<CoupleModel?>>());
    });

    test('returns AsyncError on NetworkFailure', () async {
      when(
        () => coupleRepository.findActive(),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = await makeContainer();
      final state = container.read(coupleProvider);

      expect(state, isA<AsyncError<CoupleModel?>>());
      expect(state.error, isA<NetworkFailure>());
    });

    test('returns AsyncError on ServerFailure', () async {
      when(
        () => coupleRepository.findActive(),
      ).thenAnswer((_) async => const Left(ServerFailure()));

      final container = await makeContainer();
      final state = container.read(coupleProvider);

      expect(state.error, isA<ServerFailure>());
      expect(state, isA<AsyncError<CoupleModel?>>());
    });

    test('returns AsyncError on ValidationFailure', () async {
      when(() => coupleRepository.findActive()).thenAnswer(
        (_) async => const Left(ValidationFailure('Algo inesperado.')),
      );

      final container = await makeContainer();
      final state = container.read(coupleProvider);

      expect(state.error, isA<ValidationFailure>());
      expect(state, isA<AsyncError<CoupleModel?>>());
    });

    test('returns AsyncError on UnknownFailure', () async {
      when(
        () => coupleRepository.findActive(),
      ).thenAnswer((_) async => const Left(UnknownFailure()));

      final container = await makeContainer();
      final state = container.read(coupleProvider);

      expect(state.error, isA<UnknownFailure>());
      expect(state, isA<AsyncError<CoupleModel?>>());
    });
  });
}
