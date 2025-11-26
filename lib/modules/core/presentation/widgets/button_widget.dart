import 'package:flutter/material.dart';

import 'package:trocado/modules/core/presentation/widgets/bounce_widget.dart';
import 'package:trocado/modules/core/presentation/widgets/circular_progress_indicator_widget.dart';

enum ButtonWidgetType { elevated, outlined }

class ButtonWidget extends StatelessWidget {
  final String? label;
  final bool loading;
  final bool enabled;
  final Widget? icon;
  final VoidCallback? onTap;
  final ButtonWidgetType type;

  const ButtonWidget.elevated({
    super.key,
    required this.onTap,
    this.icon,
    this.label,
    this.enabled = true,
    this.loading = false,
  }) : type = ButtonWidgetType.elevated;

  const ButtonWidget.outlined({
    super.key,
    required this.onTap,
    this.icon,
    this.label,
    this.enabled = true,
    this.loading = false,
  }) : type = ButtonWidgetType.outlined;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = !enabled || loading;

    return BounceWidget.withTap(
      onTap: isDisabled ? () {} : (onTap ?? () {}),
      child: _buildButton(
        context: context,
        isDisabled: isDisabled,
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

  Widget _buildButton({
    required BuildContext context,
    required bool isDisabled,
    required Widget child,
  }) {
    final onPressed = isDisabled ? null : onTap;

    return switch (type) {
      ButtonWidgetType.elevated => ElevatedButton(
        onPressed: onPressed,
        child: child,
      ),
      ButtonWidgetType.outlined => OutlinedButton(
        onPressed: onPressed,
        child: child,
      ),
    };
  }
}
