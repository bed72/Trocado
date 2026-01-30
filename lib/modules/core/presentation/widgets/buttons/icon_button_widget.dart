import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class IconButtonWidget extends StatelessWidget {
  final IconData name;
  final Color? color;
  final double? width;
  final double? height;
  final double? iconSize;
  final VoidCallback onPress;
  final BorderRadiusGeometry? borderRadius;

  const IconButtonWidget({
    super.key,
    required this.name,
    required this.onPress,
    this.width,
    this.color,
    this.height,
    this.iconSize,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return BounceWidget.withOnPress(
      onPress: onPress,
      child: BackgroundIconWidget(
        name: name,
        width: width,
        height: height,
        iconSize: iconSize,
        borderRadius: borderRadius,
        color: color ?? context.colors.primary,
      ),
    );
  }
}
