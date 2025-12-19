import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/transactions/presentation/widgets/bottom-sheet/menu/bottom_bar_menu_item_widget.dart';

class BottomBarMenuWidget extends StatelessWidget {
  final String type;

  const BottomBarMenuWidget({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200.0,
      width: double.infinity,
      padding: .only(top: 16.0),
      child: Column(children: [_buildType(context)]),
    );
  }

  Row _buildType(BuildContext context) => Row(
    mainAxisAlignment: .spaceEvenly,
    children: [
      Expanded(
        child: Padding(
          padding: .only(right: 4.0),
          child: BottomBarMenuItemWidget(
            onTap: () {},
            title: 'Receita',
            icon: LucideIcons.banknoteArrowUp,
            iconColor: context.colors.primary,
            backgroundColor: context.colors.primary,
          ),
        ),
      ),
      Expanded(
        child: Padding(
          padding: .only(left: 4.0),
          child: BottomBarMenuItemWidget(
            onTap: () {},
            title: 'Despesa',
            iconColor: context.colors.error,
            icon: LucideIcons.banknoteArrowDown,
            backgroundColor: context.colors.error,
          ),
        ),
      ),
    ],
  );
}
