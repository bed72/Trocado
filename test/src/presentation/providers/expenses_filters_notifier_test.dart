import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/main/providers/services_provider.dart';

import 'package:trocado/src/domain/services/date_formatter_service.dart';
import 'package:trocado/src/domain/enums/expense/expense_category_enum.dart';
import 'package:trocado/src/domain/models/expense/expense_filter_model.dart';
import 'package:trocado/src/domain/enums/expense/expense_period_preset_enum.dart';

import 'package:trocado/src/presentation/ui/expenses/notifiers/expenses_filters_intent.dart';
import 'package:trocado/src/presentation/ui/expenses/notifiers/expenses_filters_notifier.dart';

import '../../../mocks/mocks.dart';

ProviderContainer _makeContainer({
  DateTime? now,
  IDateFormatterService? dateFormatter,
}) {
  final formatter = dateFormatter ?? MockDateFormatterService();
  when(() => formatter.formatPeriod(any(), any())).thenAnswer(
    (invocation) =>
        'PERIOD(${invocation.positionalArguments[0]},${invocation.positionalArguments[1]})',
  );

  final container = ProviderContainer(
    overrides: [
      dateFormatterServiceProvider.overrideWithValue(formatter),
      if (now != null)
        nowProvider.overrideWith(
          (_) =>
              () => now,
        ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  const emptySeed = ExpenseFilterModel.empty();

  group('initial state', () {
    test('starts with the provided seed and no preset', () {
      final container = _makeContainer();
      final state = container.read(expensesFiltersProvider(emptySeed));

      expect(state.draft, emptySeed);
      expect(state.selectedPreset, isNull);
    });

    test('seeds the draft from the provided filter', () {
      final container = _makeContainer();
      final filter = const ExpenseFilterModel.empty().copyWith(
        category: .food,
        startDate: 100,
      );

      final state = container.read(expensesFiltersProvider(filter));

      expect(state.draft, filter);
      expect(state.selectedPreset, isNull);
    });
  });

  group('PresetSelected', () {
    test('currentMonth updates the draft range and highlights the chip', () {
      final container = _makeContainer(now: DateTime(2026, 4, 23, 14, 30));

      container
          .read(expensesFiltersProvider(emptySeed).notifier)
          .dispatch(const PresetSelected(ExpensePeriodPresetEnum.currentMonth));

      final state = container.read(expensesFiltersProvider(emptySeed));
      expect(state.selectedPreset, ExpensePeriodPresetEnum.currentMonth);
      expect(
        state.draft.startDate,
        DateTime(2026, 4, 1).millisecondsSinceEpoch,
      );
      expect(
        state.draft.endDate,
        DateTime(2026, 4, 30, 23, 59, 59, 999).millisecondsSinceEpoch,
      );
    });

    test('custom only updates the selected preset, not the draft range', () {
      final container = _makeContainer();

      container
          .read(expensesFiltersProvider(emptySeed).notifier)
          .dispatch(const PresetSelected(ExpensePeriodPresetEnum.custom));

      final state = container.read(expensesFiltersProvider(emptySeed));
      expect(state.selectedPreset, ExpensePeriodPresetEnum.custom);
      expect(state.draft.startDate, isNull);
      expect(state.draft.endDate, isNull);
    });
  });

  group('CustomRangeChanged', () {
    test('updates the draft range and selects the custom preset', () {
      final container = _makeContainer();
      final start = DateTime(2026, 3, 5).millisecondsSinceEpoch;
      final end = DateTime(2026, 3, 20, 23, 59, 59, 999).millisecondsSinceEpoch;

      container
          .read(expensesFiltersProvider(emptySeed).notifier)
          .dispatch(CustomRangeChanged(start, end));

      final state = container.read(expensesFiltersProvider(emptySeed));
      expect(state.selectedPreset, ExpensePeriodPresetEnum.custom);
      expect(state.draft.startDate, start);
      expect(state.draft.endDate, end);
    });

    test('exposes formattedPeriodSummary using the date service', () {
      final container = _makeContainer();
      final start = DateTime(2026, 3, 5).millisecondsSinceEpoch;
      final end = DateTime(2026, 3, 20).millisecondsSinceEpoch;

      container
          .read(expensesFiltersProvider(emptySeed).notifier)
          .dispatch(CustomRangeChanged(start, end));

      final state = container.read(expensesFiltersProvider(emptySeed));
      expect(state.formattedPeriodSummary, 'PERIOD($start,$end)');
    });
  });

  group('CategorySelected', () {
    test('sets the category', () {
      final container = _makeContainer();

      container
          .read(expensesFiltersProvider(emptySeed).notifier)
          .dispatch(const CategorySelected(ExpenseCategoryEnum.shopping));

      expect(
        container.read(expensesFiltersProvider(emptySeed)).draft.category,
        ExpenseCategoryEnum.shopping,
      );
    });

    test('null clears the category', () {
      final container = _makeContainer();
      final notifier = container.read(
        expensesFiltersProvider(emptySeed).notifier,
      );

      notifier.dispatch(const CategorySelected(ExpenseCategoryEnum.shopping));
      notifier.dispatch(const CategorySelected(null));

      expect(
        container.read(expensesFiltersProvider(emptySeed)).draft.category,
        isNull,
      );
    });
  });

  group('Cleared', () {
    test('resets draft and preset to empty', () {
      final container = _makeContainer(now: DateTime(2026, 4, 23));
      final notifier = container.read(
        expensesFiltersProvider(emptySeed).notifier,
      );

      notifier.dispatch(
        const PresetSelected(ExpensePeriodPresetEnum.currentMonth),
      );
      notifier.dispatch(const CategorySelected(ExpenseCategoryEnum.food));

      notifier.dispatch(const Cleared());

      final state = container.read(expensesFiltersProvider(emptySeed));
      expect(state.selectedPreset, isNull);
      expect(state.draft, const ExpenseFilterModel.empty());
    });
  });
}
