import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/models/expense/expense_model.dart';
import 'package:trocado/src/domain/services/interface_date_formatter_service.dart';

import 'package:trocado/src/presentation/data/expense_item_presentation_data.dart';

import 'package:trocado/src/presentation/ui/expenses/data/expense_groups_builder.dart';

import '../../../../../mocks/mocks.dart';

ExpenseItemPresentationData _item({required int id, required int millis}) =>
    ExpenseItemPresentationData(
      expense: ExpenseModel(
        id: id,
        value: 1000,
        date: millis,
        category: .food,
        createdAt: millis,
        description: 'Expense #$id',
      ),
      formattedDate: '01 de Jan de 2026',
      formattedValue: 'R\$ 10,00',
    );

void main() {
  late IDateFormatterService dateFormatter;

  setUp(() {
    dateFormatter = MockDateFormatterService();
  });

  group('buildExpenseGroups', () {
    test('returns empty list for empty input', () {
      expect(
        buildExpenseGroups(const [], dateFormatter: dateFormatter),
        isEmpty,
      );
    });

    test('groups items sharing the same header', () {
      const today = 1714000000000;
      const todayLater = 1714050000000;
      when(() => dateFormatter.relativeGroupHeader(today)).thenReturn('Hoje');
      when(
        () => dateFormatter.relativeGroupHeader(todayLater),
      ).thenReturn('Hoje');

      final groups = buildExpenseGroups([
        _item(id: 1, millis: today),
        _item(id: 2, millis: todayLater),
      ], dateFormatter: dateFormatter);

      expect(groups, hasLength(1));
      expect(groups.first.header, 'Hoje');
      expect(groups.first.expenses.map((item) => item.expense.id), [1, 2]);
    });

    test('starts a new group when header changes', () {
      const todayA = 1714000000000;
      const todayB = 1714050000000;
      const yesterday = 1713900000000;
      when(() => dateFormatter.relativeGroupHeader(todayA)).thenReturn('Hoje');
      when(() => dateFormatter.relativeGroupHeader(todayB)).thenReturn('Hoje');
      when(
        () => dateFormatter.relativeGroupHeader(yesterday),
      ).thenReturn('Ontem');

      final groups = buildExpenseGroups([
        _item(id: 1, millis: todayA),
        _item(id: 2, millis: todayB),
        _item(id: 3, millis: yesterday),
      ], dateFormatter: dateFormatter);

      expect(groups.map((group) => group.header), ['Hoje', 'Ontem']);
      expect(groups.last.expenses.map((item) => item.expense.id), [3]);
      expect(groups.first.expenses.map((item) => item.expense.id), [1, 2]);
    });

    test('preserves input order across groups', () {
      const today = 1714000000000;
      const older = 1700000000000;
      const yesterday = 1713900000000;
      when(() => dateFormatter.relativeGroupHeader(today)).thenReturn('Hoje');
      when(
        () => dateFormatter.relativeGroupHeader(older),
      ).thenReturn('Março 2026');
      when(
        () => dateFormatter.relativeGroupHeader(yesterday),
      ).thenReturn('Ontem');

      final groups = buildExpenseGroups([
        _item(id: 1, millis: today),
        _item(id: 2, millis: older),
        _item(id: 3, millis: yesterday),
      ], dateFormatter: dateFormatter);

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
