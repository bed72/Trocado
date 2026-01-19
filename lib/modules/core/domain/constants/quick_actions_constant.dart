enum QuickActionsConstant {
  input(
    icon: 'ic_bank_arrow_up',
    localizedTitle: 'Nova entrada',
    localizedSubtitle: 'Cadastrar nova entrada',
  ),
  output(
    icon: 'ic_bank_arrow_down',
    localizedTitle: 'Nova saída',
    localizedSubtitle: 'Cadastrar nova saída',
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
