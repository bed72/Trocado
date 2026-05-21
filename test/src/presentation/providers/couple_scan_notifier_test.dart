import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/models/couple/invite_lookup_model.dart';
import 'package:trocado/src/domain/services/camera_permission_service.dart';
import 'package:trocado/src/domain/repositories/interface_couple_repository.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/presentation/ui/couple/scan/data/couple_scan_state.dart';
import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_intent.dart';
import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_notifier.dart';

import '../../../mocks/mocks.dart';

const _lookup = InviteLookupModel(
  coupleId: 1,
  partner: UserModel(id: 2, name: 'Marina', email: 'marina@trocado.app'),
);

void main() {
  late ICoupleRepository coupleRepository;
  late ICameraPermissionService cameraPermission;

  setUp(() {
    coupleRepository = MockCoupleRepository();
    cameraPermission = MockCameraPermissionService();

    when(() => cameraPermission.status()).thenAnswer((_) async => .granted);
  });

  Future<ProviderContainer> makeContainer() async {
    final container = ProviderContainer(
      overrides: [
        coupleRepositoryProvider.overrideWithValue(coupleRepository),
        cameraPermissionServiceProvider.overrideWithValue(cameraPermission),
      ],
    );
    addTearDown(container.dispose);
    container.listen(coupleScanProvider, (_, _) {});
    await container.read(coupleScanProvider.future);
    return container;
  }

  group('build', () {
    test('starts ready when permission is granted', () async {
      final container = await makeContainer();
      final state = container.read(coupleScanProvider).value;

      expect(state, isNotNull);
      expect(state!.canAskAgain, isTrue);
      expect(state.status, CoupleScanStatus.ready);
    });

    test('starts permissionDenied with canAskAgain=true on denied', () async {
      when(() => cameraPermission.status()).thenAnswer((_) async => .denied);

      final container = await makeContainer();
      final state = container.read(coupleScanProvider).value!;

      expect(state.canAskAgain, isTrue);
      expect(state.status, CoupleScanStatus.permissionDenied);
    });

    test(
      'starts permissionDenied with canAskAgain=false on permanentlyDenied',
      () async {
        when(
          () => cameraPermission.status(),
        ).thenAnswer((_) async => .permanentlyDenied);

        final container = await makeContainer();
        final state = container.read(coupleScanProvider).value!;

        expect(state.canAskAgain, isFalse);
        expect(state.status, CoupleScanStatus.permissionDenied);
      },
    );
  });

  group('PermissionRequested', () {
    test('transitions to ready when user grants permission', () async {
      when(() => cameraPermission.status()).thenAnswer((_) async => .denied);
      when(() => cameraPermission.request()).thenAnswer((_) async => .granted);

      final container = await makeContainer();
      container
          .read(coupleScanProvider.notifier)
          .dispatch(const PermissionRequested());

      await Future<void>.delayed(Duration.zero);

      final state = container.read(coupleScanProvider).value!;
      expect(state.status, CoupleScanStatus.ready);
    });

    test('stays permissionDenied with canAskAgain=true on denied', () async {
      when(() => cameraPermission.status()).thenAnswer((_) async => .denied);
      when(() => cameraPermission.request()).thenAnswer((_) async => .denied);

      final container = await makeContainer();
      container
          .read(coupleScanProvider.notifier)
          .dispatch(const PermissionRequested());

      await Future<void>.delayed(Duration.zero);

      final state = container.read(coupleScanProvider).value!;
      expect(state.status, CoupleScanStatus.permissionDenied);
      expect(state.canAskAgain, isTrue);
    });

    test(
      'goes to permissionDenied with canAskAgain=false on permanentlyDenied',
      () async {
        when(() => cameraPermission.status()).thenAnswer((_) async => .denied);
        when(
          () => cameraPermission.request(),
        ).thenAnswer((_) async => .permanentlyDenied);

        final container = await makeContainer();
        container
            .read(coupleScanProvider.notifier)
            .dispatch(const PermissionRequested());

        await Future<void>.delayed(Duration.zero);

        final state = container.read(coupleScanProvider).value!;
        expect(state.status, CoupleScanStatus.permissionDenied);
        expect(state.canAskAgain, isFalse);
      },
    );
  });

  group('OpenSettingsPressed', () {
    test('calls openSettings on the permission service', () async {
      when(() => cameraPermission.openSettings()).thenAnswer((_) async {});

      final container = await makeContainer();
      container
          .read(coupleScanProvider.notifier)
          .dispatch(const OpenSettingsPressed());

      await Future<void>.delayed(Duration.zero);

      verify(() => cameraPermission.openSettings()).called(1);
    });
  });

  group('QrDetected', () {
    test('transitions to lookedUp on successful lookup', () async {
      when(
        () => coupleRepository.lookupInvite(code: 'ABC'),
      ).thenAnswer((_) async => const Right(_lookup));

      final container = await makeContainer();
      container
          .read(coupleScanProvider.notifier)
          .dispatch(const QrDetected('ABC'));

      await Future<void>.delayed(Duration.zero);

      final state = container.read(coupleScanProvider).value!;

      expect(state.code, 'ABC');
      expect(state.lookup, _lookup);
      expect(state.status, CoupleScanStatus.lookedUp);
    });

    test('ignores second QrDetected while in lookup status', () async {
      var callCount = 0;
      when(
        () => coupleRepository.lookupInvite(code: any(named: 'code')),
      ).thenAnswer((_) async {
        callCount++;
        return const Right(_lookup);
      });

      final container = await makeContainer();
      final notifier = container.read(coupleScanProvider.notifier);
      notifier.dispatch(const QrDetected('ABC'));
      notifier.dispatch(const QrDetected('ABC'));

      await Future<void>.delayed(Duration.zero);

      expect(callCount, 1);
    });

    test('transitions to failure on Left and exposes message', () async {
      when(
        () => coupleRepository.lookupInvite(code: any(named: 'code')),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = await makeContainer();
      container
          .read(coupleScanProvider.notifier)
          .dispatch(const QrDetected('ABC'));

      await Future<void>.delayed(Duration.zero);

      final state = container.read(coupleScanProvider).value!;

      expect(state.status, CoupleScanStatus.failure);
      expect(state.message, 'Sem conexão com o servidor.');
    });

    test('ignores empty code', () async {
      final container = await makeContainer();
      container
          .read(coupleScanProvider.notifier)
          .dispatch(const QrDetected('   '));

      await Future<void>.delayed(.zero);

      verifyNever(
        () => coupleRepository.lookupInvite(code: any(named: 'code')),
      );
    });
  });

  group('ManualCodeChanged', () {
    test('updates manualCode and clears manualCodeFailure', () async {
      final container = await makeContainer();
      container
          .read(coupleScanProvider.notifier)
          .dispatch(const ManualCodeChanged('AB3K7N'));

      final state = container.read(coupleScanProvider).value!;
      expect(state.manualCode, 'AB3K7N');
      expect(state.manualCodeFailure, isNull);
    });
  });

  group('ManualCodeSubmitted', () {
    test('runs lookup when code is valid', () async {
      when(
        () => coupleRepository.lookupInvite(code: 'AB3K7N'),
      ).thenAnswer((_) async => const Right(_lookup));

      final container = await makeContainer();
      final notifier = container.read(coupleScanProvider.notifier);
      notifier.dispatch(const ManualCodeChanged('AB3K7N'));
      notifier.dispatch(const ManualCodeSubmitted());

      await Future<void>.delayed(Duration.zero);

      verify(() => coupleRepository.lookupInvite(code: 'AB3K7N')).called(1);
    });

    test('sets manualCodeFailure when code is invalid', () async {
      final container = await makeContainer();
      final notifier = container.read(coupleScanProvider.notifier);
      notifier.dispatch(const ManualCodeChanged('AB3'));
      notifier.dispatch(const ManualCodeSubmitted());

      await Future<void>.delayed(Duration.zero);

      final state = container.read(coupleScanProvider).value!;
      expect(state.manualCodeFailure, 'Código deve ter 6 caracteres');
      verifyNever(
        () => coupleRepository.lookupInvite(code: any(named: 'code')),
      );
    });
  });

  group('RetryPressed', () {
    test('resets state back to ready', () async {
      when(
        () => coupleRepository.lookupInvite(code: any(named: 'code')),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = await makeContainer();
      final notifier = container.read(coupleScanProvider.notifier);
      notifier.dispatch(const QrDetected('ABC'));
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(coupleScanProvider).value!.status,
        CoupleScanStatus.failure,
      );

      notifier.dispatch(const RetryPressed());
      await Future<void>.delayed(Duration.zero);

      final state = container.read(coupleScanProvider).value!;

      expect(state.message, '');
      expect(state.lookup, isNull);
      expect(state.status, CoupleScanStatus.ready);
    });
  });
}
