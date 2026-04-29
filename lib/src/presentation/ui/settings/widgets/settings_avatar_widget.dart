import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class SettingsAvatarWidget extends StatelessWidget {
  final String name;

  const SettingsAvatarWidget({super.key, required this.name});

  String get _initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24.0,
      backgroundColor: context.colors.primaryContainer,
      child: Text(
        _initial,
        style: context.typography.titleMedium?.copyWith(
          fontWeight: .bold,
          color: context.colors.onPrimaryContainer,
        ),
      ),
    );
  }
}
