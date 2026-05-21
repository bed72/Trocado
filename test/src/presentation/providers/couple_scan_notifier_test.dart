import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/services/camera_permission_service.dart';

import 'package:trocado/src/main/providers/services_provider.dart';

import 'package:trocado/src/presentation/ui/couple/scan/data/couple_scan_state.dart';
import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_intent.dart';
import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_notifier.dart';

import '../../../mocks/mocks.dart';

void main() {
  late ICameraPermissionService cameraPermission;

  setUp(() {
    cameraPermission = MockCameraPermissionService();

    when(() => cameraPermission.status()).thenAnswer((_) async => .granted);
  });

  Future<ProviderContainer> makeContainer() async {
    final container = ProviderContainer(
      overrides: [
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
    test('transitions to detected and stores code', () async {
      final container = await makeContainer();
      container
          .read(coupleScanProvider.notifier)
          .dispatch(const QrDetected('ABC'));

      await Future<void>.delayed(Duration.zero);

      final state = container.read(coupleScanProvider).value!;
      expect(state.code, 'ABC');
      expect(state.status, CoupleScanStatus.detected);
    });

    test('ignores second QrDetected while in detected status', () async {
      final container = await makeContainer();
      final notifier = container.read(coupleScanProvider.notifier);
      notifier.dispatch(const QrDetected('ABC'));
      notifier.dispatch(const QrDetected('XYZ'));

      await Future<void>.delayed(Duration.zero);

      final state = container.read(coupleScanProvider).value!;
      expect(state.code, 'ABC');
      expect(state.status, CoupleScanStatus.detected);
    });

    test('ignores empty code', () async {
      final container = await makeContainer();
      container
          .read(coupleScanProvider.notifier)
          .dispatch(const QrDetected('   '));

      await Future<void>.delayed(.zero);

      final state = container.read(coupleScanProvider).value!;
      expect(state.code, '');
      expect(state.status, CoupleScanStatus.ready);
    });

    test('extracts code from trocado://invite/<code> deep link', () async {
      final container = await makeContainer();
      container
          .read(coupleScanProvider.notifier)
          .dispatch(const QrDetected('trocado://invite/36APAY'));

      await Future<void>.delayed(Duration.zero);

      final state = container.read(coupleScanProvider).value!;
      expect(state.code, '36APAY');
      expect(state.status, CoupleScanStatus.detected);
    });

    test('ignores deep link with empty code segment', () async {
      final container = await makeContainer();
      container
          .read(coupleScanProvider.notifier)
          .dispatch(const QrDetected('trocado://invite/'));

      await Future<void>.delayed(Duration.zero);

      final state = container.read(coupleScanProvider).value!;
      expect(state.code, '');
      expect(state.status, CoupleScanStatus.ready);
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
    test(
      'transitions to detected with code when manual code is valid',
      () async {
        final container = await makeContainer();
        final notifier = container.read(coupleScanProvider.notifier);
        notifier.dispatch(const ManualCodeChanged('AB3K7N'));
        notifier.dispatch(const ManualCodeSubmitted());

        await Future<void>.delayed(Duration.zero);

        final state = container.read(coupleScanProvider).value!;
        expect(state.code, 'AB3K7N');
        expect(state.status, CoupleScanStatus.detected);
      },
    );

    test('sets manualCodeFailure when code is invalid', () async {
      final container = await makeContainer();
      final notifier = container.read(coupleScanProvider.notifier);
      notifier.dispatch(const ManualCodeChanged('AB3'));
      notifier.dispatch(const ManualCodeSubmitted());

      await Future<void>.delayed(Duration.zero);

      final state = container.read(coupleScanProvider).value!;
      expect(state.manualCodeFailure, 'Código deve ter 6 caracteres');
      expect(state.status, CoupleScanStatus.ready);
    });
  });

  group('RetryPressed', () {
    test('resets state back to ready', () async {
      final container = await makeContainer();
      final notifier = container.read(coupleScanProvider.notifier);
      notifier.dispatch(const QrDetected('ABC'));
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(coupleScanProvider).value!.status,
        CoupleScanStatus.detected,
      );

      notifier.dispatch(const RetryPressed());
      await Future<void>.delayed(Duration.zero);

      final state = container.read(coupleScanProvider).value!;
      expect(state.code, '');
      expect(state.message, '');
      expect(state.status, CoupleScanStatus.ready);
    });
  });
}
