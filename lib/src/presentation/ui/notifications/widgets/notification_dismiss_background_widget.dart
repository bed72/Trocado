import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class NotificationDismissBackgroundWidget extends StatelessWidget {
  const NotificationDismissBackgroundWidget({super.key});

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.centerRight,
    color: context.colors.error.withValues(alpha: 0.9),
    padding: const EdgeInsets.symmetric(horizontal: 24.0),
    child: Icon(Icons.delete_outline, color: context.colors.onError),
  );
}
