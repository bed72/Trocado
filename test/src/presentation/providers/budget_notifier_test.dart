import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/core/either/either.dart';

import 'package:trocado/src/main/providers/validators_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/budget_model.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';

import 'package:trocado/src/presentation/screens/budget/notifiers/budget_state.dart';
import 'package:trocado/src/presentation/screens/budget/notifiers/budget_intent.dart';
import 'package:trocado/src/presentation/screens/budget/notifiers/budget_notifier.dart';
import 'package:trocado/src/presentation/screens/budget/validators/budget_form_validator.dart';
import 'package:trocado/src/presentation/screens/budget/validators/budget_value_validation.dart';
import 'package:trocado/src/presentation/screens/budget/validators/budget_description_validation.dart';
import 'package:trocado/src/presentation/screens/budget/validators/budget_date_range_validation.dart';

import '../../../mocks/mocks.dart';

const _endDate = 1743379200000;
const _startDate = 1740787200000;

const _budget = BudgetModel(
  id: 1,
  value: 100000,
  endDate: _endDate,
  startDate: _startDate,
  description: 'March budget',
);

ProviderContainer _makeContainer(IBudgetRepository repository) {
  final container = ProviderContainer(
    overrides: [
      budgetRepositoryProvider.overrideWithValue(repository),
      budgetFormValidatorProvider.overrideWithValue(
        const BudgetFormValidator(
          valueValidation: BudgetValueValidation(),
          dateRangeValidation: BudgetDateRangeValidation(),
          descriptionValidation: BudgetDescriptionValidation(),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.listen(budgetProvider, (_, _) {});
  container.read(budgetProvider);
  return container;
}

void main() {
  late IBudgetRepository repository;

  setUp(() {
    repository = MockBudgetRepository();
  });

  group('dispatch — ValueChanged', () {
    test('updates value in state', () {
      final container = _makeContainer(repository);

      container
          .read(budgetProvider.notifier)
          .dispatch(const ValueChanged(100000));

      expect(container.read(budgetProvider).value, 100000);
    });

    test('clears valueFailure', () {
      final container = _makeContainer(repository);
      container.read(budgetProvider.notifier).dispatch(const SubmitPressed());

      container
          .read(budgetProvider.notifier)
          .dispatch(const ValueChanged(100000));

      expect(container.read(budgetProvider).valueFailure, isNull);
    });
  });

  group('dispatch — DescriptionChanged', () {
    test('updates description in state', () {
      final container = _makeContainer(repository);

      container
          .read(budgetProvider.notifier)
          .dispatch(const DescriptionChanged('March budget'));

      expect(container.read(budgetProvider).description, 'March budget');
    });

    test('clears descriptionFailure', () {
      final container = _makeContainer(repository);
      container.read(budgetProvider.notifier).dispatch(const SubmitPressed());

      container
          .read(budgetProvider.notifier)
          .dispatch(const DescriptionChanged('March budget'));

      expect(container.read(budgetProvider).descriptionFailure, isNull);
    });
  });

  group('dispatch — DateRangeChanged', () {
    test('updates startDate and endDate in state', () {
      final container = _makeContainer(repository);

      container
          .read(budgetProvider.notifier)
          .dispatch(
            const DateRangeChanged(startDate: _startDate, endDate: _endDate),
          );

      expect(container.read(budgetProvider).endDate, _endDate);
      expect(container.read(budgetProvider).startDate, _startDate);
    });

    test('clears dateFailure', () {
      final container = _makeContainer(repository);
      container.read(budgetProvider.notifier).dispatch(const SubmitPressed());

      container
          .read(budgetProvider.notifier)
          .dispatch(
            const DateRangeChanged(startDate: _startDate, endDate: _endDate),
          );

      expect(container.read(budgetProvider).dateFailure, isNull);
    });
  });

  group('dispatch — SubmitPressed', () {
    test('sets validation failures when state is empty', () {
      final container = _makeContainer(repository);

      container.read(budgetProvider.notifier).dispatch(const SubmitPressed());

      final state = container.read(budgetProvider);
      expect(state.valueFailure, isNotNull);
      expect(state.descriptionFailure, isNotNull);
      expect(state.dateFailure, isNotNull);
    });

    test('does not call repository when validation fails', () {
      final container = _makeContainer(repository);

      container.read(budgetProvider.notifier).dispatch(const SubmitPressed());

      verifyNever(
        () => repository.create(
          value: any(named: 'value'),
          endDate: any(named: 'endDate'),
          startDate: any(named: 'startDate'),
          description: any(named: 'description'),
        ),
      );
    });

    test(
      'sets status to loading then success on successful creation',
      () async {
        when(
          () => repository.create(
            value: any(named: 'value'),
            endDate: any(named: 'endDate'),
            startDate: any(named: 'startDate'),
            description: any(named: 'description'),
          ),
        ).thenAnswer((_) async => const Right(_budget));

        final container = _makeContainer(repository);
        final notifier = container.read(budgetProvider.notifier);

        notifier.dispatch(const ValueChanged(100000));
        notifier.dispatch(const DescriptionChanged('March budget'));
        notifier.dispatch(
          const DateRangeChanged(startDate: _startDate, endDate: _endDate),
        );

        notifier.dispatch(const SubmitPressed());
        await pumpEventQueue();

        expect(container.read(budgetProvider).status, BudgetStatus.success);
      },
    );

    test('sets status to failure with message on error', () async {
      when(
        () => repository.create(
          value: any(named: 'value'),
          endDate: any(named: 'endDate'),
          startDate: any(named: 'startDate'),
          description: any(named: 'description'),
        ),
      ).thenAnswer(
        (_) async => const Left(
          ValidationFailure('Orçamento já existe para o período.'),
        ),
      );

      final container = _makeContainer(repository);
      final notifier = container.read(budgetProvider.notifier);

      notifier.dispatch(const ValueChanged(100000));
      notifier.dispatch(const DescriptionChanged('March budget'));
      notifier.dispatch(
        const DateRangeChanged(startDate: _startDate, endDate: _endDate),
      );
      notifier.dispatch(const SubmitPressed());

      await pumpEventQueue();

      final state = container.read(budgetProvider);

      expect(state.status, BudgetStatus.failure);
      expect(state.message, 'Orçamento já existe para o período.');
    });

    test('sets status to failure on network error', () async {
      when(
        () => repository.create(
          value: any(named: 'value'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = _makeContainer(repository);
      final notifier = container.read(budgetProvider.notifier);

      notifier.dispatch(const ValueChanged(100000));
      notifier.dispatch(const DescriptionChanged('March budget'));
      notifier.dispatch(
        const DateRangeChanged(startDate: _startDate, endDate: _endDate),
      );
      notifier.dispatch(const SubmitPressed());

      await pumpEventQueue();

      final state = container.read(budgetProvider);

      expect(state.message, isNotEmpty);
      expect(state.status, BudgetStatus.failure);
    });
  });
}
