import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/enums/theme/theme_mode_enum.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/extensions/theme_mode_enum_extension.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/avatar/avatar_widget.dart';
import 'package:trocado/src/presentation/widgets/avatar/avatar_pair_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/icon_button_widget.dart';

import 'package:trocado/src/presentation/ui/home/widgets/home_greeting_widget.dart';
import 'package:trocado/src/presentation/ui/home/data/home_app_bar_presentation_data.dart';

class HomeAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final ThemeModeEnum themeMode;
  final VoidCallback onCycleTheme;
  final VoidCallback navigateToProfile;
  final VoidCallback navigateToSettings;
  final VoidCallback navigateToNotification;
  final AsyncValue<HomeAppBarPresentationData> appBarState;

  const HomeAppBarWidget({
    super.key,
    required this.themeMode,
    required this.appBarState,
    required this.onCycleTheme,
    required this.navigateToProfile,
    required this.navigateToSettings,
    required this.navigateToNotification,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = appBarState is AsyncLoading;
    final data = switch (appBarState) {
      AsyncData(:final value) => value,
      _ => null,
    };

    return Skeletonizer(
      enabled: isLoading,
      child: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          spacing: 4.0,
          children: [
            _avatar(data),
            Expanded(child: HomeGreetingWidget(name: _displayName(data))),
          ],
        ),
        actions: [
          IconButtonWidget(
            withoutBackground: true,
            color: context.colors.onSurface,
            onPress: navigateToNotification,
            icon: Icons.notifications_none_rounded,
          ),

          IconButtonWidget(
            icon: themeMode.icon,
            onPress: onCycleTheme,
            withoutBackground: true,
            color: context.colors.onSurface,
          ),

          IconButtonWidget(
            withoutBackground: true,
            onPress: navigateToSettings,
            icon: Icons.settings_outlined,
            color: context.colors.onSurface,
          ),
        ],
      ),
    );
  }

  Widget _avatar(HomeAppBarPresentationData? data) => switch (data) {
    HomeAppBarSoloPresentationData(:final name) => AvatarWidget(
      name: name,
      onTap: navigateToProfile,
    ),
    HomeAppBarCouplePresentationData(
      :final currentInitial,
      :final partnerInitial,
    ) =>
      BounceWidget.withOnPress(
        onPress: navigateToProfile,
        child: AvatarPairWidget(
          firstInitial: currentInitial,
          secondInitial: partnerInitial,
        ),
      ),
    null => AvatarWidget(name: 'Pensando...', onTap: navigateToProfile),
  };

  String _displayName(HomeAppBarPresentationData? data) => switch (data) {
    HomeAppBarSoloPresentationData(:final name) => name,
    HomeAppBarCouplePresentationData(:final title) => title,
    null => 'Pensando...',
  };

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
