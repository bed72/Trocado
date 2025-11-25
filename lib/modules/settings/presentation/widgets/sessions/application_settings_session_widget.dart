import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/settings/presentation/dtos/settings_dto.dart';

import 'package:trocado/modules/settings/presentation/widgets/setting_item_widget.dart';
import 'package:trocado/modules/settings/presentation/widgets/sessions/session_widget.dart';

class ApplicationSettingsSessionWidget extends StatelessWidget {
  final SettingsDto dto;

  const ApplicationSettingsSessionWidget({super.key, required this.dto});

  @override
  Widget build(BuildContext context) {
    return SessionWidget(
      title: 'Configurações do Aplicativo',
      children: [
        SettingItemWidget.switchTile(
          value: dto.isDark,
          icon: dto.darkIcon,
          title: dto.darkTitle,
          onChanged: dto.onToggleThemes,
        ),
        SettingItemWidget.switchTile(
          value: dto.notificationsEnabled,
          icon: dto.notificationsIcon,
          title: dto.notificationsTitle,
          onChanged: dto.onToggleNotifications,
        ),
        SettingItemWidget.switchTile(
          icon: dto.fingerprintIcon,
          title: dto.fingerprintTitle,
          value: dto.fingerprintEnabled,
          onChanged: dto.onToggleFingerprint,
        ),
        SettingItemWidget.arrowTile(
          title: 'Dados pessoais',
          onTap: dto.onUserTap,
          icon: LucideIcons.userRound,
        ),
      ],
    );
  }
}
