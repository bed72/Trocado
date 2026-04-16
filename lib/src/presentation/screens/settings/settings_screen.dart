import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';

import 'package:trocado/src/presentation/screens/home/notifiers/user_notifier.dart';

import 'package:trocado/src/presentation/screens/authentication/sign_in/sign_in_location.dart';

import 'package:trocado/src/presentation/screens/settings/notifiers/settings_state.dart';
import 'package:trocado/src/presentation/screens/settings/notifiers/settings_intent.dart';
import 'package:trocado/src/presentation/screens/settings/notifiers/settings_notifier.dart';

import 'package:trocado/src/presentation/screens/settings/widgets/settings_item_widget.dart';
import 'package:trocado/src/presentation/screens/settings/widgets/settings_logout_widget.dart';
import 'package:trocado/src/presentation/screens/settings/widgets/settings_section_widget.dart';
import 'package:trocado/src/presentation/screens/settings/widgets/settings_profile_widget.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onEditProfile;
  final VoidCallback onNotification;
  final VoidCallback onSubscription;

  const SettingsScreen({
    super.key,
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
                .success when previous?.status != .success =>
                  routerConfig.navigate(
                    root: true,
                    replace: true,
                    to: SignInLocation(),
                  ),
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
            final userState = ref.watch(userProvider);

            return Column(
              crossAxisAlignment: .start,
              children: [
                userState.when(
                  data: (user) => SettingsProfileWidget(user: user),
                  loading: _profilePlaceholder,
                  error: (_, _) => _profilePlaceholder(),
                ),

                ..._buildAccount(onEditProfile, onNotification, onSubscription),
                ..._buildInformation,

                const Spacer(),

                SettingsLogoutWidget(
                  isLoading: settingsState.status == SettingsStatus.loading,
                  onTap: () => settingsNotifier.dispatch(const LogoutPressed()),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildAccount(
    VoidCallback onEditProfile,
    VoidCallback onNotification,
    VoidCallback onSubscription,
  ) => [
    const SizedBox(height: 24.0),
    const SettingsSectionWidget(label: 'Conta'),
    const SizedBox(height: 8.0),
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
    const SizedBox(height: 24.0),
    const SettingsSectionWidget(label: 'Informações'),
    const SizedBox(height: 8.0),
    SettingsItemWidget(
      label: 'Termos de uso',
      onTap: () {},
      icon: Icons.description_outlined,
    ),
    SettingsItemWidget(
      label: 'Políticas de privacidade',
      onTap: () {},
      icon: Icons.shield_outlined,
    ),
    SettingsItemWidget(label: 'Ajuda', onTap: () {}, icon: Icons.help_outline),
  ];

  SizedBox _profilePlaceholder() => const SizedBox(height: 48.0);
}
