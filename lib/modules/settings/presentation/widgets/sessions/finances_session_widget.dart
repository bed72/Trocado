import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/settings/presentation/widgets/setting_item_widget.dart';
import 'package:trocado/modules/settings/presentation/widgets/sessions/session_widget.dart';

class FinancesSessionWidget extends StatelessWidget {
  const FinancesSessionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SessionWidget(
      title: 'Gerenciamento Financeiro',
      children: [
        SettingItemWidget.arrowTile(
          title: 'Carteiras',
          icon: LucideIcons.wallet,
          onTap: () {},
        ),
        SettingItemWidget.arrowTile(
          title: 'Cartegorias',
          icon: LucideIcons.library,
          onTap: () {},
        ),
      ],
    );
  }
}
