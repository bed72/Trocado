import 'package:flutter/material.dart';
import 'package:trocado/modules/core/presentation/extensions/context_extension.dart';

import 'package:trocado/modules/core/presentation/widgets/bounce_widget.dart';
import 'package:trocado/modules/core/presentation/widgets/circular_progress_indicator_widget.dart';

enum ButtonWidgetType { elevated, outlined }

class ButtonWidget extends StatelessWidget {
  final String? label;
  final bool? loading;
  final Widget? child;
  final VoidCallback? onTap;
  final ButtonWidgetType type;

  const ButtonWidget.elevated({
    super.key,
    required this.onTap,
    this.child,
    this.label,
    this.loading,
  }) : type = ButtonWidgetType.elevated;

  const ButtonWidget.outlined({
    super.key,
    required this.onTap,
    this.child,
    this.label,
    this.loading,
  }) : type = ButtonWidgetType.outlined;

  @override
  Widget build(BuildContext context) {
    return BounceWidget.withTap(
      onTap: onTap == null ? null : () => onTap!(),
      child: _buildButton(context: context, child: _buildContent(context)),
    );
  }

  AnimatedSwitcher _buildContent(BuildContext context) => AnimatedSwitcher(
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    duration: const Duration(milliseconds: 300),
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(scale: animation, child: child),
    ),
    child: (loading ?? false) ? _buildLoading(context) : _buildTitle(),
  );

  Row _buildTitle() => Row(
    key: const ValueKey('content'),
    mainAxisSize: .min,
    spacing: (child != null && label != null) ? 8.0 : 0.0,
    children: [if (child != null) child!, Text(label ?? '')],
  );

  SizedBox _buildLoading(BuildContext context) => SizedBox(
    key: const ValueKey('loading'),
    width: 20.0,
    height: 20.0,
    child: CircularProgressIndicatorWidget(
      color: context.isDark
          ? context.colors.onPrimaryContainer
          : context.colors.onPrimary,
    ),
  );

  Widget _buildButton({required BuildContext context, required Widget child}) =>
      switch (type) {
        .elevated => ElevatedButton(onPressed: onTap, child: child),
        .outlined => OutlinedButton(onPressed: onTap, child: child),
      };
}
