import 'package:flutter/widgets.dart';
import 'package:duck_router/duck_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/user/user.dart';
import 'package:trocado/modules/debts/debts.dart';
import 'package:trocado/modules/goals/goals.dart';
import 'package:trocado/modules/wallets/wallets.dart';
import 'package:trocado/modules/categories/categories.dart';
import 'package:trocado/modules/transactions/transactions.dart';

final class SettingsDto {
  final VoidCallback onUserTap;
  final VoidCallback onDebtsTap;
  final VoidCallback onGoalsTap;
  final VoidCallback onWalletsTap;
  final VoidCallback onCategoriesTap;
  final VoidCallback onRecurringTransactionsTap;

  SettingsDto({
    required this.onUserTap,
    required this.onDebtsTap,
    required this.onGoalsTap,
    required this.onWalletsTap,
    required this.onCategoriesTap,
    required this.onRecurringTransactionsTap,
  });

  factory SettingsDto.build(BuildContext context) => SettingsDto(
    onUserTap: () => _navigateTo(context: context, location: UserLocation()),
    onDebtsTap: () => _navigateTo(context: context, location: DebtsLocation()),
    onGoalsTap: () => _navigateTo(context: context, location: GoalsLocation()),
    onWalletsTap: () =>
        _navigateTo(context: context, location: WalletsLocation()),
    onCategoriesTap: () =>
        _navigateTo(context: context, location: CategoriesLocation()),
    onRecurringTransactionsTap: () => _navigateTo(
      context: context,
      location: RecurringTransactionsLocation(),
    ),
  );

  String darkTitle(bool isDark) => isDark ? 'Modo Escuro' : 'Modo Claro';
  IconData darkIcon(bool isDark) => isDark ? LucideIcons.moon : LucideIcons.sun;

  String fingerprintTitle(bool fingerprintEnabled) =>
      fingerprintEnabled ? 'Biometria Ativada' : 'Biometria Desativada';
  IconData fingerprintIcon(bool fingerprintEnabled) =>
      fingerprintEnabled ? LucideIcons.shieldCheck : LucideIcons.shieldX;

  IconData notificationIcon(bool notificationEnabled) =>
      notificationEnabled ? LucideIcons.bell : LucideIcons.bellOff;
  String notificationTitle(bool notificationEnabled) => notificationEnabled
      ? 'Notificações Ativadas'
      : 'Notificações Desativadas';

  static void _navigateTo({
    required BuildContext context,
    required Location location,
  }) {
    context.navigate(location);
  }
}
