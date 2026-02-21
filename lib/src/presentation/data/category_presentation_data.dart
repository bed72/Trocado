import 'package:flutter/material.dart';
import 'package:trocado/src/domain/models/category_model.dart';

enum CategoryPresentationData {
  gift(
    label: 'Presente',
    icon: Icons.redeem,
    color: Color(0xFFD81B60),
    labelKey: 'label_category_gift',
  ),

  services(
    label: 'Serviços',
    icon: Icons.miscellaneous_services,
    color: Color(0xFF455A64),
    labelKey: 'label_category_services',
  ),

  financing(
    label: 'Financiamento',
    icon: Icons.account_balance,
    color: Color(0xFF5D4037),
    labelKey: 'label_category_financing',
  ),

  housing(
    label: 'Moradia',
    icon: Icons.home,
    color: Color(0xFF283593),
    labelKey: 'label_category_housing',
  ),

  debt(
    label: 'Dívidas',
    icon: Icons.credit_card,
    color: Color(0xFFC62828),
    labelKey: 'label_category_debt',
  ),

  food(
    label: 'Alimentação',
    icon: Icons.restaurant,
    color: Color(0xFFEF6C00),
    labelKey: 'label_category_food',
  ),

  transport(
    label: 'Transporte',
    icon: Icons.directions_car,
    color: Color(0xFF37474F),
    labelKey: 'label_category_transport',
  ),

  bills(
    label: 'Contas',
    icon: Icons.receipt_long,
    color: Color(0xFF6D4C41),
    labelKey: 'label_category_bills',
  ),

  entertainment(
    icon: Icons.movie,
    label: 'Entretenimento',
    color: Color(0xFF512DA8),
    labelKey: 'label_category_entertainment',
  ),

  health(
    label: 'Saúde',
    icon: Icons.favorite,
    color: Color(0xFFD32F2F),
    labelKey: 'label_category_health',
  ),

  education(
    label: 'Educação',
    icon: Icons.school,
    color: Color(0xFF1976D2),
    labelKey: 'label_category_education',
  ),

  shopping(
    label: 'Compras',
    icon: Icons.shopping_bag,
    color: Color(0xFF7B1FA2),
    labelKey: 'label_category_shopping',
  ),

  subscription(
    label: 'Assinaturas',
    icon: Icons.subscriptions,
    color: Color(0xFF00695C),
    labelKey: 'label_category_subscription',
  ),

  other(
    label: 'Outros',
    icon: Icons.category,
    color: Color(0xFF9E9E9E),
    labelKey: 'label_category_other',
  );

  final Color color;
  final IconData icon;
  final String labelKey;
  final String label;

  const CategoryPresentationData({
    required this.icon,
    required this.color,
    required this.labelKey,
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
