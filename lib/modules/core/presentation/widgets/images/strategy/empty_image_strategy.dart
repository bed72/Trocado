import 'package:flutter/material.dart';

import 'package:trocado/modules/core/presentation/widgets/icons/icon_widget.dart';
import 'package:trocado/modules/core/presentation/widgets/images/strategy/image_strategy.dart';

final class EmptyImageStrategy implements ImageStrategy {
  const EmptyImageStrategy();

  @override
  Widget build({
    required String source,
    required BoxFit? fit,
    required double? width,
    required double? height,
    required Color? color,
    required bool showLoading,
    required String? fallback,
    required String? semanticLabel,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: IconWidget(
        color: color ?? Colors.grey,
        name: Icons.add_photo_alternate,
        size: (width ?? height ?? 48) * 0.6,
        semanticsLabel: semanticLabel ?? 'Adicona foto',
      ),
    );
  }
}
