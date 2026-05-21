import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/models/couple/couple_model.dart';
import 'package:trocado/src/domain/services/date_formatter_service.dart';
import 'package:trocado/src/domain/repositories/interface_user_repository.dart';
import 'package:trocado/src/domain/repositories/interface_couple_repository.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/presentation/ui/settings/data/couple_card_state.dart';
import 'package:trocado/src/presentation/ui/settings/notifiers/settings_couple_card_notifier.dart';

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
  late IDateFormatterService dateFormatter;

  setUp(() {
    userRepository = MockUserRepository();
    coupleRepository = MockCoupleRepository();
    dateFormatter = MockDateFormatterService();

    when(() => userRepository.me()).thenAnswer((_) async => const Right(_user));
    when(() => dateFormatter.formatRelativePast(any())).thenReturn('4 meses');
  });

  Future<ProviderContainer> makeContainer() async {
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        userRepositoryProvider.overrideWithValue(userRepository),
        coupleRepositoryProvider.overrideWithValue(coupleRepository),
        dateFormatterServiceProvider.overrideWithValue(dateFormatter),
      ],
    );
    addTearDown(container.dispose);
    container.listen(settingsCoupleCardProvider, (_, _) {});
    await container.read(settingsCoupleCardProvider.future);
    return container;
  }

  group('build', () {
    test(
      'returns CoupleConnectedState with title, subtitle and initials',
      () async {
        when(
          () => coupleRepository.findActive(),
        ).thenAnswer((_) async => Right(_couple));

        final container = await makeContainer();
        final state = container.read(settingsCoupleCardProvider).asData?.value;

        expect(state, isA<CoupleConnectedState>());

        final data = (state as CoupleConnectedState).data;

        expect(data.partnerInitial, 'M');
        expect(data.currentUserInitial, 'G');
        expect(data.title, 'Gabriel & Marina');
        expect(data.subtitle, 'Conectados há 4 meses');

        verify(
          () => dateFormatter.formatRelativePast(_couple.createdAt),
        ).called(1);
      },
    );

    test(
      'returns CoupleNoneState when repository returns NotFoundFailure',
      () async {
        when(
          () => coupleRepository.findActive(),
        ).thenAnswer((_) async => const Left(NotFoundFailure()));

        final container = await makeContainer();
        final state = container.read(settingsCoupleCardProvider).asData?.value;

        expect(state, isA<CoupleNoneState>());
      },
    );

    test('returns CoupleFailureState with message on NetworkFailure', () async {
      when(
        () => coupleRepository.findActive(),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = await makeContainer();
      final state = container.read(settingsCoupleCardProvider).asData?.value;

      expect(state, isA<CoupleFailureState>());
      expect(
        (state as CoupleFailureState).message,
        'Sem conexão com o servidor.',
      );
    });

    test('returns CoupleFailureState with message on ServerFailure', () async {
      when(
        () => coupleRepository.findActive(),
      ).thenAnswer((_) async => const Left(ServerFailure()));

      final container = await makeContainer();
      final state = container.read(settingsCoupleCardProvider).asData?.value;

      expect(state, isA<CoupleFailureState>());
      expect(
        (state as CoupleFailureState).message,
        'Falha interna do servidor.',
      );
    });

    test(
      'returns CoupleFailureState with custom message on ValidationFailure',
      () async {
        when(() => coupleRepository.findActive()).thenAnswer(
          (_) async => const Left(ValidationFailure('Algo inesperado.')),
        );

        final container = await makeContainer();
        final state = container.read(settingsCoupleCardProvider).asData?.value;

        expect(state, isA<CoupleFailureState>());
        expect((state as CoupleFailureState).message, 'Algo inesperado.');
      },
    );

    test(
      'returns CoupleFailureState with default message on UnknownFailure',
      () async {
        when(
          () => coupleRepository.findActive(),
        ).thenAnswer((_) async => const Left(UnknownFailure()));

        final container = await makeContainer();
        final state = container.read(settingsCoupleCardProvider).asData?.value;

        expect(state, isA<CoupleFailureState>());
        expect((state as CoupleFailureState).message, 'Falha desconhecida.');
      },
    );

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
      final state = container.read(settingsCoupleCardProvider).asData?.value;

      expect(state, isA<CoupleConnectedState>());

      final data = (state as CoupleConnectedState).data;

      expect(data.partnerInitial, 'Á');
      expect(data.title, 'Gabriel & Ágata');
    });
  });
}
