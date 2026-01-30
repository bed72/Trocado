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
        color: context.colors.primary,
      ),
    );
  }
}
