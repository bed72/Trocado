import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(radius: 48.0, backgroundImage: NetworkImage(url)),
              Positioned(
                right: 2,
                bottom: 0,
                child: BounceWidget.withTap(
                  onTap: onEdit,
                  child: Container(
                    width: 32.0,
                    height: 32.0,
                    decoration: BoxDecoration(
                      shape: .circle,
                      color: context.colors.inversePrimary,
                    ),
                    child: IconWidget(
                      name: LucideIcons.pencil,
                      size: 16.0,
                      color: context.colors.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
