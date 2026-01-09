import 'package:flutter/material.dart';

import 'package:trocado/modules/core/presentation/states/transaction_type_state.dart';

enum CategoryState {
  salary(
    types: {.income},
    label: 'Salário',
    color: Colors.blue,
    icon: Icons.attach_money,
  ),
  freelance(
    types: {.income},
    label: 'Freelance',
    icon: Icons.work_outline,
    color: Colors.lightBlue,
  ),
  bonus(
    types: {.income},
    label: 'Bônus',
    color: Colors.teal,
    icon: Icons.card_giftcard,
  ),
  investment(
    types: {.income},
    color: Colors.green,
    label: 'Investimentos',
    icon: Icons.trending_up,
  ),
  gift(
    types: {.income},
    label: 'Presente',
    icon: Icons.redeem,
    color: Colors.purple,
  ),

  food(
    types: {.expense},
    label: 'Alimentação',
    icon: Icons.restaurant,
    color: Colors.orange,
  ),
  transport(
    types: {.expense},
    label: 'Transporte',
    color: Colors.indigo,
    icon: Icons.directions_car,
  ),
  bills(
    types: {.expense},
    label: 'Contas',
    icon: Icons.receipt_long,
    color: Colors.redAccent,
  ),
  entertainment(
    types: {.expense},
    icon: Icons.movie,
    color: Colors.pink,
    label: 'Entretenimento',
  ),
  health(
    label: 'Saúde',
    types: {.expense},
    color: Colors.red,
    icon: Icons.favorite,
  ),
  education(
    types: {.expense},
    label: 'Educação',
    icon: Icons.school,
    color: Colors.brown,
  ),
  shopping(
    types: {.expense},
    label: 'Compras',
    icon: Icons.shopping_bag,
    color: Colors.deepPurple,
  ),
  subscription(
    types: {.expense},
    label: 'Assinaturas',
    color: Colors.cyan,
    icon: Icons.subscriptions,
  ),

  other(
    label: 'Outros',
    types: {.income, .expense},
    icon: Icons.category,
    color: Colors.grey,
  );

  final Color color;
  final String label;
  final IconData icon;
  final Set<TransactionTypeState> types;

  const CategoryState({
    required this.label,
    required this.types,
    required this.icon,
    required this.color,
  });
}
