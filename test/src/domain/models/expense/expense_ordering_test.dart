import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/models/expense/expense_ordering.dart';

void main() {
  group('ExpenseOrdering', () {
    test('query strings match the RQL contract', () {
      expect(ExpenseOrdering.dateDesc.query, '-date');
      expect(ExpenseOrdering.dateAsc.query, 'date');
      expect(ExpenseOrdering.valueDesc.query, '-value');
      expect(ExpenseOrdering.valueAsc.query, 'value');
    });

    test('labels are in pt_BR', () {
      expect(ExpenseOrdering.dateDesc.label, 'Mais recentes');
      expect(ExpenseOrdering.dateAsc.label, 'Mais antigos');
      expect(ExpenseOrdering.valueDesc.label, 'Maior valor');
      expect(ExpenseOrdering.valueAsc.label, 'Menor valor');
    });
  });
}
