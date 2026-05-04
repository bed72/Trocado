import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';

class AvatarWidget extends StatelessWidget {
  final double size;
  final String name;
  final VoidCallback? onTap;

  const AvatarWidget({
    super.key,
    required this.name,
    this.size = 48.0,
    this.onTap,
  });

  String get _initial =>
      name.trim().isEmpty ? '' : name.trim().characters.first.toUpperCase();

  @override
  Widget build(BuildContext context) {
    return BounceWidget.withOnPress(
      onPress: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: .center,
        decoration: BoxDecoration(
          color: context.colors.primary.withValues(alpha: 0.2),
          borderRadius: context.radius.cornerRadius100,
        ),
        child: Text(
          _initial,
          style: context.typography.titleLarge?.copyWith(
            fontWeight: .w800,
            color: context.colors.primary,
          ),
        ),
      ),
    );
  }
}
