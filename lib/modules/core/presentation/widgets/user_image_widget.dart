import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/core/presentation/widgets/icon_widget.dart';
import 'package:trocado/modules/core/presentation/widgets/bounce_widget.dart';
import 'package:trocado/modules/core/presentation/animation/shimmer_animation.dart';
import 'package:trocado/modules/core/presentation/extensions/context_extension.dart';
import 'package:trocado/modules/core/presentation/widgets/skeletons/skeleton_widget.dart';

class UserImageWidget extends StatelessWidget {
  final VoidCallback onEdit;
  final String? source;
  final IconData? iconEmpty;
  final IconData? iconOnEdit;

  const UserImageWidget({
    super.key,
    required this.onEdit,
    this.source,
    this.iconEmpty,
    this.iconOnEdit,
  });

  factory UserImageWidget.empty({required VoidCallback onEdit}) =>
      UserImageWidget(
        onEdit: onEdit,
        iconOnEdit: LucideIcons.camera,
        iconEmpty: LucideIcons.userRound,
      );

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        source == null ? _buildEmptyUser(context) : _buildNotEmptyUser(),
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
                color: context.isDark
                    ? context.colors.onPrimary
                    : context.colors.primary,
              ),
              child: iconOnEdit == null
                  ? null
                  : IconWidget(
                      size: 16.0,
                      name: iconOnEdit!,
                      color: context.isDark
                          ? context.colors.onSurface
                          : context.colors.onInverseSurface,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  SkeletonWidget _buildLoading() =>
      SkeletonWidget(child: UserImageWidget.empty(onEdit: onEdit));

  FutureBuilder _buildNotEmptyUser() => FutureBuilder<Uint8List>(
    future: File(source!).readAsBytes(),
    builder: (_, snapshot) => !snapshot.hasData
        ? _buildLoading()
        : CircleAvatar(
            radius: 48,
            backgroundImage: MemoryImage(snapshot.data!),
          ),
  );

  ShimmerAnimation _buildEmptyUser(BuildContext context) => ShimmerAnimation(
    pause: Duration(seconds: 6),
    duration: Duration(seconds: 4),
    radius: context.radius.cornerRadiusFull,
    child: Container(
      width: 100.0,
      height: 100.0,
      decoration: BoxDecoration(
        shape: .circle,
        color: context.colors.inverseSurface.withValues(alpha: 0.10),
      ),
      child: Center(child: Icon(iconEmpty, size: 50.0)),
    ),
  );
}
