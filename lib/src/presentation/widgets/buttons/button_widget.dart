import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/animation/animation.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/circular_progress_indicator_widget.dart';

enum ButtonWidgetType { text, elevated, outlined, danger }

class ButtonWidget extends StatelessWidget {
  final String? label;
  final Widget? child;
  final bool? isLoading;
  final VoidCallback? onTap;
  final ButtonWidgetType type;

  const ButtonWidget.text({
    super.key,
    required this.onTap,
    this.child,
    this.label,
    this.isLoading,
  }) : type = ButtonWidgetType.text;

  const ButtonWidget.elevated({
    super.key,
    required this.onTap,
    this.child,
    this.label,
    this.isLoading,
  }) : type = ButtonWidgetType.elevated;

  const ButtonWidget.outlined({
    super.key,
    required this.onTap,
    this.child,
    this.label,
    this.isLoading,
  }) : type = ButtonWidgetType.outlined;

  const ButtonWidget.danger({
    super.key,
    required this.onTap,
    this.child,
    this.label,
    this.isLoading,
  }) : type = ButtonWidgetType.danger;

  @override
  Widget build(BuildContext context) {
    return BounceWidget.withOnPress(
      onPress: onTap == null ? null : () => onTap!(),
      child: _buildButton(context: context, child: _buildContent(context)),
    );
  }

  SwitcherAnimation _buildContent(BuildContext context) => SwitcherAnimation(
    child: (isLoading ?? false) ? _buildLoading(context) : _buildTitle(),
  );

  Row _buildTitle() => Row(
    key: const ValueKey('content'),
    mainAxisSize: .min,
    spacing: (child != null && label != null) ? 8.0 : 0.0,
    children: [?child, Text(label ?? '')],
  );

  CircularProgressIndicatorWidget _buildLoading(BuildContext context) =>
      CircularProgressIndicatorWidget(
        key: const ValueKey('loading'),
        width: 20.0,
        height: 20.0,
        color: _loadingColor(context),
      );

  Color _loadingColor(BuildContext context) => switch (type) {
    .danger => context.colors.onError,
    _ =>
      context.isDark
          ? context.colors.onPrimaryContainer
          : context.colors.onPrimary,
  };

  Widget _buildButton({required BuildContext context, required Widget child}) =>
      switch (type) {
        .elevated => ElevatedButton(onPressed: onTap, child: child),
        .outlined => OutlinedButton(onPressed: onTap, child: child),
        .danger => ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            iconColor: context.colors.onError,
            foregroundColor: context.colors.onError,
            backgroundColor: context.colors.error.withValues(alpha: 0.9),
          ),
          child: child,
        ),
        .text => TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: .zero,
            minimumSize: .zero,
            alignment: .centerLeft,
            tapTargetSize: .shrinkWrap,
            overlayColor: Colors.transparent,
            backgroundColor: Colors.transparent,
          ),
          child: child,
        ),
      };
}
