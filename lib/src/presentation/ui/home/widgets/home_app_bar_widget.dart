import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/buttons/icon_button_widget.dart';
import 'package:trocado/src/presentation/ui/home/widgets/home_avatar_widget.dart';
import 'package:trocado/src/presentation/ui/home/widgets/home_greeting_widget.dart';

class HomeAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final AsyncValue<UserModel> userState;
  final VoidCallback navigateToSettings;
  final VoidCallback navigateToNotification;

  const HomeAppBarWidget({
    super.key,
    required this.userState,
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
            HomeAvatarWidget(name: user?.name ?? 'Carregando'),
            HomeGreetingWidget(name: user?.name ?? 'Carregando'),
          ],
        ),
        actions: [
          IconButtonWidget(
            withoutBackground: true,
            onPress: navigateToNotification,
            color: context.colors.onSurface,
            icon: Icons.notifications_outlined,
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
