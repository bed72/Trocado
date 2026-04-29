import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/cards/icon_card_widget.dart';

class SettingsInvitePartnerWidget extends StatelessWidget {
  final VoidCallback onTap;

  const SettingsInvitePartnerWidget({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => IconCardWidget(
    onPress: onTap,
    icon: Icons.person_add_alt,
    title: 'Convidar parceiro',
    description: 'Comecem a usar juntos',
    trailing: Icons.chevron_right,
  );
}
