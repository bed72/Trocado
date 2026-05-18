import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/services/money_service.dart';
import 'package:trocado/src/domain/services/date_formatter_service.dart';
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
  required IDateFormatterService dateFormatter,
}) {
  final container = ProviderContainer(
    overrides: [
      moneyServiceProvider.overrideWithValue(moneyService),
      budgetRepositoryProvider.overrideWithValue(repository),
      dateFormatterServiceProvider.overrideWithValue(dateFormatter),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late IMoneyService moneyService;
  late IBudgetRepository repository;
  late IDateFormatterService dateFormatter;

  setUp(() {
    moneyService = MockMoneyService();
    repository = MockBudgetRepository();
    dateFormatter = MockDateFormatterService();

    when(
      () => moneyService.format(any()),
    ).thenAnswer((invocation) => 'R\$ ${invocation.positionalArguments.first}');

    when(() => dateFormatter.formatLongDate(any())).thenReturn('30 de Abr');
    when(() => dateFormatter.daysUntil(any())).thenReturn(2);
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
        dateFormatter: dateFormatter,
      );
      final data = await container.read(activeBudgetProvider.future);

      expect(data, isNotNull);
      expect(data!.overspent, isFalse);
      expect(data.formattedEndDate, '30 de Abr');
      expect(data.formattedValue, 'R\$ 18000.0');
      expect(data.formattedTotalSpent, 'R\$ 120.0');
      expect(data.formattedRemaining, 'R\$ 17880.0');
      expect(data.formattedOverspent, 'R\$ 17880.0');
    },
  );

  test(
    'formattedDailyBudget splits remaining across days remaining inclusively',
    () async {
      const daysRemaining = 2;
      const remaining = 105906;

      final model = ActiveBudgetModel(
        id: 1,
        value: 250000,
        totalSpent: 144094,
        remaining: remaining,
        description: 'Active',
        endDate: 1746057600000,
        startDate: 1743465600000,
      );

      when(() => dateFormatter.daysUntil(any())).thenReturn(daysRemaining);
      when(() => dateFormatter.formatLongDate(any())).thenReturn('01 de Mai');
      when(() => repository.findActive()).thenAnswer((_) async => Right(model));

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
        dateFormatter: dateFormatter,
      );
      final data = await container.read(activeBudgetProvider.future);

      expect(data!.formattedEndDate, '01 de Mai');
      expect(data.formattedDailyBudget, 'R\$ 529.53');
    },
  );

  test(
    'formattedDailyBudget uses full remaining when today is the last day',
    () async {
      const daysRemaining = 1;
      const remaining = 105906;

      final model = ActiveBudgetModel(
        id: 2,
        value: 250000,
        totalSpent: 144094,
        remaining: remaining,
        endDate: 1746057600000,
        description: 'Last day',
        startDate: 1743465600000,
      );

      when(() => dateFormatter.daysUntil(any())).thenReturn(daysRemaining);
      when(() => dateFormatter.formatLongDate(any())).thenReturn('12 de Mai');
      when(() => repository.findActive()).thenAnswer((_) async => Right(model));

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
        dateFormatter: dateFormatter,
      );
      final data = await container.read(activeBudgetProvider.future);

      expect(data!.formattedEndDate, '12 de Mai');
      expect(data.formattedDailyBudget, 'R\$ 1059.06');
    },
  );

  test('flags overspent and uses abs value for formattedOverspent', () async {
    when(
      () => repository.findActive(),
    ).thenAnswer((_) async => const Right(_overspent));

    final container = _makeContainer(
      repository: repository,
      moneyService: moneyService,
      dateFormatter: dateFormatter,
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
      dateFormatter: dateFormatter,
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
        dateFormatter: dateFormatter,
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
        dateFormatter: dateFormatter,
      );
      container.listen(activeBudgetProvider, (_, _) {});
      container.read(activeBudgetProvider);

      await pumpEventQueue();

      expect(container.read(activeBudgetProvider).hasError, isTrue);
      expect(container.read(activeBudgetProvider).error, isA<ServerFailure>());
    },
  );
}
