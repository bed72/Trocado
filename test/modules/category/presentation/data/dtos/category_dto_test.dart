import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/category/category.dart';
import 'package:trocado/modules/transaction/transaction.dart';

void main() {
  group('CategoryDto', () {
    test('returns correct category when label exists', () {
      final category = CategoryDto.fromByString('Salário');

      expect(category, CategoryDto.salary);
    });

    test('returns correct category for expense label', () {
      final category = CategoryDto.fromByString('Alimentação');

      expect(category, CategoryDto.food);
    });

    test('returns CategoryDto.other when label does not exist', () {
      final category = CategoryDto.fromByString('Categoria inexistente');

      expect(category, CategoryDto.other);
    });

    test('returns CategoryDto.other when label is empty', () {
      final category = CategoryDto.fromByString('');

      expect(category, CategoryDto.other);
    });

    test('is case sensitive (current behavior)', () {
      final category = CategoryDto.fromByString('salário');

      expect(category, CategoryDto.other);
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
