import 'package:flutter/material.dart';
import 'package:trocado/modules/core/presentation/extensions/context_extension.dart';

import 'package:trocado/modules/core/presentation/widgets/bottom-sheets/bottom_sheet_scaffold_widget.dart';

Future<T?> bottomSheetScaffoldWidget<T>({
  required BuildContext context,
  required Widget child,
  final String? title,
  final String? subtitle,
  double marginTop = 32,
  bool autoResize = false,
}) => showModalBottomSheet<T>(
  context: context,
  useSafeArea: true,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (context) => Container(
    constraints: autoResize
        ? null
        : BoxConstraints(maxHeight: context.height - marginTop),
    padding: .only(bottom: context.bottom),
    child: BottomSheetScaffoldWidget(
      title: title,
      subtitle: subtitle,
      child: child,
    ),
  ),
);
