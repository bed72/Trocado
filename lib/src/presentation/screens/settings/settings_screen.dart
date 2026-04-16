import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/screens/settings/widgets/settings_item_widget.dart';
import 'package:trocado/src/presentation/screens/settings/widgets/settings_logout_widget.dart';
import 'package:trocado/src/presentation/screens/settings/widgets/settings_section_widget.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onEditProfile;
  final VoidCallback onNotification;
  final VoidCallback onSubscription;

  const SettingsScreen({
    super.key,
    required this.onLogout,
    required this.onEditProfile,
    required this.onNotification,
    required this.onSubscription,
  });

  @override
  Widget build(BuildContext context) {
    return ScaffoldWidget(
      appBar: AppBarWidget(leading: GoBackWidget()),
      child: Padding(
        padding: const .all(16.0),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Text(
              'Configurações',
              style: context.typography.headlineMedium?.copyWith(
                fontWeight: .bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Gerencie suas preferências e dados da conta.',
              style: context.typography.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24.0),
            const SettingsSectionWidget(label: 'Conta'),
            const SizedBox(height: 8.0),
            SettingsItemWidget(
              onTap: onEditProfile,
              label: 'Edit Profile',
              icon: Icons.person_outline,
            ),
            SettingsItemWidget(
              label: 'Notification',
              onTap: onNotification,
              icon: Icons.notifications_outlined,
            ),
            SettingsItemWidget(
              isPremium: true,
              label: 'Subscription',
              onTap: onSubscription,
              icon: Icons.star_outline,
            ),
            const Spacer(),
            SettingsLogoutWidget(onTap: onLogout),
          ],
        ),
      ),
    );
  }
}
