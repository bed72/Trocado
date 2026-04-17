import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/core/either/either.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/active_budget_model.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';

import 'package:trocado/src/presentation/screens/budget/notifiers/active_budget_notifier.dart';

import '../../../mocks/mocks.dart';

const _model = ActiveBudgetModel(
  id: 35,
  value: 1800000,
  startDate: 1743465600000,
  endDate: 1746057600000,
  description: 'Orçamento de Abril',
  totalSpent: 12000,
  remaining: 1788000,
);

ProviderContainer _makeContainer(IBudgetRepository repository) {
  final container = ProviderContainer(
    overrides: [budgetRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late IBudgetRepository repository;

  setUp(() {
    repository = MockBudgetRepository();
  });

  test('returns AsyncData with model when repository returns Right(model)', () async {
    when(() => repository.findActive()).thenAnswer(
      (_) async => const Right(_model),
    );

    final container = _makeContainer(repository);
    final data = await container.read(activeBudgetProvider.future);

    expect(data, equals(_model));
  });

  test('returns AsyncData(null) when repository returns Right(null)', () async {
    when(() => repository.findActive()).thenAnswer(
      (_) async => const Right(null),
    );

    final container = _makeContainer(repository);
    final data = await container.read(activeBudgetProvider.future);

    expect(data, isNull);
  });

  test('emits AsyncError when repository returns Left(NetworkFailure)', () async {
    when(() => repository.findActive()).thenAnswer(
      (_) async => const Left(NetworkFailure()),
    );

    final container = _makeContainer(repository);
    container.listen(activeBudgetProvider, (_, _) {});
    container.read(activeBudgetProvider);

    await pumpEventQueue();

    expect(container.read(activeBudgetProvider).hasError, isTrue);
    expect(container.read(activeBudgetProvider).error, isA<NetworkFailure>());
  });

  test('emits AsyncError when repository returns Left(ServerFailure)', () async {
    when(() => repository.findActive()).thenAnswer(
      (_) async => const Left(ServerFailure()),
    );

    final container = _makeContainer(repository);
    container.listen(activeBudgetProvider, (_, _) {});
    container.read(activeBudgetProvider);

    await pumpEventQueue();

    expect(container.read(activeBudgetProvider).hasError, isTrue);
    expect(container.read(activeBudgetProvider).error, isA<ServerFailure>());
  });
}
