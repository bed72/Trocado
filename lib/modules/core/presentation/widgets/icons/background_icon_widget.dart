import 'package:flutter/widgets.dart';
import 'package:trocado/modules/core/core.dart';

class BackgroundIconWidget extends StatelessWidget {
  final Color color;
  final IconData name;
  final double? width;
  final double? height;
  final double? iconSize;
  final BorderRadiusGeometry? borderRadius;

  const BackgroundIconWidget({
    super.key,
    required this.name,
    required this.color,
    this.width,
    this.height,
    this.iconSize,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: .center,
      width: width ?? 48.0,
      height: height ?? 48.0,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: borderRadius ?? context.radius.cornerRadius300,
      ),
      child: IconWidget(name: name, color: color, size: iconSize),
    );
  }
}
