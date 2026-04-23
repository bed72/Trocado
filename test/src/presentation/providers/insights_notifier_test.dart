import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/core/either/either.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/insight/insight_model.dart';
import 'package:trocado/src/domain/enums/insight/insight_type_enum.dart';
import 'package:trocado/src/domain/enums/insight/insight_severity_enum.dart';
import 'package:trocado/src/domain/models/insight/insights_bundle_model.dart';
import 'package:trocado/src/domain/repositories/interface_insights_repository.dart';

import 'package:trocado/src/presentation/ui/home/notifiers/insights_notifier.dart';

import '../../../mocks/mocks.dart';

final _bundle = InsightsBundleModel(
  insights: const [
    InsightModel(
      message: 'Housing em 56%.',
      type: InsightTypeEnum.topCategory,
      severity: InsightSeverityEnum.info,
      data: {'category': 'housing', 'pct': 55.98},
    ),
  ],
  hasEnoughData: true,
  generatedAt: DateTime.utc(2026, 4, 22, 18, 24, 36),
);

ProviderContainer _makeContainer(IInsightsRepository repository) {
  final container = ProviderContainer(
    overrides: [insightsRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late IInsightsRepository repository;

  setUp(() {
    repository = MockInsightsRepository();
  });

  test(
    'returns AsyncData with bundle when repository returns Right(bundle)',
    () async {
      when(() => repository.findAll()).thenAnswer((_) async => Right(_bundle));

      final container = _makeContainer(repository);
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

      when(() => repository.findAll()).thenAnswer((_) async => Right(empty));

      final container = _makeContainer(repository);
      final data = await container.read(insightsProvider.future);

      expect(data.insights, isEmpty);
      expect(data.hasEnoughData, isFalse);
    },
  );

  test(
    'emits AsyncError when repository returns Left(NetworkFailure)',
    () async {
      when(
        () => repository.findAll(),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = _makeContainer(repository);
      container.listen(insightsProvider, (_, _) {});
      container.read(insightsProvider);

      await pumpEventQueue();

      expect(container.read(insightsProvider).hasError, isTrue);
      expect(container.read(insightsProvider).error, isA<NetworkFailure>());
    },
  );

  test(
    'emits AsyncError when repository returns Left(ServerFailure)',
    () async {
      when(
        () => repository.findAll(),
      ).thenAnswer((_) async => const Left(ServerFailure()));

      final container = _makeContainer(repository);
      container.listen(insightsProvider, (_, _) {});
      container.read(insightsProvider);

      await pumpEventQueue();

      expect(container.read(insightsProvider).hasError, isTrue);
      expect(container.read(insightsProvider).error, isA<ServerFailure>());
    },
  );
}
