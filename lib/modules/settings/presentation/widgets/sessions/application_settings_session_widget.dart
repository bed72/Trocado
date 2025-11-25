import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/settings/presentation/widgets/setting_item_widget.dart';
import 'package:trocado/modules/settings/presentation/widgets/sessions/session_widget.dart';

class ApplicationSettingsSessionWidget extends StatelessWidget {
  final bool isDark;
  final void Function(bool) onToggleThemes;

  final bool notificationsEnabled;
  final void Function(bool) onToggleNotifications;

  const ApplicationSettingsSessionWidget({
    super.key,
    required this.isDark,
    required this.onToggleThemes,
    required this.notificationsEnabled,
    required this.onToggleNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return SessionWidget(
      title: 'Configurações do Aplicativo',
      children: [
        SettingItemWidget.switchTile(
          value: isDark,
          onChanged: onToggleThemes,
          title: isDark ? 'Modo Escuro' : 'Modo Claro',
          icon: isDark ? LucideIcons.moon : LucideIcons.sun,
        ),

        SettingItemWidget.switchTile(
          value: notificationsEnabled,
          onChanged: onToggleNotifications,
          icon: notificationsEnabled ? LucideIcons.bell : LucideIcons.bellOff,
          title: notificationsEnabled
              ? 'Notificações Ativadas'
              : 'Notificações Desativadas',
        ),
      ],
    );
  }
}
