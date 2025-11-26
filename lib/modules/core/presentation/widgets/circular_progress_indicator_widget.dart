import 'package:flutter/material.dart';

import 'package:trocado/modules/core/presentation/extensions/context_extension.dart';

class CircularProgressIndicatorWidget extends StatelessWidget {
  const CircularProgressIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator.adaptive(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation(context.colors.onPrimary),
      ),
    );
  }
}
