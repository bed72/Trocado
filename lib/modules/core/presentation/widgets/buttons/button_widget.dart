import 'package:flutter/material.dart';

import 'package:trocado/modules/core/presentation/widgets/bounce_widget.dart';
import 'package:trocado/modules/core/presentation/widgets/circular_progress_indicator_widget.dart';

enum ButtonWidgetType { elevated, outlined }

class ButtonWidget extends StatelessWidget {
  final String? label;
  final bool loading;
  final Widget? icon;
  final VoidCallback? onTap;
  final ButtonWidgetType type;

  const ButtonWidget.elevated({
    super.key,
    required this.onTap,
    this.icon,
    this.label,
    this.loading = false,
  }) : type = ButtonWidgetType.elevated;

  const ButtonWidget.outlined({
    super.key,
    required this.onTap,
    this.icon,
    this.label,
    this.loading = false,
  }) : type = ButtonWidgetType.outlined;

  @override
  Widget build(BuildContext context) {
    return BounceWidget.withTap(
      onTap: onTap == null ? null : () => onTap!(),
      child: _buildButton(
        context: context,
        child: _buildContent(context: context),
      ),
    );
  }

  Widget _buildContent({required BuildContext context}) {
    if (loading) {
      return SizedBox(
        width: 20.0,
        height: 20.0,
        child: CircularProgressIndicatorWidget(),
      );
    }

    return Row(
      mainAxisSize: .min,
      spacing: (icon != null && label != null) ? 8.0 : 0.0,
      children: [if (icon != null) icon!, Text(label ?? '')],
    );
  }

  Widget _buildButton({required BuildContext context, required Widget child}) =>
      switch (type) {
        .elevated => ElevatedButton(onPressed: onTap, child: child),
        .outlined => OutlinedButton(onPressed: onTap, child: child),
      };
}
