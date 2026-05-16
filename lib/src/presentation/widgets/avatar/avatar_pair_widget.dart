import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class AvatarPairWidget extends StatelessWidget {
  static const double _size = 40.0;
  static const double _overlap = 16.0;

  final String firstInitial;
  final String secondInitial;

  const AvatarPairWidget({
    super.key,
    required this.firstInitial,
    required this.secondInitial,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _size,
      width: _size * 2 - _overlap,
      child: Stack(
        children: [
          Positioned(
            left: 0.0,
            child: _buildAvatar(
              context: context,
              initial: firstInitial,
              backgroundOpacity: 0.4,
            ),
          ),
          Positioned(
            left: _size - _overlap,
            child: _buildAvatar(
              context: context,
              initial: secondInitial,
              backgroundOpacity: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar({
    required BuildContext context,
    required String initial,
    required double backgroundOpacity,
  }) => Container(
    width: _size,
    height: _size,
    alignment: .center,
    decoration: BoxDecoration(
      borderRadius: context.radius.cornerRadius100,
      border: .all(color: context.colors.surface, width: 2.0),
      color: context.colors.primary.withValues(alpha: backgroundOpacity),
    ),
    child: Text(
      initial,
      style: context.typography.titleMedium?.copyWith(
        fontWeight: .w800,
        color: backgroundOpacity > 0.6
            ? context.colors.onPrimary
            : context.colors.primary,
      ),
    ),
  );
}
