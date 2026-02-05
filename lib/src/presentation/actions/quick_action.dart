import 'package:flutter/material.dart';

import 'package:quick_actions/quick_actions.dart';

enum QuickActionsConstant {
  input(
    icon: 'ic_bank_arrow_up',
    localizedTitle: 'Nova transação',
    localizedSubtitle: 'Cadastrar uma nova transação',
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
    icon: QuickActionsConstant.input.icon,
    type: QuickActionsConstant.input.name,
    localizedTitle: QuickActionsConstant.input.localizedTitle,
    localizedSubtitle: QuickActionsConstant.input.localizedSubtitle,
  ),
];
