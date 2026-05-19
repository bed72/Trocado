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
        category: .food,
        minValue: 5000,
        maxValue: 20000,
        description: 'Merc',
        endDate: DateTime(2026, 3, 31).millisecondsSinceEpoch,
        startDate: DateTime(2026, 3, 1).millisecondsSinceEpoch,
      );

      final query = builder.build(filter: filter, cursor: 'abc');

      expect(
        query,
        'eq(category,food)'
        '&ge(date,2026-03-01)'
        '&le(date,2026-03-31)'
        '&ge(value,50.00)'
        '&le(value,200.00)'
        '&ilike(description,*Merc*)'
        '&page_size=20'
        '&cursor=abc',
      );
    });

    test('percent-encodes description with accents', () {
      final filter = const ExpenseFilterModel.empty().copyWith(
        description: 'Café',
      );

      final query = builder.build(filter: filter, cursor: null);

      expect(query, contains('ilike(description,*Caf%C3%A9*)'));
    });

    test(
      'encodes user-typed asterisks so they are not treated as wildcards',
      () {
        final filter = const ExpenseFilterModel.empty().copyWith(
          description: 'a*b',
        );

        final query = builder.build(filter: filter, cursor: null);

        expect(query, contains('ilike(description,*a%2Ab*)'));
      },
    );

    test('emits ge(value,X.XX) when only minValue is set', () {
      final filter = const ExpenseFilterModel.empty().copyWith(minValue: 5000);

      final query = builder.build(filter: filter, cursor: null);

      expect(query, contains('ge(value,50.00)'));
      expect(query, isNot(contains('le(value')));
    });

    test('emits le(value,X.XX) when only maxValue is set', () {
      final filter = const ExpenseFilterModel.empty().copyWith(maxValue: 5000);

      final query = builder.build(filter: filter, cursor: null);

      expect(query, contains('le(value,50.00)'));
      expect(query, isNot(contains('ge(value')));
    });

    test('combines search and value fragments when both are set', () {
      final filter = const ExpenseFilterModel.empty().copyWith(
        description: 'uber',
        minValue: 3000,
      );

      final query = builder.build(filter: filter, cursor: null);

      expect(query, contains('ge(value,30.00)'));
      expect(query, contains('ilike(description,*uber*)'));
    });

    test('never emits ordering fragments', () {
      final filter = ExpenseFilterModel(
        category: ExpenseCategoryEnum.food,
        startDate: DateTime(2026, 3, 1).millisecondsSinceEpoch,
        endDate: DateTime(2026, 3, 31).millisecondsSinceEpoch,
        description: 'Merc',
      );

      final query = builder.build(filter: filter, cursor: 'abc');

      expect(query, isNot(contains('ordering')));
    });

    test('trims description and skips when empty after trim', () {
      final filter = const ExpenseFilterModel.empty().copyWith(
        description: '   ',
        category: ExpenseCategoryEnum.food,
      );

      final query = builder.build(filter: filter, cursor: null);

      expect(query, isNot(contains('like(description')));
      expect(query, isNot(contains('ilike(description')));
    });
  });
}
