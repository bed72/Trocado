import 'package:flutter/material.dart';
import 'package:trocado/modules/core/presentation/extensions/context_extension.dart';

class ScaffoldWidget extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final PopInvokedWithResultCallback<dynamic>? onPopInvokedWithResult;

  const ScaffoldWidget({
    super.key,
    required this.child,
    this.appBar,
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
      ),
    );
  }
}
