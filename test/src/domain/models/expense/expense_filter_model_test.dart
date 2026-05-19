import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/enums/expense/expense_category_enum.dart';
import 'package:trocado/src/domain/models/expense/expense_filter_model.dart';

void main() {
  group('ExpenseFilterModel', () {
    test('empty() is fully unfiltered', () {
      const filter = ExpenseFilterModel.empty();

      expect(filter.endDate, isNull);
      expect(filter.isEmpty, isTrue);
      expect(filter.category, isNull);
      expect(filter.startDate, isNull);
      expect(filter.description, isEmpty);
    });

    test('isEmpty is false when any field is set', () {
      expect(
        const ExpenseFilterModel.empty().copyWith(category: .food).isEmpty,
        isFalse,
      );
      expect(
        const ExpenseFilterModel.empty().copyWith(startDate: 1).isEmpty,
        isFalse,
      );
      expect(
        const ExpenseFilterModel.empty().copyWith(description: 'hello').isEmpty,
        isFalse,
      );
    });

    test('copyWith overrides fields individually', () {
      const filter = ExpenseFilterModel.empty();

      final updated = filter.copyWith(category: .food, startDate: 100);

      expect(updated.startDate, 100);
      expect(updated.endDate, isNull);
      expect(updated.category, ExpenseCategoryEnum.food);
    });

    test('copyWith clears nullable fields explicitly', () {
      const filter = ExpenseFilterModel(
        endDate: 200,
        startDate: 100,
        category: .food,
      );

      final cleared = filter.copyWith(
        clearEndDate: true,
        clearCategory: true,
        clearStartDate: true,
      );

      expect(cleared.endDate, isNull);
      expect(cleared.category, isNull);
      expect(cleared.startDate, isNull);
    });

    test('props cover every field', () {
      const a = ExpenseFilterModel.empty();
      final c = a.copyWith(category: .food);
      final b = a.copyWith(description: 'x');

      expect(a == b, isFalse);
      expect(a == c, isFalse);
      expect(b == b.copyWith(), isTrue);
    });
  });
}
