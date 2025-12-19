import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class ProfileWidget extends StatelessWidget {
  final String url;
  final String name;
  final VoidCallback onEdit;

  const ProfileWidget({
    super.key,
    required this.url,
    required this.name,
    required this.onEdit,
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
          UserImageWidget.pencil(onEdit: onEdit),
          Text(name, style: context.typography.titleMedium),
        ],
      ),
    );
  }
}
