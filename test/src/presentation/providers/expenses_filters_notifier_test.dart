import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/main/providers/services_provider.dart';

import 'package:trocado/src/domain/models/expense/expense_category.dart';
import 'package:trocado/src/domain/models/expense/expense_ordering.dart';
import 'package:trocado/src/domain/models/expense/expense_filter_model.dart';
import 'package:trocado/src/domain/models/expense/expense_period_preset.dart';

import 'package:trocado/src/presentation/screens/expenses/notifiers/expenses_filters_intent.dart';
import 'package:trocado/src/presentation/screens/expenses/notifiers/expenses_filters_notifier.dart';

ProviderContainer _makeContainer({DateTime? now}) {
  final container = ProviderContainer(
    overrides: [
      if (now != null) nowProvider.overrideWith((_) => () => now),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('initial state', () {
    test('starts with empty draft and no preset', () {
      final container = _makeContainer();
      final state = container.read(expensesFiltersProvider);

      expect(state.draft, const ExpenseFilterModel.empty());
      expect(state.selectedPreset, isNull);
    });
  });

  group('InitializeFrom', () {
    test('seeds the draft from the provided filter', () {
      final container = _makeContainer();
      final filter = const ExpenseFilterModel.empty().copyWith(
        category: ExpenseCategory.food,
        minValue: 10000,
      );

      container
          .read(expensesFiltersProvider.notifier)
          .dispatch(InitializeFrom(filter));

      expect(container.read(expensesFiltersProvider).draft, filter);
      expect(container.read(expensesFiltersProvider).selectedPreset, isNull);
    });
  });

  group('PresetSelected', () {
    test('currentMonth updates the draft range and highlights the chip', () {
      final container = _makeContainer(now: DateTime(2026, 4, 23, 14, 30));

      container
          .read(expensesFiltersProvider.notifier)
          .dispatch(const PresetSelected(ExpensePeriodPreset.currentMonth));

      final state = container.read(expensesFiltersProvider);
      expect(state.selectedPreset, ExpensePeriodPreset.currentMonth);
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
          .read(expensesFiltersProvider.notifier)
          .dispatch(const PresetSelected(ExpensePeriodPreset.custom));

      final state = container.read(expensesFiltersProvider);
      expect(state.selectedPreset, ExpensePeriodPreset.custom);
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
          .read(expensesFiltersProvider.notifier)
          .dispatch(CustomRangeChanged(start, end));

      final state = container.read(expensesFiltersProvider);
      expect(state.selectedPreset, ExpensePeriodPreset.custom);
      expect(state.draft.startDate, start);
      expect(state.draft.endDate, end);
    });
  });

  group('CategorySelected', () {
    test('sets the category', () {
      final container = _makeContainer();

      container
          .read(expensesFiltersProvider.notifier)
          .dispatch(const CategorySelected(ExpenseCategory.shopping));

      expect(
        container.read(expensesFiltersProvider).draft.category,
        ExpenseCategory.shopping,
      );
    });

    test('null clears the category', () {
      final container = _makeContainer();
      final notifier = container.read(expensesFiltersProvider.notifier);

      notifier.dispatch(const CategorySelected(ExpenseCategory.shopping));
      notifier.dispatch(const CategorySelected(null));

      expect(
        container.read(expensesFiltersProvider).draft.category,
        isNull,
      );
    });
  });

  group('MinValueChanged / MaxValueChanged', () {
    test('non-zero values are stored', () {
      final container = _makeContainer();
      final notifier = container.read(expensesFiltersProvider.notifier);

      notifier.dispatch(const MinValueChanged(1500));
      notifier.dispatch(const MaxValueChanged(50000));

      final draft = container.read(expensesFiltersProvider).draft;
      expect(draft.minValue, 1500);
      expect(draft.maxValue, 50000);
    });

    test('zero is treated as unset', () {
      final container = _makeContainer();
      final notifier = container.read(expensesFiltersProvider.notifier);

      notifier.dispatch(const MinValueChanged(1500));
      notifier.dispatch(const MinValueChanged(0));

      expect(container.read(expensesFiltersProvider).draft.minValue, isNull);
    });

    test('null is treated as unset', () {
      final container = _makeContainer();
      final notifier = container.read(expensesFiltersProvider.notifier);

      notifier.dispatch(const MaxValueChanged(1500));
      notifier.dispatch(const MaxValueChanged(null));

      expect(container.read(expensesFiltersProvider).draft.maxValue, isNull);
    });
  });

  group('OrderingSelected', () {
    test('updates the ordering', () {
      final container = _makeContainer();

      container
          .read(expensesFiltersProvider.notifier)
          .dispatch(const OrderingSelected(ExpenseOrdering.valueAsc));

      expect(
        container.read(expensesFiltersProvider).draft.ordering,
        ExpenseOrdering.valueAsc,
      );
    });
  });

  group('Cleared', () {
    test('resets draft and preset', () {
      final container = _makeContainer(now: DateTime(2026, 4, 23));
      final notifier = container.read(expensesFiltersProvider.notifier);

      notifier.dispatch(const PresetSelected(ExpensePeriodPreset.currentMonth));
      notifier.dispatch(const CategorySelected(ExpenseCategory.food));
      notifier.dispatch(const MinValueChanged(10000));

      notifier.dispatch(const Cleared());

      final state = container.read(expensesFiltersProvider);
      expect(state.draft, const ExpenseFilterModel.empty());
      expect(state.selectedPreset, isNull);
    });
  });
}
