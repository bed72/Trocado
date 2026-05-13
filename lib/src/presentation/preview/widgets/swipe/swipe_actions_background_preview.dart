import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/swipe/swipe_actions_background_widget.dart';

import 'package:trocado/src/presentation/preview/trocado_preview.dart';

@TrocadoPreview(group: 'Swipe', name: 'Trailing (delete)')
Widget previewSwipeTrailing() => Builder(
  builder: (context) => Scaffold(
    body: Center(
      child: SizedBox(
        height: 72.0,
        child: SwipeActionsBackgroundWidget.trailing(
          icon: Icons.delete_outline,
          color: context.colors.error,
          iconColor: context.colors.onError,
        ),
      ),
    ),
  ),
);

@TrocadoPreview(group: 'Swipe', name: 'Leading (edit)')
Widget previewSwipeLeading() => Builder(
  builder: (context) => Scaffold(
    body: Center(
      child: SizedBox(
        height: 72.0,
        child: SwipeActionsBackgroundWidget.leading(
          icon: Icons.edit_outlined,
          color: context.colors.primary,
          iconColor: context.colors.onPrimary,
        ),
      ),
    ),
  ),
);
