import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/services/money_service.dart';
import 'package:trocado/src/domain/services/date_formatter_service.dart';

import 'package:trocado/src/domain/models/budget/budget_slice_model.dart';
import 'package:trocado/src/domain/models/budget/budget_period_model.dart';
import 'package:trocado/src/domain/models/budget/partner_budget_slice_model.dart';
import 'package:trocado/src/domain/models/budget/shared_active_budget_model.dart';

import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';

import 'package:trocado/src/presentation/data/budget/shared_budget_card_presentation_data.dart';
import 'package:trocado/src/presentation/ui/home/notifiers/shared_active_budget_notifier.dart';

import '../../../mocks/mocks.dart';

const _model = SharedActiveBudgetModel(
  period: BudgetPeriodModel(
    startDate: 1746057600000,
    endDate: 1748649600000,
  ),
  me: BudgetSliceModel(value: 250000, totalSpent: 155627, remaining: 94373),
  partner: PartnerBudgetSliceModel(
    name: 'Gabriel Ramos',
    email: 'gabriel@trocado.app',
    value: 500000,
    totalSpent: 472087,
    remaining: 27913,
  ),
  combined: BudgetSliceModel(
    value: 750000,
    totalSpent: 627714,
    remaining: 122286,
  ),
  partnerHasDifferentPeriod: false,
);

ProviderContainer _makeContainer({
  required IMoneyService moneyService,
  required IBudgetRepository repository,
  required IDateFormatterService dateFormatter,
}) {
  final container = ProviderContainer(
    retry: (_, _) => null,
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
    ).thenAnswer(
      (invocation) =>
          'R\$ ${(invocation.positionalArguments.first as double).toStringAsFixed(2)}',
    );
    when(() => dateFormatter.daysUntil(any())).thenReturn(15);
    when(
      () => dateFormatter.formatLongDate(any()),
    ).thenReturn('31 de Mai de 2026');
  });

  group('build', () {
    test(
      'returns formatted SharedBudgetCardPresentationData on success',
      () async {
        when(
          () => repository.findActiveShared(),
        ).thenAnswer((_) async => const Right(_model));

        final container = _makeContainer(
          repository: repository,
          moneyService: moneyService,
          dateFormatter: dateFormatter,
        );
        container.listen(sharedActiveBudgetProvider, (_, _) {});
        final data = await container.read(
          sharedActiveBudgetProvider.future,
        );

        expect(data, isNotNull);
        expect(data!.formattedTotal, 'R\$ 7500.00');
        expect(data.formattedSpent, 'R\$ 6277.14');
        expect(data.formattedRemaining, 'R\$ 1222.86');
        expect(data.formattedEndDate, '31 de Mai de 2026');
        expect(data.formattedPercentage, '84');
        expect(data.overspent, isFalse);
        expect(data.mySlice.formattedValue, 'R\$ 2500.00');
        expect(data.mySlice.formattedRemaining, 'R\$ 943.73');
        expect(data.partnerSlice.partnerName, 'Gabriel Ramos');
        expect(data.partnerSlice.formattedValue, 'R\$ 5000.00');
        expect(data.partnerHasDifferentPeriod, isFalse);
      },
    );

    test('returns null when there is no active shared budget', () async {
      when(
        () => repository.findActiveShared(),
      ).thenAnswer((_) async => const Right(null));

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
        dateFormatter: dateFormatter,
      );
      container.listen(sharedActiveBudgetProvider, (_, _) {});
      final data = await container.read(sharedActiveBudgetProvider.future);

      expect(data, isNull);
    });

    test('emits AsyncError on NetworkFailure', () async {
      when(
        () => repository.findActiveShared(),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
        dateFormatter: dateFormatter,
      );
      container.listen(
        sharedActiveBudgetProvider,
        (_, _) {},
        onError: (_, _) {},
      );
      unawaited(
        container.read(sharedActiveBudgetProvider.future).then<void>(
              (_) {},
              onError: (_, _) {},
            ),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(sharedActiveBudgetProvider);
      expect(state, isA<AsyncError<SharedBudgetCardPresentationData?>>());
      expect(state.error, isA<NetworkFailure>());
    });
  });
}
