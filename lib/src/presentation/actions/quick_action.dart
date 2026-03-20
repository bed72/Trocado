import 'package:flutter/material.dart';

import 'package:quick_actions/quick_actions.dart';

enum QuickActionsConstant {
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

  const QuickActionsConstant({
    required this.icon,
    required this.localizedTitle,
    required this.localizedSubtitle,
  });
}

void quickAction({required ValueChanged<String> action}) {
  QuickActions()
    ..initialize(action)
    ..setShortcutItems(_items);
}

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
