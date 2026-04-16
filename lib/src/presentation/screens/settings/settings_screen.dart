import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/screens/settings/notifiers/settings_intent.dart';
import 'package:trocado/src/presentation/screens/settings/notifiers/settings_notifier.dart';

import 'package:trocado/src/presentation/screens/settings/widgets/settings_item_widget.dart';
import 'package:trocado/src/presentation/screens/settings/widgets/settings_logout_widget.dart';
import 'package:trocado/src/presentation/screens/settings/widgets/settings_section_widget.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onSignIn;
  final VoidCallback onEditProfile;
  final VoidCallback onNotification;
  final VoidCallback onSubscription;

  const SettingsScreen({
    super.key,
    required this.onSignIn,
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
        child: Consumer(
          builder: (_, ref, _) {
            ref.listen(
              settingsProvider,
              (previous, next) => switch (next.status) {
                .success when previous?.status != .success => onSignIn(),
                .failure when previous?.status != .failure => showToastWidget(
                  context: context,
                  title: 'Opps',
                  type: .failure,
                  description: next.message,
                ),
                _ => null,
              },
            );

            final settingsState = ref.watch(settingsProvider);
            final settingsNotifier = ref.read(settingsProvider.notifier);

            return Column(
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

                ..._buildAccount,
                ..._buildInformation,

                const Spacer(),

                SettingsLogoutWidget(
                  isLoading: settingsState.status == .loading,
                  onTap: () => settingsNotifier.dispatch(const LogoutPressed()),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Column _buildTitleItem(String label) => Column(
    spacing: 8.0,
    children: [
      const SizedBox(height: 16.0),
      SettingsSectionWidget(label: label),
    ],
  );

  List<Widget> get _buildAccount => [
    _buildTitleItem('Conta'),

    SettingsItemWidget(
      onTap: onEditProfile,
      label: 'Dados pessoais',
      icon: Icons.person_outline,
    ),
    SettingsItemWidget(
      label: 'Notificações',
      onTap: onNotification,
      icon: Icons.notifications_outlined,
    ),
    SettingsItemWidget(
      isPremium: true,
      label: 'Subscrição',
      onTap: onSubscription,
      icon: Icons.star_outline,
    ),
  ];

  List<Widget> get _buildInformation => [
    _buildTitleItem('Informações'),
    SettingsItemWidget(
      onTap: () {},
      label: 'Termos de uso',
      icon: Icons.description_outlined,
    ),
    SettingsItemWidget(
      onTap: () {},
      icon: Icons.shield_outlined,
      label: 'Políticas de privacidade',
    ),
    SettingsItemWidget(label: 'Ajuda', onTap: () {}, icon: Icons.help_outline),
  ];
}
