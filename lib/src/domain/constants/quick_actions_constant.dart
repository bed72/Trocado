enum QuickActionsConstant {
  input(
    icon: 'ic_bank_arrow_up',
    localizedTitle: 'Nova transação',
    localizedSubtitle: 'Cadastrar uma nova transação',
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
