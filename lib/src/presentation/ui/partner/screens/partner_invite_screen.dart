import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';

class PartnerInviteScreen extends StatelessWidget {
  const PartnerInviteScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldWidget(
    appBar: AppBarWidget(leading: GoBackWidget()),
    child: Padding(
      padding: const .all(16.0),
      child: Column(
        crossAxisAlignment: .start,
        children: const [
          ScreenHeaderWidget(
            title: 'Convidar parceiro',
            description: 'Comecem a usar juntos.',
          ),
          SizedBox(height: 16.0),
          Expanded(child: Placeholder()),
        ],
      ),
    ),
  );
}
