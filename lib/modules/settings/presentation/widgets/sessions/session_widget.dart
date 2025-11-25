import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class SessionWidget extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SessionWidget({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: .only(top: 32),
      child: Column(
        spacing: 16.0,
        crossAxisAlignment: .start,
        children: [_buildTitle(context), ...children],
      ),
    );
  }

  Text _buildTitle(BuildContext context) =>
      Text(title, style: context.typography.titleMedium);
}
