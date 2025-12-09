import 'dart:async';

import 'package:flutter/widgets.dart';

mixin AfterLayoutMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) afterFirstLayout(context);
    });
  }

  FutureOr<void> afterFirstLayout(BuildContext context);
}
