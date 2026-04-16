import 'package:flutter/material.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

class HomeAvatarWidget extends StatelessWidget {
  final double size;
  final String? avatar;

  const HomeAvatarWidget({super.key, this.avatar, this.size = 40.0});

  bool get _hasValidAvatar =>
      avatar != null &&
      Uri.tryParse(avatar!)?.hasAbsolutePath == true &&
      Uri.parse(avatar!).hasScheme;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: size / 2,
    onBackgroundImageError: _hasValidAvatar ? (_, _) {} : null,
    backgroundColor: context.colors.primary.withValues(alpha: 0.2),
    backgroundImage: _hasValidAvatar ? NetworkImage(avatar!) : null,
    child: _hasValidAvatar
        ? null
        : Icon(Icons.person, color: context.colors.primary),
  );
}
