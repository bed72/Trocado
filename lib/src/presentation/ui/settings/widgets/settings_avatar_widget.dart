import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class SettingsAvatarWidget extends StatelessWidget {
  final String name;
  final String? avatar;

  const SettingsAvatarWidget({super.key, required this.name, this.avatar});

  String get _initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24.0,
      backgroundColor: context.colors.primaryContainer,
      backgroundImage: avatar != null ? NetworkImage(avatar!) : null,
      child: avatar == null
          ? Text(
              _initial,
              style: context.typography.titleMedium?.copyWith(
                fontWeight: .bold,
                color: context.colors.onPrimaryContainer,
              ),
            )
          : null,
    );
  }
}
