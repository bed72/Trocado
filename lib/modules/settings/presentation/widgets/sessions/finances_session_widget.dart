import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/settings/presentation/dtos/settings_dto.dart';

import 'package:trocado/modules/settings/presentation/widgets/setting_item_widget.dart';
import 'package:trocado/modules/settings/presentation/widgets/sessions/session_widget.dart';

class FinancesSessionWidget extends StatelessWidget {
  final SettingsDto dto;

  const FinancesSessionWidget({super.key, required this.dto});

  @override
  Widget build(BuildContext context) {
    return SessionWidget(
      title: 'Gerenciamento Financeiro',
      children: [
        SettingItemWidget.arrowTile(
          title: 'Carteiras',
          onTap: dto.onWalletsTap,
          icon: LucideIcons.wallet,
        ),
        SettingItemWidget.arrowTile(
          title: 'Cartegorias',
          icon: LucideIcons.library,
          onTap: dto.onCategoriesTap,
        ),
        SettingItemWidget.arrowTile(
          title: 'Metas',
          onTap: dto.onGoalsTap,
          icon: LucideIcons.piggyBank,
        ),
        SettingItemWidget.arrowTile(
          title: 'Dívidas',
          onTap: dto.onDebtsTap,
          icon: LucideIcons.handshake,
        ),
        SettingItemWidget.arrowTile(
          icon: LucideIcons.receiptText,
          title: 'Transações recorrentes',
          onTap: dto.onRecurringTransactionsTap,
        ),
      ],
    );
  }
}
