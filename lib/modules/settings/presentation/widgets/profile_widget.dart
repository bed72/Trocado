import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/core/core.dart';

class ProfileWidget extends StatelessWidget {
  final String name;
  final String? resource;
  final VoidCallback onEdit;

  const ProfileWidget({
    super.key,
    required this.name,
    required this.onEdit,
    required this.resource,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        spacing: 12.0,
        mainAxisSize: .min,
        mainAxisAlignment: .center,
        crossAxisAlignment: .center,
        children: [
          UserImageWidget(
            onEdit: onEdit,
            resource: resource,
            iconOnEdit: LucideIcons.pen,
          ),
          Text(name, style: context.typography.titleMedium),
        ],
      ),
    );
  }
}
