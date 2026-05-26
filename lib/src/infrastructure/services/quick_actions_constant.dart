enum QuickActionsConstant {
  budget(
    icon: 'ic_bank_arrow_up',
    localizedTitle: 'Novo orçamento',
    localizedSubtitle: 'Cadastrar novo orçamento.',
  ),
  expense(
    icon: 'ic_bank_arrow_down',
    localizedTitle: 'Nova despesa',
    localizedSubtitle: 'Cadastrar nova despesa.',
  );

  final String icon;
  final String localizedTitle;
  final String localizedSubtitle;

  const QuickActionsConstant({
    required this.icon,
    required this.localizedTitle,
    required this.localizedSubtitle,
  });
}
