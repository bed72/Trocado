import 'package:flutter/material.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/icons/icon_widget.dart';

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
      child: Container(
        width: 56.0,
        height: 56.0,
        alignment: .center,
        decoration: BoxDecoration(
          color: context.colors.primary,
          borderRadius: context.radius.cornerRadius300,
        ),
        child: IconWidget(
          size: 26.0,
          icon: Icons.add,
          color: context.colors.onPrimary,
        ),
      ),
    );
  }
}
