import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class ScaffoldWidget extends StatelessWidget {
  final Widget child;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final PopInvokedWithResultCallback<dynamic>? onPopInvokedWithResult;

  const ScaffoldWidget({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.onPopInvokedWithResult,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: onPopInvokedWithResult,
      child: Scaffold(
        appBar: appBar,
        body: SafeArea(child: child),
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: SafeArea(
          top: false,
          child: bottomNavigationBar ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
