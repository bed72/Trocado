import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/couple/invite_model.dart';
import 'package:trocado/src/domain/services/interface_date_formatter_service.dart';
import 'package:trocado/src/domain/repositories/interface_couple_repository.dart';

import 'package:trocado/src/presentation/ui/couple/invite/notifiers/invite_qr_code_notifier.dart';

import '../../../mocks/mocks.dart';

const _expiresAt = 1773945000000;
const _qrData = 'trocado://invite/A3K7FN';
const _invite = InviteModel(
  code: 'A3K7FN',
  qrData: _qrData,
  expiresAt: _expiresAt,
);

ProviderContainer _makeContainer({
  required ICoupleRepository repository,
  required IDateFormatterService dateFormatter,
}) {
  final container = ProviderContainer(
    overrides: [
      coupleRepositoryProvider.overrideWithValue(repository),
      dateFormatterServiceProvider.overrideWithValue(dateFormatter),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late ICoupleRepository repository;
  late IDateFormatterService dateFormatter;

  setUp(() {
    repository = MockCoupleRepository();
    dateFormatter = MockDateFormatterService();

    when(
      () => dateFormatter.formatInviteExpiration(any()),
    ).thenReturn('18 de Maio às 18:23');
    when(
      () => repository.shareInvite(qrData: any(named: 'qrData')),
    ).thenAnswer((_) async => const Right(null));
  });

  group('build', () {
    test('emits AsyncData with formatted expiration on success', () async {
      when(
        () => repository.createInvite(),
      ).thenAnswer((_) async => const Right(_invite));

      final container = _makeContainer(
        repository: repository,
        dateFormatter: dateFormatter,
      );
      container.listen(inviteQrCodeProvider, (_, _) {});
      final value = await container.read(inviteQrCodeProvider.future);

      expect(value.code, 'A3K7FN');
      expect(value.qrData, _qrData);
      expect(value.formattedExpiration, '18 de Maio às 18:23');

      verify(() => dateFormatter.formatInviteExpiration(_expiresAt)).called(1);
    });

    test('emits AsyncError when repository returns Left', () async {
      when(
        () => repository.createInvite(),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = _makeContainer(
        repository: repository,
        dateFormatter: dateFormatter,
      );
      container.listen(inviteQrCodeProvider, (_, _) {});
      container.read(inviteQrCodeProvider);

      await pumpEventQueue();

      final state = container.read(inviteQrCodeProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<NetworkFailure>());
    });
  });

  group('retry', () {
    test('replays the request and emits AsyncData on success', () async {
      var calls = 0;
      when(() => repository.createInvite()).thenAnswer((_) async {
        calls += 1;
        return calls == 1 ? const Left(NetworkFailure()) : const Right(_invite);
      });

      final container = _makeContainer(
        repository: repository,
        dateFormatter: dateFormatter,
      );
      container.listen(inviteQrCodeProvider, (_, _) {});
      container.read(inviteQrCodeProvider);

      await pumpEventQueue();

      expect(container.read(inviteQrCodeProvider).hasError, isTrue);

      await container.read(inviteQrCodeProvider.notifier).retry();

      final state = container.read(inviteQrCodeProvider);
      expect(state.hasValue, isTrue);
      expect(state.value?.code, 'A3K7FN');
      expect(calls, 2);
    });
  });

  group('share', () {
    test(
      'delegates qrData to repository.shareInvite when state is AsyncData',
      () async {
        when(
          () => repository.createInvite(),
        ).thenAnswer((_) async => const Right(_invite));

        final container = _makeContainer(
          repository: repository,
          dateFormatter: dateFormatter,
        );
        container.listen(inviteQrCodeProvider, (_, _) {});
        await container.read(inviteQrCodeProvider.future);

        await container.read(inviteQrCodeProvider.notifier).share();

        verify(() => repository.shareInvite(qrData: _qrData)).called(1);
      },
    );

    test('does nothing when state is AsyncError', () async {
      when(
        () => repository.createInvite(),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = _makeContainer(
        repository: repository,
        dateFormatter: dateFormatter,
      );
      container.listen(inviteQrCodeProvider, (_, _) {});
      container.read(inviteQrCodeProvider);

      await pumpEventQueue();

      await container.read(inviteQrCodeProvider.notifier).share();

      verifyNever(() => repository.shareInvite(qrData: any(named: 'qrData')));
    });
  });
}
