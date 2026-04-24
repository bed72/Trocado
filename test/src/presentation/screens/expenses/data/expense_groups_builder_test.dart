import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:trocado/src/domain/models/expense/expense_model.dart';
import 'package:trocado/src/domain/enums/expense/expense_category_enum.dart';

import 'package:trocado/src/presentation/data/expense_item_data.dart';

import 'package:trocado/src/presentation/ui/expenses/data/expense_groups_builder.dart';

ExpenseItemData _item({required int id, required DateTime date}) =>
    ExpenseItemData(
      expense: ExpenseModel(
        id: id,
        value: 1000,
        date: date.millisecondsSinceEpoch,
        createdAt: date.millisecondsSinceEpoch,
        description: 'Expense #$id',
        category: ExpenseCategoryEnum.food,
      ),
      formattedValue: 'R\$ 10,00',
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  group('buildExpenseGroups', () {
    test('returns empty list for empty input', () {
      expect(buildExpenseGroups(const []), isEmpty);
    });

    test('groups same-day items under a single "Hoje" header', () {
      final now = DateTime(2026, 4, 22, 22, 0);
      final items = [
        _item(id: 1, date: DateTime(2026, 4, 22, 18, 0)),
        _item(id: 2, date: DateTime(2026, 4, 22, 10, 0)),
      ];

      final groups = buildExpenseGroups(items, now: now);

      expect(groups, hasLength(1));
      expect(groups.first.header, 'Hoje');
      expect(groups.first.expenses.map((item) => item.expense.id), [1, 2]);
    });

    test('emits "Hoje" and "Ontem" in input order', () {
      final now = DateTime(2026, 4, 22, 22, 0);
      final items = [
        _item(id: 1, date: DateTime(2026, 4, 22, 18, 0)),
        _item(id: 2, date: DateTime(2026, 4, 22, 10, 0)),
        _item(id: 3, date: DateTime(2026, 4, 21, 20, 0)),
      ];

      final groups = buildExpenseGroups(items, now: now);

      expect(groups.map((group) => group.header), ['Hoje', 'Ontem']);
      expect(groups.first.expenses.map((item) => item.expense.id), [1, 2]);
      expect(groups.last.expenses.map((item) => item.expense.id), [3]);
    });

    test('uses "Weekday, dd mmm" for dates within the week', () {
      final now = DateTime(2026, 4, 18, 10, 0);
      final items = [_item(id: 1, date: DateTime(2026, 4, 15, 12, 0))];

      final groups = buildExpenseGroups(items, now: now);

      expect(groups, hasLength(1));
      expect(groups.first.header, 'Quarta-feira, 15 abr.');
    });

    test('uses "MMMM yyyy" header for older months', () {
      final now = DateTime(2026, 4, 20, 10, 0);
      final items = [_item(id: 1, date: DateTime(2026, 3, 15, 12, 0))];

      final groups = buildExpenseGroups(items, now: now);

      expect(groups, hasLength(1));
      expect(groups.first.header, 'Março 2026');
    });

    test('preserves input order across groups', () {
      final now = DateTime(2026, 4, 22, 10, 0);
      final items = [
        _item(id: 1, date: DateTime(2026, 4, 22, 9, 0)),
        _item(id: 2, date: DateTime(2026, 3, 10, 9, 0)),
        _item(id: 3, date: DateTime(2026, 4, 21, 9, 0)),
      ];

      final groups = buildExpenseGroups(items, now: now);

      expect(groups.map((group) => group.header), [
        'Hoje',
        'Março 2026',
        'Ontem',
      ]);
      expect(groups[0].expenses.single.expense.id, 1);
      expect(groups[1].expenses.single.expense.id, 2);
      expect(groups[2].expenses.single.expense.id, 3);
    });
  });
}
