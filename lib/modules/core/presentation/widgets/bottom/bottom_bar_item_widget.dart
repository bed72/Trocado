import 'package:flutter/material.dart';

import 'package:trocado/modules/core/presentation/widgets/icon_widget.dart';
import 'package:trocado/modules/core/presentation/widgets/bounce_widget.dart';

class BottomBarItemWidget extends StatelessWidget {
  final Color color;
  final IconData name;
  final String semanticLabel;

  const BottomBarItemWidget({
    super.key,
    required this.name,
    required this.color,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return BounceWidget.withoutTap(
      child: Tab(
        child: IconWidget(
          name: name,
          size: 24.0,
          color: color,
          semanticsLabel: semanticLabel,
        ),
      ),
    );
  }
}
