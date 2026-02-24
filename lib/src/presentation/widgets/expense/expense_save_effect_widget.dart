import 'package:flutter/material.dart';

import 'package:rearch/rearch.dart';
import 'package:flutter_rearch/flutter_rearch.dart';
import 'package:trocado/src/presentation/actions/callback_action.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/capsules/expense_capsule.dart';
import 'package:trocado/src/presentation/data/expense_presentation_data.dart';

class ExpenseSaveEffectWidget extends StatelessWidget {
  const ExpenseSaveEffectWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return RearchBuilder(
      builder: (_, use) {
        final (value, _, setClear) = use(saveExpenseCapsule);

        use.effect(() {
          addPostFrameCallback(() {
            if (value == null) return null;

            switch (value) {
              case ExpenseSavedFailurePresentationData(:final message):
                showToastWidget(context: context, title: message);
              case ExpenseSavedSuccessPresentationData(:final message):
                showToastWidget(
                  context: context,
                  title: message,
                  onClose: context.pop,
                );
            }

            setClear();
          });

          return null;
        }, [value]);

        return const SizedBox.shrink();
      },
    );
  }
}
