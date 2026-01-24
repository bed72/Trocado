import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class HomeAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      toolbarHeight: 72.0,
      title: SelectorWidget(
        selected: 0,
        onSelected: (value) {},
        options: ['Todas', 'Despesas', 'Receitas'],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
