import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/circular_progress_indicator_widget.dart';

class ExpensesLoadMoreLoadingWidget extends StatelessWidget {
  const ExpensesLoadMoreLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const .symmetric(vertical: 16.0),
    child: CircularProgressIndicatorWidget(color: context.colors.primary),
  );
}
