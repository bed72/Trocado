// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:duck_router/duck_router.dart';

import 'package:trocado/src/presentation/actions/callback_action.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

final class BottomSheetPage<T> extends DuckPage<T> {
  final WidgetBuilder builder;

  BottomSheetPage({required this.builder})
    : super.custom(
        isModal: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );

  @override
  Route<T> createRoute(BuildContext context, RouteSettings? settings) =>
      PageRouteBuilder<T>(
        opaque: false,
        settings: settings,
        transitionDuration: .zero,
        maintainState: maintainState,
        reverseTransitionDuration: .zero,
        barrierColor: Colors.transparent,
        pageBuilder: (context, _, _) {
          addPostFrameCallback(() {
            showModalBottomSheet<T>(
              context: context,
              useSafeArea: true,
              isScrollControlled: true,
              builder: (_) => builder(context),
              backgroundColor: context.colors.surfaceContainerLowest,
            ).then((value) {
              if (context.canPop()) context.pop(value);
            });
          });

          return const SizedBox.shrink();
        },
      );
}
