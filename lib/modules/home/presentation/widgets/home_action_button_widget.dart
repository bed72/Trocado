import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class HomeActionButtonWidget extends StatelessWidget {
  final VoidCallback onNavigateToTransaction;

  const HomeActionButtonWidget({
    super.key,
    required this.onNavigateToTransaction,
  });

  @override
  Widget build(BuildContext context) {
    return BounceWidget.withOnPress(
      onPress: onNavigateToTransaction,
      child: BackgroundIconWidget(
        icon: Icons.add,
        alpha: .8,
        width: 64.0,
        height: 64.0,
        borderRadius: .circular(26.0),
        color: context.colors.primary,
      ),
    );
  }
}
