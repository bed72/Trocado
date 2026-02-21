import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/icons/background_icon_widget.dart';

class IconButtonWidget extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double? width;
  final double? height;
  final double? iconSize;
  final VoidCallback onPress;
  final BorderRadiusGeometry? borderRadius;

  const IconButtonWidget({
    super.key,
    required this.icon,
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
        icon: icon,
        width: width,
        height: height,
        iconSize: iconSize,
        borderRadius: borderRadius,
        color: color ?? context.colors.primary,
      ),
    );
  }
}
