import 'package:flutter/material.dart';

class SwipeActionsBackgroundWidget extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final Alignment alignment;

  const SwipeActionsBackgroundWidget.leading({
    super.key,
    required this.icon,
    required this.color,
    required this.iconColor,
  }) : alignment = Alignment.centerLeft;

  const SwipeActionsBackgroundWidget.trailing({
    super.key,
    required this.icon,
    required this.color,
    required this.iconColor,
  }) : alignment = Alignment.centerRight;

  @override
  Widget build(BuildContext context) => Container(
    alignment: alignment,
    color: color.withValues(alpha: 0.9),
    padding: const .symmetric(horizontal: 24.0),
    child: Icon(icon, color: iconColor),
  );
}
