import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/enums/expense/expense_category_enum.dart';
import 'package:trocado/src/domain/enums/expense/expense_ordering_enum.dart';
import 'package:trocado/src/domain/models/expense/expense_filter_model.dart';

void main() {
  group('ExpenseFilterModel', () {
    test('empty() is fully unfiltered', () {
      const filter = ExpenseFilterModel.empty();

      expect(filter.category, isNull);
      expect(filter.startDate, isNull);
      expect(filter.endDate, isNull);
      expect(filter.minValue, isNull);
      expect(filter.maxValue, isNull);
      expect(filter.description, isEmpty);
      expect(filter.ordering, ExpenseOrderingEnum.dateDesc);
      expect(filter.isEmpty, isTrue);
    });

    test('isEmpty is false when any field is set', () {
      expect(
        const ExpenseFilterModel.empty()
            .copyWith(category: ExpenseCategoryEnum.food)
            .isEmpty,
        isFalse,
      );
      expect(
        const ExpenseFilterModel.empty()
            .copyWith(startDate: 1)
            .isEmpty,
        isFalse,
      );
      expect(
        const ExpenseFilterModel.empty()
            .copyWith(ordering: ExpenseOrderingEnum.valueDesc)
            .isEmpty,
        isFalse,
      );
      expect(
        const ExpenseFilterModel.empty()
            .copyWith(description: 'hello')
            .isEmpty,
        isFalse,
      );
    });

    test('copyWith overrides fields individually', () {
      const filter = ExpenseFilterModel.empty();

      final updated = filter.copyWith(
        category: ExpenseCategoryEnum.food,
        minValue: 1000,
      );

      expect(updated.category, ExpenseCategoryEnum.food);
      expect(updated.minValue, 1000);
      expect(updated.maxValue, isNull);
    });

    test('copyWith clears nullable fields explicitly', () {
      const filter = ExpenseFilterModel(
        category: ExpenseCategoryEnum.food,
        startDate: 100,
        endDate: 200,
        minValue: 1000,
        maxValue: 5000,
      );

      final cleared = filter.copyWith(
        clearCategory: true,
        clearStartDate: true,
        clearEndDate: true,
        clearMinValue: true,
        clearMaxValue: true,
      );

      expect(cleared.category, isNull);
      expect(cleared.startDate, isNull);
      expect(cleared.endDate, isNull);
      expect(cleared.minValue, isNull);
      expect(cleared.maxValue, isNull);
    });

    test('props cover every field', () {
      const a = ExpenseFilterModel.empty();
      final b = a.copyWith(description: 'x');
      final c = a.copyWith(ordering: ExpenseOrderingEnum.valueAsc);

      expect(a == b, isFalse);
      expect(a == c, isFalse);
      expect(b == b.copyWith(), isTrue);
    });
  });

  group('normalized', () {
    test('swaps min and max when inverted', () {
      final filter = const ExpenseFilterModel.empty().copyWith(
        minValue: 10000,
        maxValue: 7200,
      );

      final normalized = filter.normalized();

      expect(normalized.minValue, 7200);
      expect(normalized.maxValue, 10000);
    });

    test('is a no-op when bounds are in order', () {
      final filter = const ExpenseFilterModel.empty().copyWith(
        minValue: 1000,
        maxValue: 5000,
      );

      expect(filter.normalized(), filter);
    });

    test('is a no-op when bounds are equal', () {
      final filter = const ExpenseFilterModel.empty().copyWith(
        minValue: 5000,
        maxValue: 5000,
      );

      expect(filter.normalized(), filter);
    });

    test('is a no-op when either bound is null', () {
      final minOnly = const ExpenseFilterModel.empty().copyWith(minValue: 1000);
      final maxOnly = const ExpenseFilterModel.empty().copyWith(maxValue: 1000);

      expect(minOnly.normalized(), minOnly);
      expect(maxOnly.normalized(), maxOnly);
    });
  });
}
