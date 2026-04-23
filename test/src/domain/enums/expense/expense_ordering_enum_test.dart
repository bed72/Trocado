import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/enums/expense/expense_ordering_enum.dart';

void main() {
  group('ExpenseOrderingEnum', () {
    test('query strings match the RQL contract', () {
      expect(ExpenseOrderingEnum.dateDesc.query, '-date');
      expect(ExpenseOrderingEnum.dateAsc.query, 'date');
      expect(ExpenseOrderingEnum.valueDesc.query, '-value');
      expect(ExpenseOrderingEnum.valueAsc.query, 'value');
    });

    test('labels are in pt_BR', () {
      expect(ExpenseOrderingEnum.dateDesc.label, 'Mais recentes');
      expect(ExpenseOrderingEnum.dateAsc.label, 'Mais antigos');
      expect(ExpenseOrderingEnum.valueDesc.label, 'Maior valor');
      expect(ExpenseOrderingEnum.valueAsc.label, 'Menor valor');
    });
  });
}
