import 'package:flutter/material.dart';

import 'package:trocado/src/domain/enums/notification/notification_type_enum.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

extension NotificationTypeVisualExtension on NotificationTypeEnum {
  IconData get icon => switch (this) {
    .budgetEightyPercent => Icons.warning_amber_rounded,
    .sharedExpenseCreated => Icons.shopping_cart_outlined,
    .unknown => Icons.notifications_outlined,
  };

  String get label => switch (this) {
    .sharedExpenseCreated => 'Casal',
    .budgetEightyPercent => 'Orçamento',
    .unknown => 'Aviso',
  };

  Color color(BuildContext context) => switch (this) {
    .budgetEightyPercent => context.colors.error,
    .sharedExpenseCreated => context.colors.primary,
    .unknown => context.colors.outline,
  };
}
