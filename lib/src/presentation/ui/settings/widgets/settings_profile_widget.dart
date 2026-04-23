import 'package:flutter/material.dart';

import 'package:trocado/src/domain/models/user_model.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/ui/settings/widgets/settings_avatar_widget.dart';

class SettingsProfileWidget extends StatelessWidget {
  final UserModel user;

  const SettingsProfileWidget({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 16.0,
      children: [
        SettingsAvatarWidget(name: user.name, avatar: user.avatar),
        Expanded(
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            children: [
              Text(
                user.name,
                maxLines: 1,
                overflow: .ellipsis,
                style: context.typography.titleMedium?.copyWith(
                  fontWeight: .bold,
                ),
              ),
              Text(
                user.email,
                maxLines: 1,
                overflow: .ellipsis,
                style: context.typography.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
