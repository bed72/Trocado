import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/category/category.dart';
import 'package:trocado/modules/transaction/transaction.dart';

void main() {
  group('CategoryData', () {
    test('categoriesBy returns only income categories', () {
      final data = CategoryDto.categoriesBy(TransactionTypeDto.income);

      expect(data, isNotEmpty);
      expect(
        data.every(
          (category) => category.types.contains(TransactionTypeDto.income),
        ),
        isTrue,
      );
    });

    test('categoriesBy returns only expense categories', () {
      final data = CategoryDto.categoriesBy(TransactionTypeDto.expense);

      expect(data, isNotEmpty);
      expect(
        data.every(
          (category) => category.types.contains(TransactionTypeDto.expense),
        ),
        isTrue,
      );
    });

    test('other category supports both income and expense', () {
      final other = CategoryDto.other;

      expect(
        other.types.containsAll({
          TransactionTypeDto.income,
          TransactionTypeDto.expense,
        }),
        isTrue,
      );
    });
  });
}
