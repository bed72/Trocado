import 'package:flutter/widgets.dart';
import 'package:trocado/modules/core/core.dart';

class BackgroundIconWidget extends StatelessWidget {
  final Color color;
  final IconData icon;
  final double? alpha;
  final double? width;
  final double? height;
  final double? iconSize;
  final BorderRadiusGeometry? borderRadius;

  const BackgroundIconWidget({
    super.key,
    required this.icon,
    required this.color,
    this.alpha,
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
        color: color.withValues(alpha: alpha ?? 0.2),
        borderRadius: borderRadius ?? context.radius.cornerRadius300,
      ),
      child: IconWidget(icon: icon, color: color, size: iconSize),
    );
  }
}
