import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class ProfileWidget extends StatelessWidget {
  final String url;
  final String name;
  final String email;
  final VoidCallback onEdit;

  const ProfileWidget({
    super.key,
    required this.url,
    required this.name,
    required this.email,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: .min,
        mainAxisAlignment: .center,
        crossAxisAlignment: .center,
        children: [
          UserImageWidget.empty(onEdit: onEdit),
          const SizedBox(height: 12.0),
          Text(name, style: context.typography.titleMedium),
          const SizedBox(height: 6.0),
          Text(
            email,
            style: context.typography.bodyMedium?.copyWith(
              fontWeight: .w600,
              color: context.colors.onSurface.withAlpha(960),
            ),
          ),
        ],
      ),
    );
  }
}
