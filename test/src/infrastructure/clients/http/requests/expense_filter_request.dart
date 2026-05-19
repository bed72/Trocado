import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/enums/expense/expense_category_enum.dart';
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
        category: ExpenseCategoryEnum.food,
        startDate: DateTime(2026, 3, 1).millisecondsSinceEpoch,
        endDate: DateTime(2026, 3, 31).millisecondsSinceEpoch,
        description: 'Merc',
      );

      final query = builder.build(filter: filter, cursor: 'abc');

      expect(
        query,
        'eq(category,food)'
        '&ge(date,2026-03-01)'
        '&le(date,2026-03-31)'
        '&like(description,Merc*)'
        '&page_size=20'
        '&cursor=abc',
      );
    });

    test('percent-encodes description with accents', () {
      final filter = const ExpenseFilterModel.empty().copyWith(
        description: 'Café',
      );

      final query = builder.build(filter: filter, cursor: null);

      expect(query, contains('like(description,Caf%C3%A9*)'));
    });

    test('never emits value or ordering fragments', () {
      final filter = ExpenseFilterModel(
        category: ExpenseCategoryEnum.food,
        startDate: DateTime(2026, 3, 1).millisecondsSinceEpoch,
        endDate: DateTime(2026, 3, 31).millisecondsSinceEpoch,
        description: 'Merc',
      );

      final query = builder.build(filter: filter, cursor: 'abc');

      expect(query, isNot(contains('ordering')));
      expect(query, isNot(contains('ge(value')));
      expect(query, isNot(contains('le(value')));
    });

    test('trims description and skips when empty after trim', () {
      final filter = const ExpenseFilterModel.empty().copyWith(
        description: '   ',
        category: ExpenseCategoryEnum.food,
      );

      final query = builder.build(filter: filter, cursor: null);

      expect(query, isNot(contains('like(description')));
    });
  });
}
