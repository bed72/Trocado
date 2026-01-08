import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldWidget(
      title: 'User',
      child: Center(child: Text('User data')),
    );
  }
}
