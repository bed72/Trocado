import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/models/expense/expense_category.dart';
import 'package:trocado/src/domain/models/expense/expense_ordering.dart';
import 'package:trocado/src/domain/models/expense/expense_filter_model.dart';

import 'package:trocado/src/infrastructure/clients/http/requests/expense_filter_request.dart';

void main() {
  const builder = ExpenseFilterRequest();

  group('ExpenseFilterRqlBuilder.build', () {
    test('returns empty string when filter and cursor are both null', () {
      expect(builder.build(filter: null, cursor: null), '');
    });

    test('returns only cursor when filter is null', () {
      expect(builder.build(filter: null, cursor: 'abc'), 'cursor=abc');
    });

    test('treats isEmpty filter as no filter', () {
      expect(
        builder.build(filter: const ExpenseFilterModel.empty(), cursor: null),
        '',
      );
      expect(
        builder.build(filter: const ExpenseFilterModel.empty(), cursor: 'abc'),
        'cursor=abc',
      );
    });

    test('preserves the documented fragment ordering with all fields set', () {
      final filter = ExpenseFilterModel(
        category: ExpenseCategory.food,
        startDate: DateTime(2026, 3, 1).millisecondsSinceEpoch,
        endDate: DateTime(2026, 3, 31).millisecondsSinceEpoch,
        minValue: 100,
        maxValue: 50000,
        description: 'Merc',
        ordering: ExpenseOrdering.valueDesc,
      );

      final query = builder.build(filter: filter, cursor: 'abc');

      expect(
        query,
        'eq(category,food)'
        '&ge(date,2026-03-01)'
        '&le(date,2026-03-31)'
        '&ge(value,1.00)'
        '&le(value,500.00)'
        '&like(description,Merc*)'
        '&ordering=-value'
        '&page_size=20'
        '&cursor=abc',
      );
    });

    test('formats decimal values with two decimal places', () {
      final filter = const ExpenseFilterModel.empty().copyWith(minValue: 9);

      final query = builder.build(filter: filter, cursor: null);

      expect(query, contains('ge(value,0.09)'));

      final filter2 = const ExpenseFilterModel.empty().copyWith(minValue: 100);
      expect(
        builder.build(filter: filter2, cursor: null),
        contains('ge(value,1.00)'),
      );
    });

    test('omits value fragments when centavos is zero', () {
      final filter = const ExpenseFilterModel.empty().copyWith(
        minValue: 0,
        maxValue: 0,
        category: ExpenseCategory.food,
      );

      final query = builder.build(filter: filter, cursor: null);

      expect(query, isNot(contains('ge(value')));
      expect(query, isNot(contains('le(value')));
      expect(query, contains('eq(category,food)'));
    });

    test('percent-encodes description with accents', () {
      final filter = const ExpenseFilterModel.empty().copyWith(
        description: 'Café',
      );

      final query = builder.build(filter: filter, cursor: null);

      expect(query, contains('like(description,Caf%C3%A9*)'));
    });

    test('emits ordering even when it matches the default', () {
      final filter = const ExpenseFilterModel.empty().copyWith(
        category: ExpenseCategory.food,
      );

      final query = builder.build(filter: filter, cursor: null);

      expect(query, contains('ordering=-date'));
    });

    test('omits ordering when filter is null', () {
      expect(
        builder.build(filter: null, cursor: 'abc'),
        isNot(contains('ordering')),
      );
    });

    test('trims description and skips when empty after trim', () {
      final filter = const ExpenseFilterModel.empty().copyWith(
        description: '   ',
        category: ExpenseCategory.food,
      );

      final query = builder.build(filter: filter, cursor: null);

      expect(query, isNot(contains('like(description')));
    });
  });
}
