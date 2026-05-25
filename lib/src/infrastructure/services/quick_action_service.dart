import 'package:quick_actions/quick_actions.dart';

import 'package:trocado/src/domain/services/interface_quick_action_service.dart';

enum _QuickActionsConstant {
  budget(
    icon: 'ic_bank_arrow_up',
    localizedTitle: 'Novo orçamento',
    localizedSubtitle: 'Cadastrar novo orçamento.',
  ),
  expense(
    icon: 'ic_bank_arrow_down',
    localizedTitle: 'Nova despesa',
    localizedSubtitle: 'Cadastrar nova despesa.',
  );

  final String icon;
  final String localizedTitle;
  final String localizedSubtitle;

  const _QuickActionsConstant({
    required this.icon,
    required this.localizedTitle,
    required this.localizedSubtitle,
  });
}

final class QuickActionService implements IQuickActionService {
  @override
  void register({
    required void Function() onBudget,
    required void Function() onExpense,
  }) {
    QuickActions()
      ..initialize((type) {
        if (type == _QuickActionsConstant.budget.name) {
          onBudget();
        } else {
          onExpense();
        }
      })
      ..setShortcutItems(_items);
  }

  @override
  void clear() {
    QuickActions().setShortcutItems([]);
  }
}

List<ShortcutItem> get _items => <ShortcutItem>[
  ShortcutItem(
    icon: _QuickActionsConstant.expense.icon,
    type: _QuickActionsConstant.expense.name,
    localizedTitle: _QuickActionsConstant.expense.localizedTitle,
    localizedSubtitle: _QuickActionsConstant.expense.localizedSubtitle,
  ),
  ShortcutItem(
    icon: _QuickActionsConstant.budget.icon,
    type: _QuickActionsConstant.budget.name,
    localizedTitle: _QuickActionsConstant.budget.localizedTitle,
    localizedSubtitle: _QuickActionsConstant.budget.localizedSubtitle,
  ),
];
