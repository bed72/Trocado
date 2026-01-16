import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/category/category.dart';
import 'package:trocado/modules/transaction/transaction.dart';

void main() {
  group('CategoryData', () {
    test('categoriesBy returns only income categories', () {
      final data = CategoryData.categoriesBy(TransactionTypeData.income);

      expect(data, isNotEmpty);
      expect(
        data.every(
          (category) => category.types.contains(TransactionTypeData.income),
        ),
        isTrue,
      );
    });

    test('categoriesBy returns only expense categories', () {
      final data = CategoryData.categoriesBy(TransactionTypeData.expense);

      expect(data, isNotEmpty);
      expect(
        data.every(
          (category) => category.types.contains(TransactionTypeData.expense),
        ),
        isTrue,
      );
    });

    test('other category supports both income and expense', () {
      final other = CategoryData.other;

      expect(
        other.types.containsAll({
          TransactionTypeData.income,
          TransactionTypeData.expense,
        }),
        isTrue,
      );
    });
  });
}
