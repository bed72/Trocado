import 'package:flutter/material.dart';

import 'package:trocado/src/domain/models/expense/expense_category.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

extension ExpenseCategoryVisualExtension on ExpenseCategory {
  IconData get icon => switch (this) {
    .housing => Icons.home_outlined,
    .health => Icons.favorite_outline,
    .food => Icons.restaurant_outlined,
    .entertainment => Icons.movie_outlined,
    .debt => Icons.account_balance_outlined,
    .unknown => Icons.receipt_long_outlined,
    .shopping => Icons.shopping_bag_outlined,
    .transport => Icons.directions_car_outlined,
  };

  String get label => switch (this) {
    .health => 'Saúde',
    .debt => 'Dívidas',
    .housing => 'Moradia',
    .unknown => 'Despesa',
    .shopping => 'Compras',
    .food => 'Alimentação',
    .entertainment => 'Lazer',
    .transport => 'Transporte',
  };

  Color color(BuildContext context) => switch (this) {
    .debt => context.colors.error,
    .health => context.colors.error,
    .food => context.colors.tertiary,
    .unknown => context.colors.outline,
    .housing => context.colors.tertiary,
    .transport => context.colors.primary,
    .shopping => context.colors.secondary,
    .entertainment => context.colors.secondary,
  };
}
