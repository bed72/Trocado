import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/models/couple/invite_lookup_model.dart';
import 'package:trocado/src/domain/repositories/interface_couple_repository.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/presentation/ui/couple/scan/data/couple_scan_confirm_state.dart';
import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_confirm_intent.dart';
import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_confirm_notifier.dart';

import '../../../mocks/mocks.dart';

const _lookup = InviteLookupModel(
  coupleId: 1,
  partner: UserModel(id: 2, name: 'Marina', email: 'marina@trocado.app'),
);

void main() {
  late ICoupleRepository repository;

  setUp(() {
    repository = MockCoupleRepository();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [coupleRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.listen(coupleScanConfirmProvider, (_, _) {});
    return container;
  }

  group('build', () {
    test('returns initial state', () {
      final container = makeContainer();
      final state = container.read(coupleScanConfirmProvider);

      expect(state.message, '');
      expect(state.status, CoupleScanConfirmStatus.initial);
    });
  });

  group('AcceptPressed', () {
    test('transitions to success on Right', () async {
      when(
        () => repository.acceptInvite(code: 'ABC'),
      ).thenAnswer((_) async => const Right(_lookup));

      final container = makeContainer();
      container
          .read(coupleScanConfirmProvider.notifier)
          .dispatch(const AcceptPressed('ABC'));

      await Future<void>.delayed(Duration.zero);

      final state = container.read(coupleScanConfirmProvider);
      expect(state.status, CoupleScanConfirmStatus.success);
    });

    test('transitions to failure with message on Left', () async {
      when(
        () => repository.acceptInvite(code: any(named: 'code')),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = makeContainer();
      container
          .read(coupleScanConfirmProvider.notifier)
          .dispatch(const AcceptPressed('ABC'));

      await Future<void>.delayed(Duration.zero);

      final state = container.read(coupleScanConfirmProvider);

      expect(state.message, 'Sem conexão com o servidor.');
      expect(state.status, CoupleScanConfirmStatus.failure);
    });

    test('skips second dispatch while loading', () async {
      int callCount = 0;
      when(() => repository.acceptInvite(code: any(named: 'code'))).thenAnswer((
        _,
      ) async {
        callCount++;
        return const Right(_lookup);
      });

      final container = makeContainer();
      final notifier = container.read(coupleScanConfirmProvider.notifier);
      notifier.dispatch(const AcceptPressed('A'));
      notifier.dispatch(const AcceptPressed('A'));

      await Future<void>.delayed(Duration.zero);

      expect(callCount, 1);
    });
  });
}
