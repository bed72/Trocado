import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class CircularProgressIndicatorWidget extends StatelessWidget {
  final Color? color;
  final double? width;
  final double? height;

  const CircularProgressIndicatorWidget({
    super.key,
    this.color,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: width ?? 20.0,
        height: height ?? 20.0,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(color ?? context.colors.onPrimary),
        ),
      ),
    );
  }
}
