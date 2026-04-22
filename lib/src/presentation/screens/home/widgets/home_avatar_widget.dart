import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/icons/background_icon_widget.dart';

class HomeAvatarWidget extends StatelessWidget {
  final double size;
  final String? avatar;

  const HomeAvatarWidget({super.key, this.avatar, this.size = 40.0});

  bool get _hasValidAvatar =>
      avatar != null &&
      Uri.tryParse(avatar!)?.hasAbsolutePath == true &&
      Uri.parse(avatar!).hasScheme;

  @override
  Widget build(BuildContext context) {
    if (_hasValidAvatar) {
      return CircleAvatar(
        radius: size / 2,
        onBackgroundImageError: (_, _) {},
        backgroundColor: context.colors.primary.withValues(alpha: 0.2),
        backgroundImage: NetworkImage(avatar!),
      );
    }

    return BackgroundIconWidget(
      width: size,
      height: size,
      icon: Icons.person,
      color: context.colors.primary,
    );
  }
}
