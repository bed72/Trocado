import 'package:quick_actions/quick_actions.dart';

import 'package:trocado/src/domain/services/interface_quick_action_service.dart';
import 'package:trocado/src/infrastructure/services/quick_actions_constant.dart';

final class QuickActionService implements IQuickActionService {
  List<ShortcutItem> get _items => <ShortcutItem>[
    ShortcutItem(
      icon: QuickActionsConstant.expense.icon,
      type: QuickActionsConstant.expense.name,
      localizedTitle: QuickActionsConstant.expense.localizedTitle,
      localizedSubtitle: QuickActionsConstant.expense.localizedSubtitle,
    ),
    ShortcutItem(
      icon: QuickActionsConstant.budget.icon,
      type: QuickActionsConstant.budget.name,
      localizedTitle: QuickActionsConstant.budget.localizedTitle,
      localizedSubtitle: QuickActionsConstant.budget.localizedSubtitle,
    ),
  ];

  @override
  void register({
    required void Function() onBudget,
    required void Function() onExpense,
  }) {
    QuickActions()
      ..initialize((type) {
        if (type == QuickActionsConstant.budget.name) {
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
