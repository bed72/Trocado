import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class HomeAvatarWidget extends StatelessWidget {
  final double size;
  final String name;
  final String? avatar;

  const HomeAvatarWidget({
    super.key,
    required this.name,
    this.avatar,
    this.size = 48.0,
  });

  bool get _hasValidAvatar =>
      avatar != null &&
      Uri.tryParse(avatar!)?.hasAbsolutePath == true &&
      Uri.parse(avatar!).hasScheme;

  String get _initial =>
      name.trim().isEmpty ? '' : name.trim().characters.first.toUpperCase();

  @override
  Widget build(BuildContext context) {
    if (_hasValidAvatar) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: context.colors.primary.withValues(alpha: 0.2),
          borderRadius: context.radius.cornerRadius100,
          image: DecorationImage(
            fit: .cover,
            onError: (_, _) {},
            image: NetworkImage(avatar!),
          ),
        ),
      );
    }

    return Container(
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
    );
  }
}
