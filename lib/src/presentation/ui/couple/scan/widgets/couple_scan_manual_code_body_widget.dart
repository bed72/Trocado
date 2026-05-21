import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_intent.dart';
import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_notifier.dart';
import 'package:trocado/src/presentation/ui/couple/scan/validators/invite_code_validation.dart';
import 'package:trocado/src/presentation/ui/couple/scan/formatters/uppercase_alphabet_formatter.dart';

class CoupleScanManualCodeBodyWidget extends StatelessWidget {
  const CoupleScanManualCodeBodyWidget({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const .only(top: 16.0),
    child: Consumer(
      builder: (_, ref, _) {
        ref.listen(coupleScanProvider, (_, next) {
          if (next case AsyncData(:final value)
              when value.status != .ready &&
                  value.status != .permissionDenied &&
                  value.status != .cameraUnavailable) {
            context.pop();
          }
        });

        final state = ref.watch(
          coupleScanProvider.select((async) => async.value),
        );
        final notifier = ref.read(coupleScanProvider.notifier);

        if (state == null) return const SizedBox.shrink();

        return Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          spacing: 16.0,
          children: [
            TextFieldWidget(
              label: 'Código',
              autofocus: true,
              hint: 'Ex.: AB3K7N',
              failure: state.manualCodeFailure,
              onChanged: (value) => notifier.dispatch(ManualCodeChanged(value)),
              inputFormatters: [
                LengthLimitingTextInputFormatter(InviteCodeValidation.length),
                UppercaseAlphabetFormatter(),
              ],
            ),
            SizedBox(
              width: .infinity,
              child: ButtonWidget.elevated(
                label: 'Confirmar',
                onTap: () => notifier.dispatch(const ManualCodeSubmitted()),
              ),
            ),
          ],
        );
      },
    ),
  );
}
