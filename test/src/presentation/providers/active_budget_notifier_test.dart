import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/either/either.dart';

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
  totalSpent: 12000,
  remaining: 1788000,
  endDate: 1746057600000,
  startDate: 1743465600000,
  description: 'Orçamento de Abril',
);

const _overspent = ActiveBudgetModel(
  id: 36,
  value: 1000000,
  remaining: -500000,
  totalSpent: 1500000,
  endDate: 1746057600000,
  description: 'Overspent',
  startDate: 1743465600000,
);

ProviderContainer _makeContainer({
  required IMoneyService moneyService,
  required IBudgetRepository repository,
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

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

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
      expect(
        data.formattedEndDate,
        DateFormat(
          'dd/MM',
          'pt_BR',
        ).format(DateTime.fromMillisecondsSinceEpoch(_model.endDate)),
      );
    },
  );

  test(
    'formattedDailyBudget splits remaining across days remaining inclusively',
    () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final endDate = today.add(const Duration(days: 1));

      final model = ActiveBudgetModel(
        id: 1,
        value: 250000,
        remaining: 105906,
        totalSpent: 144094,
        description: 'Active',
        endDate: endDate.millisecondsSinceEpoch,
        startDate: today
            .subtract(const Duration(days: 28))
            .millisecondsSinceEpoch,
      );

      when(() => repository.findActive()).thenAnswer((_) async => Right(model));

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
      );
      final data = await container.read(activeBudgetProvider.future);

      expect(data!.formattedDailyBudget, 'R\$ 529.53');
      expect(
        data.formattedEndDate,
        DateFormat('dd/MM', 'pt_BR').format(endDate),
      );
    },
  );

  test(
    'formattedDailyBudget uses full remaining when today is the last day',
    () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final model = ActiveBudgetModel(
        id: 2,
        value: 250000,
        remaining: 105906,
        totalSpent: 144094,
        description: 'Last day',
        endDate: today.millisecondsSinceEpoch,
        startDate: today
            .subtract(const Duration(days: 29))
            .millisecondsSinceEpoch,
      );

      when(() => repository.findActive()).thenAnswer((_) async => Right(model));

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
      );
      final data = await container.read(activeBudgetProvider.future);

      expect(data!.formattedDailyBudget, 'R\$ 1059.06');
      expect(data.formattedEndDate, DateFormat('dd/MM', 'pt_BR').format(today));
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
