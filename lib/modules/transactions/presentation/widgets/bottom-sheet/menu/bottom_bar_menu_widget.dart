import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/transactions/main/type_transaction_location.dart';
import 'package:trocado/modules/transactions/presentation/widgets/bottom-sheet/menu/bottom_bar_menu_item_widget.dart';

class BottomBarMenuWidget extends StatelessWidget {
  const BottomBarMenuWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200.0,
      width: double.infinity,
      child: Row(
        mainAxisAlignment: .spaceEvenly,
        children: [
          Expanded(
            child: Padding(
              padding: .only(right: 4.0),
              child: BottomBarMenuItemWidget(
                title: 'Receita',
                icon: LucideIcons.banknoteArrowUp,
                iconColor: context.colors.primary,
                backgroundColor: context.colors.primary,
                onTap: () => _navigateTo(
                  context: context,
                  title: QuickActionsConstant.input.localizedTitle,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: .only(left: 4.0),
              child: BottomBarMenuItemWidget(
                title: 'Despesa',
                iconColor: context.colors.error,
                icon: LucideIcons.banknoteArrowDown,
                backgroundColor: context.colors.error,
                onTap: () => _navigateTo(
                  context: context,
                  title: QuickActionsConstant.output.localizedTitle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo({required BuildContext context, required String title}) {
    context.navigate(TypeTransactionLocation(title: title), root: true);
  }
}
