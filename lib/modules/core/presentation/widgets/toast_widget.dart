import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import 'package:trocado/modules/core/domain/constants/toast_constant.dart';
import 'package:trocado/modules/core/presentation/widgets/icons/icon_widget.dart';
import 'package:trocado/modules/core/presentation/extensions/context_extension.dart';

void showToastWidget({
  required BuildContext context,
  required String title,
  String? description,
  VoidCallback? onClose,
  ToastConstant type = .success,
}) => switch (type) {
  .success => _showSuccessToast(context, title, description, onClose),
  .failure => _showFailureToast(context, title, description, onClose),
};

void _showSuccessToast(
  BuildContext context,
  String title,
  String? description,
  VoidCallback? onClose,
) {
  toastification.show(
    style: .flat,
    type: .success,
    context: context,
    alignment: .bottomRight,
    borderRadius: .circular(20.0),
    dismissDirection: .horizontal,
    autoCloseDuration: const Duration(seconds: 6),
    closeButton: ToastCloseButton(showType: .none),
    borderSide: BorderSide(width: 0.0, style: .none),
    backgroundColor: context.colors.surfaceContainer,
    icon: IconWidget(
      name: Icons.celebration_rounded,
      color: context.colors.primary,
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
  );
}

void _showFailureToast(
  BuildContext context,
  String title,
  String? description,
  VoidCallback? onClose,
) {
  toastification.show(
    style: .flat,
    type: .error,
    context: context,
    alignment: .bottomRight,
    borderRadius: .circular(20.0),
    dismissDirection: .horizontal,
    autoCloseDuration: const Duration(seconds: 6),
    closeButton: ToastCloseButton(showType: .none),
    borderSide: BorderSide(width: 0.0, style: .none),
    backgroundColor: context.colors.surfaceContainer,
    icon: IconWidget(name: Icons.error, color: context.colors.error),
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
  );
}
