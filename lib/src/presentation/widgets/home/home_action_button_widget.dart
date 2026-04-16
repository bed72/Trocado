import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/icons/icon_widget.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

class HomeActionButtonWidget extends StatelessWidget {
  final VoidCallback onNavigateToBudget;
  final VoidCallback onNavigateToExpense;

  const HomeActionButtonWidget({
    super.key,
    required this.onNavigateToBudget,
    required this.onNavigateToExpense,
  });

  @override
  Widget build(BuildContext context) {
    return ExpandableFab(
      distance: 66.0,
      elevation: 0.0,
      openButtonBuilder: RotateFloatingActionButtonBuilder(
        elevation: 0.0,
        child: BounceWidget.withoutOnPress(
          child: Container(
            width: 56.0,
            height: 56.0,
            alignment: .center,
            child: IconWidget(size: 26.0, icon: Icons.menu),
          ),
        ),
      ),
      children: [
        BounceWidget.withOnPress(
          onPress: onNavigateToExpense,
          child: Container(
            width: 56.0,
            height: 56.0,
            alignment: .center,
            decoration: BoxDecoration(
              color: context.colors.primary,
              borderRadius: context.radius.cornerRadius300,
            ),
            child: IconWidget(
              size: 26.0,
              color: context.colors.onPrimary,
              icon: Icons.receipt_long_outlined,
            ),
          ),
        ),
        BounceWidget.withOnPress(
          onPress: onNavigateToBudget,
          child: Container(
            width: 56.0,
            height: 56.0,
            alignment: .center,
            decoration: BoxDecoration(
              color: context.colors.primary,
              borderRadius: context.radius.cornerRadius300,
            ),
            child: IconWidget(
              size: 26.0,
              color: context.colors.onPrimary,
              icon: Icons.wallet_outlined,
            ),
          ),
        ),
      ],
    );
  }
}
