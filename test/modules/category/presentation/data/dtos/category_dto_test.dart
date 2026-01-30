import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/category/category.dart';
import 'package:trocado/modules/transaction/transaction.dart';

void main() {
  group('CategoryDto', () {
    test('returns correct category when label exists', () {
      final category = CategoryModel.fromByString('Salário');

      expect(category, CategoryModel.salary);
    });

    test('returns correct category for expense label', () {
      final category = CategoryModel.fromByString('Alimentação');

      expect(category, CategoryModel.food);
    });

    test('returns CategoryDto.other when label does not exist', () {
      final category = CategoryModel.fromByString('Categoria inexistente');

      expect(category, CategoryModel.other);
    });

    test('returns CategoryDto.other when label is empty', () {
      final category = CategoryModel.fromByString('');

      expect(category, CategoryModel.other);
    });

    test('is case sensitive (current behavior)', () {
      final category = CategoryModel.fromByString('salário');

      expect(category, CategoryModel.other);
    });

    test('other category supports both income and expense', () {
      final other = CategoryModel.other;

      expect(
        other.types.containsAll({
          TransactionTypeModel.income,
          TransactionTypeModel.expense,
        }),
        isTrue,
      );
    });
  });
}
