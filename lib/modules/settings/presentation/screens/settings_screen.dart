import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/settings/presentation/widgets/profile_widget.dart';
import 'package:trocado/modules/settings/presentation/widgets/sessions/finances_session_widget.dart';
import 'package:trocado/modules/settings/presentation/widgets/sessions/application_settings_session_widget.dart';

class SettingsScreen extends StatelessWidget {
  final bool isDark;
  final void Function(bool) onToggleThemes;

  final bool notificationsEnabled;
  final void Function(bool) onToggleNotifications;

  const SettingsScreen({
    super.key,
    required this.isDark,
    required this.onToggleThemes,
    required this.notificationsEnabled,
    required this.onToggleNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(title: 'Configurações'),
      body: SafeArea(
        child: Padding(
          padding: const .symmetric(horizontal: 20.0),
          child: ListView(
            children: [
              const SizedBox(height: 32.0),
              ProfileWidget(
                name: 'Bed',
                email: 'bed@gmail.com',
                onEdit: () {},
                url:
                    'https://avatars.githubusercontent.com/u/30250307?s=96&v=4',
              ),
              FinancesSessionWidget(),
              ApplicationSettingsSessionWidget(
                isDark: isDark,
                onToggleThemes: onToggleThemes,
                notificationsEnabled: notificationsEnabled,
                onToggleNotifications: onToggleNotifications,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
