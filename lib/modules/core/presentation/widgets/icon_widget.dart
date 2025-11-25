import 'package:flutter/material.dart';

class IconWidget extends StatelessWidget {
  final Color? color;
  final double? size;
  final IconData name;
  final String? semanticsLabel;

  const IconWidget({
    super.key,
    required this.name,
    this.size,
    this.color,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) =>
      Icon(name, size: size, color: color, semanticLabel: semanticsLabel);
}
