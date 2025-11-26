import 'package:flutter/material.dart';

import 'package:trocado/modules/core/presentation/widgets/image/strategy/asset_image_strategy.dart';
import 'package:trocado/modules/core/presentation/widgets/image/strategy/empty_image_strategy.dart';
import 'package:trocado/modules/core/presentation/widgets/image/strategy/image_strategy.dart';
import 'package:trocado/modules/core/presentation/widgets/image/strategy/network_image_strategy.dart';

class ImageWidget extends StatelessWidget {
  final BoxFit? fit;
  final String? alt;
  final Color? color;
  final double? width;
  final double? height;
  final String? source;
  final String? fallback;
  final bool showLoading;

  const ImageWidget({
    super.key,
    required this.source,
    this.alt,
    this.fit,
    this.width,
    this.color,
    this.height,
    this.fallback,
    this.showLoading = false,
  });

  ImageStrategy _resolve() => switch (source) {
    null => const EmptyImageStrategy(),
    final data when !data.startsWith('http') => const AssetImageStrategy(),
    _ => const NetworkImageStrategy(),
  };

  @override
  Widget build(BuildContext context) {
    final strategy = _resolve();

    return strategy.build(
      source: source!,
      semanticLabel: alt,
      width: width,
      color: color,
      height: height,
      fallback: fallback,
      showLoading: showLoading,
      fit: fit ?? BoxFit.cover,
    );
  }
}
