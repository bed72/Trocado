import 'package:flutter/material.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

class HomeAvatarWidget extends StatelessWidget {
  final double size;
  final String? avatar;

  const HomeAvatarWidget({super.key, this.avatar, this.size = 40.0});

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: size / 2,
    backgroundColor: context.colors.onSurface.withValues(alpha: 0.6),
    backgroundImage: avatar != null ? NetworkImage(avatar!) : null,
    child: avatar != null
        ? null
        : Icon(Icons.person, color: context.colors.primary),
  );
}
