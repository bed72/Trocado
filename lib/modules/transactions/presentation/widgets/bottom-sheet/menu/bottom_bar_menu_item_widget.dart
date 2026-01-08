import 'package:flutter/material.dart';

import 'package:trocado/modules/core/presentation/widgets/bounce_widget.dart';
import 'package:trocado/modules/core/presentation/animation/shimmer_animation.dart';
import 'package:trocado/modules/core/presentation/extensions/context_extension.dart';

class BottomBarMenuItemWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final Color backgroundColor;

  const BottomBarMenuItemWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return BounceWidget.withTap(
      onTap: onTap,
      child: ShimmerAnimation(
        pause: Duration(seconds: 8),
        duration: Duration(seconds: 4),
        radius: context.radius.cornerRadius500,
        child: Container(
          width: 200.0,
          height: 70.0,
          decoration: BoxDecoration(
            color: backgroundColor.withAlpha(60),
            borderRadius: context.radius.cornerRadius500,
            border: .all(color: backgroundColor, width: 1.0),
          ),
          child: Row(
            spacing: 8.0,
            mainAxisAlignment: .center,
            crossAxisAlignment: .center,
            children: [
              Icon(icon, size: 26.0, color: iconColor),

              Text(
                title,
                style: context.typography.bodyLarge?.copyWith(
                  color: iconColor,
                  fontWeight: .w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
