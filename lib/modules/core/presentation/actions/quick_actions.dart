import 'package:flutter/material.dart';

import 'package:quick_actions/quick_actions.dart';

import 'package:trocado/modules/core/domain/constant/quick_actions_constant.dart';

void quickAction({required ValueChanged<String> action}) {
  QuickActions()
    ..initialize(action)
    ..setShortcutItems(_items);
}

List<ShortcutItem> get _items => <ShortcutItem>[
  ShortcutItem(
    icon: QuickActionsConstant.output.icon,
    type: QuickActionsConstant.output.name,
    localizedTitle: QuickActionsConstant.output.localizedTitle,
    localizedSubtitle: QuickActionsConstant.output.localizedSubtitle,
  ),
  ShortcutItem(
    icon: QuickActionsConstant.input.icon,
    type: QuickActionsConstant.input.name,
    localizedTitle: QuickActionsConstant.input.localizedTitle,
    localizedSubtitle: QuickActionsConstant.input.localizedSubtitle,
  ),
];
