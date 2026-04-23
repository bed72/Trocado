import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/icons/icon_widget.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

class HomeActionButtonWidget extends StatelessWidget {
  final VoidCallback onChat;
  final VoidCallback onBudget;
  final VoidCallback onExpense;

  const HomeActionButtonWidget({
    super.key,
    required this.onChat,
    required this.onBudget,
    required this.onExpense,
  });

  @override
  Widget build(BuildContext context) {
    return ExpandableFab(
      distance: 80.0,
      elevation: 0.0,
      openButtonBuilder: RotateFloatingActionButtonBuilder(
        elevation: 0.0,
        shape: RoundedRectangleBorder(
          borderRadius: context.radius.cornerRadius100,
        ),
        child: BounceWidget.withoutOnPress(
          child: Container(
            width: 48.0,
            height: 48.0,
            alignment: .center,
            child: IconWidget(size: 20.0, icon: Icons.menu),
          ),
        ),
      ),
      children: [
        BounceWidget.withOnPress(
          onPress: onExpense,
          child: Container(
            width: 48.0,
            height: 48.0,
            alignment: .center,
            decoration: BoxDecoration(
              color: context.colors.primary,
              borderRadius: context.radius.cornerRadius100,
            ),
            child: IconWidget(
              size: 20.0,
              color: context.colors.onPrimary,
              icon: Icons.receipt_long_outlined,
            ),
          ),
        ),
        BounceWidget.withOnPress(
          onPress: onChat,
          child: Container(
            width: 48.0,
            height: 48.0,
            alignment: .center,
            decoration: BoxDecoration(
              color: context.colors.primary,
              borderRadius: context.radius.cornerRadius100,
            ),
            child: IconWidget(
              size: 20.0,
              color: context.colors.onPrimary,
              icon: Icons.chat_sharp,
            ),
          ),
        ),
        BounceWidget.withOnPress(
          onPress: onBudget,
          child: Container(
            width: 48.0,
            height: 48.0,
            alignment: .center,
            decoration: BoxDecoration(
              color: context.colors.primary,
              borderRadius: context.radius.cornerRadius100,
            ),
            child: IconWidget(
              size: 20.0,
              color: context.colors.onPrimary,
              icon: Icons.savings_outlined,
            ),
          ),
        ),
      ],
    );
  }
}
