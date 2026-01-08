import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldWidget(
      title: 'Categories',
      child: Center(child: Text('Categories')),
    );
  }
}
