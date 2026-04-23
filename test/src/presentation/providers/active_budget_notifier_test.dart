import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/core/either/either.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/services/money_service.dart';
import 'package:trocado/src/domain/models/budget/active_budget_model.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';

import 'package:trocado/src/presentation/ui/home/notifiers/active_budget_notifier.dart';

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

const _overspent = ActiveBudgetModel(
  id: 36,
  value: 1000000,
  startDate: 1743465600000,
  endDate: 1746057600000,
  description: 'Overspent',
  totalSpent: 1500000,
  remaining: -500000,
);

ProviderContainer _makeContainer({
  required IBudgetRepository repository,
  required IMoneyService moneyService,
}) {
  final container = ProviderContainer(
    overrides: [
      moneyServiceProvider.overrideWithValue(moneyService),
      budgetRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late IMoneyService moneyService;
  late IBudgetRepository repository;

  setUp(() {
    moneyService = MockMoneyService();
    repository = MockBudgetRepository();

    when(
      () => moneyService.format(any()),
    ).thenAnswer((invocation) => 'R\$ ${invocation.positionalArguments.first}');
  });

  test(
    'returns AsyncData with mapped BudgetCardData when repository returns Right(model)',
    () async {
      when(
        () => repository.findActive(),
      ).thenAnswer((_) async => const Right(_model));

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
      );
      final data = await container.read(activeBudgetProvider.future);

      expect(data, isNotNull);
      expect(data!.overspent, isFalse);
      expect(data.formattedValue, 'R\$ 18000.0');
      expect(data.formattedTotalSpent, 'R\$ 120.0');
      expect(data.formattedRemaining, 'R\$ 17880.0');
      expect(data.formattedOverspent, 'R\$ 17880.0');
    },
  );

  test('flags overspent and uses abs value for formattedOverspent', () async {
    when(
      () => repository.findActive(),
    ).thenAnswer((_) async => const Right(_overspent));

    final container = _makeContainer(
      repository: repository,
      moneyService: moneyService,
    );
    final data = await container.read(activeBudgetProvider.future);

    expect(data, isNotNull);
    expect(data!.overspent, isTrue);
    expect(data.formattedRemaining, 'R\$ 0.0');
    expect(data.formattedOverspent, 'R\$ 5000.0');
  });

  test('returns AsyncData(null) when repository returns Right(null)', () async {
    when(
      () => repository.findActive(),
    ).thenAnswer((_) async => const Right(null));

    final container = _makeContainer(
      repository: repository,
      moneyService: moneyService,
    );
    final data = await container.read(activeBudgetProvider.future);

    expect(data, isNull);
  });

  test(
    'emits AsyncError when repository returns Left(NetworkFailure)',
    () async {
      when(
        () => repository.findActive(),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
      );
      container.listen(activeBudgetProvider, (_, _) {});
      container.read(activeBudgetProvider);

      await pumpEventQueue();

      expect(container.read(activeBudgetProvider).hasError, isTrue);
      expect(container.read(activeBudgetProvider).error, isA<NetworkFailure>());
    },
  );

  test(
    'emits AsyncError when repository returns Left(ServerFailure)',
    () async {
      when(
        () => repository.findActive(),
      ).thenAnswer((_) async => const Left(ServerFailure()));

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
      );
      container.listen(activeBudgetProvider, (_, _) {});
      container.read(activeBudgetProvider);

      await pumpEventQueue();

      expect(container.read(activeBudgetProvider).hasError, isTrue);
      expect(container.read(activeBudgetProvider).error, isA<ServerFailure>());
    },
  );
}
