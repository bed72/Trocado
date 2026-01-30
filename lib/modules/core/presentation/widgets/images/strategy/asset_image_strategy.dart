import 'package:flutter/material.dart';

import 'package:trocado/modules/core/presentation/widgets/images/strategy/image_strategy.dart';

final class AssetImageStrategy implements ImageStrategy {
  const AssetImageStrategy();

  @override
  Widget build({
    required String source,
    required BoxFit? fit,
    required Color? color,
    required double? width,
    required double? height,
    required bool showLoading,
    required String? fallback,
    required String? semanticLabel,
  }) {
    return Image.asset(
      source,
      fit: fit,
      color: color,
      width: width,
      height: height,
      isAntiAlias: true,
      alignment: .center,
      filterQuality: .high,
      semanticLabel: semanticLabel ?? 'Local imagem',
      errorBuilder: (_, _, _) => fallback != null
          ? Image.asset(fallback, fit: fit, width: width, height: height)
          : SizedBox(width: width, height: height),
    );
  }
}
