import 'package:flutter/material.dart';

import 'package:trocado/modules/core/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/modules/core/presentation/stores/bottom_bar_store.dart';
import 'package:trocado/modules/core/presentation/extensions/context_extension.dart';

class ScaffoldWidget extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;

  const ScaffoldWidget({
    super.key,
    required this.child,
    this.title,
    this.leading,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final store = context.get<BottomBarStore>();

    return PopScope(
      onPopInvokedWithResult: (_, _) {
        store.onChanged(true);
      },
      child: Scaffold(
        appBar: AppBarWidget(title: title, leading: leading, actions: actions),
        body: SafeArea(child: child),
      ),
    );
  }
}
