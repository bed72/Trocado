import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';

import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldWidget(
    appBar: AppBarWidget(leading: GoBackWidget()),
    child: Padding(
      padding: const .all(16.0),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          const ScreenHeaderWidget(
            title: 'Notificações',
            description: 'Acompanhe os alertas e avisos da sua conta.',
          ),

          const SizedBox(height: 24.0),
          const Expanded(child: Placeholder()),
        ],
      ),
    ),
  );
}
