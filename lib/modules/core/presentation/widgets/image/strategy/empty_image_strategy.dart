import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/core/presentation/widgets/icon_widget.dart';
import 'package:trocado/modules/core/presentation/widgets/image/strategy/image_strategy.dart';

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
        name: LucideIcons.userRound,
        color: color ?? Colors.grey,
        semanticsLabel: semanticLabel ?? 'User icon',
        size: (width ?? height ?? 48) * 0.6,
      ),
    );
  }
}
