import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/enums/theme/theme_mode_enum.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/extensions/theme_mode_enum_extension.dart';

import 'package:trocado/src/presentation/widgets/avatar/avatar_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/icon_button_widget.dart';
import 'package:trocado/src/presentation/ui/home/widgets/home_greeting_widget.dart';

class HomeAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final ThemeModeEnum themeMode;
  final VoidCallback onCycleTheme;
  final AsyncValue<UserModel> userState;
  final VoidCallback navigateToProfile;
  final VoidCallback navigateToSettings;
  final VoidCallback navigateToNotification;

  const HomeAppBarWidget({
    super.key,
    required this.userState,
    required this.themeMode,
    required this.onCycleTheme,
    required this.navigateToProfile,
    required this.navigateToSettings,
    required this.navigateToNotification,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = userState is AsyncLoading;
    final user = switch (userState) {
      AsyncData(:final value) => value,
      _ => null,
    };

    return Skeletonizer(
      enabled: isLoading,
      child: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          spacing: 12.0,
          children: [
            AvatarWidget(
              onTap: navigateToProfile,
              name: user?.name ?? 'Pensando...',
            ),
            HomeGreetingWidget(name: user?.name ?? 'Pensando...'),
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

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
