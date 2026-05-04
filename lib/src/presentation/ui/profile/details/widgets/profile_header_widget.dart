import 'package:flutter/material.dart';

import 'package:trocado/src/domain/models/user_model.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/avatar/avatar_widget.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final UserModel user;

  const ProfileHeaderWidget({super.key, required this.user});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .center,
    children: [
      Center(child: AvatarWidget(name: user.name, size: 72.0)),
      const SizedBox(height: 16.0),
      Text(
        user.name,
        textAlign: .center,
        style: context.typography.titleLarge?.copyWith(fontWeight: .bold),
      ),
      const SizedBox(height: 4.0),
      Text(
        user.email,
        textAlign: .center,
        style: context.typography.bodyMedium?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    ],
  );
}
