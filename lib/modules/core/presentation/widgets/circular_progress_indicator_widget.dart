import 'package:flutter/material.dart';

import 'package:trocado/modules/core/presentation/extensions/context_extension.dart';

class CircularProgressIndicatorWidget extends StatelessWidget {
  final Color? color;

  const CircularProgressIndicatorWidget({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator.adaptive(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation(color ?? context.colors.onPrimary),
      ),
    );
  }
}
