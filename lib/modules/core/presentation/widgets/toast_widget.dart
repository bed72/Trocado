import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import 'package:trocado/modules/core/domain/constants/toast_constant.dart';
import 'package:trocado/modules/core/presentation/widgets/icons/icon_widget.dart';
import 'package:trocado/modules/core/presentation/extensions/context_extension.dart';

void showToastWidget({
  required BuildContext context,
  required String title,
  int? seconds,
  String? description,
  VoidCallback? onClose,
  ToastConstant type = .success,
}) => switch (type) {
  .success => _showSuccessToast(
    context: context,
    title: title,
    onClose: onClose,
    seconds: seconds ?? 3,
    description: description,
  ),
  .failure => _showFailureToast(
    context: context,
    title: title,
    onClose: onClose,
    seconds: seconds ?? 3,
    description: description,
  ),
};

void _showSuccessToast({
  required BuildContext context,
  required int seconds,
  required String title,
  String? description,
  VoidCallback? onClose,
}) {
  toastification.show(
    style: .flat,
    type: .success,
    context: context,
    showProgressBar: true,
    alignment: .bottomRight,
    dismissDirection: .down,
    borderRadius: .circular(20.0),
    autoCloseDuration: Duration(seconds: seconds),
    closeButton: ToastCloseButton(showType: .none),
    borderSide: BorderSide(width: 0.0, style: .none),
    backgroundColor: context.colors.surfaceContainer,
    icon: IconWidget(
      color: context.colors.primary,
      icon: Icons.celebration_rounded,
    ),
    callbacks: ToastificationCallbacks(
      onDismissed: (_) => onClose?.call(),
      onAutoCompleteCompleted: (_) => onClose?.call(),
    ),
    title: Text(
      title,
      style: context.typography.titleSmall?.copyWith(
        fontWeight: .w600,
        color: context.colors.onSurfaceVariant,
      ),
    ),
    description: description == null
        ? null
        : Text(
            description,
            style: context.typography.labelMedium?.copyWith(
              color: context.colors.onSurfaceVariant.withValues(alpha: .6),
            ),
          ),
    progressBarTheme: ProgressIndicatorThemeData(
      stopIndicatorRadius: 2.0,
      borderRadius: .all(.circular(2.0)),
      color: context.colors.primary.withValues(alpha: .2),
      linearTrackColor: context.colors.primary.withValues(alpha: .2),
    ),
    animationBuilder: (context, animation, _, child) {
      final position =
          Tween<Offset>(end: Offset.zero, begin: const Offset(0, 1)).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            ),
          );

      return SlideTransition(position: position, child: child);
    },
  );
}

void _showFailureToast({
  required BuildContext context,
  required int seconds,
  required String title,
  String? description,
  VoidCallback? onClose,
}) {
  toastification.show(
    style: .flat,
    type: .error,
    context: context,
    showProgressBar: true,
    alignment: .bottomRight,
    dismissDirection: .down,
    borderRadius: .circular(20.0),
    autoCloseDuration: Duration(seconds: seconds),
    closeButton: ToastCloseButton(showType: .none),
    borderSide: BorderSide(width: 0.0, style: .none),
    backgroundColor: context.colors.surfaceContainer,
    icon: IconWidget(icon: Icons.error, color: context.colors.error),
    progressBarTheme: ProgressIndicatorThemeData(
      stopIndicatorRadius: 2.0,
      borderRadius: .all(.circular(2.0)),
      color: context.colors.error.withValues(alpha: 6),
      linearTrackColor: context.colors.error.withValues(alpha: .2),
    ),
    callbacks: ToastificationCallbacks(
      onDismissed: (_) => onClose?.call(),
      onAutoCompleteCompleted: (_) => onClose?.call(),
    ),
    title: Text(
      title,
      style: context.typography.titleSmall?.copyWith(
        fontWeight: .w600,
        color: context.colors.onSurfaceVariant,
      ),
    ),
    description: description == null
        ? null
        : Text(
            description,
            style: context.typography.labelMedium?.copyWith(
              color: context.colors.onSurfaceVariant.withValues(alpha: .6),
            ),
          ),
    animationBuilder: (context, animation, _, child) {
      final position =
          Tween<Offset>(end: Offset.zero, begin: const Offset(0, 1)).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            ),
          );

      return SlideTransition(position: position, child: child);
    },
  );
}
