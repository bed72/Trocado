import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';

import 'package:trocado/src/presentation/ui/settings/notifiers/settings_intent.dart';
import 'package:trocado/src/presentation/ui/settings/notifiers/settings_notifier.dart';

import 'package:trocado/src/presentation/ui/settings/widgets/settings_card_widget.dart';
import 'package:trocado/src/presentation/ui/settings/widgets/settings_item_widget.dart';
import 'package:trocado/src/presentation/ui/settings/widgets/settings_logout_widget.dart';
import 'package:trocado/src/presentation/ui/settings/widgets/settings_section_widget.dart';
import 'package:trocado/src/presentation/ui/settings/widgets/settings_invite_partner_widget.dart';

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
                const ScreenHeaderWidget(
                  title: 'Configurações',
                  description: 'Gerencie suas preferências.',
                ),

                const SizedBox(height: 8.0),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        ..._buildCouple,
                        ..._buildAccount,
                        ..._buildInformation,
                      ],
                    ),
                  ),
                ),

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

  List<Widget> get _buildCouple => [
    _buildTitleItem('Casal'),
    const SizedBox(height: 8.0),
    SettingsInvitePartnerWidget(onTap: () {}),
  ];

  List<Widget> get _buildAccount => [
    _buildTitleItem('Conta'),
    const SizedBox(height: 8.0),
    SettingsCardWidget(
      children: [
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
      ],
    ),
  ];

  List<Widget> get _buildInformation => [
    _buildTitleItem('Informações'),
    const SizedBox(height: 8.0),
    SettingsCardWidget(
      children: [
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
        SettingsItemWidget(
          onTap: () {},
          label: 'Ajuda',
          icon: Icons.help_outline,
        ),
      ],
    ),
  ];
}
