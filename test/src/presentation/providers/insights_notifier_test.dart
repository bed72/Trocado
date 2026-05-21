import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/models/couple/couple_model.dart';
import 'package:trocado/src/domain/models/insight/insight_model.dart';
import 'package:trocado/src/domain/enums/scope/financial_scope_enum.dart';
import 'package:trocado/src/domain/models/insight/insights_bundle_model.dart';
import 'package:trocado/src/domain/repositories/interface_couple_repository.dart';
import 'package:trocado/src/domain/repositories/interface_insights_repository.dart';

import 'package:trocado/src/presentation/ui/home/notifiers/insights_notifier.dart';

import '../../../mocks/mocks.dart';

final _bundle = InsightsBundleModel(
  insights: const [
    InsightModel(
      severity: .info,
      type: .topCategory,
      title: 'Categoria em destaque',
      description: 'Housing em 56%.',
      data: {'category': 'housing', 'pct': 55.98},
    ),
  ],
  hasEnoughData: true,
  generatedAt: DateTime.utc(2026, 4, 22, 18, 24, 36),
);

final _coupleModel = CoupleModel(
  id: 7,
  createdAt: 1746000000000,
  partner: const UserModel(id: 2, name: 'Kira', email: 'kira@trocado.app'),
);

ProviderContainer _makeContainer({
  required IInsightsRepository repository,
  required ICoupleRepository coupleRepository,
}) {
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      coupleRepositoryProvider.overrideWithValue(coupleRepository),
      insightsRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late IInsightsRepository repository;
  late ICoupleRepository coupleRepository;

  setUpAll(() {
    registerFallbackValue(FinancialScopeEnum.mine);
  });

  setUp(() {
    repository = MockInsightsRepository();
    coupleRepository = MockCoupleRepository();

    when(
      () => coupleRepository.findActive(),
    ).thenAnswer((_) async => const Left(NotFoundFailure()));
  });

  test(
    'returns AsyncData with bundle when repository returns Right(bundle)',
    () async {
      when(
        () => repository.findAll(scope: any(named: 'scope')),
      ).thenAnswer((_) async => Right(_bundle));

      final container = _makeContainer(
        repository: repository,
        coupleRepository: coupleRepository,
      );
      final data = await container.read(insightsProvider.future);

      expect(data, equals(_bundle));
    },
  );

  test(
    'returns AsyncData with empty bundle when backend has no data',
    () async {
      final empty = InsightsBundleModel(
        insights: const [],
        hasEnoughData: false,
        generatedAt: DateTime.utc(2026, 4, 22),
      );

      when(
        () => repository.findAll(scope: any(named: 'scope')),
      ).thenAnswer((_) async => Right(empty));

      final container = _makeContainer(
        repository: repository,
        coupleRepository: coupleRepository,
      );
      final data = await container.read(insightsProvider.future);

      expect(data.insights, isEmpty);
      expect(data.hasEnoughData, isFalse);
    },
  );

  test(
    'emits AsyncError when repository returns Left(NetworkFailure)',
    () async {
      when(
        () => repository.findAll(scope: any(named: 'scope')),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = _makeContainer(
        repository: repository,
        coupleRepository: coupleRepository,
      );
      container.listen(insightsProvider, (_, _) {}, onError: (_, _) {});
      unawaited(
        container
            .read(insightsProvider.future)
            .then<void>((_) {}, onError: (_, _) {}),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(insightsProvider).hasError, isTrue);
      expect(container.read(insightsProvider).error, isA<NetworkFailure>());
    },
  );

  test(
    'emits AsyncError when repository returns Left(ServerFailure)',
    () async {
      when(
        () => repository.findAll(scope: any(named: 'scope')),
      ).thenAnswer((_) async => const Left(ServerFailure()));

      final container = _makeContainer(
        repository: repository,
        coupleRepository: coupleRepository,
      );
      container.listen(insightsProvider, (_, _) {}, onError: (_, _) {});
      unawaited(
        container
            .read(insightsProvider.future)
            .then<void>((_) {}, onError: (_, _) {}),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(insightsProvider).hasError, isTrue);
      expect(container.read(insightsProvider).error, isA<ServerFailure>());
    },
  );

  test('calls findAll with scope mine when solo', () async {
    when(
      () => repository.findAll(scope: any(named: 'scope')),
    ).thenAnswer((_) async => Right(_bundle));

    final container = _makeContainer(
      repository: repository,
      coupleRepository: coupleRepository,
    );
    await container.read(insightsProvider.future);

    verify(() => repository.findAll(scope: .mine)).called(1);
  });

  test('calls findAll with scope couple when in couple', () async {
    when(
      () => coupleRepository.findActive(),
    ).thenAnswer((_) async => Right(_coupleModel));
    when(
      () => repository.findAll(scope: any(named: 'scope')),
    ).thenAnswer((_) async => Right(_bundle));

    final container = _makeContainer(
      repository: repository,
      coupleRepository: coupleRepository,
    );
    await container.read(insightsProvider.future);

    verify(() => repository.findAll(scope: .couple)).called(1);
  });
}
