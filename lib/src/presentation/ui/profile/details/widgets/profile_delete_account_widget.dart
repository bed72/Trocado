import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

class ProfileDeleteAccountWidget extends StatelessWidget {
  final VoidCallback onTap;

  const ProfileDeleteAccountWidget({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    width: .infinity,
    padding: const .only(top: 16.0),
    child: ButtonWidget.elevated(label: 'Excluir conta', onTap: onTap),
  );
}
