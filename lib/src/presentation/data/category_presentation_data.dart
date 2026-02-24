import 'package:flutter/material.dart';
import 'package:trocado/src/domain/models/category_model.dart';

enum CategoryPresentationData {
  housing(label: 'Moradia', icon: Icons.home, color: Color(0xFF283593)),
  gift(label: 'Presente', icon: Icons.redeem, color: Color(0xFFD81B60)),
  health(label: 'Saúde', icon: Icons.favorite, color: Color(0xFFD32F2F)),
  debt(label: 'Dívidas', icon: Icons.credit_card, color: Color(0xFFC62828)),
  bills(label: 'Contas', icon: Icons.receipt_long, color: Color(0xFF6D4C41)),
  education(label: 'Educação', icon: Icons.school, color: Color(0xFF1976D2)),
  food(label: 'Alimentação', icon: Icons.restaurant, color: Color(0xFFEF6C00)),
  shopping(
    label: 'Compras',
    icon: Icons.shopping_bag,
    color: Color(0xFF7B1FA2),
  ),
  financing(
    label: 'Financiamento',
    color: Color(0xFF5D4037),
    icon: Icons.account_balance,
  ),
  transport(
    label: 'Transporte',
    icon: Icons.directions_car,
    color: Color(0xFF37474F),
  ),
  entertainment(
    icon: Icons.movie,
    label: 'Entretenimento',
    color: Color(0xFF512DA8),
  ),
  subscription(
    label: 'Assinaturas',
    icon: Icons.subscriptions,
    color: Color(0xFF00695C),
  ),
  services(
    label: 'Serviços',
    color: Color(0xFF455A64),
    icon: Icons.miscellaneous_services,
  ),
  other(label: 'Outros', icon: Icons.category, color: Color(0xFF9E9E9E));

  final Color color;
  final String label;
  final IconData icon;

  const CategoryPresentationData({
    required this.icon,
    required this.color,
    required this.label,
  });

  static CategoryPresentationData fromName(String name) =>
      CategoryPresentationData.values.firstWhere(
        (category) => category.name == name,
        orElse: () => CategoryPresentationData.other,
      );

  static CategoryPresentationData fromModel(CategoryModel model) =>
      switch (model) {
        CategoryModel.debt => CategoryPresentationData.debt,
        CategoryModel.food => CategoryPresentationData.food,
        CategoryModel.gift => CategoryPresentationData.gift,
        CategoryModel.bills => CategoryPresentationData.bills,
        CategoryModel.other => CategoryPresentationData.other,
        CategoryModel.health => CategoryPresentationData.health,
        CategoryModel.housing => CategoryPresentationData.housing,
        CategoryModel.services => CategoryPresentationData.services,
        CategoryModel.shopping => CategoryPresentationData.shopping,
        CategoryModel.financing => CategoryPresentationData.financing,
        CategoryModel.transport => CategoryPresentationData.transport,
        CategoryModel.education => CategoryPresentationData.education,
        CategoryModel.subscription => CategoryPresentationData.subscription,
        CategoryModel.entertainment => CategoryPresentationData.entertainment,
      };
}
