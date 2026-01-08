import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'package:trocado/modules/core/core.dart';

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
      children: [_buildTheme()],
    );
  }

  Observer _buildTheme() => Observer(
    builder: (context) {
      final store = context.get<ThemeStore>();

      return SettingItemWidget.switchTile(
        value: store.isDark,
        onChanged: store.onChanged,
        icon: dto.darkIcon(store.isDark),
        title: dto.darkTitle(store.isDark),
      );
    },
  );
}
