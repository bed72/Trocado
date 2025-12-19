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

  final bool isDark;
  final ValueChanged<bool> onToggleThemes;

  final bool fingerprintEnabled;
  final ValueChanged<bool> onToggleFingerprint;

  final bool notificationsEnabled;
  final ValueChanged<bool> onToggleNotifications;

  SettingsDto({
    required this.isDark,
    required this.onToggleThemes,
    required this.fingerprintEnabled,
    required this.onToggleFingerprint,
    required this.notificationsEnabled,
    required this.onToggleNotifications,
    required this.onUserTap,
    required this.onDebtsTap,
    required this.onGoalsTap,
    required this.onWalletsTap,
    required this.onCategoriesTap,
    required this.onRecurringTransactionsTap,
  });

  factory SettingsDto.build({
    required BuildContext context,
    required bool isDark,
    required ValueChanged<bool> onToggleThemes,
    required bool fingerprintEnabled,
    required ValueChanged<bool> onToggleFingerprint,
    required bool notificationsEnabled,
    required ValueChanged<bool> onToggleNotifications,
  }) => SettingsDto(
    isDark: isDark,
    onToggleThemes: onToggleThemes,
    fingerprintEnabled: fingerprintEnabled,
    onToggleFingerprint: onToggleFingerprint,
    notificationsEnabled: notificationsEnabled,
    onToggleNotifications: onToggleNotifications,
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

  String get darkTitle => isDark ? 'Modo Escuro' : 'Modo Claro';
  IconData get darkIcon => isDark ? LucideIcons.moon : LucideIcons.sun;

  String get fingerprintTitle =>
      fingerprintEnabled ? 'Biometria Ativada' : 'Biometria Desativada';
  IconData get fingerprintIcon =>
      fingerprintEnabled ? LucideIcons.shieldCheck : LucideIcons.shieldX;

  String get notificationsTitle => notificationsEnabled
      ? 'Notificações Ativadas'
      : 'Notificações Desativadas';
  IconData get notificationsIcon =>
      notificationsEnabled ? LucideIcons.bell : LucideIcons.bellOff;

  static void _navigateTo({
    required BuildContext context,
    required Location location,
  }) {
    context.navigate(location);
  }
}
